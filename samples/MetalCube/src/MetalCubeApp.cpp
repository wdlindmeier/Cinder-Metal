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

    GeomBufferTargetRef mGeomBufferTeapot;
    GeomBufferTargetRef mAttribBufferCube;
    MetalBufferRef mVertexBuffer;
    MetalBufferRef mDynamicConstantBuffer;
    uint8_t _constantDataBufferIndex;

    MetalPipelineRef mPipelineInterleavedLighting;
    MetalPipelineRef mPipelineGeomLighting;
    MetalPipelineRef mPipelineAttribLighting;

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

    // EXAMPLE 1
    // Create a buffer from an interleaved c array
    // Setup the vertex buffers
    mVertexBuffer = MetalBuffer::create(sizeof(cubeVertexData),  // the size of the buffer
                                        cubeVertexData,          // the data
                                        "Interleaved Vertices"); // the name of the buffer
    // Create a reusable pipeline state
    // This is similar to a GlslProg
    mPipelineInterleavedLighting = MetalPipeline::create("lighting_vertex_interleaved", // The name of the vertex shader function
                                                         "lighting_fragment",           // The name of the fragment shader function
                                                         MetalPipeline::Format().depth(true) ); // Format
    
    
    // EXAMPLE 2
    // Use a geom source
    mGeomBufferTeapot = GeomBufferTarget::create( ci::geom::Teapot(),   // The source
                                                {{ ci::geom::POSITION,  // The requested attributes.
                                                   ci::geom::NORMAL }});
    mPipelineGeomLighting = MetalPipeline::create("lighting_vertex_geom", "lighting_fragment",
                                                  MetalPipeline::Format().depth(true) );

    
    // Load verts and normals into vectors
    vector<vec3> positions;
    vector<vec3> normals;
    vector<vec3> positionsAndNormals;
    // iterate over cube data and split into verts and normals
    for ( int i = 0; i < 36; ++i )
    {
        vec3 pos(cubeVertexData[i*6+0], cubeVertexData[i*6+1], cubeVertexData[i*6+2]);
        vec3 norm(cubeVertexData[i*6+3], cubeVertexData[i*6+4], cubeVertexData[i*6+5]);
        positions.push_back(pos);
        normals.push_back(norm);
        positionsAndNormals.push_back(pos);
        positionsAndNormals.push_back(norm);
    }
    
    // EXAMPLE 3
    // Use attribtue buffers
    mAttribBufferCube = GeomBufferTarget::create( {{ ci::geom::POSITION, ci::geom::NORMAL }} );
    MetalBufferRef positionBuffer = MetalBuffer::create(positions, "positions");
    mAttribBufferCube->setBufferForAttribute(positionBuffer, ci::geom::POSITION);
    MetalBufferRef normalBuffer = MetalBuffer::create(normals, "normals");
    mAttribBufferCube->setBufferForAttribute(normalBuffer, ci::geom::NORMAL);
    
    mPipelineAttribLighting = MetalPipeline::create("lighting_vertex_attrib_buffers", "lighting_fragment",
                                                    MetalPipeline::Format().depth(true) );
    
    // EXAMPLE 4
    // Create an interleaved buffer with from a vector
    // NOTE: This is overwriting the member variables defined in Example 1
    mVertexBuffer = MetalBuffer::create(sizeof(positionsAndNormals) + sizeof(vec3) * positionsAndNormals.size(),
                                        positionsAndNormals.data(),
                                        "Positions and Normals");

    mPipelineInterleavedLighting = MetalPipeline::create("lighting_vertex", "lighting_fragment",
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
            encoder->pushDebugGroup("Draw Interleaved Cube");
            
            // Set the program
            encoder->setPipeline( mPipelineInterleavedLighting );
            
            // Set render state & resources
            encoder->setVertexBuffer(mVertexBuffer, 0, BUFFER_INDEX_VERTS);
            encoder->setVertexBufferForInflightIndex<uniforms_t>(mDynamicConstantBuffer,
                                                                 _constantDataBufferIndex,
                                                                 BUFFER_INDEX_UNIFORMS);
            // Draw
            encoder->draw(mtl::geom::TRIANGLE, 0, 36, 1);
            encoder->popDebugGroup();
            
            
            // Using Cinder geom to draw the cube
            
//            // Geom Target
//            encoder->pushDebugGroup("Draw Teapot");
//            
//            // Set the program
//            encoder->setPipeline( mPipelineGeomLighting );
//            
//            // Set render state & resources
//            encoder->setVertexBufferForInflightIndex<uniforms_t>(mDynamicConstantBuffer,
//                                                                 _constantDataBufferIndex,
//                                                                 BUFFER_INDEX_GEOM_UNIFORMS);
//            mGeomBufferTeapot->render( encoder );
//
//            // Draw
//            encoder->popDebugGroup();
            
            
//            // Using attrib buffers to draw the cube
//            
//            // Geom Target
//            encoder->pushDebugGroup("Draw Attrib Cube");
//            
//            // Set the program
//            encoder->setPipeline( mPipelineAttribLighting );
//            
//            // Set render state & resources
//            encoder->setVertexBufferForInflightIndex<uniforms_t>(mDynamicConstantBuffer,
//                                                                 _constantDataBufferIndex,
//                                                                 BUFFER_INDEX_ATTRIB_UNIFORMS);
//            mAttribBufferCube->render( encoder, 36 );
//            
//            // Draw
//            encoder->popDebugGroup();


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
