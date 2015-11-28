#include "cinder/app/App.h"
#include "cinder/gl/gl.h"
#include "cinder/Camera.h"
#include "cinder/GeomIo.h"

// Cinder-Metal
#include "metal.h"
#include "VertexBuffer.h"

using namespace std;
using namespace ci;
using namespace ci::app;
using namespace cinder::mtl;

// Raw cube data. Layout is positionX, positionY, positionZ, normalX, normalY, normalZ
float cubeVertexData[216] =
{
    0.5, -0.5, 0.5, 0.0, -1.0,  0.0, -0.5, -0.5, 0.5, 0.0, -1.0, 0.0, -0.5, -0.5, -0.5, 0.0, -1.0,  0.0, 0.5, -0.5, -0.5,  0.0, -1.0,  0.0, 0.5, -0.5, 0.5, 0.0, -1.0,  0.0, -0.5, -0.5, -0.5, 0.0, -1.0,  0.0, 0.5, 0.5, 0.5,  1.0, 0.0,  0.0, 0.5, -0.5, 0.5, 1.0,  0.0,  0.0, 0.5, -0.5, -0.5,  1.0,  0.0,  0.0, 0.5, 0.5, -0.5, 1.0, 0.0,  0.0, 0.5, 0.5, 0.5,  1.0, 0.0,  0.0, 0.5, -0.5, -0.5,  1.0,  0.0,  0.0, -0.5, 0.5, 0.5,  0.0, 1.0,  0.0, 0.5, 0.5, 0.5,  0.0, 1.0,  0.0, 0.5, 0.5, -0.5, 0.0, 1.0,  0.0, -0.5, 0.5, -0.5, 0.0, 1.0,  0.0, -0.5, 0.5, 0.5,  0.0, 1.0,  0.0, 0.5, 0.5, -0.5, 0.0, 1.0,  0.0, -0.5, -0.5, 0.5,  -1.0,  0.0, 0.0, -0.5, 0.5, 0.5, -1.0, 0.0,  0.0, -0.5, 0.5, -0.5,  -1.0, 0.0,  0.0, -0.5, -0.5, -0.5,  -1.0,  0.0,  0.0, -0.5, -0.5, 0.5,  -1.0,  0.0, 0.0, -0.5, 0.5, -0.5,  -1.0, 0.0,  0.0, 0.5, 0.5,  0.5,  0.0, 0.0,  1.0, -0.5, 0.5,  0.5,  0.0, 0.0,  1.0, -0.5, -0.5, 0.5, 0.0,  0.0, 1.0, -0.5, -0.5, 0.5, 0.0,  0.0, 1.0, 0.5, -0.5, 0.5, 0.0,  0.0,  1.0, 0.5, 0.5,  0.5,  0.0, 0.0,  1.0, 0.5, -0.5, -0.5,  0.0,  0.0, -1.0, -0.5, -0.5, -0.5, 0.0,  0.0, -1.0, -0.5, 0.5, -0.5,  0.0, 0.0, -1.0, 0.5, 0.5, -0.5,  0.0, 0.0, -1.0, 0.5, -0.5, -0.5,  0.0,  0.0, -1.0, -0.5, 0.5, -0.5,  0.0, 0.0, -1.0
};

const static int kNumInflightBuffers = 3;

class MetalCubeApp : public App
{
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

    RenderPipelineStateRef mPipelineInterleavedLighting;
    RenderPipelineStateRef mPipelineGeomLighting;
    RenderPipelineStateRef mPipelineAttribLighting;
    
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
    
    mRenderDescriptor = RenderPassDescriptor::create(RenderPassDescriptor::Format()
                                                     .clearColor(ColorAf(1.f,0.f,0.f,1.f)));

    mTexture = TextureBuffer::create(loadImage(getAssetPath("checker.png")),
                                     TextureBuffer::Format().mipmapLevel(4));
    
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
    mDynamicConstantBuffer = DataBuffer::create(sizeof(ciUniforms_t) * kNumInflightBuffers,
                                                nullptr,
                                                "Uniform Buffer");
    
