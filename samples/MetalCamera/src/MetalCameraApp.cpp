#include "cinder/app/App.h"
#include "metal.h"
#include "Batch.h"
#include "Draw.h"
#include "ImageHelpers.h"
#include "CameraManager.h"

using namespace ci;
using namespace ci::app;
using namespace std;

class MetalCameraApp : public App
{
public:
    
    void setup() override;
    void resize() override;
    void update() override;
    void draw() override;
    
    mtl::RenderPassDescriptorRef mRenderDescriptor;
    
    CameraOrtho mCam;

    CameraManager mCameraManager;
};

void MetalCameraApp::setup()
{
    mRenderDescriptor = mtl::RenderPassDescriptor::create();
    mCameraManager.startCapture();
}

void MetalCameraApp::resize()
{
    mCam.setOrtho( 0, getWindowWidth(),
                   0, getWindowHeight(),
                  -1, 1 );
}

void MetalCameraApp::update()
{
}

void MetalCameraApp::draw()
{
    mtl::ScopedRenderCommandBuffer renderBuffer;
    mtl::ScopedRenderEncoder renderEncoder = renderBuffer.scopedRenderEncoder(mRenderDescriptor);
    
    mtl::setMatrices(mCam);
    
    mtl::color(1,1,1);

    if ( mCameraManager.hasTexture() )
    {
        mtl::ScopedModelMatrix modelMat;
        
        mtl::translate(getWindowCenter());
        mtl::rotate(M_PI * -0.5f);
        mtl::scale(1, -1, 1);
        
        vec2 imageSize(640,480);
        renderEncoder.draw(mCameraManager.getTexture(),
                           Rectf( imageSize.x * -0.5,
                                  imageSize.y * -0.5,
                                  imageSize.x * 0.5,
                                  imageSize.y * 0.5
                                 ));
    }
}

CINDER_APP( MetalCameraApp, RendererMetal, [](MetalCameraApp::Settings *settings){} );
