#include "cinder/app/App.h"
#include "metal.h"
#include "Batch.h"
#include "Shader.h"

using namespace ci;
using namespace ci::app;
using namespace std;

class StockShaderApp : public App
{
public:
    
    void setup() override;
    void resize() override;
    void update() override;
    void draw() override;
    
    mtl::RenderPassDescriptorRef mRenderDescriptor;
    
    CameraPersp mCam;
    mtl::BatchRef mBatchStockColor;
};

void StockShaderApp::setup()
{
    mRenderDescriptor = mtl::RenderPassDescriptor::create();
    
    mCam.lookAt(vec3(0,0,-10), vec3(0));
    
    ci::mtl::RenderPipelineStateRef renderPipeline = mtl::PipelineBuilder::buildPipeline(mtl::ShaderDef().color());
    mBatchStockColor = mtl::Batch::create(ci::geom::Rect(Rectf(-0.5,-0.5,0.5,0.5)), renderPipeline);
    
//    mtl::RenderPipelineStateRef sPipelineWire;
//    mtl::RenderPipelineStateRef getStockPipelineWire()
//    {
//        if ( !sPipelineWire )
//        {
//            sPipelineWire = mtl::RenderPipelineState::create("ci_wire_vertex", "ci_color_fragment",
//                                                             mtl::RenderPipelineState::Format()
//                                                             .blendingEnabled()
//                                                             );
//        }
//        return sPipelineWire;
//    }

}

void StockShaderApp::resize()
{
}

void StockShaderApp::update()
{
}

void StockShaderApp::draw()
{
    mtl::ScopedRenderCommandBuffer renderBuffer;
    mtl::ScopedRenderEncoder renderEncoder = renderBuffer.scopedRenderEncoder(mRenderDescriptor);
    
    mtl::setMatrices(mCam);
    // Put your drawing here
    
    mtl::color(1, 0, 0);
    renderEncoder.drawSolidRect(Rectf(-0.5,-0.5,0.5,0.5));
}

CINDER_APP( StockShaderApp, RendererMetal )
