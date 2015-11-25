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
using namespace cinder::mtl;

const static int kNumInflightBuffers = 3;
const static int kNumSortStateBuffers = 128;

typedef struct {
    vec3 position;
    vec3 velocity;
} Particle;

class ParticleSortingApp : public App {

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
    void debugSort();
    void debugSimpleSort();
    void logComputeOutput( const myUniforms_t uniforms );
    void logTestOutput();
    void logIndices();
    void resetDebugBuffer();
    
    SamplerStateRef mSamplerMipMapped;
    DepthStateRef mDepthEnabled;
    
    myUniforms_t mUniforms;
    debugInfo_t mDebugInfo;
    DataBufferRef mDynamicConstantBuffer;
    DataBufferRef mSortStateBuffer;
    uint8_t mConstantDataBufferIndex;
    
    float mRotation;
    CameraPersp mCamera;
    
    // Teapot
    VertexBufferRef mGeomBufferTeapot;
    RenderPipelineStateRef mPipelineGeomLighting;
    
    // Particles
    DataBufferRef mParticlesUnsorted;
    DataBufferRef mParticleIndices;
    RenderPassDescriptorRef mRenderDescriptor;
    RenderPipelineStateRef mPipelineParticles;
    TextureBufferRef mTextureParticle;
    DataBufferRef mDebugBuffer;
    DataBufferRef mRandomIntsBuffer;
    
    // Sort pass
    ComputePipelineStateRef mPipelineDebugSort;
    ComputePipelineStateRef mPipelineSimpleSort;
    ComputePipelineStateRef mPipelineBitonicSort;
    
    long mParticleBufferLength;
    
    vec2 mMousePos;
    float mModelScale;
};

#include <UIKit/UIKit.h>

void ParticleSortingApp::setup()
{
    mConstantDataBufferIndex = 0;
    
    mSamplerMipMapped = SamplerState::create();

    mDepthEnabled = DepthState::create( DepthState::Format().depthCompareFunction(7) );
    
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
    mDynamicConstantBuffer = DataBuffer::create( sizeof(myUniforms_t) * kNumInflightBuffers,
                                                 nullptr,
                                                 "Uniform Buffer" );
    
    mSortStateBuffer = DataBuffer::create( sizeof(sortState_t) * kNumSortStateBuffers,
                                           nullptr,
                                           "Sort State Buffer" );
    
    mDebugBuffer = DataBuffer::create( sizeof(debugInfo_t), // * kNumSortStateBuffers,
                                       nullptr,
                                       "Debug Buffer" );
    // NOTE: Only set it from the CPU once, otherwise data from the GPU will get clobbered
    
    resetDebugBuffer();

    mGeomBufferTeapot = VertexBuffer::create( ci::geom::Teapot(),
                                             {{ci::geom::INDEX,
                                               ci::geom::POSITION,
                                               ci::geom::NORMAL }});
    
    mPipelineGeomLighting = RenderPipelineState::create("vertex_lighting_geom",
                                                        "fragment_color",
                                                        RenderPipelineState::Format()
                                                        .blendingEnabled(true) );

    // Set up the particles
    vector<Particle> particles;
    vector<ivec4> indices;
    //vector<int> randInts;
    vector<ivec4> randInts;
    ci::Rand random;
    random.seed((UInt32)time(NULL));
    CI_LOG_I("Rand ints:");
    for ( unsigned int i = 0; i < kParticleDimension * kParticleDimension; ++i )
    {
        Particle p;
        p.position = random.randVec3();
        p.velocity = random.randVec3();
        particles.push_back(p);
        if ( i % 4 == 0 )
        {
            indices.push_back(ivec4(i, i+1, i+2, i+3));
            randInts.push_back(ivec4(random.randInt(kParticleDimension * kParticleDimension),
                                     random.randInt(kParticleDimension * kParticleDimension),
                                     random.randInt(kParticleDimension * kParticleDimension),
                                     random.randInt(kParticleDimension * kParticleDimension)));
        }
        //randInts.push_back(randIndex);
        //printf("%i, ", randIndex);
    }
    printf("\n");
    
    // Make sure we've got the right number of indicies
    assert( float(indices.size()) == particles.size() / 4.0f );
    
    mPipelineParticles = RenderPipelineState::create("vertex_particles", "fragment_point_texture",
                                                     RenderPipelineState::Format()
                                                     .blendingEnabled(true));
    
    mTextureParticle = TextureBuffer::create(loadImage(getAssetPath("particle.png")));
    
    mParticlesUnsorted = DataBuffer::create(particles);
    // NOTE: 3x the buffer size so we dont overwrite the render particles mid-stream
//    mParticleBufferLength = sizeof(Particle) * particles.size();
//    mParticlesSorted = DataBuffer::create(mParticleBufferLength * kNumInflightBuffers, NULL);
    mParticleIndices = DataBuffer::create(indices);
    mPipelineBitonicSort = ComputePipelineState::create("bitonic_sort_by_value");
    mPipelineDebugSort = ComputePipelineState::create("debug_sort");
    mPipelineSimpleSort = ComputePipelineState::create("simple_bitonic_sort");//simple_sort");
    mRandomIntsBuffer = DataBuffer::create(randInts);
}

