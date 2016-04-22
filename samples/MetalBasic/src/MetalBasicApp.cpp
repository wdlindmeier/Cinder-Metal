#include "cinder/app/App.h"
#include "metal.h"

using namespace ci;
using namespace ci::app;
using namespace std;

// This is an empty project with the relevant XCode changes made to import Metal.
// Meant to be copied as a starting point for a new project, since TinderBox can't make build-setting changes.

class MetalBasicApp : public App
{
public:
    
    void setup() override;
    void resize() override;
    void update() override;
    void draw() override;
    
    mtl::RenderPassDescriptorRef mRenderDescriptor;
};

void MetalBasicApp::setup()
{
    mRenderDescriptor = mtl::RenderPassDescriptor::create();
}

void MetalBasicApp::resize()
{
}

void MetalBasicApp::update()
{
}

void MetalBasicApp::draw()
{
    mtl::ScopedRenderCommandBuffer renderBuffer;
    mtl::ScopedRenderEncoder renderEncoder = renderBuffer.scopedRenderEncoder(mRenderDescriptor);
    
    // Put your drawing here
}

CINDER_APP( MetalBasicApp, RendererMetal )
