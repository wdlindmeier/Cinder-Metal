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

#define IMPL ((__bridge id <MTLCommandBuffer>)mImpl)

CommandBufferRef CommandBuffer::create( const std::string & bufferName )
{
    RendererMetalImpl *renderer = [RendererMetalImpl sharedRenderer];
    // instantiate a command buffer
    id <MTLCommandBuffer> commandBuffer = [renderer.commandQueue commandBuffer];
    commandBuffer.label = [NSString stringWithUTF8String:bufferName.c_str()];
    return CommandBufferRef( new CommandBuffer( (__bridge void *)commandBuffer ) );
}

CommandBuffer::CommandBuffer( void * mtlCommandBuffer )
:
mImpl(mtlCommandBuffer)
{
    assert( mtlCommandBuffer != NULL );
    assert( [(__bridge id)mtlCommandBuffer conformsToProtocol:@protocol(MTLCommandBuffer)] );
    CFRetain(mImpl);
}

CommandBuffer::~CommandBuffer()
{
    CFRelease(mImpl);
}

RenderEncoderRef CommandBuffer::createRenderEncoder( const RenderPassDescriptorRef & descriptor,
                                                     void *drawableTexture,
                                                     const std::string & encoderName )
{
    descriptor->applyToDrawableTexture(drawableTexture);

    id <MTLRenderCommandEncoder> renderEncoder = [IMPL renderCommandEncoderWithDescriptor:
                                                  (__bridge MTLRenderPassDescriptor *)descriptor->getNative()];

    renderEncoder.label = [NSString stringWithUTF8String:encoderName.c_str()];
    return RenderEncoder::create((__bridge void *)renderEncoder);
}

void CommandBuffer::waitUntilCompleted()
{
    [IMPL waitUntilCompleted];
}

ComputeEncoderRef CommandBuffer::createComputeEncoder( const std::string & encoderName )
{
    id <MTLComputeCommandEncoder> computeEncoder = [IMPL computeCommandEncoder];
    computeEncoder.label = [NSString stringWithUTF8String:encoderName.c_str()];
    return ComputeEncoder::create((__bridge void *)computeEncoder);
}

BlitEncoderRef CommandBuffer::createBlitEncoder( const std::string & encoderName )
{
    id <MTLBlitCommandEncoder> blitEncoder = [IMPL blitCommandEncoder];
    blitEncoder.label = [NSString stringWithUTF8String:encoderName.c_str()];
    return BlitEncoder::create((__bridge void *)blitEncoder);
}

void CommandBuffer::commit( std::function< void( void * mtlCommandBuffer) > completionHandler )
{
    if ( completionHandler != NULL )
    {
        [IMPL addCompletedHandler:^(id<MTLCommandBuffer> buffer)
         {
             completionHandler( (__bridge void *) buffer );
         }];
    }
    [IMPL commit];
}