//
//  Scope.cpp
//  MetalCube
//
//  Created by William Lindmeier on 11/4/15.
//
//

#include "Scope.h"
#include "RendererMetalImpl.h"
#include "RenderFormat.h"
#include "RenderFormatImpl.h"
#include "ComputeEncoder.h"
#include "BlitEncoder.h"

using namespace cinder;
using namespace cinder::mtl;

ScopedCommandBuffer::ScopedCommandBuffer( const std::string & bufferName )
{
    RendererMetalImpl *renderer = [RendererMetalImpl sharedRenderer];
    // instantiate a command buffer
    id <MTLCommandBuffer> commandBuffer = [renderer.commandQueue commandBuffer];
    commandBuffer.label = (__bridge NSString *)cocoa::createCfString(bufferName);
    id <CAMetalDrawable> drawable = [renderer.metalLayer nextDrawable];
    mInstance = CommandBuffer::create((__bridge void *)commandBuffer,
                                      (__bridge void *)drawable);
    
};

ScopedCommandBuffer::~ScopedCommandBuffer()
{
    RendererMetalImpl *renderer = [RendererMetalImpl sharedRenderer];
    // clean up the command buffer
    __block dispatch_semaphore_t block_sema = [renderer inflightSemaphore];
    id <MTLCommandBuffer> commandBuffer = (__bridge id<MTLCommandBuffer>)mInstance->mCommandBuffer;
    id <MTLDrawable> drawable = (__bridge id<MTLDrawable>)mInstance->mDrawable;
    [commandBuffer addCompletedHandler:^(id<MTLCommandBuffer> buffer)
     {
        dispatch_semaphore_signal(block_sema);
    }];    
    [commandBuffer presentDrawable:drawable];
    // Finalize rendering here & push the command buffer to the GPU
    [commandBuffer commit];
};

ScopedRenderEncoder::ScopedRenderEncoder( CommandBufferRef commandBuffer,
                                          const RenderFormatRef format,
                                          const std::string & encoderName )
{
    id <MTLCommandBuffer> mtlCommandBuffer = (__bridge id<MTLCommandBuffer>)commandBuffer->mCommandBuffer;
    id <CAMetalDrawable> drawable = (__bridge id<CAMetalDrawable>)commandBuffer->mDrawable;
    // NOTE: We have to prepare the render description before getting the encoder
    [format->mImpl prepareForRenderToTexture:drawable.texture];
    
    id <MTLRenderCommandEncoder> renderEncoder = [mtlCommandBuffer renderCommandEncoderWithDescriptor:format->mImpl.renderPassDescriptor];
    renderEncoder.label = (__bridge NSString *)cocoa::createCfString(encoderName);

    mInstance = RenderEncoder::create((__bridge void *)renderEncoder);
}

ScopedRenderEncoder::~ScopedRenderEncoder()
{
    [(__bridge id<MTLRenderCommandEncoder>)mInstance->mImpl endEncoding];
}

ScopedComputeEncoder::ScopedComputeEncoder( CommandBufferRef commandBuffer,
                                            const std::string & encoderName )
{
    id <MTLCommandBuffer> mtlCommandBuffer = (__bridge id<MTLCommandBuffer>)commandBuffer->mCommandBuffer;
    id <MTLComputeCommandEncoder> computeEncoder = [mtlCommandBuffer computeCommandEncoder];
    computeEncoder.label = (__bridge NSString *)cocoa::createCfString(encoderName);
    mInstance = ComputeEncoder::create((__bridge void *)computeEncoder);
}

ScopedComputeEncoder::~ScopedComputeEncoder()
{
    [(__bridge id<MTLComputeCommandEncoder>)mInstance->mImpl endEncoding];
}


ScopedBlitEncoder::ScopedBlitEncoder( CommandBufferRef commandBuffer,
                                      const std::string & encoderName )
{
    id <MTLCommandBuffer> mtlCommandBuffer = (__bridge id<MTLCommandBuffer>)commandBuffer->mCommandBuffer;
    id <MTLBlitCommandEncoder> blitEncoder = [mtlCommandBuffer blitCommandEncoder];
    blitEncoder.label = (__bridge NSString *)cocoa::createCfString(encoderName);
    mInstance = BlitEncoder::create((__bridge void *)blitEncoder);
}

ScopedBlitEncoder::~ScopedBlitEncoder()
{
    [(__bridge id<MTLBlitCommandEncoder>)mInstance->mImpl endEncoding];
}