void ParticleSortingApp::mouseDown( MouseEvent event )
{
    mMousePos = event.getPos();
}

void ParticleSortingApp::mouseDrag( MouseEvent event )
{
    vec2 newPos = event.getPos();
    vec2 offset = newPos - mMousePos;
    mMousePos = newPos;
    mModelScale = ci::math<float>::clamp(mModelScale + (offset.x / getWindowWidth()), 1.f, 3.f);
}

void ParticleSortingApp::resetDebugBuffer()
{
    // Reset the debug buffer
    for ( int s = 0; s < kNumStages; ++s )
    {
        mDebugInfo.completedStages[s] = 0;
        mDebugInfo.previousStage[s] = 999;
    }
    for ( int s = 0; s < kNumPasses; ++s )
    {
        mDebugInfo.completedPasses[s] = 0;
        mDebugInfo.previousPass[s] = 999;
    }
    mDebugInfo.hasDuplicateIndices = false;
    mDebugInfo.numTimesAccessed = 0;
    mDebugInfo.numInt4s = 0;
    mDebugInfo.duplicateStage = -1;
    mDebugInfo.duplicatePass = -1;
    mDebugInfo.duplicateIndex = -1;
    
    mDebugBuffer->setData( &mDebugInfo, 0 );
}

void ParticleSortingApp::update()
{
    mRotation += 0.0015f;

    mat4 modelMatrix = glm::rotate(mRotation, vec3(1.0f, 1.0f, 1.0f));
    modelMatrix = glm::scale(modelMatrix, vec3(mModelScale));
    
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
    mDynamicConstantBuffer->setData( &mUniforms, mConstantDataBufferIndex );

//    // NOTE: These log values will be at least 1 frame behind
//    if ( getElapsedFrames() % 500 == 1 )
//    {
//        logIndices();
//    }
//
    // Log out the first sort to validate the results
    //bitonicSort( getElapsedFrames() % 500 == 1 );

    
    bitonicSort( false );
}

