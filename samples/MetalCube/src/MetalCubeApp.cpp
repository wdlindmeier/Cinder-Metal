#include "cinder/app/App.h"
#include "cinder/gl/gl.h"
#include "cinder/Camera.h"
#include "cinder/GeomIo.h"

// Cinder-Metal
#include "metal.h"
#include "VertexBuffer.h"
#include "MetalConstants.h"
#include "Scope.h"

using namespace std;
using namespace ci;
using namespace ci::app;
using namespace cinder::mtl;

// Max API memory buffer size.
static const size_t MAX_BYTES_PER_FRAME = 1024*1024;

// Raw cube data. Layout is positionX, positionY, positionZ, normalX, normalY, normalZ
float cubeVertexData[216] =
{
    0.5, -0.5, 0.5, 0.0, -1.0,  0.0, -0.5, -0.5, 0.5, 0.0, -1.0, 0.0, -0.5, -0.5, -0.5, 0.0, -1.0,  0.0, 0.5, -0.5, -0.5,  0.0, -1.0,  0.0, 0.5, -0.5, 0.5, 0.0, -1.0,  0.0, -0.5, -0.5, -0.5, 0.0, -1.0,  0.0, 0.5, 0.5, 0.5,  1.0, 0.0,  0.0, 0.5, -0.5, 0.5, 1.0,  0.0,  0.0, 0.5, -0.5, -0.5,  1.0,  0.0,  0.0, 0.5, 0.5, -0.5, 1.0, 0.0,  0.0, 0.5, 0.5, 0.5,  1.0, 0.0,  0.0, 0.5, -0.5, -0.5,  1.0,  0.0,  0.0, -0.5, 0.5, 0.5,  0.0, 1.0,  0.0, 0.5, 0.5, 0.5,  0.0, 1.0,  0.0, 0.5, 0.5, -0.5, 0.0, 1.0,  0.0, -0.5, 0.5, -0.5, 0.0, 1.0,  0.0, -0.5, 0.5, 0.5,  0.0, 1.0,  0.0, 0.5, 0.5, -0.5, 0.0, 1.0,  0.0, -0.5, -0.5, 0.5,  -1.0,  0.0, 0.0, -0.5, 0.5, 0.5, -1.0, 0.0,  0.0, -0.5, 0.5, -0.5,  -1.0, 0.0,  0.0, -0.5, -0.5, -0.5,  -1.0,  0.0,  0.0, -0.5, -0.5, 0.5,  -1.0,  0.0, 0.0, -0.5, 0.5, -0.5,  -1.0, 0.0,  0.0, 0.5, 0.5,  0.5,  0.0, 0.0,  1.0, -0.5, 0.5,  0.5,  0.0, 0.0,  1.0, -0.5, -0.5, 0.5, 0.0,  0.0, 1.0, -0.5, -0.5, 0.5, 0.0,  0.0, 1.0, 0.5, -0.5, 0.5, 0.0,  0.0,  1.0, 0.5, 0.5,  0.5,  0.0, 0.0,  1.0, 0.5, -0.5, -0.5,  0.0,  0.0, -1.0, -0.5, -0.5, -0.5, 0.0,  0.0, -1.0, -0.5, 0.5, -0.5,  0.0, 0.0, -1.0, 0.5, 0.5, -0.5,  0.0, 0.0, -1.0, 0.5, -0.5, -0.5,  0.0,  0.0, -1.0, -0.5, 0.5, -0.5,  0.0, 0.0, -1.0
};

//typedef struct
//{
//    mat4 modelviewProjectionMatrix;
//    mat4 normalMatrix;
//} uniforms_t;
//
// typedef mat4 matrix_float4x4;



const static int kNumInflightBuffers = 3;

class MetalCubeApp : public App {
  public:
    
    MetalCubeApp() :
    mRotation(0.f)
    {}
    
