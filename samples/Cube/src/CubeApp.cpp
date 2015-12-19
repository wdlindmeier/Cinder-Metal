#include "cinder/app/App.h"
#include "metal.h"
#include "VertexBuffer.h"

using namespace ci;
using namespace ci::app;
using namespace std;

class CubeApp : public App
{
public:
    
    void setup() override;
    void resize() override;
    void update() override;
    void draw() override;
    
    CameraPersp                     mCam;
    mat4                            mCubeRotation;

    mtl::ciUniforms_t               mUniforms;

    mtl::RenderPassDescriptorRef    mRenderDescriptor;
    mtl::VertexBufferRef            mCube;
    mtl::TextureBufferRef           mTexture;
    mtl::RenderPipelineStateRef     mPipeline;
    mtl::DataBufferRef              mDynamicConstantBuffer;
    mtl::DepthStateRef              mDepthEnabled;
    
};

void CubeApp::setup()
{
    mRenderDescriptor = mtl::RenderPassDescriptor::create();

    mCam.lookAt( vec3( 3, 2, 4 ), vec3( 0 ) );

    mDynamicConstantBuffer = mtl::DataBuffer::create(mtlConstantSizeOf(mtl::ciUniforms_t),
                                                     nullptr,
                                                     mtl::DataBuffer::Format().label("Uniform Buffer").isConstant());
    
    mTexture = mtl::TextureBuffer::create( loadImage(getAssetPath("texture.jpg") ),
                                           mtl::TextureBuffer::Format().mipmapLevel(3).flipVertically() );

    mDepthEnabled = mtl::DepthState::create( mtl::DepthState::Format().depthWriteEnabled() );
    
    mPipeline = mtl::RenderPipelineState::create("cube_vertex", "cube_fragment");
    
    mCube = mtl::VertexBuffer::create(geom::Cube(), {{ ci::geom::POSITION,
                                                       ci::geom::NORMAL,
                                                       ci::geom::TEX_COORD_0 }});
}

void CubeApp::resize()
{
    mCam.setPerspective( 60, getWindowAspectRatio(), 1, 1000 );
}

void CubeApp::update()
{
    // Rotate the cube by 0.2 degrees around the y-axis
    mCubeRotation *= rotate( toRadians( 0.2f ), normalize( vec3( 0, 1, 0 ) ) );
    
    // Create the matrices
    mat4 modelMatrix = mCubeRotation;
    mat4 normalMatrix = inverse(transpose(modelMatrix));
    mat4 modelViewMatrix = mCam.getViewMatrix() * modelMatrix;
    mat4 modelViewProjectionMatrix = mCam.getProjectionMatrix() * modelViewMatrix;
    
    // Pass the matrices into the uniform block
    mUniforms.normalMatrix = toMtl(normalMatrix);
    mUniforms.modelViewProjectionMatrix = toMtl(modelViewProjectionMatrix);
    
    mDynamicConstantBuffer->setDataAtIndex(&mUniforms, 0);
}

void CubeApp::draw()
{
    mtl::ScopedRenderCommandBuffer renderBuffer;
    mtl::ScopedRenderEncoder renderEncoder = renderBuffer.scopedRenderEncoder(mRenderDescriptor);

    renderEncoder.setDepthStencilState(mDepthEnabled);

    renderEncoder.setPipelineState(mPipeline);
    
    renderEncoder.setUniforms(mDynamicConstantBuffer);
    
    renderEncoder.setTexture(mTexture);
    
    mCube->draw(renderEncoder);
}

CINDER_APP( CubeApp, RendererMetal( RendererMetal::Options().numInflightBuffers(1) ) )
