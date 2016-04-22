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
    mCam.lookAt(vec3(6, 0, 8.f),
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
    renderEncoder.draw(mTexture, Rectf(-2,-1,0,1));

    // Draw a circle
    mtl::color(1,0,0);
    renderEncoder.drawStrokedCircle(vec3(0), 1.f);

    // Draw a solid circle
    mtl::color(1,1,0);
    renderEncoder.drawSolidCircle(vec3(2,0,0), 1.f);

    // Draw a square
    mtl::color(0,1,1);
    renderEncoder.drawStrokedRect(Rectf(-1,-1,1,1));

    // Draw a solid square
    mtl::color(1,0,1);
    renderEncoder.drawSolidRect(Rectf(3,-1,5,1));

    // Draw a sphere
    mtl::color(0,1,0);
    renderEncoder.drawSphere(vec3(6,0,0), 1.f);

    // Draw a cube
    mtl::color(1,0,1);
    renderEncoder.drawCube(vec3(8,0,0), vec3(2.f));

    // Draw a line
    mtl::color(1,1,1);
    renderEncoder.drawLine(vec3(0), vec3(10,0,0));

    // Draw a ring
    mtl::color(0,0,1);
    renderEncoder.drawRing(vec3(10,0,0), 1.f, 0.5);
    
    // Draw a colored cube
    mtl::color(1,1,1);
    renderEncoder.drawColoredCube(vec3(12,0,0), vec3(2.f));
}

CINDER_APP( MetalBasicApp, RendererMetal, [](MetalBasicApp::Settings *settings)
{
    settings->setWindowSize(1400,400);
});