	void setup() override;
    void loadAssets();
    void resize() override;
	void update() override;
	void draw() override;

    DataBufferRef mVertexBuffer;
    VertexBufferRef mGeomBufferCube;
    VertexBufferRef mAttribBufferCube;
    vector<vec3> mPositions;

    PipelineStateRef mPipelineInterleavedLighting;
    PipelineStateRef mPipelineGeomLighting;
    PipelineStateRef mPipelineAttribLighting;
    
    SamplerStateRef mSamplerMipMapped;
    DepthStateRef mDepthEnabled;
    
    ciUniforms_t mUniforms;
    DataBufferRef mDynamicConstantBuffer;
    uint8_t mConstantDataBufferIndex;
    
    float mRotation;
    CameraPersp mCamera;
    
    RenderPassDescriptorRef mRenderDescriptor;
    
    TextureBufferRef mTexture;
};

void MetalCubeApp::setup()
{
    mConstantDataBufferIndex = 0;
    
    mSamplerMipMapped = SamplerState::create();
    mDepthEnabled = DepthState::create();
    
    mRenderDescriptor = RenderPassDescriptor::create( RenderPassDescriptor::Format()
                                                      .clearColor( ColorAf(1.f,0.f,0.f,1.f) ) );

    mTexture = TextureBuffer::create( loadImage( getAssetPath("checker.png") ),
                                      TextureBuffer::Format().mipmapLevel(4) );
    
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
    // Use raw, interleaved vertex data
    mVertexBuffer = DataBuffer::create(sizeof(cubeVertexData),  // the size of the buffer
                                       cubeVertexData,          // the data
                                       "Interleaved Vertices"); // the name of the buffer
    mPipelineInterleavedLighting = PipelineState::create("lighting_vertex_interleaved",
                                                         "lighting_fragment",
                                                         PipelineState::Format().depthEnabled(true).blendingEnabled(true) );

    // EXAMPLE 2
    // Use a geom source
    mGeomBufferCube = VertexBuffer::create( ci::geom::Cube(),     // A geom source
                                           {{ci::geom::INDEX,     // Pass in the requested attributes
                                             ci::geom::POSITION,  // which will be sent to the shader.
                                             ci::geom::NORMAL,
                                             ci::geom::TEX_COORD_0 }});
    mPipelineGeomLighting = PipelineState::create("lighting_vertex_geom",
                                                  "lighting_texture_fragment",
                                                  PipelineState::Format().depthEnabled(true).blendingEnabled(true) );

    // EXAMPLE 3
    // Use attribtue buffers
    // Load verts and normals into vectors
    vector<vec3> positions;
    vector<vec3> normals;
    // iterate over cube data and split into verts and normals
    for ( int i = 0; i < 36; ++i )
    {
        vec3 pos(cubeVertexData[i*6+0], cubeVertexData[i*6+1], cubeVertexData[i*6+2]);
        vec3 norm(cubeVertexData[i*6+3], cubeVertexData[i*6+4], cubeVertexData[i*6+5]);
        positions.push_back(pos);
        normals.push_back(norm);
    }
    
    mAttribBufferCube = VertexBuffer::create();
    mPositions = positions;
    DataBufferRef positionBuffer = DataBuffer::create(mPositions, "positions");
    mAttribBufferCube->setBufferForAttribute(positionBuffer, ci::geom::POSITION );
    DataBufferRef normalBuffer = DataBuffer::create(normals, "normals");
    mAttribBufferCube->setBufferForAttribute(normalBuffer, ci::geom::NORMAL );
    
    mPipelineAttribLighting = PipelineState::create("lighting_vertex_attrib_buffers",
                                                    "lighting_fragment",
                                                    PipelineState::Format().depthEnabled(true).blendingEnabled(true) );
}

