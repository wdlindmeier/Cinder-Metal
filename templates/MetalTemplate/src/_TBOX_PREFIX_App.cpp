#include "cinder/app/App.h"
#include "metal.h"

using namespace ci;
using namespace ci::app;
using namespace std;

class _TBOX_PREFIX_App : public App
{
public:
    
    void setup() override;
    void resize() override;
    void update() override;
    void draw() override;
    
    mtl::RenderPassDescriptorRef mRenderDescriptor;
};

void _TBOX_PREFIX_App::setup()
{
    // NEXT STEPS:
    // 1) Change the Deployment Target to iOS >= 9.0 or Mac OS >= 10.11 in the Project info
    // 2) Enable "Automatic Reference Counting" in the Project Build Settings
    // 3) Add the Metal Framework to your target in Build Phases > Link Binaries with Libraries
    // 4) If you're building for OS X, also add the QuartzCore Framework 
    // 5) If you want to include block headers in your Metal shaders, add this path to 
    //    Build Settings > Metal > Header Search Paths:
    //          $(CINDER_PATH)/blocks/Cinder-Metal/include
    
    // NOTE: You cannot build the project for the iOS Simulator

    mRenderDescriptor = mtl::RenderPassDescriptor::create();
}

void _TBOX_PREFIX_App::resize()
{
}

void _TBOX_PREFIX_App::update()
{
}

void _TBOX_PREFIX_App::draw()
{
    mtl::ScopedRenderCommandBuffer renderBuffer;
    mtl::ScopedRenderEncoder renderEncoder = renderBuffer.scopedRenderEncoder(mRenderDescriptor);
    
    // Put your drawing here
}

CINDER_APP( _TBOX_PREFIX_App, RendererMetal )
