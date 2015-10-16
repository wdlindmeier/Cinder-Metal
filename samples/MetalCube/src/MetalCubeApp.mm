#include "cinder/app/App.h"
#include "cinder/gl/gl.h"
#include "cinder/Camera.h"
#import <QuartzCore/CAMetalLayer.h>
#import <Metal/Metal.h>
#import <simd/simd.h>

// Cinder-Metal
#include "metal.h"
#include "RendererMetal.h"
// TODO: Remove
#include "MetalContext.h"

using namespace std;
using namespace ci;
using namespace ci::app;
using namespace cinder::mtl;

float cubeVertexData[216] =
{
    // Data layout for each line below is:
    // positionX, positionY, positionZ,     normalX, normalY, normalZ,
    0.5, -0.5, 0.5,   0.0, -1.0,  0.0,
    -0.5, -0.5, 0.5,   0.0, -1.0, 0.0,
    -0.5, -0.5, -0.5,   0.0, -1.0,  0.0,
    0.5, -0.5, -0.5,  0.0, -1.0,  0.0,
    0.5, -0.5, 0.5,   0.0, -1.0,  0.0,
    -0.5, -0.5, -0.5,   0.0, -1.0,  0.0,
    
    0.5, 0.5, 0.5,    1.0, 0.0,  0.0,
    0.5, -0.5, 0.5,   1.0,  0.0,  0.0,
    0.5, -0.5, -0.5,  1.0,  0.0,  0.0,
    0.5, 0.5, -0.5,   1.0, 0.0,  0.0,
    0.5, 0.5, 0.5,    1.0, 0.0,  0.0,
    0.5, -0.5, -0.5,  1.0,  0.0,  0.0,
    
    -0.5, 0.5, 0.5,    0.0, 1.0,  0.0,
    0.5, 0.5, 0.5,    0.0, 1.0,  0.0,
    0.5, 0.5, -0.5,   0.0, 1.0,  0.0,
    -0.5, 0.5, -0.5,   0.0, 1.0,  0.0,
    -0.5, 0.5, 0.5,    0.0, 1.0,  0.0,
    0.5, 0.5, -0.5,   0.0, 1.0,  0.0,
    
    -0.5, -0.5, 0.5,  -1.0,  0.0, 0.0,
    -0.5, 0.5, 0.5,   -1.0, 0.0,  0.0,
    -0.5, 0.5, -0.5,  -1.0, 0.0,  0.0,
    -0.5, -0.5, -0.5,  -1.0,  0.0,  0.0,
    -0.5, -0.5, 0.5,  -1.0,  0.0, 0.0,
    -0.5, 0.5, -0.5,  -1.0, 0.0,  0.0,
    
    0.5, 0.5,  0.5,  0.0, 0.0,  1.0,
    -0.5, 0.5,  0.5,  0.0, 0.0,  1.0,
    -0.5, -0.5, 0.5,   0.0,  0.0, 1.0,
    -0.5, -0.5, 0.5,   0.0,  0.0, 1.0,
    0.5, -0.5, 0.5,   0.0,  0.0,  1.0,
    0.5, 0.5,  0.5,  0.0, 0.0,  1.0,
    
    0.5, -0.5, -0.5,  0.0,  0.0, -1.0,
    -0.5, -0.5, -0.5,   0.0,  0.0, -1.0,
    -0.5, 0.5, -0.5,  0.0, 0.0, -1.0,
    0.5, 0.5, -0.5,  0.0, 0.0, -1.0,
    0.5, -0.5, -0.5,  0.0,  0.0, -1.0,
    -0.5, 0.5, -0.5,  0.0, 0.0, -1.0
};

typedef struct
{
    mat4 modelview_projection_matrix;
    mat4 normal_matrix;
} uniforms_t;

class MetalCubeApp : public App {
  public:
	void setup() override;
    void loadAssets();
    void resize() override;
	void update() override;
	void draw() override;
    
    void setupRenderPassDescriptorForTexture(id <MTLTexture> texture);

    RendererMetalRef mRenderer;
//    MetalRenderPassRef mRenderPass;
    
    id <MTLBuffer> _dynamicConstantBuffer;
    uint8_t _constantDataBufferIndex;
    
//    MTLRenderPassDescriptor *_renderPassDescriptor;
    id <MTLRenderPipelineState> _pipelineState;
    id <MTLBuffer> _vertexBuffer;
    id <MTLDepthStencilState> _depthState;
//    id <MTLTexture> _depthTex;
//    id <MTLTexture> _msaaTex;
    
    // uniforms
    uniforms_t _uniform_buffer;
    float _rotation;
    CameraPersp mCamera;

};

void MetalCubeApp::setup()
{
    console() << "Setup\n";
    mRenderer = std::dynamic_pointer_cast<RendererMetal>( this->getRenderer() );
    
    

    // TODO: How much of this should be in the app and how much in the renderer?
    _constantDataBufferIndex = 0;
//    _inflight_semaphore = dispatch_semaphore_create(g_max_inflight_buffers);

    loadAssets();
}

void MetalCubeApp::resize()
{
    mCamera = CameraPersp(getWindowWidth(), getWindowHeight(), 65.f, 0.1f, 100.f);
    mCamera.lookAt(vec3(0,0,-5), vec3(0));
}