void MetalCubeApp::update()
{
    mat4 modelMatrix = glm::rotate(mRotation, vec3(1.0f, 1.0f, 1.0f));
    mat4 normalMatrix = inverse(transpose(modelMatrix));
    mat4 modelViewMatrix = mCamera.getViewMatrix() * modelMatrix;
    mat4 modelViewProjectionMatrix = mCamera.getProjectionMatrix() * modelViewMatrix;

    // Is there a clean way to automatically wrap these up?
    mUniforms.normalMatrix = toMtl(normalMatrix);
    mUniforms.modelViewProjectionMatrix = toMtl(modelViewProjectionMatrix);
    mUniforms.elapsedSeconds = getElapsedSeconds();
    mDynamicConstantBuffer->setData( &mUniforms, mConstantDataBufferIndex );
    
    mRotation += 0.01f;

    // Update the verts to grow and shrink w/ time
    vector<vec3> newPositions;
    for ( vec3 & v : mPositions )
    {
        newPositions.push_back( (v + vec3(0,1,0)) // offset along Y
                                * (1.f + (float(1.0f + sin(getElapsedSeconds())) * 0.5f ) ) );
    }
    mAttribBufferCube->update(ci::geom::POSITION, newPositions);
}

void MetalCubeApp::draw()
{    
    {
        ScopedCommandBuffer commandBuffer;
        
        {
            ScopedComputeEncoder computeEncoder(commandBuffer());
            //            computeEncoder()-> ...
        } // scoped compute
        
        {
            ScopedBlitEncoder blitEncoder(commandBuffer());
            //            blitEncoder()-> ...
        } // scoped blit

        
        {
            ScopedRenderEncoder renderEncoder(commandBuffer(), mRenderDescriptor);
            
            // Enable depth
            renderEncoder()->setDepthStencilState(mDepthEnabled);

            // Enable mip-mapping
            renderEncoder()->setFragSamplerState(mSamplerMipMapped);
            
            uint constantsOffset = (sizeof(ciUniforms_t) * mConstantDataBufferIndex);
            renderEncoder()->setUniforms( mDynamicConstantBuffer, constantsOffset );
            
            // EXAMPLE 1
            // Using interleaved data
//            renderEncoder()->pushDebugGroup("Draw Interleaved Cube");
//
//            // Set the program
//            renderEncoder()->setPipelineState( mPipelineInterleavedLighting );
//
//            // Set render state & resources
//            renderEncoder()->setBufferAtIndex( mVertexBuffer, ciBufferIndexInterleavedVerts );
//            renderEncoder()->setBufferAtIndex( mDynamicConstantBuffer, ciBufferIndexUniforms, constantsOffset );
//
//            // Draw
//            renderEncoder()->draw(mtl::geom::TRIANGLE, 0, 36, 1);
//            renderEncoder()->popDebugGroup();

            
            // EXAMPLE 2
            // Using Cinder geom to draw the cube
            
            // Geom Target
            renderEncoder()->pushDebugGroup("Draw Geom Cube");
            
            // Set the program
            renderEncoder()->setPipelineState( mPipelineGeomLighting );

            // Set the texture
            renderEncoder()->setTexture( mTexture );

            // Draw
            mGeomBufferCube->draw( renderEncoder() );

            renderEncoder()->popDebugGroup();

            
            // EXAMPLE 3
            // Using attrib buffers to draw the cube
            
            // Geom Target
            renderEncoder()->pushDebugGroup("Draw Attrib Cube");
            
            // Set the program
            renderEncoder()->setPipelineState( mPipelineAttribLighting );

            mAttribBufferCube->draw( renderEncoder(), 36 );
            
            renderEncoder()->popDebugGroup();

        } // scoped render encoder
        
    } // scoped command buffer
    
    mConstantDataBufferIndex = (mConstantDataBufferIndex + 1) % kNumInflightBuffers;
}

CINDER_APP( MetalCubeApp, RendererMetal( RendererMetal::Options().numInflightBuffers(kNumInflightBuffers) ) )
