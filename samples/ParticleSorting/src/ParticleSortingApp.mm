#include "cinder/app/App.h"
#include "cinder/Rand.h"

// Cinder-Metal
#include "metal.h"
#include "VertexBuffer.h"

// TMP
#include <Metal/Metal.h>
#include "RendererMetalImpl.h"


using namespace ci;
using namespace ci::app;
using namespace std;
using namespace cinder::mtl;

static const size_t MAX_BYTES_PER_FRAME = 1024*1024;

const static int kNumInflightBuffers = 3;
const static int kParticleDimension = 32;

typedef struct {
    vec3 position;
    vec3 velocity;
} Particle;

class ParticleSortingApp : public App {

public:
    
    ParticleSortingApp() :
    mRotation(0.f)
    {}
    
    void setup() override;
    void loadAssets();
    void resize() override;
    void update() override;
    void draw() override;
    
    SamplerStateRef mSamplerMipMapped;
    DepthStateRef mDepthEnabled;
    
    ciUniforms_t mUniforms;
    DataBufferRef mDynamicConstantBuffer;
    uint8_t mConstantDataBufferIndex;
    
    float mRotation;
    CameraPersp mCamera;
    
    // Teapot
    VertexBufferRef mGeomBufferTeapot;
    RenderPipelineStateRef mPipelineGeomLighting;
    
    // Particles
    DataBufferRef mParticleBuffer;
    DataBufferRef mParticleIndicesBuffer;
    RenderPassDescriptorRef mRenderDescriptor;
    RenderPipelineStateRef mPipelineParticles;
    
    // Sort pass
    ComputePipelineStateRef mPipelineSorting;
};

void ParticleSortingApp::setup()
{
    mConstantDataBufferIndex = 0;
    
    mSamplerMipMapped = SamplerState::create();
    mDepthEnabled = DepthState::create();
    
    mRenderDescriptor = RenderPassDescriptor::create( RenderPassDescriptor::Format()
                                                     .clearColor( ColorAf(0.5f,0.f,1.f,1.f) ) );

    loadAssets();
}

void ParticleSortingApp::resize()
{
    mCamera = CameraPersp(getWindowWidth(), getWindowHeight(), 65.f, 0.1f, 100.f);
    mCamera.lookAt(vec3(0,0,-5), vec3(0));
}

void ParticleSortingApp::loadAssets()
{
    mDynamicConstantBuffer = DataBuffer::create(MAX_BYTES_PER_FRAME, nullptr, "Uniform Buffer");
    
    mGeomBufferTeapot = VertexBuffer::create( ci::geom::Teapot(),
                                             {{ci::geom::INDEX,
                                               ci::geom::POSITION,
                                               ci::geom::NORMAL }});
    mPipelineGeomLighting = RenderPipelineState::create("vertex_lighting_geom",
                                                        "fragment_color",
                                                        RenderPipelineState::Format()
                                                        .depthEnabled(true)
                                                        .blendingEnabled(true) );
    
    
    // Set up the particles
    vector<Particle> particles;
    vector<int> indices;
    ci::Rand random;
    random.seed((UInt32)time(NULL));
    for ( int y = 0; y < kParticleDimension; ++y )
    {
        for ( int x = 0; x < kParticleDimension; ++x )
        {
            Particle p;
            p.position = random.randVec3();
            p.velocity = random.randVec3();
            particles.push_back(p);
            indices.push_back((int)indices.size());
        }
    }
    mParticleBuffer = DataBuffer::create(particles);
    mParticleIndicesBuffer = DataBuffer::create(indices);
    mPipelineParticles = RenderPipelineState::create("vertex_particles", "fragment_color",
                                                     RenderPipelineState::Format()
                                                     .depthEnabled(true)
                                                     .blendingEnabled(true));
    
    mPipelineSorting = ComputePipelineState::create("kernel_sort");
}

void ParticleSortingApp::update()
{
    mat4 modelMatrix = glm::rotate(mRotation, vec3(1.0f, 1.0f, 1.0f));
    mat4 normalMatrix = inverse(transpose(modelMatrix));
    mat4 modelViewMatrix = mCamera.getViewMatrix() * modelMatrix;
    mat4 modelViewProjectionMatrix = mCamera.getProjectionMatrix() * modelViewMatrix;
    
    // Is there a clean way to automatically wrap these up?
    mUniforms.normalMatrix = toMtl(normalMatrix);
    mUniforms.modelViewProjectionMatrix = toMtl(modelViewProjectionMatrix);
    mUniforms.viewMatrix = toMtl(mCamera.getViewMatrix());
    mUniforms.inverseViewMatrix = toMtl(mCamera.getInverseViewMatrix());
    mUniforms.inverseModelMatrix = toMtl(inverse(modelMatrix));
    mUniforms.modelMatrix = toMtl(modelMatrix);
    mUniforms.modelViewMatrix = toMtl(modelViewMatrix);
    mUniforms.elapsedSeconds = getElapsedSeconds();
    mDynamicConstantBuffer->setData( &mUniforms, mConstantDataBufferIndex );

    mRotation += 0.0015f;
}

void ParticleSortingApp::draw()
{
    uint constantsOffset = (sizeof(ciUniforms_t) * mConstantDataBufferIndex);

    {
        ScopedCommandBuffer commandBuffer;
        
        {
            ScopedComputeEncoder computeEncoder(commandBuffer());
            
            computeEncoder()->setPipelineState(mPipelineSorting);

            computeEncoder()->setUniforms( mDynamicConstantBuffer, constantsOffset );
            computeEncoder()->setBufferAtIndex( mParticleBuffer, 1 );
            computeEncoder()->setBufferAtIndex( mParticleIndicesBuffer, 2 );
            
            computeEncoder()->dispatch( ivec3( kParticleDimension, kParticleDimension, 1 ) );

        } // scoped compute

        {
            ScopedRenderEncoder renderEncoder(commandBuffer(), mRenderDescriptor);
            
            // Enable depth
            renderEncoder()->setDepthStencilState(mDepthEnabled);
            
            // Enable mip-mapping
            renderEncoder()->setFragSamplerState(mSamplerMipMapped);
            
            renderEncoder()->setUniforms( mDynamicConstantBuffer, constantsOffset );
            
            // Draw Teapot
            renderEncoder()->pushDebugGroup("Draw Geom Teapot");
            
            // Set the program
            renderEncoder()->setPipelineState( mPipelineGeomLighting );
            
            // Draw
            mGeomBufferTeapot->draw( renderEncoder() );
            
            renderEncoder()->popDebugGroup();
            
            
            // Draw particles
            // Geom Target
            renderEncoder()->pushDebugGroup("Draw Particles");
            
            // Set the program
            renderEncoder()->setPipelineState( mPipelineParticles );

            renderEncoder()->setBufferAtIndex( mParticleBuffer, ciBufferIndexInterleavedVerts );
            
            // Send in the sorted indices
            renderEncoder()->setBufferAtIndex( mParticleIndicesBuffer, ciBufferIndexIndicies );
            //renderEncoder()->setBufferAtIndex( particleIndicesBuffer, ciBufferIndexIndicies );
            
            renderEncoder()->draw( mtl::geom::POINT, kParticleDimension * kParticleDimension );

            renderEncoder()->popDebugGroup();

            
        } // scoped render encoder
        
    } // scoped command buffer
    
    mConstantDataBufferIndex = (mConstantDataBufferIndex + 1) % kNumInflightBuffers;
}

CINDER_APP( ParticleSortingApp, RendererMetal( RendererMetal::Options().numInflightBuffers(kNumInflightBuffers) ) )
