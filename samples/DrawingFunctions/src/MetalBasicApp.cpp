#include "cinder/app/App.h"
#include "cinder/CameraUi.h"
#include "metal.h"
#include "Batch.h"
#include "Draw.h"
#include "SharedTypes.h"

using namespace ci;
using namespace ci::app;
using namespace std;

class MetalBasicApp : public App
{
public:
    
    void setup() override;
    void resize() override;
    void update() override;
    void draw() override;
    
    mtl::RenderPassDescriptorRef mRenderDescriptor;
    mtl::DepthStateRef mDepthEnabled;
    mtl::TextureBufferRef mTexture;
    
    CameraPersp mCam;
    CameraUi mCamUi;
};

void MetalBasicApp::setup()
{
    mCamUi = CameraUi(&mCam, getWindow(), -1);

    mRenderDescriptor = mtl::RenderPassDescriptor::create(mtl::RenderPassDescriptor::Format()
                                                          .clearColor(Color(0,0,0)));

    mDepthEnabled = mtl::DepthState::create(mtl::DepthState::Format()
                                            .depthWriteEnabled(true));

    mTexture = mtl::TextureBuffer::create(loadImage(loadAsset("cinderblock.png")));
}

void MetalBasicApp::resize()
{
    mCam.setPerspective(40, getWindowAspectRatio(), 0.01, 10000);
    mCam.lookAt(vec3(6, 0, 6.f),
                vec3(6, 0, 0));
}

void MetalBasicApp::update()
{
}

void MetalBasicApp::draw()
{
    mtl::ScopedRenderCommandBuffer renderBuffer;
    mtl::ScopedRenderEncoder renderEncoder = renderBuffer.scopedRenderEncoder(mRenderDescriptor);

    mtl::setMatrices(mCam);
    
    renderEncoder << mDepthEnabled;
    
    // Draw a Texture
    mtl::color(1,1,1);
    mtl::draw(mTexture, renderEncoder, Rectf(-2,-1,0,1));

    // Draw a circle
    mtl::color(1,0,0);
    mtl::drawStrokedCircle(vec3(0), 1.f, renderEncoder);

    // Draw a solid circle
    mtl::color(1,1,0);
    mtl::drawSolidCircle(vec3(2,0,0), 1.f, renderEncoder);

    // Draw a square
    mtl::color(0,1,1);
    mtl::drawStrokedRect(Rectf(-1,-1,1,1), renderEncoder);

    // Draw a solid square
    mtl::color(1,0,1);
    mtl::drawSolidRect(Rectf(3,-1,5,1), renderEncoder);

    // Draw a sphere
    mtl::color(0,1,0);
    mtl::drawSphere(vec3(6,0,0), 1.f, renderEncoder);

    // Draw a cube
    mtl::color(1,0,1);
    mtl::drawCube(vec3(8,0,0), vec3(2.f), renderEncoder);

    // Draw a line
    mtl::color(1,1,1);
    mtl::drawLine(vec3(0), vec3(10,0,0), renderEncoder);

    // Draw a ring
    mtl::color(0,0,1);
    mtl::drawRing(vec3(10,0,0), 1.f, 0.5, renderEncoder );
    
    // Draw a colored cube
    mtl::color(1,1,1);
    mtl::drawColoredCube(vec3(12,0,0), vec3(2.f), renderEncoder);
}

CINDER_APP( MetalBasicApp, RendererMetal, [](MetalBasicApp::Settings *settings)
{
    settings->setWindowSize(1400,400);
});
