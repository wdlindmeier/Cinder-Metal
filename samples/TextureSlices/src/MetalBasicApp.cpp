#include "cinder/app/App.h"
#include "cinder/CameraUi.h"
#include "metal.h"
#include "Batch.h"
#include "Draw.h"
#include "SharedTypes.h"
#include "ImageHelpers.h"

using namespace ci;
using namespace ci::app;
using namespace std;

const static int kNumImages = 4;

class MetalBasicApp : public App
{
public:
    
    void setup() override;
    void resize() override;
    void update() override;
    void draw() override;
    
    mtl::RenderPassDescriptorRef mRenderDescriptor;
    mtl::TextureBufferRef mTextureArray;
    
    mtl::DataBufferRef mInstanceData;
    
    CameraPersp mCam;
    CameraUi mCamUi;
};

void MetalBasicApp::setup()
{
    mCamUi = CameraUi(&mCam, getWindow(), -1);

    mRenderDescriptor = mtl::RenderPassDescriptor::create();

    // Load our images
    vector<ImageSourceRef> images;
    for ( int i = 0; i < kNumImages; ++i )
    {
        images.push_back(loadImage(loadAsset("cinderblock_" + to_string(i) + ".png")));
    }

    // Create the format
    mtl::TextureBuffer::Format arrayFormat;
    arrayFormat.setTextureType(mtl::TextureType2DArray);
    arrayFormat.setArrayLength(kNumImages);
    // Get the pixel format from the image source
    ImageIo::ChannelOrder channelOrder = images[0]->getChannelOrder();
    arrayFormat.setPixelFormat(mtl::pixelFormatFromChannelOrder(channelOrder, images[0]->getDataType()));

    // Create the texture
    mTextureArray = mtl::TextureBuffer::create( images[0]->getWidth(),
                                                images[0]->getHeight(),
                                                arrayFormat );
    
    // Send in the slices from our images
    for ( int i = 0; i < kNumImages; ++i )
    {
        mTextureArray->update(images[i], i);
    }

    // Create instance infos
    vector<mtl::Instance> instances;
    for ( int i = 0; i < kNumImages; ++i )
    {
        mtl::Instance instance;
        vec3 pos(i - ((kNumImages / 2) - 0.5f), 0, 0);
        instance.modelMatrix = toMtl(glm::translate(mat4(1), pos));
        // Define which slice to draw from
        instance.textureSlice = i;
        // Add a little color for each instance
        instance.color = toMtl(ColorAf(CM_HSV, float(i)/kNumImages, 1, 1));
        instances.push_back(instance);
    }
    mInstanceData = mtl::DataBuffer::create(instances);
}

void MetalBasicApp::resize()
{
    mCam.setPerspective(40, getWindowAspectRatio(), 0.01, 10000);
    mCam.lookAt(vec3(0, 0, 5.f),
                vec3(0, 0, 0));
}

void MetalBasicApp::update()
{
}

void MetalBasicApp::draw()
{
    mtl::ScopedRenderCommandBuffer renderBuffer;
    mtl::ScopedRenderEncoder renderEncoder = renderBuffer.scopedRenderEncoder(mRenderDescriptor);

    mtl::setMatrices(mCam);
    
    mtl::color(1,1,1);
    renderEncoder.draw(mTextureArray, Rectf(-0.5,-0.5,0.5,0.5), mInstanceData, kNumImages);
}

CINDER_APP( MetalBasicApp, RendererMetal, [](MetalBasicApp::Settings *settings)
{
    settings->setWindowSize(800, 600);
});
