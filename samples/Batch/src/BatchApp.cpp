#include "cinder/app/App.h"
#include "metal.h"
#include "SharedTypes.h"
#include "Batch.h"

using namespace ci;
using namespace ci::app;
using namespace std;

float cubeVertexData[216] =
{
    0.5, -0.5, 0.5, 0.0, -1.0,  0.0, -0.5, -0.5, 0.5, 0.0, -1.0, 0.0, -0.5, -0.5, -0.5, 0.0, -1.0,  0.0, 0.5, -0.5, -0.5,  0.0, -1.0,  0.0, 0.5, -0.5, 0.5, 0.0, -1.0,  0.0, -0.5, -0.5, -0.5, 0.0, -1.0,  0.0, 0.5, 0.5, 0.5,  1.0, 0.0,  0.0, 0.5, -0.5, 0.5, 1.0,  0.0,  0.0, 0.5, -0.5, -0.5,  1.0,  0.0,  0.0, 0.5, 0.5, -0.5, 1.0, 0.0,  0.0, 0.5, 0.5, 0.5,  1.0, 0.0,  0.0, 0.5, -0.5, -0.5,  1.0,  0.0,  0.0, -0.5, 0.5, 0.5,  0.0, 1.0,  0.0, 0.5, 0.5, 0.5,  0.0, 1.0,  0.0, 0.5, 0.5, -0.5, 0.0, 1.0,  0.0, -0.5, 0.5, -0.5, 0.0, 1.0,  0.0, -0.5, 0.5, 0.5,  0.0, 1.0,  0.0, 0.5, 0.5, -0.5, 0.0, 1.0,  0.0, -0.5, -0.5, 0.5,  -1.0,  0.0, 0.0, -0.5, 0.5, 0.5, -1.0, 0.0,  0.0, -0.5, 0.5, -0.5,  -1.0, 0.0,  0.0, -0.5, -0.5, -0.5,  -1.0,  0.0,  0.0, -0.5, -0.5, 0.5,  -1.0,  0.0, 0.0, -0.5, 0.5, -0.5,  -1.0, 0.0,  0.0, 0.5, 0.5,  0.5,  0.0, 0.0,  1.0, -0.5, 0.5,  0.5,  0.0, 0.0,  1.0, -0.5, -0.5, 0.5, 0.0,  0.0, 1.0, -0.5, -0.5, 0.5, 0.0,  0.0, 1.0, 0.5, -0.5, 0.5, 0.0,  0.0,  1.0, 0.5, 0.5,  0.5,  0.0, 0.0,  1.0, 0.5, -0.5, -0.5,  0.0,  0.0, -1.0, -0.5, -0.5, -0.5, 0.0,  0.0, -1.0, -0.5, 0.5, -0.5,  0.0, 0.0, -1.0, 0.5, 0.5, -0.5,  0.0, 0.0, -1.0, 0.5, -0.5, -0.5,  0.0,  0.0, -1.0, -0.5, 0.5, -0.5,  0.0, 0.0, -1.0
};

class BatchApp : public App
{
public:
    
    void setup() override;
    void resize() override;
    void update() override;
    void draw() override;
    
    float mRotation;
    
    mtl::RenderPassDescriptorRef mRenderDescriptor;
    
    mtl::RenderPipelineStateRef mPipelineSource;
    mtl::BatchRef mBatchSource;

    mtl::RenderPipelineStateRef mPipelineAttribBuffers;
    mtl::BatchRef mBatchAttribBuffers;

    mtl::RenderPipelineStateRef mPipelineRawInterleaved;
    mtl::BatchRef mBatchRawInterleaved;

    mtl::DepthStateRef mDepthEnabled;
    
    mtl::TextureBufferRef mTexture;
    
    CameraPersp mCamera;
};

