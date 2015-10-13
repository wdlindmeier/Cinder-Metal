#include "cinder/app/App.h"
#include "cinder/gl/gl.h"
#include "cinder/Camera.h"
#import <QuartzCore/CAMetalLayer.h>
#import <Metal/Metal.h>
#import <simd/simd.h>

// Cinder-Metal
#include "RendererMetal.h"

using namespace ci;
using namespace ci::app;
using namespace std;

template <typename T, typename U>
static void matData( const T & glmType, U * data, const int dimensions )
{
    for ( int col = 0; col < dimensions; ++col )
    {
        //        auto column = glmType[col];
        for ( int row = 0; row < dimensions; ++row )
        {
            U v = glmType[col][row];//column[row];
            int i = col * dimensions + row;
            data[i] = v;
        }
    }
}

// The max number of command buffers in flight
static const NSUInteger g_max_inflight_buffers = 3;

// Max API memory buffer size.
static const size_t MAX_BYTES_PER_FRAME = 1024*1024;

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
//    matrix_float4x4 modelview_projection_matrix;
//    matrix_float4x4 normal_matrix;
    mat4 modelview_projection_matrix;
    mat4 normal_matrix;
//    float modelview_projection_matrix[16];
//    float normal_matrix[16];
} uniforms_t;

#pragma mark Utilities

// TODO: Replace with glm stuff

static matrix_float4x4 matrix_from_perspective_fov_aspectLH(const float fovY, const float aspect, const float nearZ, const float farZ)
{
    float yscale = 1.0f / tanf(fovY * 0.5f); // 1 / tan == cot
    float xscale = yscale / aspect;
    float q = farZ / (farZ - nearZ);
    
    matrix_float4x4 m = {
        .columns[0] = { xscale, 0.0f, 0.0f, 0.0f },
        .columns[1] = { 0.0f, yscale, 0.0f, 0.0f },
        .columns[2] = { 0.0f, 0.0f, q, 1.0f },
        .columns[3] = { 0.0f, 0.0f, q * -nearZ, 0.0f }
    };
    
    return m;
}

static matrix_float4x4 matrix_from_translation(float x, float y, float z)
{
    matrix_float4x4 m = matrix_identity_float4x4;
    m.columns[3] = (vector_float4) { x, y, z, 1.0 };
    return m;
}

static matrix_float4x4 matrix_from_rotation(float radians, float x, float y, float z)
{
    vector_float3 v = vector_normalize(((vector_float3){x, y, z}));
    float cos = cosf(radians);
    float cosp = 1.0f - cos;
    float sin = sinf(radians);
    
    matrix_float4x4 m = {
        .columns[0] = {
            cos + cosp * v.x * v.x,
            cosp * v.x * v.y + v.z * sin,
            cosp * v.x * v.z - v.y * sin,
            0.0f,
        },
        
        .columns[1] = {
            cosp * v.x * v.y - v.z * sin,
            cos + cosp * v.y * v.y,
            cosp * v.y * v.z + v.x * sin,
            0.0f,
        },
        
        .columns[2] = {
            cosp * v.x * v.z + v.y * sin,
            cosp * v.y * v.z - v.x * sin,
            cos + cosp * v.z * v.z,
            0.0f,
        },
        
        .columns[3] = { 0.0f, 0.0f, 0.0f, 1.0f
        }
    };
    return m;
}


class MetalCubeApp : public App {
  public:
	void setup() override;
    void loadAssets();
    void resize() override;
	void update() override;
	void draw() override;
    
    void setupRenderPassDescriptorForTexture(id <MTLTexture> texture);

    RendererMetalRef mRenderer;
    
    dispatch_semaphore_t _inflight_semaphore;
    id <MTLBuffer> _dynamicConstantBuffer;
    uint8_t _constantDataBufferIndex;
    
    // renderer
    id <MTLDevice> _device;
    MTLRenderPassDescriptor *_renderPassDescriptor;
    id <MTLCommandQueue> _commandQueue;
    id <MTLLibrary> _defaultLibrary;
    id <MTLRenderPipelineState> _pipelineState;
    id <MTLBuffer> _vertexBuffer;
    id <MTLDepthStencilState> _depthState;
    id <MTLTexture> _depthTex;
    id <MTLTexture> _msaaTex;
    
