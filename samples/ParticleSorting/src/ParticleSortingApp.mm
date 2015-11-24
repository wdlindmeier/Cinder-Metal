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
const static int kNumSortStateBuffers = 64;

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
    void bitonicSort();
    void debugSort();
    void debugSimpleSort();
    void logComputeOutput( int numPasses );
    void logTestOutput();
    
    SamplerStateRef mSamplerMipMapped;
    DepthStateRef mDepthEnabled;
    
    myUniforms_t mUniforms;
//    sortState_t mSortState;
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
    //DataBufferRef mParticlesSorted;
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
    mDebugBuffer->setData( &mDebugInfo, 0 );

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
                                                     .depthEnabled(true)
                                                     .blendingEnabled(true));
    
    mTextureParticle = TextureBuffer::create(loadImage(getAssetPath("particle.png")));
    
    mParticlesUnsorted = DataBuffer::create(particles);
    // NOTE: 3x the buffer size so we dont overwrite the render particles mid-stream
//    mParticleBufferLength = sizeof(Particle) * particles.size();
//    mParticlesSorted = DataBuffer::create(mParticleBufferLength * kNumInflightBuffers, NULL);
    mParticleIndices = DataBuffer::create(indices);
    mPipelineBitonicSort = ComputePipelineState::create("bitonic_sort");
    mPipelineDebugSort = ComputePipelineState::create("debug_sort");
    mPipelineSimpleSort = ComputePipelineState::create("simple_bitonic_sort");//simple_sort");
    mRandomIntsBuffer = DataBuffer::create(randInts);
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
    mDynamicConstantBuffer->setData( &mUniforms, mConstantDataBufferIndex );

    mRotation += 0.0015f;
    
    //debugSimpleSort();
}

