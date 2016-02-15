#include "cinder/app/App.h"
#include "cinder/gl/gl.h"
#include "cinder/Camera.h"
#include "cinder/GeomIo.h"

// Cinder-Metal
#include "metal.h"
#include "VertexBuffer.h"
#include "SharedData.h"

using namespace std;
using namespace ci;
using namespace ci::app;

// Raw cube data. Layout is positionX, positionY, positionZ, normalX, normalY, normalZ
float cubeVertexData[216] =
{
    0.5, -0.5, 0.5, 0.0, -1.0,  0.0, -0.5, -0.5, 0.5, 0.0, -1.0, 0.0, -0.5, -0.5, -0.5, 0.0, -1.0,  0.0, 0.5, -0.5, -0.5,  0.0, -1.0,  0.0, 0.5, -0.5, 0.5, 0.0, -1.0,  0.0, -0.5, -0.5, -0.5, 0.0, -1.0,  0.0, 0.5, 0.5, 0.5,  1.0, 0.0,  0.0, 0.5, -0.5, 0.5, 1.0,  0.0,  0.0, 0.5, -0.5, -0.5,  1.0,  0.0,  0.0, 0.5, 0.5, -0.5, 1.0, 0.0,  0.0, 0.5, 0.5, 0.5,  1.0, 0.0,  0.0, 0.5, -0.5, -0.5,  1.0,  0.0,  0.0, -0.5, 0.5, 0.5,  0.0, 1.0,  0.0, 0.5, 0.5, 0.5,  0.0, 1.0,  0.0, 0.5, 0.5, -0.5, 0.0, 1.0,  0.0, -0.5, 0.5, -0.5, 0.0, 1.0,  0.0, -0.5, 0.5, 0.5,  0.0, 1.0,  0.0, 0.5, 0.5, -0.5, 0.0, 1.0,  0.0, -0.5, -0.5, 0.5,  -1.0,  0.0, 0.0, -0.5, 0.5, 0.5, -1.0, 0.0,  0.0, -0.5, 0.5, -0.5,  -1.0, 0.0,  0.0, -0.5, -0.5, -0.5,  -1.0,  0.0,  0.0, -0.5, -0.5, 0.5,  -1.0,  0.0, 0.0, -0.5, 0.5, -0.5,  -1.0, 0.0,  0.0, 0.5, 0.5,  0.5,  0.0, 0.0,  1.0, -0.5, 0.5,  0.5,  0.0, 0.0,  1.0, -0.5, -0.5, 0.5, 0.0,  0.0, 1.0, -0.5, -0.5, 0.5, 0.0,  0.0, 1.0, 0.5, -0.5, 0.5, 0.0,  0.0,  1.0, 0.5, 0.5,  0.5,  0.0, 0.0,  1.0, 0.5, -0.5, -0.5,  0.0,  0.0, -1.0, -0.5, -0.5, -0.5, 0.0,  0.0, -1.0, -0.5, 0.5, -0.5,  0.0, 0.0, -1.0, 0.5, 0.5, -0.5,  0.0, 0.0, -1.0, 0.5, -0.5, -0.5,  0.0,  0.0, -1.0, -0.5, 0.5, -0.5,  0.0, 0.0, -1.0
};

const static int kNumInflightBuffers = 3;

class VertexBufferApp : public App
{
  public:
    
    VertexBufferApp() :
    mRotation(0.f)
    {}
    
	void setup() override;
    void loadAssets();
    void resize() override;
	void update() override;
	void draw() override;

    mtl::VertexBufferRef mInterleavedBuffer;
    mtl::VertexBufferRef mGeomBufferCube;
    mtl::VertexBufferRef mAttribBufferCube;
    vector<vec3> mPositions;

    mtl::RenderPipelineStateRef mPipelineInterleavedLighting;
    mtl::RenderPipelineStateRef mPipelineGeomLighting;
    mtl::RenderPipelineStateRef mPipelineAttribLighting;
    
    mtl::SamplerStateRef mSamplerMipMapped;
    mtl::DepthStateRef mDepthEnabled;
    
    mtl::UniformBlock<mtl::ciUniforms_t> mUniforms;

    float mRotation;
    CameraPersp mCamera;
    
    mtl::RenderPassDescriptorRef mRenderDescriptor;
    
    mtl::TextureBufferRef mTexture;
};

void VertexBufferApp::setup()
{
    
    mTexture = mtl::TextureBuffer::create(loadImage(getAssetPath("checker.png")),
                                          mtl::TextureBuffer::Format().mipmapLevel(4));
    
    mSamplerMipMapped = mtl::SamplerState::create();
    
    mDepthEnabled = mtl::DepthState::create(mtl::DepthState::Format().depthWriteEnabled());
    
    mRenderDescriptor = mtl::RenderPassDescriptor::create(mtl::RenderPassDescriptor::Format()
                                                          .clearColor(ColorAf(1.f,0.f,0.f,1.f)));
    loadAssets();
}

void VertexBufferApp::resize()
{
    mCamera = CameraPersp(getWindowWidth(), getWindowHeight(), 65.f, 0.1f, 100.f);
    mCamera.lookAt(vec3(0,0,-5), vec3(0));
}

