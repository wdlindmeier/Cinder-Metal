#include "cinder/app/App.h"
#include "metal.h"

using namespace ci;
using namespace ci::app;
using namespace std;
using namespace cinder::mtl;

class _TBOX_PREFIX_App : public App
{
public:
    
    void setup() override;
    void resize() override;
    void update() override;
    void draw() override;
    
    RenderPassDescriptorRef mRenderDescriptor;
};

void _TBOX_PREFIX_App::setup()
{
    // NEXT STEPS:
    // 1) Change the Deployment Target to iOS >= 8.0 or Mac OS >= 10.11 in the Project info
    // 2) Enable "Automatic Reference Counting" in the Target Build Settings
    // 3) Add the Metal Framework to your target in Build Phases > Link Binaries with Libraries
    
    // NOTE: You cannot build the project for the iOS Simulator

    mRenderDescriptor = RenderPassDescriptor::create();
}

void _TBOX_PREFIX_App::resize()
{
}

void _TBOX_PREFIX_App::update()
{
}

void _TBOX_PREFIX_App::draw()
{
    ScopedRenderBuffer renderBuffer;
    ScopedRenderEncoder renderEncoder(renderBuffer(), mRenderDescriptor);
    
    // Put your drawing here
}

CINDER_APP( _TBOX_PREFIX_App, RendererMetal )
