#include "cinder/app/App.h"
#include "cinder/gl/gl.h"
#include "cinder/Camera.h"
#include "cinder/GeomIo.h"

// Cinder-Metal
#include "metal.h"
#include "GeomBufferTarget.h"
#include "BufferConstants.h"


using namespace std;
using namespace ci;
using namespace ci::app;
using namespace cinder::mtl;

// Max API memory buffer size.
static const size_t MAX_BYTES_PER_FRAME = 1024*1024;

float cubeVertexData[216] =
{
    // Data layout for each line below is:
    // positionX, positionY, positionZ,     normalX, normalY, normalZ,
    0.5, -0.5, 0.5,   0.0, -1.0,  0.0,
    -0.5, -0.5, 0.5,   0.0, -1.0, 0.0,
    -0.5, -0.5, -0.5,   0.0, -1.0,  0.0,
    0.5, -0.5, -0.5,  0.0, -1.0,  0.0,
    0.5, -0.5, 0.5,   0.0, -1.0,  0.0,
    -0.5, -0.5, -0.5,   0.0, -1.0,  0.0,
    
    0.5, 0.5, 0.5,    1.0, 0.0,  0.0,
    0.5, -0.5, 0.5,   1.0,  0.0,  0.0,
    0.5, -0.5, -0.5,  1.0,  0.0,  0.0,
    0.5, 0.5, -0.5,   1.0, 0.0,  0.0,
    0.5, 0.5, 0.5,    1.0, 0.0,  0.0,
    0.5, -0.5, -0.5,  1.0,  0.0,  0.0,
    
    -0.5, 0.5, 0.5,    0.0, 1.0,  0.0,
    0.5, 0.5, 0.5,    0.0, 1.0,  0.0,
    0.5, 0.5, -0.5,   0.0, 1.0,  0.0,
    -0.5, 0.5, -0.5,   0.0, 1.0,  0.0,
    -0.5, 0.5, 0.5,    0.0, 1.0,  0.0,
    0.5, 0.5, -0.5,   0.0, 1.0,  0.0,
    
    -0.5, -0.5, 0.5,  -1.0,  0.0, 0.0,
    -0.5, 0.5, 0.5,   -1.0, 0.0,  0.0,
    -0.5, 0.5, -0.5,  -1.0, 0.0,  0.0,
    -0.5, -0.5, -0.5,  -1.0,  0.0,  0.0,
    -0.5, -0.5, 0.5,  -1.0,  0.0, 0.0,
    -0.5, 0.5, -0.5,  -1.0, 0.0,  0.0,
    
    0.5, 0.5,  0.5,  0.0, 0.0,  1.0,
    -0.5, 0.5,  0.5,  0.0, 0.0,  1.0,
    -0.5, -0.5, 0.5,   0.0,  0.0, 1.0,
    -0.5, -0.5, 0.5,   0.0,  0.0, 1.0,
    0.5, -0.5, 0.5,   0.0,  0.0,  1.0,
    0.5, 0.5,  0.5,  0.0, 0.0,  1.0,
    
    0.5, -0.5, -0.5,  0.0,  0.0, -1.0,
    -0.5, -0.5, -0.5,   0.0,  0.0, -1.0,
    -0.5, 0.5, -0.5,  0.0, 0.0, -1.0,
    0.5, 0.5, -0.5,  0.0, 0.0, -1.0,
    0.5, -0.5, -0.5,  0.0,  0.0, -1.0,
    -0.5, 0.5, -0.5,  0.0, 0.0, -1.0
};

typedef struct
{
    mat4 modelview_projection_matrix;
    mat4 normal_matrix;
} uniforms_t;

const static int kNumInflightBuffers = 3;

class MetalCubeApp : public App {
  public:
	void setup() override;
    void loadAssets();
    void resize() override;
	void update() override;
	void draw() override;

    GeomBufferTargetRef mGeomBufferCube;
    MetalBufferRef mVertexBuffer;
    MetalBufferRef mDynamicConstantBuffer;
    uint8_t _constantDataBufferIndex;

    MetalPipelineRef mPipelineLighting;
    MetalPipelineRef mPipelineGeomLighting;

    // uniforms
    uniforms_t _uniform_buffer;
    float _rotation;
    CameraPersp mCamera;
    
    MetalRenderFormatRef mRenderFormat;
    MetalComputeFormatRef mComputeFormat;
    MetalBlitFormatRef mBlitFormat;
};

