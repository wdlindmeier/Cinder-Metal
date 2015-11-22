#include "cinder/app/App.h"
#include "metal.h"

using namespace ci;
using namespace ci::app;
using namespace std;
using namespace cinder::mtl;

const static int kNumInflightBuffers = 3;

class MetalTemplateApp : public App
{
public:
    
    MetalTemplateApp() :
    mUniformBufferIndex(0)
    {}
    
    void setup() override;
    void resize() override;
    void update() override;
    void draw() override;
    
    ciUniforms_t mUniforms;
    DataBufferRef mUniformBuffer;
    uint8_t mUniformBufferIndex;
    
    RenderPassDescriptorRef mRenderDescriptor;
    
    CameraPersp mCamera;
};

void MetalTemplateApp::setup()
{
    mRenderDescriptor = RenderPassDescriptor::create();
    mUniformBuffer = DataBuffer::create( sizeof(ciUniforms_t) * kNumInflightBuffers,
                                         nullptr, "Uniform Buffer" );
}

void MetalTemplateApp::resize()
{
    mCamera = CameraPersp( getWindowWidth(), getWindowHeight(), 65.f, 0.1f, 100.f );
    mCamera.lookAt( vec3(0,0,-5), vec3(0) );
}

void MetalTemplateApp::update()
{
    mat4 modelMatrix(1.f);
    mat4 modelViewMatrix = mCamera.getViewMatrix() * modelMatrix;
    mat4 modelViewProjectionMatrix = mCamera.getProjectionMatrix() * modelViewMatrix;
    
    mUniforms.modelMatrix = toMtl( modelMatrix );
    mUniforms.modelViewProjectionMatrix = toMtl( modelViewProjectionMatrix );
    mUniforms.elapsedSeconds = getElapsedSeconds();
    mUniformBuffer->setData( &mUniforms, mUniformBufferIndex );
}

void MetalTemplateApp::draw()
{
    ScopedRenderBuffer renderBuffer;
    {
        ScopedRenderEncoder renderEncoder(renderBuffer(), mRenderDescriptor);
        
        // ...
    }
    mUniformBufferIndex = (mUniformBufferIndex + 1) % kNumInflightBuffers;
}

CINDER_APP( MetalTemplateApp, RendererMetal( RendererMetal::Options()
                                            .numInflightBuffers(kNumInflightBuffers) ) )