void MetalCubeApp::loadAssets()
{
    // Allocate one region of memory for the uniform buffer

    // TODO: Abstract
    auto device = [MetalContext sharedContext].device;
    auto library = [MetalContext sharedContext].library;
    
    _dynamicConstantBuffer = [device newBufferWithLength:MAX_BYTES_PER_FRAME options:0];
    _dynamicConstantBuffer.label = @"UniformBuffer";
    
    // Load the fragment program into the library
    id <MTLFunction> fragmentProgram = [library newFunctionWithName:@"lighting_fragment"];
    
    // Load the vertex program into the library
    id <MTLFunction> vertexProgram = [library newFunctionWithName:@"lighting_vertex"];
    
    // Setup the vertex buffers
    _vertexBuffer = [device newBufferWithBytes:cubeVertexData length:sizeof(cubeVertexData) options:MTLResourceOptionCPUCacheModeDefault];
    _vertexBuffer.label = @"Vertices";
    
    // Create a reusable pipeline state
    MTLRenderPipelineDescriptor *pipelineStateDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
    pipelineStateDescriptor.label = @"MyPipeline";
    [pipelineStateDescriptor setSampleCount: 1];
    [pipelineStateDescriptor setVertexFunction:vertexProgram];
    [pipelineStateDescriptor setFragmentFunction:fragmentProgram];
    pipelineStateDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;
    pipelineStateDescriptor.depthAttachmentPixelFormat = MTLPixelFormatDepth32Float;
    
    NSError* error = NULL;
    _pipelineState = [device newRenderPipelineStateWithDescriptor:pipelineStateDescriptor error:&error];
    if (!_pipelineState) {
        NSLog(@"Failed to created pipeline state, error %@", error);
    }
    
    MTLDepthStencilDescriptor *depthStateDesc = [[MTLDepthStencilDescriptor alloc] init];
    depthStateDesc.depthCompareFunction = MTLCompareFunctionLess;
    depthStateDesc.depthWriteEnabled = YES;
    _depthState = [device newDepthStencilStateWithDescriptor:depthStateDesc];
}

//void MetalCubeApp::setupRenderPassDescriptorForTexture(id <MTLTexture> texture)
//{
//    // TODO: Abstract
//    auto device = [MetalContext sharedContext].device;
//
//    if (_renderPassDescriptor == nil)
//    {
//        _renderPassDescriptor = [MTLRenderPassDescriptor renderPassDescriptor];
//    }
//
//    _renderPassDescriptor.colorAttachments[0].texture = texture;
//    _renderPassDescriptor.colorAttachments[0].loadAction = MTLLoadActionClear;
//    _renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0.65f, 0.65f, 0.65f, 1.0f);
//    _renderPassDescriptor.colorAttachments[0].storeAction = MTLStoreActionStore;
//    
//    if (!_depthTex || (_depthTex && (_depthTex.width != texture.width || _depthTex.height != texture.height)))
//    {
//        //  If we need a depth texture and don't have one, or if the depth texture we have is the wrong size
//        //  Then allocate one of the proper size
//        
//        MTLTextureDescriptor* desc = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat: MTLPixelFormatDepth32Float width: texture.width height: texture.height mipmapped: NO];
//        _depthTex = [device newTextureWithDescriptor: desc];
//        _depthTex.label = @"Depth";
//        
//        _renderPassDescriptor.depthAttachment.texture = _depthTex;
//        _renderPassDescriptor.depthAttachment.loadAction = MTLLoadActionClear;
//        _renderPassDescriptor.depthAttachment.clearDepth = 1.0f;
//        _renderPassDescriptor.depthAttachment.storeAction = MTLStoreActionDontCare;
//    }
//}

void MetalCubeApp::update()
{
    mat4 modelMatrix = glm::rotate(_rotation, vec3(1.0f, 1.0f, 1.0f));
    mat4 normalMatrix = inverse(transpose(modelMatrix));
    mat4 modelViewMatrix = mCamera.getViewMatrix() * modelMatrix;
    mat4 modelViewProjectionMatrix = mCamera.getProjectionMatrix() * modelViewMatrix;

    _uniform_buffer.normal_matrix = normalMatrix;
    _uniform_buffer.modelview_projection_matrix = modelViewProjectionMatrix;

    assert(sizeof(mat4) == sizeof(matrix_float4x4));

    // Load constant buffer data into appropriate buffer at current index
    uint8_t *bufferPointer = (uint8_t *)[_dynamicConstantBuffer contents] + (sizeof(uniforms_t) * _constantDataBufferIndex);
    memcpy(bufferPointer, &_uniform_buffer, sizeof(uniforms_t));
    
    _rotation += 0.01f;
}

void MetalCubeApp::draw()
{
    // TODO: Make this more cinder-like
    [[MetalContext sharedContext] commandBufferDraw:^void( id <MTLRenderCommandEncoder> renderEncoder )
    {
        [renderEncoder setDepthStencilState:_depthState];
        
        // Set context state
        [renderEncoder pushDebugGroup:@"DrawCube"];
        [renderEncoder setRenderPipelineState:_pipelineState];
        [renderEncoder setVertexBuffer:_vertexBuffer offset:0 atIndex:0 ];
        [renderEncoder setVertexBuffer:_dynamicConstantBuffer offset:(sizeof(uniforms_t) * _constantDataBufferIndex) atIndex:1 ];
        
        // Tell the render context we want to draw our primitives
        [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:36 instanceCount:1];
        [renderEncoder popDebugGroup];
        
    }];
    
    _constantDataBufferIndex = (_constantDataBufferIndex + 1) % MAX_INFLIGHT_BUFFERS;

}

CINDER_APP( MetalCubeApp, RendererMetal )