    // uniforms
    matrix_float4x4 _projectionMatrix_;
    mat4 _projectionMatrix;
//    matrix_float4x4 _viewMatrix;
    mat4 _viewMatrix;
    uniforms_t _uniform_buffer;
    float _rotation;
    
    CameraPersp mCamera;

};

void MetalCubeApp::setup()
{
    console() << "Setup\n";
    mRenderer = std::dynamic_pointer_cast<RendererMetal>( this->getRenderer() );
    
    _device = mRenderer->getDevice();
    _defaultLibrary = [_device newDefaultLibrary];

    // TODO: How much of this should be in the app and how much in the renderer?
    _constantDataBufferIndex = 0;
    _inflight_semaphore = dispatch_semaphore_create(g_max_inflight_buffers);
    
    _commandQueue = [_device newCommandQueue];

    loadAssets();
}

//void MetalCubeApp::resize()
//{
//    
//}
//
//void MetalCubeApp::update()
//{
//    console() << "Update\n";
//}
//
//void MetalCubeApp::draw()
//{
//    console() << "Draw\n";
//}

void MetalCubeApp::resize()
{
    // When reshape is called, update the view and projection matricies since this means the view orientation or size changed
//    _projectionMatrix = glm::perspective(toRadians(65.0f),
//                                         getWindowAspectRatio(),
//                                         -0.1f,
//                                         -100.f);
    
    _projectionMatrix_ = matrix_from_perspective_fov_aspectLH(65.0f * (M_PI / 180.0f),
                                                             getWindowAspectRatio(),
                                                             0.1f,
                                                             100.0f);
    
    mCamera = CameraPersp(getWindowWidth(), getWindowHeight(), 65.f, 0.1f, 100.f);
    mCamera.lookAt(vec3(0,0,-5), vec3(0));
    
    _projectionMatrix = mat4(_projectionMatrix_.columns[0][0],
                             _projectionMatrix_.columns[0][1],
                             _projectionMatrix_.columns[0][2],
                             _projectionMatrix_.columns[0][3],
                             _projectionMatrix_.columns[1][0],
                             _projectionMatrix_.columns[1][1],
                             _projectionMatrix_.columns[1][2],
                             _projectionMatrix_.columns[1][3],
                             _projectionMatrix_.columns[2][0],
                             _projectionMatrix_.columns[2][1],
                             _projectionMatrix_.columns[2][2],
                             _projectionMatrix_.columns[2][3],
                             _projectionMatrix_.columns[3][0],
                             _projectionMatrix_.columns[3][1],
                             _projectionMatrix_.columns[3][2],
                             _projectionMatrix_.columns[3][3]);
                             
    
//    _viewMatrix = matrix_identity_float4x4;
    _viewMatrix = mat4();
}

void MetalCubeApp::loadAssets()
{
    // Allocate one region of memory for the uniform buffer
    _dynamicConstantBuffer = [_device newBufferWithLength:MAX_BYTES_PER_FRAME options:0];
    _dynamicConstantBuffer.label = @"UniformBuffer";
    
    // Load the fragment program into the library
    id <MTLFunction> fragmentProgram = [_defaultLibrary newFunctionWithName:@"lighting_fragment"];
    
    // Load the vertex program into the library
    id <MTLFunction> vertexProgram = [_defaultLibrary newFunctionWithName:@"lighting_vertex"];
    
    // Setup the vertex buffers
    _vertexBuffer = [_device newBufferWithBytes:cubeVertexData length:sizeof(cubeVertexData) options:MTLResourceOptionCPUCacheModeDefault];
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
    _pipelineState = [_device newRenderPipelineStateWithDescriptor:pipelineStateDescriptor error:&error];
    if (!_pipelineState) {
        NSLog(@"Failed to created pipeline state, error %@", error);
    }
    
    MTLDepthStencilDescriptor *depthStateDesc = [[MTLDepthStencilDescriptor alloc] init];
    depthStateDesc.depthCompareFunction = MTLCompareFunctionLess;
    depthStateDesc.depthWriteEnabled = YES;
    _depthState = [_device newDepthStencilStateWithDescriptor:depthStateDesc];
}

