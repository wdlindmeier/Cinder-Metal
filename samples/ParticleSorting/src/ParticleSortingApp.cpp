#include "cinder/app/App.h"
#include "cinder/Rand.h"
#include "cinder/Log.h"

// Cinder-Metal
#include "metal.h"
#include "VertexBuffer.h"
#include "SharedData.h"

using namespace ci;
using namespace ci::app;
using namespace std;

const static int kNumSortStateBuffers = 91; // Must be >= the number of sort passes
const static int kNumInflightBuffers = 4;

typedef struct {
    vec3 position;
    vec3 velocity;
} Particle;

class ParticleSortingApp : public App
{
public:
    
    ParticleSortingApp() :
    mRotation(0.f)
    ,mModelScale(2.f)
    {}
    
    void setup() override;
    void loadAssets();
    void resize() override;
    void update() override;
    void draw() override;
    void mouseDown( MouseEvent event ) override;
    void mouseDrag( MouseEvent event ) override;

    void bitonicSort( bool shouldLogOutput );
    void logComputeOutput( const myUniforms_t uniforms );
    void calculateDepths( mtl::ScopedCommandBuffer & commandBuffer );
    
    unsigned int mNumParticles;
    mtl::UniformBlock<myUniforms_t> mUniforms;

    float mRotation;
    CameraPersp mCamera;
    vec2 mMousePos;
    float mModelScale;

    // Particles
    mtl::DataBufferRef mParticlesUnsorted;
    mtl::DataBufferRef mParticleIndices;
    mtl::DataBufferRef mParticleDepths;
    mtl::DataBufferRef mSortStateBuffer;
    mtl::RenderPassDescriptorRef mRenderDescriptor;
    mtl::RenderPipelineStateRef mPipelineParticles;
    mtl::TextureBufferRef mTextureParticle;
    
    // Sort pass
    mtl::ComputePipelineStateRef mPipelineCalculateDepths;
    mtl::ComputePipelineStateRef mPipelineBitonicSort;
};

void ParticleSortingApp::setup()
{
    mNumParticles = mUniforms.getData().numParticles;
    
    mRenderDescriptor = mtl::RenderPassDescriptor::create(mtl::RenderPassDescriptor::Format()
                                                          .clearColor( ColorAf(0.5f,0.f,1.f,1.f)));

    loadAssets();
}

void ParticleSortingApp::resize()
{
    mCamera = CameraPersp(getWindowWidth(), getWindowHeight(), 65.f, 0.1f, 100.f);
    mCamera.lookAt(vec3(0,0,-5), vec3(0));
}

void ParticleSortingApp::loadAssets()
{
    mSortStateBuffer = mtl::DataBuffer::create( mtlConstantSizeOf(sortState_t) * kNumSortStateBuffers,
                                                nullptr,
                                                mtl::DataBuffer::Format().label("Sort State Buffer").isConstant() );

    // Set up the particles
    vector<Particle> particles;
    vector<ivec4> indices;
    vector<float> particleDepths;
    ci::Rand random;
    random.seed((UInt32)time(NULL));
    for ( unsigned int i = 0; i < kParticleDimension * kParticleDimension; ++i )
    {
        Particle p;
        p.position = random.randVec3();
        p.velocity = random.randVec3();
        particles.push_back(p);
        if ( i % 4 == 0 )
        {
            indices.push_back(ivec4(i, i+1, i+2, i+3));
        }
        particleDepths.push_back(p.position.z);
    }

    // Make sure we've got the right number of indices
    assert( float(indices.size()) == particles.size() / 4.0f );

    mPipelineParticles = mtl::RenderPipelineState::create("vertex_particles", "fragment_point_texture",
                                                          mtl::RenderPipelineState::Format()
                                                          .blendingEnabled());
    
    mTextureParticle = mtl::TextureBuffer::create(loadImage(getAssetPath("particle.png")));
    
    mParticlesUnsorted = mtl::DataBuffer::create(particles, mtl::DataBuffer::Format().label("Particles"));
    mParticleDepths = mtl::DataBuffer::create(particleDepths, mtl::DataBuffer::Format().label("Depths").isConstant(true));
    mParticleIndices = mtl::DataBuffer::create(indices, mtl::DataBuffer::Format().label("Indices"));
    mPipelineBitonicSort = mtl::ComputePipelineState::create("bitonic_sort_by_value");
    mPipelineCalculateDepths = mtl::ComputePipelineState::create("calculate_particle_depths");
}

void ParticleSortingApp::mouseDown( MouseEvent event )
{
    mMousePos = event.getPos();
}

void ParticleSortingApp::mouseDrag( MouseEvent event )
{
    // As the finger moves away from the center, scale up.
    vec2 newPos = event.getPos();
    vec2 offset = newPos - mMousePos;
    float gestureLength = length(offset);
    if ( distance(newPos, getWindowCenter()) <
         distance(mMousePos, getWindowCenter()) )
    {
        // We're getting closer to the center.
        // Scale down.
        gestureLength *= -1;
    }
    mMousePos = newPos;
    mModelScale = ci::math<float>::clamp(mModelScale + (gestureLength / getWindowCenter().x),
                                         1.f, 3.f );
}

