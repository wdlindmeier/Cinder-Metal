#include "cinder/app/App.h"
#include "cinder/gl/gl.h"
#include "cinder/Camera.h"
#include "cinder/GeomIo.h"

// Cinder-Metal
#include "metal.h"
#include "VertexBuffer.h"
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
    
    MetalCubeApp() :
    _rotation(0.f)
    {}
    
	void setup() override;
    void loadAssets();
    void resize() override;
	void update() override;
	void draw() override;

    VertexBufferRef mGeomBufferCube;
    VertexBufferRef mAttribBufferCube;
    DataBufferRef mVertexBuffer;
    DataBufferRef mDynamicConstantBuffer;
    uint8_t _constantDataBufferIndex;

    PipelineRef mPipelineInterleavedLighting;
    PipelineRef mPipelineGeomLighting;
    PipelineRef mPipelineAttribLighting;

    // uniforms
    uniforms_t _uniform_buffer;
    float _rotation;
    CameraPersp mCamera;
    
    RenderFormatRef mRenderFormat;
    ComputeFormatRef mComputeFormat;
    BlitFormatRef mBlitFormat;
    
    vector<vec3> mPositions;
    
    TextureBufferRef mTexture;
};

void MetalCubeApp::setup()
{
    _constantDataBufferIndex = 0;
    
    /*
     Calvin's Code:
     
    \]]]]]/

    ,.m
    '/
    'p[--=-=
    '/
    ;==\''''
    */
    
    // TODO:
    // Use an options-style constructor
    mRenderFormat = RenderFormat::create();
    mRenderFormat->setShouldClear(true);
    mRenderFormat->setClearColor(ColorAf(1.f,0.f,0.f,1.f));
    
    mComputeFormat = ComputeFormat::create();
    mBlitFormat = BlitFormat::create();
    
    TextureBuffer::Format format;
    // NOTE: mipmap level doesn't seem to help
    format.mipmapLevel = 4;
    
    // This works:
    //mTexture = TextureBuffer::create( loadImage( getAssetPath("texture.jpg") ), format );

    // This doesn't, because it doesn't have an alpha channel.
    // What MTLPixelFormat do we use for RGB??
    SurfaceRef surf = Surface::create(loadImage( getAssetPath("texture.jpg") ));
    mTexture = TextureBuffer::create( *surf, format );    

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
    mDynamicConstantBuffer = DataBuffer::create(MAX_BYTES_PER_FRAME, nullptr, "Uniform Buffer");

    // EXAMPLE 1
    // Create a buffer from an interleaved c array
    // Setup the vertex buffers
    mVertexBuffer = DataBuffer::create(sizeof(cubeVertexData),  // the size of the buffer
                                        cubeVertexData,          // the data
                                        "Interleaved Vertices"); // the name of the buffer
    // Create a reusable pipeline state
    // This is similar to a GlslProg
    mPipelineInterleavedLighting = Pipeline::create("lighting_vertex_interleaved",    // The name of the vertex shader function
                                                    "lighting_fragment",              // The name of the fragment shader function
                                                    Pipeline::Format().depth(true) ); // Format
    
    
    // EXAMPLE 2
    // Use a geom source
    mGeomBufferCube = VertexBuffer::create( ci::geom::Cube(),     // The source
                                           // Pass in the requested attributes w/ shader indices.
                                           // NOTE: We need to specify the vert indices, since they need an explicit shader index.
                                           {{ci::geom::INDEX, BUFFER_INDEX_GEOM_INDICES },
                                            {ci::geom::POSITION, BUFFER_INDEX_GEOM_VERTS },
                                            {ci::geom::NORMAL, BUFFER_INDEX_GEOM_NORMALS },
                                            {ci::geom::TEX_COORD_0, BUFFER_INDEX_GEOM_TEX_COORDS }});
    mPipelineGeomLighting = Pipeline::create("lighting_vertex_geom",
                                              "lighting_fragment",
                                              Pipeline::Format().depth(true) );
    
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
    mAttribBufferCube = VertexBuffer::create();
    mPositions = positions;
    DataBufferRef positionBuffer = DataBuffer::create(mPositions, "positions");
    mAttribBufferCube->setBufferForAttribute(positionBuffer, ci::geom::POSITION, BUFFER_INDEX_ATTRIB_POSITIONS);
    DataBufferRef normalBuffer = DataBuffer::create(normals, "normals");
    mAttribBufferCube->setBufferForAttribute(normalBuffer, ci::geom::NORMAL, BUFFER_INDEX_ATTRIB_NORMALS);
    
    mPipelineAttribLighting = Pipeline::create("lighting_vertex_attrib_buffers",
                                               "lighting_fragment",
                                               Pipeline::Format().depth(true) );
    
    // EXAMPLE 4
    // Create an interleaved buffer with from a vector
    // NOTE: This is overwriting the member variables defined in Example 1
    mVertexBuffer = DataBuffer::create(sizeof(positionsAndNormals) + sizeof(vec3) * positionsAndNormals.size(),
                                        positionsAndNormals.data(),
                                        "Positions and Normals");

    mPipelineInterleavedLighting = Pipeline::create("lighting_vertex_interleaved",
                                                    "lighting_fragment",
                                                    Pipeline::Format().depth(true) );

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

    // Update the verts
    vector<vec3> newPositions;
    for ( vec3 & v : mPositions )
    {
        newPositions.push_back( v * (1.f + (float(1.0f + sin(getElapsedSeconds())) * 0.5f ) ) );
    }
    mAttribBufferCube->update(ci::geom::POSITION, newPositions);
}