void BatchApp::setup()
{
    mRenderDescriptor = mtl::RenderPassDescriptor::create(mtl::RenderPassDescriptor::Format()
                                                          .clearColor(ColorAf(0.25f,0.2f,0.3f)));
    
    mTexture = mtl::TextureBuffer::create(loadImage(getAssetPath("checker.png")),
                                          mtl::TextureBuffer::Format().mipmapLevel(4));

    mDepthEnabled = mtl::DepthState::create( mtl::DepthState::Format().depthWriteEnabled() );

    // Set up a couple different kinds of Batches.
    
    // Basic Geom Source
    mPipelineSource = mtl::RenderPipelineState::create("lighting_vertex_interleaved_src",
                                                       "lighting_texture_fragment");
    
    mBatchSource = mtl::Batch::create(geom::Teapot(),
                                      mPipelineSource);
    

    // Raw Interleaved Data
    mtl::DataBufferRef rawBuffer = mtl::DataBuffer::create( sizeof(cubeVertexData),
                                                            cubeVertexData,
                                                            mtl::DataBuffer::Format().label("Interleaved Vertices"));
    
    mPipelineRawInterleaved = mtl::RenderPipelineState::create("lighting_vertex_interleaved",
                                                               "lighting_fragment");
    
    mBatchRawInterleaved = mtl::Batch::create(cinder::mtl::VertexBuffer::create(36, rawBuffer),
                                              mPipelineRawInterleaved);

    // Custom Vertex Buffer w/ non-interleaved attribute buffers
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
    
    mtl::VertexBufferRef attribBufferCube = mtl::VertexBuffer::create( positions.size() );
    mtl::DataBufferRef positionBuffer = mtl::DataBuffer::create(positions, mtl::DataBuffer::Format().label("Positions"));
    attribBufferCube->setBufferForAttribute(positionBuffer, ci::geom::POSITION);
    mtl::DataBufferRef normalBuffer = mtl::DataBuffer::create(normals, mtl::DataBuffer::Format().label("Normals"));
    attribBufferCube->setBufferForAttribute(normalBuffer, ci::geom::NORMAL);
    
    mPipelineAttribBuffers = mtl::RenderPipelineState::create("lighting_vertex_attrib_buffers",
                                                              "lighting_fragment",
                                                              mtl::RenderPipelineState::Format());
    
    mBatchAttribBuffers = mtl::Batch::create( attribBufferCube, mPipelineAttribBuffers );
}

void BatchApp::resize()
{
    mCamera.setPerspective(65.f, getWindowAspectRatio(), 0.01, 1000.f);
    mCamera.lookAt(vec3(0,0,-5),vec3(0));
}

void BatchApp::update()
{
    mRotation += 0.01f;
}

void BatchApp::draw()
{
    mtl::ScopedRenderCommandBuffer renderBuffer;
    mtl::ScopedRenderEncoder renderEncoder = renderBuffer.scopedRenderEncoder(mRenderDescriptor);
    
    renderEncoder << mDepthEnabled;
    renderEncoder.setTexture(mTexture);

    mtl::setMatrices(mCamera);

    {
        mtl::ScopedMatrices matSource;
        mtl::translate(vec3(0,-0.5,0));
        mtl::rotate(mRotation, vec3(1.0f, 1.0f, 1.0f));
        mtl::scale(vec3(2.f));
        mBatchSource->draw(renderEncoder);
    }
    
    // Left
    {
        mtl::ScopedMatrices matAttribBuffer;
        mtl::translate(vec3(2,0,0));
        mtl::rotate(-mRotation, vec3(-1.0f, 1.0f, -1.0f));
        mtl::ScopedColor green(0,1,0);
        mBatchAttribBuffers->draw(renderEncoder);
    }

    // Right
    {
        mtl::ScopedMatrices matInterleaved;
        mtl::translate(vec3(-2,0,0));
        mtl::rotate(-mRotation, vec3(1.0f, -1.0f, 1.0f));
        mtl::ScopedColor red(1,0,0);
        mBatchRawInterleaved->draw(renderEncoder);
    }
}

CINDER_APP( BatchApp, RendererMetal )
