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
const static int kNumSortStateBuffers = 50;

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
    
    myUniforms_t mUniforms;
    sortState_t mSortState;
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
    
    // Sort pass
    ComputePipelineStateRef mPipelineParallelSort;
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
    }
    
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
    mPipelineParallelSort = ComputePipelineState::create("kernel_sort");
    mPipelineBitonicSort = ComputePipelineState::create("bitonic_sort");
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
}

void ParticleSortingApp::draw()
{
    uint constantsOffset = (sizeof(myUniforms_t) * mConstantDataBufferIndex);
    ScopedRenderBuffer renderBuffer(true);
    {
        // Bitonic particle sort
        {
            ScopedComputeEncoder computeEncoder(renderBuffer());
            
            computeEncoder()->setPipelineState( mPipelineBitonicSort );
            computeEncoder()->setUniforms( mDynamicConstantBuffer, constantsOffset );
            computeEncoder()->setBufferAtIndex( mParticlesUnsorted, 1 );
            computeEncoder()->setBufferAtIndex( mParticleIndices, 2 );
            
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
            mSortState.direction = 1; // sort ascending
            
            
            NEXT:
            Seems like the stages are causing some problems
            
            // for ( stage = 0; stage < numStages; stage++ )
            // TEST
            stage = 0;
            {
                // Sort stage is in mSortState
                //                err = clSetKernelArg(executable.kernel, 1, sizeof(cl_uint), (void *) &stage);
                //                SAMPLE_CHECK_ERRORS(err);
                
                mSortState.stage = stage;
                
                for ( passOfStage = stage; passOfStage >= 0; passOfStage-- )
                // TEST
                //passOfStage = 0;
                {
                    mSortState.pass = passOfStage;
                    mSortStateBuffer->setData( &mSortState, stage );
                    computeEncoder()->setBufferAtIndex(mSortStateBuffer, 3, sizeof(sortState_t) * stage);

//                    err = clSetKernelArg(executable.kernel, 2, sizeof(cl_uint), (void *) &passOfStage);
//                    SAMPLE_CHECK_ERRORS(err);
                    
                    // set work-item dimensions
                    size_t gsz = arraySize / (2*4);
                    // NOTE: work size is not 1-per vector
                    // This is sorting integers
                    size_t global_work_size = passOfStage ? gsz : gsz << 1;    // number of quad items in input array
                    
                    computeEncoder()->dispatch( ivec3( global_work_size, 1, 1), ivec3( 32, 1, 1 ) );
                    
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
        
        ivec4 * indices = (ivec4 *)mParticleIndices->contents();
        long maxParticleIndex = 0;
        for ( int i = 0; i < mUniforms.numParticles / 4; ++i )
        {
            ivec4 v = indices[i];
            console() << "i " << i << ": " << v << "\n";
            for ( int j = 0; j < 4; ++j )
            {
                if ( v[j] > maxParticleIndex )
                {
                    maxParticleIndex = v[j];
                }
            }
        }
        console() << "NUM PARTICLES: " << mUniforms.numParticles << "\n";
        console() << "MAX PARTICLE INDEX: " << maxParticleIndex << "\n";
        if ( getElapsedFrames() == 2 )
        {
            exit(0);            
        }
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
            
        } // scoped render encoder
        
    } // scoped command buffer
    

    mConstantDataBufferIndex = (mConstantDataBufferIndex + 1) % kNumInflightBuffers;
}

CINDER_APP( ParticleSortingApp, RendererMetal( RendererMetal::Options().numInflightBuffers(kNumInflightBuffers) ) )