void ParticleSortingApp::update()
{
    mRotation += 0.0015f;
    
    // Create the matrices
    mat4 modelMatrix = glm::rotate(mRotation, vec3(1.0f, 1.0f, 1.0f));
    modelMatrix = glm::scale(modelMatrix, vec3(mModelScale));
    mat4 modelViewMatrix = mCamera.getViewMatrix() * modelMatrix;
    mat4 modelViewProjectionMatrix = mCamera.getProjectionMatrix() * modelViewMatrix;
    
    // Set the uniform data
    mUniforms.updateData([&]( auto data )
    {
        data.modelViewProjectionMatrix = toMtl(modelViewProjectionMatrix);
        data.modelMatrix = toMtl(modelMatrix);
        return data;
    });

    bitonicSort( false );
}

// NOTE: We pass in a copy of the uniforms because they may have changed
// by the time the compute is finished.
void ParticleSortingApp::logComputeOutput( const myUniforms_t uniforms )
{
    ivec4 *sortedIndices = (ivec4 *)mParticleIndices->contents();
    Particle *particles = (Particle *)mParticlesUnsorted->contents();

    CI_LOG_I("Sorted Z values:");
    for ( long i = 0; i < mNumParticles / 4; ++i )
    {
        ivec4 v = sortedIndices[i];
        for ( int j = 0; j < 4; ++j )
        {
            int index = v[j];
            Particle & p = particles[index];
            vec4 pos = fromMtl(uniforms.modelMatrix) * vec4(p.position, 0.f);
            float value = pos.z;
            printf("%f, ", value);
        }
    }
}

void ParticleSortingApp::calculateDepths( mtl::ScopedCommandBuffer & commandBuffer )
{
    mtl::ScopedComputeEncoder computeEncoder = commandBuffer.scopedComputeEncoder();
    
    computeEncoder.setPipelineState(mPipelineCalculateDepths);
    computeEncoder.setBufferAtIndex(mParticleDepths, 1);
    computeEncoder.setBufferAtIndex(mParticlesUnsorted, 2);
    mUniforms.sendToEncoder(computeEncoder);
    
    long arraySize = mNumParticles;
    computeEncoder.dispatch(ivec3(arraySize, 1, 1), ivec3(32,1,1));
}

void ParticleSortingApp::bitonicSort( bool shouldLogOutput )
{
    mtl::ScopedCommandBuffer commandBuffer;

    // Calculate the particle depths once before sorting
    calculateDepths( commandBuffer );

    int passNum = 0;
    uint arraySize = mNumParticles;
    int numStages = 0;
    
    // Calculate the number of stages
    for ( uint temp = arraySize; temp > 2; temp >>= 1 )
    {
        numStages++;
    }
    
    // NOTE:
    // If we log out the results while the command buffer is still running, the values might
    // have already changed. This can be fixed by logging out in the completion handler.
    if ( shouldLogOutput )
    {
        myUniforms_t uniformsCopy = mUniforms.getData();
        commandBuffer.addCompletionHandler([&]( void * mtlCommandBuffer )
        {
            logComputeOutput(uniformsCopy);
        });
    }
    
    mtl::ScopedComputeEncoder computeEncoder = commandBuffer.scopedComputeEncoder();
    
    for ( int stage = 0; stage < numStages; stage++ )
    {
        for ( int passOfStage = stage; passOfStage >= 0; passOfStage-- )
        {
            sortState_t sortState;
            sortState.stage = stage;
            sortState.pass = passOfStage;
            sortState.passNum = passNum;
            sortState.direction = 1; // ascending
            mSortStateBuffer->setDataAtIndex(&sortState, passNum);
            
            computeEncoder.setPipelineState(mPipelineBitonicSort);
            
            computeEncoder.setBufferAtIndex(mParticleIndices, 1);
            computeEncoder.setBufferAtIndex(mParticleDepths, 2);
            computeEncoder.setBufferAtIndex(mSortStateBuffer, 3,
                                               mtlConstantSizeOf(sortState_t) * passNum);
            
            mUniforms.sendToEncoder(computeEncoder);
            
            size_t gsz = arraySize / (2*4);
            // NOTE: work size is not 1-per vector.
            // Its the number of quad items in input array
            size_t globalWorkSize = passOfStage ? gsz : gsz << 1;
            
            computeEncoder.dispatch(ivec3(globalWorkSize, 1, 1), ivec3(32,1,1));
            assert( passNum < kNumSortStateBuffers );
            passNum++;
        }
    }
}

void ParticleSortingApp::draw()
{
    mtl::ScopedRenderCommandBuffer renderBuffer;
    mtl::ScopedRenderEncoder renderEncoder = renderBuffer.scopedRenderEncoder(mRenderDescriptor);

    // Set uniforms
    mUniforms.sendToEncoder(renderEncoder);
   
    // Set the program
    renderEncoder.setPipelineState(mPipelineParticles);

    // Pass in the unsorted particles
    renderEncoder.setVertexBufferAtIndex(mParticlesUnsorted, mtl::ciBufferIndexInterleavedVerts);

    // Pass in the sorted particle indices
    renderEncoder.setVertexBufferAtIndex(mParticleIndices, mtl::ciBufferIndexIndices);

    renderEncoder.setTexture(mTextureParticle);
    
    renderEncoder.draw(mtl::geom::POINT, mNumParticles);
}

CINDER_APP( ParticleSortingApp,
            RendererMetal(RendererMetal::Options()
                          .numInflightBuffers(kNumInflightBuffers)),
            []( ParticleSortingApp::Settings *settings )
            {
                // Just observe 1 touch for scaling
                settings->setMultiTouchEnabled(false);
            }
          )
