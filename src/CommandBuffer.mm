//
//  CommandBuffer.cpp
//  MetalCube
//
//  Created by William Lindmeier on 10/17/15.
//
//

#include "CommandBuffer.h"
#include "RendererMetalImpl.h"
#import <QuartzCore/CAMetalLayer.h>

using namespace ci;
using namespace ci::mtl;

#define CMD_BUFFER ((__bridge id <MTLCommandBuffer>)mCommandBuffer)
#define DRAWABLE ((__bridge id <CAMetalDrawable>)mDrawable)

CommandBufferRef CommandBuffer::createForRenderLoop( const std::string & bufferName )
{
    RendererMetalImpl *renderer = [RendererMetalImpl sharedRenderer];
    // instantiate a command buffer
    id <MTLCommandBuffer> commandBuffer = [renderer.commandQueue commandBuffer];
    commandBuffer.label = (__bridge NSString *)cocoa::createCfString(bufferName);
    id <CAMetalDrawable> drawable = [renderer.metalLayer nextDrawable];
    return CommandBufferRef( new CommandBuffer( (__bridge void *)commandBuffer,
                                                (__bridge void *)drawable ) );
}

CommandBuffer::CommandBuffer( void * mtlCommandBuffer, void * mtlDrawable )
:
mCommandBuffer(mtlCommandBuffer)
,mDrawable(mtlDrawable)
{
     // <MTLCommandBuffer>
    assert( mtlCommandBuffer != NULL );
    assert( [(__bridge id)mtlCommandBuffer conformsToProtocol:@protocol(MTLCommandBuffer)] );
    CFRetain(mCommandBuffer);
    assert( mtlDrawable != NULL );
    assert( [(__bridge id)mtlDrawable conformsToProtocol:@protocol(CAMetalDrawable)] );
}

CommandBuffer::~CommandBuffer()
{
    CFRelease(mCommandBuffer);
}

RenderEncoderRef CommandBuffer::createRenderEncoderWithDescriptor( RenderPassDescriptorRef descriptor,
                                                                   const std::string & encoderName )
{
    descriptor->applyToDrawableTexture((__bridge void *)DRAWABLE.texture);

    id <MTLRenderCommandEncoder> renderEncoder = [CMD_BUFFER renderCommandEncoderWithDescriptor:
                                                  (__bridge MTLRenderPassDescriptor *)descriptor->getNative()];

    renderEncoder.label = (__bridge NSString *)cocoa::createCfString(encoderName);
    
    return RenderEncoder::create((__bridge void *)renderEncoder);
}

ComputeEncoderRef CommandBuffer::createComputeEncoder( const std::string & encoderName )
{
    id <MTLComputeCommandEncoder> computeEncoder = [CMD_BUFFER computeCommandEncoder];
    computeEncoder.label = (__bridge NSString *)cocoa::createCfString(encoderName);
    return ComputeEncoder::create((__bridge void *)computeEncoder);
}

BlitEncoderRef CommandBuffer::createBlitEncoder( const std::string & encoderName )
{
    id <MTLBlitCommandEncoder> blitEncoder = [CMD_BUFFER blitCommandEncoder];
    blitEncoder.label = (__bridge NSString *)cocoa::createCfString(encoderName);
    return BlitEncoder::create((__bridge void *)blitEncoder);
}

void CommandBuffer::commitAndPresentForRendererLoop()
{
    RendererMetalImpl *renderer = [RendererMetalImpl sharedRenderer];
    // clean up the command buffer
    __block dispatch_semaphore_t block_sema = [renderer inflightSemaphore];
    [CMD_BUFFER addCompletedHandler:^(id<MTLCommandBuffer> buffer)
     {
         dispatch_semaphore_signal(block_sema);
     }];
    [CMD_BUFFER presentDrawable:DRAWABLE];
    // Finalize rendering here & push the command buffer to the GPU
    [CMD_BUFFER commit];

}