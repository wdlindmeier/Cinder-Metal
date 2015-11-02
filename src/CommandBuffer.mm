//
//  CommandBuffer.cpp
//  MetalCube
//
//  Created by William Lindmeier on 10/17/15.
//
//

#include "CommandBuffer.h"
#import "RenderFormatImpl.h"
#import <QuartzCore/CAMetalLayer.h>

using namespace ci;
using namespace ci::mtl;

#define CMD_BUFFER ((__bridge id <MTLCommandBuffer>)mCommandBuffer)
#define DRAWABLE ((__bridge id <CAMetalDrawable>)mDrawable)

CommandBufferRef CommandBuffer::create( void * mtlCommandBuffer, void * mtlDrawable )
{
    return CommandBufferRef( new CommandBuffer( mtlCommandBuffer, mtlDrawable ) );
}

CommandBuffer::CommandBuffer( void * mtlCommandBuffer, void * mtlDrawable )
:
mCommandBuffer(mtlCommandBuffer)
,mDrawable(mtlDrawable)
{
     // <MTLCommandBuffer>
    assert( mtlCommandBuffer != NULL );
    assert( [(__bridge id)mtlCommandBuffer conformsToProtocol:@protocol(MTLCommandBuffer)] );
    assert( mtlDrawable != NULL );
    assert( [(__bridge id)mtlDrawable conformsToProtocol:@protocol(CAMetalDrawable)] );
}

void CommandBuffer::renderTargetWithFormat( RenderFormatRef format,
                                            std::function< void ( RenderEncoderRef renderEncoder ) > renderFunc,
                                            const std::string encoderName )
{
    // NOTE: We have to prepare the render description before getting the encoder
    [format->mImpl prepareForRenderToTexture:DRAWABLE.texture];
    
    id <MTLRenderCommandEncoder> renderEncoder = [CMD_BUFFER renderCommandEncoderWithDescriptor:format->mImpl.renderPassDescriptor];
    renderEncoder.label = (__bridge NSString *)cocoa::createCfString(encoderName);
    RenderEncoderRef encoder = RenderEncoder::create((__bridge void *)renderEncoder);
    
    renderFunc( encoder );
    
    [renderEncoder endEncoding];
}

void CommandBuffer::computeTargetWithFormat( ComputeFormatRef format,
                                                  std::function< void ( ComputeEncoderRef computeEncoder ) > computeFunc,
                                                  const std::string encoderName )
{
    // TODO: Do we need to prepare the format with the drawable?
    id <MTLComputeCommandEncoder> computeEncoder = [CMD_BUFFER computeCommandEncoder];
    computeEncoder.label = (__bridge NSString *)cocoa::createCfString(encoderName);
    ComputeEncoderRef encoder = ComputeEncoder::create((__bridge void *)computeEncoder);

    computeFunc( encoder );
    
    [computeEncoder endEncoding];
}

void CommandBuffer::blitTargetWithFormat( BlitFormatRef format,
                                               std::function< void ( BlitEncoderRef blitEncoder ) > blitFunc,
                                               const std::string encoderName )
{
    // TODO: Do we need to prepare the format with the drawable?
    id <MTLBlitCommandEncoder> blitEncoder = [CMD_BUFFER blitCommandEncoder];
    blitEncoder.label = (__bridge NSString *)cocoa::createCfString(encoderName);
    BlitEncoderRef encoder = BlitEncoder::create((__bridge void *)blitEncoder);

    blitFunc( encoder );
    
    [blitEncoder endEncoding];
}