void ParticleSortingApp::logTestOutput()
{
    CI_LOG_I("TEST Output:");
    debugInfo_t *debugInfo = (debugInfo_t *)((char *)mDebugBuffer->contents());
    
    CI_LOG_I("# times accessed: " << debugInfo->numTimesAccessed );
    CI_LOG_I("Last Stage: " << debugInfo->lastStage << " Last Pass: " << debugInfo->lastPass);
    
    for ( int s = 0; s < kNumStages; ++s )
    {
        CI_LOG_I("Completed Stage[" << s << "] ? " << debugInfo->completedStages[s]);
        CI_LOG_I("Previous Stage[" << s << "] ? " << debugInfo->previousStage[s]);
    }
    
    for ( int s = 0; s < kNumPasses; ++s )
    {
        CI_LOG_I("Completed Pass[" << s << "] ? " << debugInfo->completedPasses[s]);
        CI_LOG_I("Previous Pass[" << s << "] ? " << debugInfo->previousPass[s]);
    }
    
    ivec4 *sortedValues = (ivec4 *)mRandomIntsBuffer->contents();
    CI_LOG_I("Sorted values:");
    for ( long i = 0; i < mUniforms.numParticles / 4; ++i )
    {
        ivec4 v = sortedValues[i];
        printf("%i, %i, %i, %i, ", v[0], v[1], v[2], v[3]);
    }
}

// NOTE: We have to pass in a copy of the uniforms because they may have changed
// by the time the compute is finished.
void ParticleSortingApp::logComputeOutput( const myUniforms_t uniforms )
{
    CI_LOG_I("Sort Output:");
    debugInfo_t *debugInfo = (debugInfo_t *)((char *)mDebugBuffer->contents());
    
    CI_LOG_I("# times accessed: " << debugInfo->numTimesAccessed );
    CI_LOG_I("Last Stage: " << debugInfo->lastStage << " Last Pass: " << debugInfo->lastPass);
    
    for ( int s = 0; s < kNumStages; ++s )
    {
        CI_LOG_I("Completed Stage[" << s << "] ? " << debugInfo->completedStages[s]);
        CI_LOG_I("Previous Stage[" << s << "] ? " << debugInfo->previousStage[s]);
    }
    
    for ( int s = 0; s < kNumPasses; ++s )
    {
        CI_LOG_I("Completed Pass[" << s << "] ? " << debugInfo->completedPasses[s]);
        CI_LOG_I("Previous Pass[" << s << "] ? " << debugInfo->previousPass[s]);
    }
    
    ivec4 *sortedIndices = (ivec4 *)mParticleIndices->contents();
    Particle *particles = (Particle *)mParticlesUnsorted->contents();

    if ( debugInfo->hasDuplicateIndices )
    {
        ivec4 duped = fromMtl(debugInfo->duplicateIndices);
        ivec4 dupedStart = fromMtl(debugInfo->duplicateIndicesStart);
        
        CI_LOG_E("Duplicate index " << debugInfo->duplicateIndex << " in block " << debugInfo->duplicateBlock );
        CI_LOG_E("Duplicate indicies " << duped);
        CI_LOG_E("Start indicies " << dupedStart);
        CI_LOG_E("Stage: " << debugInfo->duplicateStage << " pass: " << debugInfo->duplicatePass);
        if ( debugInfo->numInt4s > 0 )
        {
            for ( int i = 0; i < debugInfo->numInt4s; ++i )
            {
                ivec4 v = fromMtl(debugInfo->int4s[i]);
                CI_LOG_I( "ivec4 " << i << ": " << v );
            }
        }
        printf("\n");
        logIndices();
//        debugInfo->hasDuplicateIndices = false;
        exit(1);
    }
    else
    {
        CI_LOG_I("Sorted Z values:");
        float prevValue = -1.f; // min z
        for ( long i = 0; i < mUniforms.numParticles / 4; ++i )
        {
            ivec4 v = sortedIndices[i];
            for ( int j = 0; j < 4; ++j )
            {
                int index = v[j];
                Particle & p = particles[index];
                vec4 pos = fromMtl(uniforms.modelMatrix) * vec4(p.position, 0.f);
                float value = pos.z;
                printf("%f, ", value);
                if ( value > prevValue )
                {
                    // We tend to get 1 value that's out of place.
                    // Could this be a precision issue, or just inherent in the bitonic sort?
                    printf("\n");
                    CI_LOG_E("prev value " << prevValue << " is < than current value " << value);
                }
                prevValue = value;
            }
        }        
    }
    resetDebugBuffer();
}

