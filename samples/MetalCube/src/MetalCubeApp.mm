#include "cinder/app/App.h"
#include "cinder/gl/gl.h"
#include "cinder/Camera.h"
#import <QuartzCore/CAMetalLayer.h>
#import <Metal/Metal.h>
#import <simd/simd.h>

// Cinder-Metal
#include "metal.h"
#include "RendererMetal.h"
// TODO: Remove
#include "MetalContext.h"

#include "Uniforms.h"

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

class MetalCubeApp : public App {
  public:
	void setup() override;
    void loadAssets();
    void resize() override;
	void update() override;
	void draw() override;

    MetalBufferRef mVertexBuffer;
    MetalBufferRef mDynamicConstantBuffer;
    uint8_t _constantDataBufferIndex;

    MetalPipelineRef mPipelineLighting;

    // uniforms
    uniforms_t _uniform_buffer;
    float _rotation;
    CameraPersp mCamera;
};

void MetalCubeApp::setup()
{
    console() << "Setup\n";
    _constantDataBufferIndex = 0;
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
}

void MetalCubeApp::update()
{
    mat4 modelMatrix = glm::rotate(_rotation, vec3(1.0f, 1.0f, 1.0f));
    mat4 normalMatrix = inverse(transpose(modelMatrix));
    mat4 modelViewMatrix = mCamera.getViewMatrix() * modelMatrix;
    mat4 modelViewProjectionMatrix = mCamera.getProjectionMatrix() * modelViewMatrix;

    _uniform_buffer.normal_matrix = normalMatrix;
    _uniform_buffer.modelview_projection_matrix = modelViewProjectionMatrix;

    assert(sizeof(mat4) == sizeof(matrix_float4x4));

    // REFACTOR
    // Load constant buffer data into appropriate buffer at current index
    uint8_t *bufferPointer = (uint8_t *)mDynamicConstantBuffer->contents() + (sizeof(uniforms_t) * _constantDataBufferIndex);
    memcpy(bufferPointer, &_uniform_buffer, sizeof(uniforms_t));
    
    _rotation += 0.01f;
}

void MetalCubeApp::draw()
{
    // TODO: Make this more cinder-like
    [[MetalContext sharedContext] commandBufferDraw:^void( MetalRenderEncoderRef renderEncoder )
    {
        renderEncoder->beginPipeline( mPipelineLighting );

        renderEncoder->pushDebugGroup("DrawCube");

        // Set context state
        renderEncoder->setVertexBuffer(mVertexBuffer, 0, SHADER_INDEX_VERTS);

        uint offset = (sizeof(uniforms_t) * _constantDataBufferIndex);
        renderEncoder->setVertexBuffer(mDynamicConstantBuffer, offset, SHADER_INDEX_UNIFORMS);
        
        // Tell the render context we want to draw our primitives
        renderEncoder->draw(mtl::geom::TRIANGLE, 0, 36, 1);
        renderEncoder->popDebugGroup();
        
    }];
    
    _constantDataBufferIndex = (_constantDataBufferIndex + 1) % MAX_INFLIGHT_BUFFERS;

}

CINDER_APP( MetalCubeApp, RendererMetal )
