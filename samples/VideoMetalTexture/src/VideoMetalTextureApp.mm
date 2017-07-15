#include "cinder/app/App.h"
#include "metal.h"
#include "Batch.h"
#import "MovieMetal.h"

using namespace ci;
using namespace ci::app;
using namespace std;

class VideoMetalTextureApp : public App
{
public:
    
    void setup() override;
    void resize() override;
    void update() override;
    void draw() override;
    
    mtl::RenderPassDescriptorRef mRenderDescriptor;
    mtl::MovieMetalRef mMovieMetal;
    mtl::RenderPipelineStateRef mPipelineVideo;
    mtl::BatchRef mBatchVideo;
};

void VideoMetalTextureApp::setup()
{
    mPipelineVideo = mtl::RenderPipelineState::create("camera_vertex", "camera_fragment");
    mBatchVideo = mtl::Batch::create(geom::Rect(Rectf(-1,-1,1,1)).texCoords( vec2(0,1),
                                                                             vec2(1,1),
                                                                             vec2(1,0),
                                                                             vec2(0,0)),
                                      mPipelineVideo);
    
    mRenderDescriptor = mtl::RenderPassDescriptor::create();
    
    const fs::path moviePath = getAssetPath("IMG_4529.MP4");
    assert( fs::exists(moviePath) );
    mMovieMetal = mtl::MovieMetal::create(moviePath);
    mMovieMetal->play();
}

void VideoMetalTextureApp::resize()
{
}

void VideoMetalTextureApp::update()
{
}

void VideoMetalTextureApp::draw()
{
    mtl::ScopedRenderCommandBuffer renderBuffer;
    mtl::ScopedRenderEncoder renderEncoder = renderBuffer.scopedRenderEncoder(mRenderDescriptor);
    
    mtl::TextureBufferRef & luma = mMovieMetal->getTextureLuma();
    mtl::TextureBufferRef & chroma = mMovieMetal->getTextureChroma();
    if ( luma && chroma )
    {
        renderEncoder.setTexture(luma, mtl::ciTextureIndex0);
        renderEncoder.setTexture(chroma, mtl::ciTextureIndex1);
        renderEncoder.draw(mBatchVideo);
    }
}

CINDER_APP( VideoMetalTextureApp, RendererMetal )