void ParticleSortingApp::logIndices()
{
    ivec4 *sortedIndices = (ivec4 *)mParticleIndices->contents();
    CI_LOG_I("Sorted indices:");
    for ( long i = 0; i < mUniforms.numParticles / 4; ++i )
    {
        ivec4 v = sortedIndices[i];
        printf("[%li] %i, [%li] %i, [%li] %i, [%li] %i, ", i*4+0, v[0], i*4+1, v[1], i*4+2, v[2], i*4+3, v[3]);
    }
}

void ParticleSortingApp::debugSort()
{
    int passNum = 0;
    uint constantsOffset = (sizeof(myUniforms_t) * mConstantDataBufferIndex);
    // Test data
    {
        uint arraySize = mUniforms.numParticles;
        
        // IMPORTANT:
        // The command buffer must be created with (true), or the data will not be updated by the time
        // we get to the next step.
        ScopedCommandBuffer commandBuffer(true);
        
        for ( int stage = 0; stage < kNumStages; stage++ )
        {
            for ( int passOfStage = 0; passOfStage < kNumPasses; ++passOfStage )
            {
                {
                    CI_LOG_I( "stage " << stage << " pass: " << passOfStage );
                    
                    ScopedComputeEncoder computeEncoder(commandBuffer());
                    
                    // x) broaden the scope of the command buffer
                    // Verdict: seems to work
                    // x) create an array with stage and pass masks
                    // Verdict: every stage and pass seem to work
                    // x) use the sort state struct
                    // try variations on the device / constant / etc.
                    //>>                        // Verdict: THIS IS NOT working
                    // Because we're clobbering the same struct over and over before
                    // we commit the encoder.
                    // Use an offset: THIS WORKS
                    // x) carry over values from the previous buffer
                    // Add another stage + pass array for "previous pass" & "previous stage" completed
                    // Verdict: THIS IS WORKING
                    // What does this mean for the state of the unsorted indices being passed from stage to stage...?

                    // Sort state
                    
                    // NOTE: This does NOT work if we're overwriting the same memory.
                    // OPTIONS:
                    // We can either allot enough space for every sort state in a shared buffer
                    // or we can just create a new buffer each pass.
                    // Lets do the former with a new struct every pass.
                    sortState_t sortState;
                    sortState.stage = stage;
                    sortState.pass = passOfStage;
                    sortState.direction = 1; // ascending
                    mSortStateBuffer->setData(&sortState, passNum);
                    
                    DataBufferRef stageBuffer = DataBuffer::create( sizeof(uint),
                                                                   &stage,
                                                                   "Stage Buffer" );
                    
                    DataBufferRef passBuffer = DataBuffer::create( sizeof(uint),
                                                                  &passOfStage,
                                                                  "Pass Buffer" );
                    
                    computeEncoder()->setPipelineState( mPipelineDebugSort );
                    computeEncoder()->setBufferAtIndex( mSortStateBuffer, 3, sizeof(sortState_t) * passNum );
                    computeEncoder()->setBufferAtIndex( mDebugBuffer, 4 );
                    computeEncoder()->setBufferAtIndex( stageBuffer, 5 );
                    computeEncoder()->setBufferAtIndex( passBuffer, 6 );
                    
                    computeEncoder()->setUniforms( mDynamicConstantBuffer, constantsOffset );
                    
                    // set work-item dimensions
                    size_t gsz = arraySize / (2*4);
                    // NOTE: work size is not 1-per vector
                    // This is sorting integers
                    size_t global_work_size = passOfStage ? gsz : gsz << 1;    // number of quad items in input array
                    
                    CI_LOG_I( "global_work_size: " << global_work_size );
                    
                    // Interesting... each kernel gets a copy of the debug info
                    // and the last one to write out is the one that persists.
                    // E.g. the "numTimesAccessed" is 96, NOT 96 * global_work_size
                    computeEncoder()->dispatch( ivec3( global_work_size, 1, 1), ivec3( 32, 1, 1 ) );
                }
                passNum++;
                assert( passNum <= kNumSortStateBuffers );
            }
        }
    }
    
    logTestOutput();
}