void ParticleSortingApp::logTestOutput()
{
//    logComputeOutput(numPasses);
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

void ParticleSortingApp::logComputeOutput( int numPasses )
{
//    synchronizeResource
    debugInfo_t *debugInfo = (debugInfo_t *)((char *)mDebugBuffer->contents());// + size_t(sizeof(debugInfo_t) * (numPasses - 1)));
    CI_LOG_I("Compute Output after " << numPasses << " passes:");
    for ( int i = 0; i < debugInfo->numInt4s; ++i )
    {
        ivec4 vec = fromMtl(debugInfo->int4s[i]);
        CI_LOG_I("ivec4 " << i << ": " << vec);
    }
    CI_LOG_I("Min Stage: " << debugInfo->minStage << ", Max Stage: " << debugInfo->maxStage );
    CI_LOG_I("Min Pass: " << debugInfo->minPass << ", Max Pass: " << debugInfo->maxPass );
}

#include <Metal/Metal.h>

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
                    sortState.direction = 0; // ascending
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

void ParticleSortingApp::bitonicSort()
{
    int passNum = 0;
    uint constantsOffset = (sizeof(myUniforms_t) * mConstantDataBufferIndex);
    
    // Bitonic particle sort
    {
        // No benchmakr
        //    double   perf_start;
        //    double   perf_stop;
        //
        //    cl_int err = CL_SUCCESS;
        int numStages = 0;
        uint temp;
        
        int stage;
        int passOfStage;
        uint arraySize = mUniforms.numParticles;
        
        // buffer is already created
        // create OpenCL buffer using input array memory
        //            cl_mem cl_input_buffer =
        //            clCreateBuffer
        //            (
        //             oclobjects.context,
        //             CL_MEM_USE_HOST_PTR,
        //             zeroCopySizeAlignment(sizeof(cl_int) * arraySize, oclobjects.device),
        //             p_input,
        //             &err
        //             );
        //SAMPLE_CHECK_ERRORS(err);
        
        //    if (cl_input_buffer == (cl_mem)0)
        //    {
        //        throw Error("Failed to create input data Buffer\n");
        //    }
        
        
        // Calculate the number of stages
        for (temp = arraySize; temp > 2; temp >>= 1)
        {
            numStages++;
        }
        
        
        // Set the input buffer
        // Move buffer from index 0 => 1
        //            err=  clSetKernelArg(executable.kernel, 0, sizeof(cl_mem), (void *) &cl_input_buffer);
        //            SAMPLE_CHECK_ERRORS(err);
        // SET ABOVE
        
        // Sort state is in mSortState
        // sortAscending is in uniforms
        //            err = clSetKernelArg(executable.kernel, 3, sizeof(cl_uint), (void *) &sortAscending);
        //            SAMPLE_CHECK_ERRORS(err);
        // SET BELOW
        
        // Don't bother doing a performance benchmarking
        //            perf_start=time_stamp();
        // // sort ascending
        
        for ( stage = 0; stage < numStages; stage++ )
            // TEST
            //stage = 0;
        {
            // Sort stage is in mSortState
            //                err = clSetKernelArg(executable.kernel, 1, sizeof(cl_uint), (void *) &stage);
            //                SAMPLE_CHECK_ERRORS(err);
            
            
            
            for ( passOfStage = stage; passOfStage >= 0; passOfStage-- )
                // TEST
                //passOfStage = 0;
            {
                sortState_t sortState;
                sortState.direction = 1;
                sortState.stage = stage;
                sortState.pass = passOfStage;
                mSortStateBuffer->setData(&sortState, passNum);

                CI_LOG_I( "stage " << sortState.stage << " pass: " << sortState.pass );
                
                ScopedCommandBuffer commandBuffer; //(true);
                {
                    ScopedComputeEncoder computeEncoder(commandBuffer());
                    
                    computeEncoder()->setPipelineState( mPipelineBitonicSort );
                    computeEncoder()->setUniforms( mDynamicConstantBuffer, constantsOffset );
                    computeEncoder()->setBufferAtIndex( mParticlesUnsorted, 1 );
                    computeEncoder()->setBufferAtIndex( mParticleIndices, 2 );
                    computeEncoder()->setBufferAtIndex( mDebugBuffer, 4 );
                    computeEncoder()->setBufferAtIndex( mSortStateBuffer, 3, sizeof(sortState_t) * passNum );
                    
                    //                    err = clSetKernelArg(executable.kernel, 2, sizeof(cl_uint), (void *) &passOfStage);
                    //                    SAMPLE_CHECK_ERRORS(err);
                    
                    // set work-item dimensions
                    size_t gsz = arraySize / (2*4);
                    // NOTE: work size is not 1-per vector
                    // This is sorting integers
                    size_t global_work_size = passOfStage ? gsz : gsz << 1;    // number of quad items in input array
                    
                    computeEncoder()->dispatch( ivec3( global_work_size, 1, 1), ivec3( 32, 1, 1 ) );
                    
                }
                
                passNum++;
                
                // execute kernel
                // err = clEnqueueNDRangeKernel(oclobjects.queue, executable.kernel, 1, NULL, global_work_size, NULL, 0, NULL, NULL);
                // SAMPLE_CHECK_ERRORS(err);
            }
        }
        
        //err = clFinish(oclobjects.queue);
        //SAMPLE_CHECK_ERRORS(err);
        
        //perf_stop=time_stamp();
        
        //            void* tmp_ptr = NULL;
        //            tmp_ptr = clEnqueueMapBuffer(oclobjects.queue, cl_input_buffer, true, CL_MAP_READ, 0, sizeof(cl_int) * arraySize , 0, NULL, NULL, &err);
        //            SAMPLE_CHECK_ERRORS(err);
        //            if(tmp_ptr!=p_input)
        //            {
        //                throw Error("clEnqueueMapBuffer failed to return original pointer\n");
        //            }
        //
        //            err = clFinish(oclobjects.queue);
        //            SAMPLE_CHECK_ERRORS(err);
        //
        //            err = clEnqueueUnmapMemObject(oclobjects.queue, cl_input_buffer, tmp_ptr, 0, NULL, NULL);
        //            SAMPLE_CHECK_ERRORS(err);
        //
        //            err = clReleaseMemObject(cl_input_buffer);
        //            SAMPLE_CHECK_ERRORS(err);
        //
        //            return (float)(perf_stop - perf_start);
        //
        
        //            computeEncoder()->setPipelineState( mPipelineParallelSort );
        //            computeEncoder()->setUniforms( mDynamicConstantBuffer, constantsOffset );
        //            computeEncoder()->setBufferAtIndex( mParticlesUnsorted, 1 );
        //            computeEncoder()->setBufferAtIndex( mParticlesSorted, 2,
        //                                                mParticleBufferLength * mConstantDataBufferIndex );
        //            computeEncoder()->dispatch( ivec3(mUniforms.numParticles, 1, 1), ivec3(64, 1, 1) );
    }
    
    logComputeOutput(passNum);
}

void ParticleSortingApp::draw()
{

    uint constantsOffset = (sizeof(myUniforms_t) * mConstantDataBufferIndex);
    
//    if ( getElapsedFrames() < 3 )
//    {
//        bitonicSort();
//    }
    if ( getElapsedFrames() == 1 )
    {
//        //debugSort();
        debugSimpleSort();
    }

    {
        ScopedRenderBuffer renderBuffer;//(true);
        {
            ScopedRenderEncoder renderEncoder(renderBuffer(), mRenderDescriptor);
            
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
    
//    logComputeOutput( passNum );
//    ivec4 * indices = (ivec4 *)mParticleIndices->contents();
//    long maxParticleIndex = 0;
//    for ( int i = 0; i < mUniforms.numParticles / 4; ++i )
//    {
//        ivec4 v = indices[i];
//        console() << "i " << i << ": " << v << "\n";
//        for ( int j = 0; j < 4; ++j )
//        {
//            if ( v[j] > maxParticleIndex )
//            {
//                maxParticleIndex = v[j];
//            }
//        }
//    }
//    console() << "NUM PARTICLES: " << mUniforms.numParticles << "\n";
//    console() << "MAX PARTICLE INDEX: " << maxParticleIndex << "\n";


    
    mConstantDataBufferIndex = (mConstantDataBufferIndex + 1) % kNumInflightBuffers;
}

CINDER_APP( ParticleSortingApp, RendererMetal( RendererMetal::Options().numInflightBuffers(kNumInflightBuffers) ) )