    // EXAMPLE 1
    // Use raw, interleaved vertex data
    mVertexBuffer = DataBuffer::create(sizeof(cubeVertexData),  // the size of the buffer
                                       cubeVertexData,          // the data
                                       "Interleaved Vertices"); // the name of the buffer
    
    mPipelineInterleavedLighting = RenderPipelineState::create("lighting_vertex_interleaved",
                                                               "lighting_fragment",
                                                               RenderPipelineState::Format()
                                                               .blendingEnabled(true));

    // EXAMPLE 2
    // Use a geom source
    mGeomBufferCube = VertexBuffer::create(ci::geom::Cube(),     // A geom source
                                           {{ci::geom::INDEX,     // Pass in the requested attributes
                                             ci::geom::POSITION,  // which will be sent to the shader.
                                             ci::geom::NORMAL,
                                             ci::geom::TEX_COORD_0 }});
    
    mPipelineGeomLighting = RenderPipelineState::create("lighting_vertex_geom",
                                                        "lighting_texture_fragment",
                                                        RenderPipelineState::Format()
                                                        .blendingEnabled(true));

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
    mAttribBufferCube->setBufferForAttribute(positionBuffer, ci::geom::POSITION);
    DataBufferRef normalBuffer = DataBuffer::create(normals, "normals");
    mAttribBufferCube->setBufferForAttribute(normalBuffer, ci::geom::NORMAL);
    
    mPipelineAttribLighting = RenderPipelineState::create("lighting_vertex_attrib_buffers",
                                                          "lighting_fragment",
                                                          RenderPipelineState::Format()
                                                          .blendingEnabled(true) );
}

void MetalCubeApp::update()
{
    mat4 modelMatrix = glm::rotate(mRotation, vec3(1.0f, 1.0f, 1.0f));
    mat4 normalMatrix = inverse(transpose(modelMatrix));
    mat4 modelViewMatrix = mCamera.getViewMatrix() * modelMatrix;
    mat4 modelViewProjectionMatrix = mCamera.getProjectionMatrix() * modelViewMatrix;

    // Pass the matrices into the uniform block
    mUniforms.normalMatrix = toMtl(normalMatrix);
    mUniforms.modelViewProjectionMatrix = toMtl(modelViewProjectionMatrix);
    mUniforms.elapsedSeconds = getElapsedSeconds();
    mDynamicConstantBuffer->setData(&mUniforms, mConstantDataBufferIndex);
    
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

void MetalCubeApp::draw()
{    
    ScopedRenderBuffer renderBuffer;
    ScopedRenderEncoder renderEncoder(renderBuffer(), mRenderDescriptor);
    
    // Enable depth
    renderEncoder()->setDepthStencilState(mDepthEnabled);

    // Enable mip-mapping
    renderEncoder()->setFragSamplerState(mSamplerMipMapped);
    
    uint constantsOffset = (sizeof(ciUniforms_t) * mConstantDataBufferIndex);
    renderEncoder()->setUniforms(mDynamicConstantBuffer, constantsOffset);
    
    
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
//            renderEncoder()->draw(mtl::geom::TRIANGLE, 36);
//            renderEncoder()->popDebugGroup();

    
    // EXAMPLE 2
    // Using Cinder geom to draw the cube
    
    // Geom Target
    renderEncoder()->pushDebugGroup("Draw Geom Cube");
    
    // Set the program
    renderEncoder()->setPipelineState(mPipelineGeomLighting);

    // Set the texture
    renderEncoder()->setTexture(mTexture);

    // Draw
    mGeomBufferCube->draw(renderEncoder());

    renderEncoder()->popDebugGroup();

    
    // EXAMPLE 3
    // Using attrib buffers to draw the cube
    
    // Geom Target
    renderEncoder()->pushDebugGroup("Draw Attrib Cube");
    
    // Set the program
    renderEncoder()->setPipelineState(mPipelineAttribLighting);

    mAttribBufferCube->draw(renderEncoder(), 36);
    
    renderEncoder()->popDebugGroup();
    
    mConstantDataBufferIndex = (mConstantDataBufferIndex + 1) % kNumInflightBuffers;
}

CINDER_APP( MetalCubeApp, RendererMetal( RendererMetal::Options().numInflightBuffers(kNumInflightBuffers) ) )
