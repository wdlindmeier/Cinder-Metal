//
//  MetalCommandBuffer.cpp
//  MetalCube
//
//  Created by William Lindmeier on 10/17/15.
//
//

#include "MetalCommandBuffer.h"
#import "MetalRenderFormatImpl.h"
#import <QuartzCore/CAMetalLayer.h>

using namespace ci;
using namespace ci::mtl;

#define CMD_BUFFER ((__bridge id <MTLCommandBuffer>)mCommandBuffer)
#define DRAWABLE ((__bridge id <CAMetalDrawable>)mDrawable)

MetalCommandBufferRef MetalCommandBuffer::create( void * mtlCommandBuffer, void * mtlDrawable )
{
    return MetalCommandBufferRef( new MetalCommandBuffer( mtlCommandBuffer, mtlDrawable ) );
}

MetalCommandBuffer::MetalCommandBuffer( void * mtlCommandBuffer, void * mtlDrawable )
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

void MetalCommandBuffer::renderTargetWithFormat( MetalRenderFormatRef format,
                                                 std::function< void ( MetalRenderEncoderRef renderEncoder ) > renderFunc,
                                                 const std::string encoderName )
{
    // NOTE: We have to prepare the render description before getting the encoder
    [format->mImpl prepareForRenderToTexture:DRAWABLE.texture];
    
    id <MTLRenderCommandEncoder> renderEncoder = [CMD_BUFFER renderCommandEncoderWithDescriptor:format->mImpl.renderPassDescriptor];
    renderEncoder.label = (__bridge NSString *)cocoa::createCfString(encoderName);
    MetalRenderEncoderRef encoder = MetalRenderEncoder::create((__bridge void *)renderEncoder);
    
    renderFunc( encoder );
    
    [renderEncoder endEncoding];
}

void MetalCommandBuffer::computeTargetWithFormat( MetalComputeFormatRef format,
                                                  std::function< void ( MetalComputeEncoderRef computeEncoder ) > computeFunc,
                                                  const std::string encoderName )
{
    // TODO: Do we need to prepare the format with the drawable?
    id <MTLComputeCommandEncoder> computeEncoder = [CMD_BUFFER computeCommandEncoder];
    computeEncoder.label = (__bridge NSString *)cocoa::createCfString(encoderName);
    MetalComputeEncoderRef encoder = MetalComputeEncoder::create((__bridge void *)computeEncoder);

    computeFunc( encoder );
    
    [computeEncoder endEncoding];
}

void MetalCommandBuffer::blitTargetWithFormat( MetalBlitFormatRef format,
                                               std::function< void ( MetalBlitEncoderRef blitEncoder ) > blitFunc,
                                               const std::string encoderName )
{
    // TODO: Do we need to prepare the format with the drawable?
    id <MTLBlitCommandEncoder> blitEncoder = [CMD_BUFFER blitCommandEncoder];
    blitEncoder.label = (__bridge NSString *)cocoa::createCfString(encoderName);
    MetalBlitEncoderRef encoder = MetalBlitEncoder::create((__bridge void *)blitEncoder);

    blitFunc( encoder );
    
    [blitEncoder endEncoding];
}