void MetalCubeApp::draw()
{
    commandBufferBlock( [&]( CommandBufferRef commandBuffer )
    {
        commandBuffer->renderTargetWithFormat( mRenderFormat, [&]( RenderEncoderRef encoder )
        {
            uint constantsOffset = (sizeof(uniforms_t) * _constantDataBufferIndex);
            
            
//            encoder->pushDebugGroup("Draw Interleaved Cube");
//            
//            // Set the program
//            encoder->setPipeline( mPipelineInterleavedLighting );
//            
//            // Set render state & resources
//            encoder->setBufferAtIndex(mVertexBuffer, BUFFER_INDEX_VERTS);
//            encoder->setBufferAtIndex( mDynamicConstantBuffer, BUFFER_INDEX_UNIFORMS, constantsOffset);
//
//            // Draw
//            encoder->draw(mtl::geom::TRIANGLE, 0, 36, 1);
//            encoder->popDebugGroup();            
            
            // Using Cinder geom to draw the cube
            
            // Geom Target
            encoder->pushDebugGroup("Draw Geom Cube");
            
            // Set the program
            encoder->setPipeline( mPipelineGeomLighting );
            
            // Set render state & resources
            encoder->setBufferAtIndex( mDynamicConstantBuffer, BUFFER_INDEX_GEOM_UNIFORMS, constantsOffset);

            // Set the texture
            encoder->setTextureAtIndex( mTexture, TEXTURE_INDEX_CUBE );

            mGeomBufferCube->render( encoder );

            // Draw
            encoder->popDebugGroup();
                        
//            // Using attrib buffers to draw the cube
//            
//            // Geom Target
//            encoder->pushDebugGroup("Draw Attrib Cube");
//            
//            // Set the program
//            encoder->setPipeline( mPipelineAttribLighting );
//            
//            // Set render state & resources
//            encoder->setBufferAtIndex( mDynamicConstantBuffer, BUFFER_INDEX_ATTRIB_UNIFORMS, constantsOffset);
//
//            mAttribBufferCube->render( encoder, 36 );
//            
//            // Draw
//            encoder->popDebugGroup();

        });

        commandBuffer->computeTargetWithFormat( mComputeFormat, [&]( ComputeEncoderRef encoder )
        {
            // FPO
        });
        
        commandBuffer->blitTargetWithFormat( mBlitFormat, [&]( BlitEncoderRef encoder )
        {
            // FPO
        });
    });
    
    _constantDataBufferIndex = (_constantDataBufferIndex + 1) % kNumInflightBuffers;
}

CINDER_APP( MetalCubeApp, RendererMetal( RendererMetal::Options().numInflightBuffers(kNumInflightBuffers) ) )
