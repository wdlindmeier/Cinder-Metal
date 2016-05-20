#include "cinder/app/App.h"
#include "metal.h"
#include "VertexBuffer.h"
#include "Batch.h"
#include "Shader.h"

using namespace ci;
using namespace ci::app;
using namespace std;

class CubeApp : public App
{
public:
    
    void setup() override;
    void resize() override;
    void update() override;
    void draw() override;
    
    CameraPersp                     mCam;
    mat4                            mCubeRotation;
    
    mtl::RenderPassDescriptorRef    mRenderDescriptor;
    mtl::TextureBufferRef           mTexture;
    mtl::RenderPipelineStateRef     mPipeline;
    mtl::DepthStateRef              mDepthEnabled;
    mtl::BatchRef                   mBatchCube;
    
};

void CubeApp::setup()
{
    mRenderDescriptor = mtl::RenderPassDescriptor::create();

    mCam.lookAt( vec3( 3, 2, 4 ), vec3( 0 ) );

    mTexture = mtl::TextureBuffer::create(loadImage(getAssetPath("texture.jpg")),
                                          mtl::TextureBuffer::Format().mipmapLevel(3).flipVertically());

    mDepthEnabled = mtl::DepthState::create( mtl::DepthState::Format().depthWriteEnabled() );

    mPipeline = mtl::RenderPipelineState::create("batch_vertex", "cube_fragment");
    mBatchCube = mtl::Batch::create(geom::Cube(), mPipeline);
}

void CubeApp::resize()
{
    mCam.setPerspective( 60, getWindowAspectRatio(), 1, 1000 );
}

void CubeApp::update()
{
    // Rotate the cube by 0.2 degrees around the y-axis
    mCubeRotation *= rotate( toRadians( 0.2f ), normalize( vec3( 0, 1, 0 ) ) );
}

void CubeApp::draw()
{
    mtl::ScopedRenderCommandBuffer renderBuffer;
    mtl::ScopedRenderEncoder renderEncoder = renderBuffer.scopedRenderEncoder(mRenderDescriptor);

    renderEncoder.setDepthStencilState(mDepthEnabled);
    renderEncoder.setTexture(mTexture);
    
    mtl::setMatrices(mCam);
    mtl::setModelMatrix(mCubeRotation);
    renderEncoder.draw(mBatchCube);
}

CINDER_APP( CubeApp, RendererMetal( RendererMetal::Options().numInflightBuffers(1) ) )
