#include "cinder/app/App.h"
#include "metal.h"
#include "Batch.h"
#include "Draw.h"
#include "VertexBuffer.h"
#include "Shader.h"

using namespace ci;
using namespace ci::app;
using namespace std;

class FboBasicApp : public App
{
public:
    
    void setup() override;
    void resize() override;
    void update() override;
    void draw() override;
    void createFBO();

    mtl::RenderPassDescriptorRef mRenderDescriptor;
    mtl::RenderPassDescriptorRef mRenderDescriptorFbo;

    mtl::RenderPipelineStateRef mPipelineCube;
    mtl::RenderPipelineStateRef mPipelineTextureRGB;
    mtl::RenderPipelineStateRef mPipelineTextureGray;
    mtl::RenderPipelineStateRef mPipelineTexturedGeom;

    mtl::DepthStateRef mDepthEnabled;

    // An "FBO" in metal is a TextureBuffer and RenderPassDescriptor w/ specific formats.
    mtl::TextureBufferRef mFBO;
    
    mat4 mRotation;

    mtl::VertexBufferRef mCube;
    mtl::VertexBufferRef mRect;
};

void FboBasicApp::setup()
{
    mRenderDescriptor = mtl::RenderPassDescriptor::create(mtl::RenderPassDescriptor::Format()
                                                          .clearColor(Color(0.35f, 0.35f, 0.35f)));

    mRenderDescriptorFbo = mtl::RenderPassDescriptor::create(mtl::RenderPassDescriptor::Format()
                                                             .clearColor(Color(0.25, 0.5f, 1.0f))
                                                             .depthStoreAction(mtl::StoreActionStore)
                                                             .depthUsage((mtl::TextureUsage)
                                                                         (mtl::TextureUsageRenderTarget |
                                                                          mtl::TextureUsageShaderRead))
                                                             );

    mDepthEnabled = mtl::DepthState::create( mtl::DepthState::Format().depthWriteEnabled() );
    
    mPipelineCube = mtl::RenderPipelineState::create("cube_vertex", "color_fragment");
    mPipelineTexturedGeom = mtl::RenderPipelineState::create("cube_vertex", "rgb_texture_fragment");

    mCube = mtl::VertexBuffer::create( ci::geom::Cube()
                                       .size(vec3(2.2f))
                                       .colors(Color(1,0,0),Color(0,1,0),Color(0,0,1),Color(1,1,0),Color(0,1,1),Color(1,0,1)),
                                       {{ ci::geom::POSITION, ci::geom::NORMAL, ci::geom::TEX_COORD_0, ci::geom::COLOR }} );
}

void FboBasicApp::resize()
{
    createFBO();
}

void FboBasicApp::createFBO()
{
    // TODO: simplify this
    // NOTE: getWindowContentScale() only works on Mac with setHighDensityDisplayEnabled
    float contentScale = getWindow()->getDisplay()->getContentScale();
    mFBO = mtl::TextureBuffer::create( getWindowWidth() * contentScale,
                                       getWindowWidth() * contentScale, // width x width keeps it square
                                       mtl::TextureBuffer::Format()
                                       .pixelFormat(mtl::PixelFormatBGRA8Unorm)
                                       .usage((mtl::TextureUsage)(mtl::TextureUsageRenderTarget |
                                                                  mtl::TextureUsageShaderRead)));
}

void FboBasicApp::update()
{
    mRotation *= rotate( 0.06f, normalize( vec3( 0.16666f, 0.333333f, 0.666666f ) ) );
}

void FboBasicApp::draw()
{
    {
        // Draw to the FBO
        mtl::ScopedCommandBuffer fboBuffer(true);
        mtl::ScopedRenderEncoder fboEncoder = fboBuffer.scopedRenderEncoder(mRenderDescriptorFbo, mFBO, "fbo");
        fboEncoder << mDepthEnabled;
        mtl::ScopedMatrices matCam;

        vec2 fboSize = mFBO->getSize();
        CameraPersp cam( fboSize.x, fboSize.y, 60.0f );
        cam.setPerspective( 60, fboSize.x / fboSize.y, 1, 1000 );
        cam.lookAt( vec3( 2.8f, 1.8f, -2.8f ), vec3( 0 ));
        mtl::setMatrices(cam);
        mtl::setModelMatrix(mRotation);
        mtl::ScopedColor blue(0, 0, 1);
        fboEncoder.draw(mCube, mPipelineCube);
    }
    
    // Draw the FBO texture
    mtl::ScopedRenderCommandBuffer renderBuffer;
    mtl::ScopedRenderEncoder renderEncoder = renderBuffer.scopedRenderEncoder(mRenderDescriptor);
    renderEncoder << mDepthEnabled;
    
    // Draw the textured cube
    {
        mtl::ScopedMatrices matCam;
        CameraPersp cam( getWindowWidth(), getWindowHeight(), 60.0f );
        cam.setPerspective( 60, getWindowAspectRatio(), 1, 1000 );
        cam.lookAt( vec3( 2.6f, 1.6f, -2.6f ), vec3( 0 ) );
        mtl::setMatrices( cam );
        
        renderEncoder.setTexture(mFBO);
        renderEncoder.draw(mCube, mPipelineTexturedGeom);
    }
    
    {
        // Draw the textures
        mtl::ScopedMatrices matBackground;
        mtl::setMatricesWindow(getWindowSize());
        renderEncoder.draw(mFBO, Rectf(0,0,128,128));
        mtl::TextureBufferRef depthTex = mRenderDescriptorFbo->getDepthTexture();
        renderEncoder.draw(depthTex, Rectf(128,0,256,128));
    }
}

CINDER_APP( FboBasicApp, RendererMetal )