void VertexBufferApp::loadAssets()
{
    // EXAMPLE 1
    // Use raw, interleaved vertex data
    mtl::DataBufferRef rawBuffer = mtl::DataBuffer::create(sizeof(cubeVertexData),  // the size of the buffer
                                                           cubeVertexData,          // the data
                                                           mtl::DataBuffer::Format().label("Interleaved Vertices")); // the name of the buffer

    mInterleavedBuffer = cinder::mtl::VertexBuffer::create(36, rawBuffer);

    mPipelineInterleavedLighting = mtl::RenderPipelineState::create("lighting_vertex_interleaved",
                                                                    "lighting_fragment");

    // EXAMPLE 2
    // Use a geom source
    ci::geom::BufferLayout cubeLayout;
    cubeLayout.append(ci::geom::Attrib::POSITION, 3, sizeof(CubeVertex), offsetof(CubeVertex, position));
    cubeLayout.append(ci::geom::Attrib::NORMAL, 3, sizeof(CubeVertex), offsetof(CubeVertex, normal));
    cubeLayout.append(ci::geom::Attrib::TEX_COORD_0, 2, sizeof(CubeVertex), offsetof(CubeVertex, texCoord0));
    mGeomBufferCube = mtl::VertexBuffer::create(ci::geom::Cube(), cubeLayout, mtl::DataBuffer::Format().label("Geom Cube"));

    mPipelineGeomLighting = mtl::RenderPipelineState::create("lighting_vertex_interleaved_src",
                                                             "lighting_texture_fragment");

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
    
    mAttribBufferCube = mtl::VertexBuffer::create( positions.size() );
    mPositions = positions;
    mtl::DataBufferRef positionBuffer = mtl::DataBuffer::create(mPositions, mtl::DataBuffer::Format().label("Positions"));
    mAttribBufferCube->setBufferForAttribute(positionBuffer, ci::geom::POSITION);
    mtl::DataBufferRef normalBuffer = mtl::DataBuffer::create(normals, mtl::DataBuffer::Format().label("Normals"));
    mAttribBufferCube->setBufferForAttribute(normalBuffer, ci::geom::NORMAL);
    
    mPipelineAttribLighting = mtl::RenderPipelineState::create("lighting_vertex_attrib_buffers",
                                                               "lighting_fragment",
                                                               mtl::RenderPipelineState::Format());
}

void VertexBufferApp::update()
{
    mat4 modelMatrix = glm::rotate(mRotation, vec3(1.0f, 1.0f, 1.0f));
    mat4 normalMatrix = inverse(transpose(modelMatrix));
    mat4 modelViewMatrix = mCamera.getViewMatrix() * modelMatrix;
    mat4 modelViewProjectionMatrix = mCamera.getProjectionMatrix() * modelViewMatrix;

    // Pass the matrices into the uniform block
    mUniforms.updateData([&]( auto data )
    {
        data.ciNormalMatrix4x4 = toMtl(normalMatrix);
        data.ciModelViewProjection = toMtl(modelViewProjectionMatrix);
        return data;
    });

    mRotation += 0.01f;

    // Update the verts to grow and shrink w/ time
    vector<vec3> newPositions;
    for ( vec3 & v : mPositions )
    {
        newPositions.push_back((v + vec3(0,1,0))
                               * (1.f + (float(1.0f + sin(getElapsedSeconds())) * 0.5f )));
    }
    mAttribBufferCube->update(ci::geom::POSITION, newPositions);
}

void VertexBufferApp::draw()
{    
    mtl::ScopedRenderCommandBuffer renderBuffer;
    mtl::ScopedRenderEncoder renderEncoder = renderBuffer.scopedRenderEncoder(mRenderDescriptor);

    // Enable depth
    renderEncoder.setDepthStencilState(mDepthEnabled);

    // Pass in the uniforms
    mUniforms.sendToEncoder(renderEncoder);
    
    // EXAMPLE 1 (Green)
    // Using interleaved data
    renderEncoder.pushDebugGroup("Draw Interleaved Cube");

    // Set the program
    renderEncoder.setPipelineState( mPipelineInterleavedLighting );

    // Draw
    mInterleavedBuffer->draw(renderEncoder);

    renderEncoder.popDebugGroup();
    
    // EXAMPLE 2 (Checkered)
    // Using Cinder geom to draw the cube
    
    // Geom Target
    renderEncoder.pushDebugGroup("Draw Textured Geom Cube");
    
    // Set the program
    renderEncoder.setPipelineState(mPipelineGeomLighting);

    // Set the texture
    renderEncoder.setTexture(mTexture);

    // Enable mip-mapping
    renderEncoder.setFragSamplerState(mSamplerMipMapped);
    
    // Draw
    mGeomBufferCube->draw(renderEncoder);

    renderEncoder.popDebugGroup();
    
    // EXAMPLE 3 (Blue)
    // Using attrib buffers to draw the cube
    
    // Geom Target
    renderEncoder.pushDebugGroup("Draw Attrib Cube");
    
    // Set the program
    renderEncoder.setPipelineState(mPipelineAttribLighting);
    
    mAttribBufferCube->draw(renderEncoder, 36);
    
    renderEncoder.popDebugGroup();
}

CINDER_APP( VertexBufferApp, RendererMetal( RendererMetal::Options().numInflightBuffers(kNumInflightBuffers) ) )