void ParticleSortingApp::debugSimpleSort()
{
    int passNum = 0;
    uint constantsOffset = (sizeof(myUniforms_t) * mConstantDataBufferIndex);
    // Test data
    {
        uint arraySize = mUniforms.numParticles;
        int numStages = 0;

        // Calculate the number of stages
        for ( uint temp = arraySize; temp > 2; temp >>= 1 )
        {
            numStages++;
        }

        // NOTE:
        // If we log out the results while the command buffer is still running, the values might
        // be incorrect. This can be fixed by logging out in the completion handler, OR, passing
        // `true` into the ScopedCommandBuffer constructor, which causes it to wait synchronously
        // until the work is done.

        ScopedCommandBuffer commandBuffer;
        commandBuffer.addCompletionHandler([&]( void * mtlCommandBuffer ){
            logTestOutput();
        });
        
        ScopedComputeEncoder computeEncoder(commandBuffer());

        for ( int stage = 0; stage < numStages; stage++ )
        {
            for ( int passOfStage = stage; passOfStage >= 0; passOfStage-- )
            {
                {
                    sortState_t sortState;
                    sortState.stage = stage;
                    sortState.pass = passOfStage;
                    sortState.passNum = passNum;
                    sortState.direction = 1; // ascending
                    mSortStateBuffer->setData(&sortState, passNum);

                    computeEncoder()->setPipelineState( mPipelineSimpleSort );
                    computeEncoder()->setBufferAtIndex( mSortStateBuffer, 3, sizeof(sortState_t) * passNum );
                    computeEncoder()->setBufferAtIndex( mDebugBuffer, 4 );
                    computeEncoder()->setBufferAtIndex( mRandomIntsBuffer, 1 );
                    computeEncoder()->setUniforms( mDynamicConstantBuffer, constantsOffset );

                    size_t gsz = arraySize / (2*4);
                    // NOTE: work size is not 1-per vector.
                    // Its the number of quad items in input array
                    size_t global_work_size = passOfStage ? gsz : gsz << 1;
                    
                    computeEncoder()->dispatch( ivec3( global_work_size, 1, 1), ivec3( 32, 1, 1 ) );
                }
                passNum++;
            }
        }
    }
}