void MetalCubeApp::setupRenderPassDescriptorForTexture(id <MTLTexture> texture)
{
    if (_renderPassDescriptor == nil)
    {
        _renderPassDescriptor = [MTLRenderPassDescriptor renderPassDescriptor];
    }
    
//    assert(_renderPassDescriptor != nil);
//    NSLog(@"_renderPassDescriptor.colorAttachments: %@", _renderPassDescriptor);
    _renderPassDescriptor.colorAttachments[0].texture = texture;
    _renderPassDescriptor.colorAttachments[0].loadAction = MTLLoadActionClear;
    _renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0.65f, 0.65f, 0.65f, 1.0f);
    _renderPassDescriptor.colorAttachments[0].storeAction = MTLStoreActionStore;
    
    if (!_depthTex || (_depthTex && (_depthTex.width != texture.width || _depthTex.height != texture.height)))
    {
        //  If we need a depth texture and don't have one, or if the depth texture we have is the wrong size
        //  Then allocate one of the proper size
        
        MTLTextureDescriptor* desc = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat: MTLPixelFormatDepth32Float width: texture.width height: texture.height mipmapped: NO];
        _depthTex = [_device newTextureWithDescriptor: desc];
        _depthTex.label = @"Depth";
        
        _renderPassDescriptor.depthAttachment.texture = _depthTex;
        _renderPassDescriptor.depthAttachment.loadAction = MTLLoadActionClear;
        _renderPassDescriptor.depthAttachment.clearDepth = 1.0f;
        _renderPassDescriptor.depthAttachment.storeAction = MTLStoreActionDontCare;
    }
}
//


void MetalCubeApp::update()
{
    console() << "UPDATE 0\n";
    
//    @autoreleasepool {
    {
        // TODO: REFACTOR
        // We're releasing this semaphore at the end of draw.
        // It's not obvious that update and draw follow each other (and this might change).
        // TODO: Cinderize this (we could use a block, or bind, or...)
        
        dispatch_semaphore_wait(_inflight_semaphore, DISPATCH_TIME_FOREVER);
        
        console() << "UPDATE 1\n";
        
        matrix_float4x4 base_model_ = matrix_multiply(matrix_from_translation(0.0f, 0.0f, 5.0f), matrix_from_rotation(_rotation, 0.0f, 1.0f, 0.0f));
        matrix_float4x4 base_mv_ = matrix_multiply(matrix_identity_float4x4, base_model_);
        matrix_float4x4 modelViewMatrix_ = matrix_multiply(base_mv_, matrix_from_rotation(_rotation, 1.0f, 1.0f, 1.0f));
    
        matrix_float4x4 modelInvTrans_ = matrix_invert(matrix_transpose(modelViewMatrix_));
        matrix_float4x4 mvp_ = matrix_multiply(_projectionMatrix_, modelViewMatrix_);
    
//        _uniform_buffer.normal_matrix = matrix_invert(matrix_transpose(modelViewMatrix));
//        _uniform_buffer.modelview_projection_matrix = matrix_multiply(_projectionMatrix, modelViewMatrix);

        mat4 rotMat = glm::rotate(_rotation, vec3(0.0f, 1.0f, 0.0f));
//        mat4 transMat = glm::translate(vec3(0.0f, 0.0f, 5.0f));
//        mat4 base_model = transMat * rotMat;
        mat4 base_mv = _viewMatrix * rotMat;
        mat4 modelViewMatrix = base_mv * rotate(_rotation, vec3(1.f, 1.f, 1.f));
    
//        float stuff[16];
        mat4 invmvm = inverse(transpose(modelViewMatrix));
//        matData(invmvm, stuff, 4);
//    
//        // Copy the values to the buffer
//        memcpy(&_uniform_buffer.normal_matrix,
//               //glm::value_ptr(inverse(transpose(modelViewMatrix))),
//               //&modelInvTrans_.columns[0],
//               &stuff,
//               sizeof(float) * 16);
//    
//        mat4 mvpm = _projectionMatrix * modelViewMatrix;
        mat4 mvpm = mCamera.getProjectionMatrix() * mCamera.getViewMatrix() * modelViewMatrix;
        
//        matData(mvpm, stuff, 4);
//
//        memcpy(&_uniform_buffer.modelview_projection_matrix,
//               //glm::value_ptr(_projectionMatrix * modelViewMatrix),
//               //&mvp_.columns[0],
//               &stuff,
//               sizeof(float) * 16);
    
//        _uniform_buffer.normal_matrix = *glm::value_ptr(inverse(transpose(modelViewMatrix)));
//        _uniform_buffer.modelview_projection_matrix = *glm::value_ptr(_projectionMatrix * modelViewMatrix);
    
        _uniform_buffer.normal_matrix = invmvm;
        _uniform_buffer.modelview_projection_matrix = mvpm;

        assert(sizeof(mat4) == sizeof(matrix_float4x4));
    
        //mat4 base_model = matrix_multiply(matrix_from_translation(0.0f, 0.0f, 5.0f), matrix_from_rotation(_rotation, 0.0f, 1.0f, 0.0f));
        //mat4 base_mv = matrix_multiply(_viewMatrix, base_model);
        //mat4 modelViewMatrix = matrix_multiply(base_mv, matrix_from_rotation(_rotation, 1.0f, 1.0f, 1.0f));
        //_uniform_buffer.normal_matrix = matrix_invert(matrix_transpose(modelViewMatrix));
        // _uniform_buffer.modelview_projection_matrix = matrix_multiply(_projectionMatrix, modelViewMatrix);

        // Load constant buffer data into appropriate buffer at current index
        uint8_t *bufferPointer = (uint8_t *)[_dynamicConstantBuffer contents] + (sizeof(uniforms_t) * _constantDataBufferIndex);
        memcpy(bufferPointer, &_uniform_buffer, sizeof(uniforms_t));
        
        _rotation += 0.01f;
        
        
//        render();
    }
}


