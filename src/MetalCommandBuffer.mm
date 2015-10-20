//
//  MetalCommandBuffer.cpp
//  MetalCube
//
//  Created by William Lindmeier on 10/17/15.
//
//

#include "MetalCommandBuffer.h"
#import "MetalCommandBufferImpl.h"
#import "MetalRenderFormatImpl.h"
#import "MetalRenderEncoderImpl.h"
#import "MetalComputeEncoderImpl.h"
#import "MetalBlitEncoderImpl.h"
#import "MetalContext.h"

using namespace ci;
using namespace ci::mtl;

MetalCommandBufferRef MetalCommandBuffer::create( MetalCommandBufferImpl * impl )
{
    return MetalCommandBufferRef( new MetalCommandBuffer( impl ) );
}

MetalCommandBuffer::MetalCommandBuffer( MetalCommandBufferImpl * impl)
:
mImpl(impl)
{
}

void MetalCommandBuffer::renderTargetWithFormat( MetalRenderFormatRef format,
                                                 std::function< void ( MetalRenderEncoderRef renderEncoder ) > renderFunc,
                                                 const std::string encoderName )
{
    // NOTE: We have to prepare the render description before getting the encoder
    id <CAMetalDrawable> drawable = mImpl.drawable;
    [format->mImpl prepareForRenderToTexture:drawable.texture];
    
    id <MTLRenderCommandEncoder> renderEncoder = [mImpl.commandBuffer renderCommandEncoderWithDescriptor:format->mImpl.renderPassDescriptor];
    renderEncoder.label = (__bridge NSString *)cocoa::createCfString(encoderName);
    MetalRenderEncoderImpl *encoderImpl = [[MetalRenderEncoderImpl alloc] initWithRenderCommandEncoder:renderEncoder];
    MetalRenderEncoderRef encoder = MetalRenderEncoder::create(encoderImpl);
    
    renderFunc( encoder );
    
    [renderEncoder endEncoding];
}

void MetalCommandBuffer::computeTargetWithFormat( MetalComputeFormatRef format,
                                                  std::function< void ( MetalComputeEncoderRef computeEncoder ) > computeFunc,
                                                  const std::string encoderName )
{
    // TODO: Do we need to prepare the format with the drawable?
    id <MTLComputeCommandEncoder> computeEncoder = [mImpl.commandBuffer computeCommandEncoder];
    computeEncoder.label = (__bridge NSString *)cocoa::createCfString(encoderName);
    MetalComputeEncoderImpl *encoderImpl = [[MetalComputeEncoderImpl alloc] initWithComputeCommandEncoder:computeEncoder];
    MetalComputeEncoderRef encoder = MetalComputeEncoder::create(encoderImpl);

    computeFunc( encoder );
    
    [computeEncoder endEncoding];
}

void MetalCommandBuffer::blitTargetWithFormat( MetalBlitFormatRef format,
                                               std::function< void ( MetalBlitEncoderRef blitEncoder ) > blitFunc,
                                               const std::string encoderName )
{
    // TODO: Do we need to prepare the format with the drawable?
    id <MTLBlitCommandEncoder> blitEncoder = [mImpl.commandBuffer blitCommandEncoder];
    blitEncoder.label = (__bridge NSString *)cocoa::createCfString(encoderName);
    MetalBlitEncoderImpl *encoderImpl = [[MetalBlitEncoderImpl alloc] initWithBlitCommandEncoder:blitEncoder];
    MetalBlitEncoderRef encoder = MetalBlitEncoder::create(encoderImpl);

    blitFunc( encoder );
    
    [blitEncoder endEncoding];
}