void MetalCubeApp::setup()
{
    _constantDataBufferIndex = 0;
    
    // TODO:
    // Use an options-style constructor
    mRenderFormat = MetalRenderFormat::create();
    mRenderFormat->setShouldClear(true);
    mRenderFormat->setClearColor(ColorAf(1.f,0.f,0.f,1.f));
    
    mComputeFormat = MetalComputeFormat::create();
    mBlitFormat = MetalBlitFormat::create();

    loadAssets();
}

void MetalCubeApp::resize()
{
    mCamera = CameraPersp(getWindowWidth(), getWindowHeight(), 65.f, 0.1f, 100.f);
    mCamera.lookAt(vec3(0,0,-5), vec3(0));
}

void MetalCubeApp::loadAssets()
{
    // Allocate one region of memory for the uniform buffer
    mDynamicConstantBuffer = MetalBuffer::create(MAX_BYTES_PER_FRAME, nullptr, "Uniform Buffer");

    // Setup the vertex buffers
    mVertexBuffer = MetalBuffer::create(sizeof(cubeVertexData), cubeVertexData, "Vertices");
    // Create a reusable pipeline state
    mPipelineLighting = MetalPipeline::create("lighting_vertex", "lighting_fragment",
                                              MetalPipeline::Format().depth(true) );
    
    mGeomBufferCube = GeomBufferTarget::create( ci::geom::Cube().size(vec3(1.f)),
                                                {{ ci::geom::POSITION,
                                                   ci::geom::NORMAL }});
    // Create a reusable pipeline state
    mPipelineGeomLighting = MetalPipeline::create("lighting_vertex_geom", "lighting_fragment",
                                                   MetalPipeline::Format().depth(true) );
    
}

void MetalCubeApp::update()
{
    mat4 modelMatrix = glm::rotate(_rotation, vec3(1.0f, 1.0f, 1.0f));
    mat4 normalMatrix = inverse(transpose(modelMatrix));
    mat4 modelViewMatrix = mCamera.getViewMatrix() * modelMatrix;
    mat4 modelViewProjectionMatrix = mCamera.getProjectionMatrix() * modelViewMatrix;

    _uniform_buffer.normal_matrix = normalMatrix;
    _uniform_buffer.modelview_projection_matrix = modelViewProjectionMatrix;

    mDynamicConstantBuffer->setData( &_uniform_buffer, _constantDataBufferIndex );

    _rotation += 0.01f;
}

void MetalCubeApp::draw()
{
    commandBufferBlock( [&]( MetalCommandBufferRef commandBuffer )
    {
        commandBuffer->renderTargetWithFormat( mRenderFormat, [&]( MetalRenderEncoderRef encoder )
        {
//            encoder->pushDebugGroup("Draw Cube");
//            
//            // Set the program
//            encoder->setPipeline( mPipelineLighting );
//            
//            // Set render state & resources
//            encoder->setVertexBuffer(mVertexBuffer, 0, BUFFER_INDEX_VERTS);
//            encoder->setVertexBufferForInflightIndex<uniforms_t>(mDynamicConstantBuffer,
//                                                                 _constantDataBufferIndex,
//                                                                 BUFFER_INDEX_UNIFORMS);
//            // Draw
//            encoder->draw(mtl::geom::TRIANGLE, 0, 36, 1);
//            encoder->popDebugGroup();
//            
//            
            // TEST: Using Cinder geom to draw the cube
            // Woohoo!
            
            // Geom Target
            encoder->pushDebugGroup("Draw Cube Geom");
            
            // Set the program
            encoder->setPipeline( mPipelineGeomLighting );
            
            // Set render state & resources
            
            encoder->setVertexBufferForInflightIndex<uniforms_t>(mDynamicConstantBuffer,
                                                                 _constantDataBufferIndex,
                                                                 BUFFER_INDEX_GEOM_UNIFORMS);
            mGeomBufferCube->render( encoder );

            // Draw
            encoder->popDebugGroup();

        });

        commandBuffer->computeTargetWithFormat( mComputeFormat, [&]( MetalComputeEncoderRef encoder )
        {
            // FPO
        });
        
        commandBuffer->blitTargetWithFormat( mBlitFormat, [&]( MetalBlitEncoderRef encoder )
        {
            // FPO
        });
    });
    
    _constantDataBufferIndex = (_constantDataBufferIndex + 1) % kNumInflightBuffers;
}

CINDER_APP( MetalCubeApp, RendererMetal( RendererMetal::Options().numInflightBuffers(kNumInflightBuffers) ) )