void MetalCubeApp::draw()
{
//}
//
//void MetalCubeApp::render()
//{
    console() << "DRAW\n";
    
    // Create a new command buffer for each renderpass to the current drawable
    id <MTLCommandBuffer> commandBuffer = [_commandQueue commandBuffer];
    commandBuffer.label = @"MyCommand"; // TODO: Don't use NSStrings
    
    // obtain a drawable texture for this render pass and set up the renderpass descriptor for the command encoder to render into
    id <CAMetalDrawable> drawable = [mRenderer->getLayer() nextDrawable];
    assert( drawable != nil );
    setupRenderPassDescriptorForTexture(drawable.texture);
    
    // Create a render command encoder so we can render into something
    id <MTLRenderCommandEncoder> renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:_renderPassDescriptor];
    renderEncoder.label = @"MyRenderEncoder";
    [renderEncoder setDepthStencilState:_depthState];
    
    // Set context state
    [renderEncoder pushDebugGroup:@"DrawCube"];
    [renderEncoder setRenderPipelineState:_pipelineState];
    [renderEncoder setVertexBuffer:_vertexBuffer offset:0 atIndex:0 ];
    [renderEncoder setVertexBuffer:_dynamicConstantBuffer offset:(sizeof(uniforms_t) * _constantDataBufferIndex) atIndex:1 ];
    
    // Tell the render context we want to draw our primitives
    [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:36 instanceCount:1];
    [renderEncoder popDebugGroup];
    
    // We're done encoding commands
    [renderEncoder endEncoding];
    
    // Call the view's completion handler which is required by the view since it will signal its semaphore and set up the next buffer
    __block dispatch_semaphore_t block_sema = _inflight_semaphore;
    [commandBuffer addCompletedHandler:^(id<MTLCommandBuffer> buffer) {
        console() << "DRAW COMPLETE\n";
        dispatch_semaphore_signal(block_sema);
     }];
    
    // The renderview assumes it can now increment the buffer index and that the previous index won't be touched until we cycle back around to the same index
    _constantDataBufferIndex = (_constantDataBufferIndex + 1) % g_max_inflight_buffers;
    
    // Schedule a present once the framebuffer is complete
    [commandBuffer presentDrawable:drawable];
    
    // Finalize rendering here & push the command buffer to the GPU
    [commandBuffer commit];
}



CINDER_APP( MetalCubeApp, RendererMetal )
