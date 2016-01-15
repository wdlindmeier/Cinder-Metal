#include "cinder/app/App.h"
#include "metal.h"
#include "SharedTypes.h"
#include "Batch.h"

using namespace ci;
using namespace ci::app;
using namespace std;

class BatchApp : public App
{
public:
    
    void setup() override;
    void resize() override;
    void update() override;
    void draw() override;
    
    float mRotation;
    
    mtl::RenderPassDescriptorRef mRenderDescriptor;
    mtl::UniformBlock<mtl::ciUniforms_t> mUniformBlock;
    
    mtl::RenderPipelineStateRef mPipeline;
    mtl::BatchRef mBatchCube;
    
    mtl::DepthStateRef mDepthEnabled;
    mtl::DepthStateRef mDepthDisabled;
    
    mtl::TextureBufferRef mTexture;
    
    CameraPersp mCamera;
};

void BatchApp::setup()
{
    mRenderDescriptor = mtl::RenderPassDescriptor::create(mtl::RenderPassDescriptor::Format()
                                                          .clearColor(ColorAf(0.f,1.f,1.f)));
    
    // mGeomBufferCube = mtl::VertexBuffer::create(ci::geom::Cube(), cubeLayout, mtl::DataBuffer::Format().label("Geom Cube"));
    
    mPipeline = mtl::RenderPipelineState::create("lighting_vertex_interleaved_src",
                                                 "lighting_texture_fragment");
    
    mTexture = mtl::TextureBuffer::create(loadImage(getAssetPath("checker.png")),
                                          mtl::TextureBuffer::Format().mipmapLevel(4));

    mBatchCube = mtl::Batch::create(geom::Cube(), mPipeline);
    
    mDepthEnabled = mtl::DepthState::create(mtl::DepthState::Format().depthWriteEnabled());
    mDepthDisabled = mtl::DepthState::create(mtl::DepthState::Format()
                                             .depthWriteEnabled(false)
//                                             .depthCompareFunction(mtl::CompareFunctionNever)
                                             );

}

void BatchApp::resize()
{
    mCamera.setPerspective(65.f, getWindowAspectRatio(), 0.01, 1000.f);
    mCamera.lookAt(vec3(0,0,-5),vec3(0));
}

void BatchApp::update()
{
    mRotation += 0.01f;
    mat4 modelMatrix = glm::rotate( mRotation, vec3(1.0f, 1.0f, 1.0f) );
    mat4 normalMatrix = inverse(transpose(modelMatrix));
    mat4 modelViewMatrix = mCamera.getViewMatrix() * modelMatrix;
    mat4 modelViewProjectionMatrix = mCamera.getProjectionMatrix() * modelViewMatrix;

    mUniformBlock.updateData( [&]( mtl::ciUniforms_t data )
    {
        data.ciModelMatrix = toMtl(modelMatrix);
        data.ciNormalMatrix = toMtl(normalMatrix);
        data.ciProjectionMatrix = toMtl(mCamera.getProjectionMatrix());
        data.ciModelViewProjectionMatrix = toMtl(modelViewProjectionMatrix);
        return data;
    });

    // TEST
//    mtl::BatchRef batch = mtl::Batch::create(geom::Cube(), mPipeline);
}

void BatchApp::draw()
{
    mtl::ScopedRenderCommandBuffer renderBuffer;
    mtl::ScopedRenderEncoder renderEncoder = renderBuffer.scopedRenderEncoder(mRenderDescriptor);
    
    renderEncoder.setDepthStencilState(mDepthEnabled);
    
    mUniformBlock.sendToEncoder(renderEncoder);
    
    renderEncoder.setTexture(mTexture);
    
    // Put your drawing here
    mBatchCube->draw(renderEncoder);
    
    // TEST
    
// << START CONTEXT BLOCK
    
    renderEncoder.setDepthStencilState(mDepthDisabled);
    
    mat4 modelMatrix = glm::translate(mat4(1), vec3(2,0,0));
    modelMatrix = glm::rotate(modelMatrix, -mRotation, vec3(1.0f, 1.0f, 1.0f));
    
    mat4 normalMatrix = inverse(transpose(modelMatrix));
    mat4 modelViewMatrix = mCamera.getViewMatrix() * modelMatrix;
    mat4 modelViewProjectionMatrix = mCamera.getProjectionMatrix() * modelViewMatrix;
    
    mUniformBlock.updateData( [&]( mtl::ciUniforms_t data )
                             {
                                 data.ciModelMatrix = toMtl(modelMatrix);
                                 data.ciNormalMatrix = toMtl(normalMatrix);
                                 // data.ciProjectionMatrix = toMtl(mCamera.getProjectionMatrix());
                                 data.ciModelViewProjectionMatrix = toMtl(modelViewProjectionMatrix);
                                 return data;
                             });
    mUniformBlock.sendToEncoder(renderEncoder);
    
// << END CONTEXT BLOCK
    
    mBatchCube->draw(renderEncoder);
}

CINDER_APP( BatchApp, RendererMetal )