void ParticleSortingApp::bitonicSort( bool shouldLogOutput )
{
    int passNum = 0;
    uint constantsOffset = (sizeof(myUniforms_t) * mConstantDataBufferIndex);
    // Test data
    {
        uint arraySize = mUniforms.numParticles;
        int numStages = 0;
        
        // Calculate the number of stages
        for ( uint temp = arraySize; temp > 2; temp >>= 1 )
        {
            numStages++;
        }
        
        // NOTE:
        // If we log out the results while the command buffer is still running, the values might
        // be incorrect. This can be fixed by logging out in the completion handler, OR, passing
        // `true` into the ScopedCommandBuffer constructor, which causes it to wait synchronously
        // until the work is done.
        // We'll do both for demonstration.
        
        ScopedCommandBuffer commandBuffer( shouldLogOutput ); // param value indicates if we should synchrounously wait until the work is done.
        
        if ( shouldLogOutput )
        {
            myUniforms_t uniformsCopy = mUniforms;
            commandBuffer.addCompletionHandler([&]( void * mtlCommandBuffer ){
                logComputeOutput(uniformsCopy);
            });
        }
        
        ScopedComputeEncoder computeEncoder(commandBuffer());
        
        for ( int stage = 0; stage < numStages; stage++ )
        {
            for ( int passOfStage = stage; passOfStage >= 0; passOfStage-- )
            {
                {
                    // TMP
                    // TEST
//                    ScopedCommandBuffer commandBuffer( true );
//                    ScopedComputeEncoder computeEncoder( commandBuffer() );

//                    CI_LOG_I( "stage " << stage << "/" << (numStages-1) << " pass: " << passOfStage );
                    
                    sortState_t sortState;
                    sortState.stage = stage;
                    sortState.pass = passOfStage;
                    sortState.passNum = passNum;
                    sortState.direction = 1; // ascending
                    mSortStateBuffer->setData(&sortState, passNum);
                    
                    computeEncoder()->setPipelineState( mPipelineBitonicSort );
                    
                    computeEncoder()->setBufferAtIndex( mParticleIndices, 1 );
                    computeEncoder()->setBufferAtIndex( mParticlesUnsorted, 2 );
                    computeEncoder()->setBufferAtIndex( mSortStateBuffer, 3, sizeof(sortState_t) * passNum );
                    computeEncoder()->setBufferAtIndex( mDebugBuffer, 4 );

                    computeEncoder()->setUniforms( mDynamicConstantBuffer, constantsOffset );
                    
                    size_t gsz = arraySize / (2*4);
                    // NOTE: work size is not 1-per vector.
                    // Its the number of quad items in input array
                    size_t global_work_size = passOfStage ? gsz : gsz << 1;
                    
                    computeEncoder()->dispatch( ivec3( global_work_size, 1, 1), ivec3( 32, 1, 1 ) );
                }
                assert( passNum < kNumSortStateBuffers );
                passNum++;
            }
        }
    }
    
//    CI_LOG_I( "passNum: " << passNum );
    
//    if ( shouldLogOutput )
//    {
//        myUniforms_t uniformsCopy = mUniforms;
//        logComputeOutput(uniformsCopy);
//    }
}

void ParticleSortingApp::draw()
{
    uint constantsOffset = (sizeof(myUniforms_t) * mConstantDataBufferIndex);
    {
        ScopedRenderBuffer renderBuffer;//(true);
        {
            ScopedRenderEncoder renderEncoder(renderBuffer(), mRenderDescriptor);
            
            // Enable mip-mapping
//            renderEncoder()->setFragSamplerState(mSamplerMipMapped);

            // Set uniforms
            renderEncoder()->setUniforms( mDynamicConstantBuffer, constantsOffset );
            
            // Enable depth
            renderEncoder()->setDepthStencilState( mDepthEnabled );

        
//            // Draw Teapot
//            renderEncoder()->pushDebugGroup("Draw Geom Teapot");
//            
//            // Set the program
//            renderEncoder()->setPipelineState( mPipelineGeomLighting );
//
//            // Draw
//            mGeomBufferTeapot->draw( renderEncoder() );
//            
//            renderEncoder()->popDebugGroup();


            // Draw particles
            renderEncoder()->pushDebugGroup("Draw Particles");
            
            // Set the program
            renderEncoder()->setPipelineState( mPipelineParticles );

            // Pass in the unsorted particles
            renderEncoder()->setBufferAtIndex( mParticlesUnsorted, ciBufferIndexInterleavedVerts );

            // Pass in the sorted particle indices
            renderEncoder()->setBufferAtIndex( mParticleIndices, ciBufferIndexIndicies );

            renderEncoder()->setTexture(mTextureParticle);
            
            renderEncoder()->draw( mtl::geom::POINT, mUniforms.numParticles );

            renderEncoder()->popDebugGroup();

        } //
        
    } //
    
    mConstantDataBufferIndex = (mConstantDataBufferIndex + 1) % kNumInflightBuffers;
}

CINDER_APP( ParticleSortingApp,
            RendererMetal( RendererMetal::Options().numInflightBuffers(kNumInflightBuffers) ),
            []( ParticleSortingApp::Settings *settings )
            {
                // Just observe 1 touch for scaling
                settings->setMultiTouchEnabled(false);
            }
          )
