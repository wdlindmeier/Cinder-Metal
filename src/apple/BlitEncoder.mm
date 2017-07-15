//
//  BlitEncoder.cpp
//
//  Created by William Lindmeier on 10/17/15.
//
//

#include "BlitEncoder.h"
#include "cinder/cocoa/CinderCocoa.h"
#import <QuartzCore/CAMetalLayer.h>
#import <Metal/Metal.h>
#import <simd/simd.h>

using namespace ci;
using namespace ci::mtl;
using namespace ci::cocoa;

#define IMPL ((__bridge id <MTLBlitCommandEncoder>)mImpl)

BlitEncoderRef BlitEncoder::create( void * mtlBlitCommandEncoder )
{
    return BlitEncoderRef( new BlitEncoder( mtlBlitCommandEncoder ) );
}

BlitEncoder::BlitEncoder( void * mtlBlitCommandEncoder )
:
mImpl(mtlBlitCommandEncoder)
{
    assert( mtlBlitCommandEncoder != NULL );
    assert( [(__bridge id)mtlBlitCommandEncoder conformsToProtocol:@protocol(MTLBlitCommandEncoder)] );
    CFRetain(mImpl);
}

BlitEncoder::~BlitEncoder()
{
    if ( mImpl )
    {
        CFRelease(mImpl);
    }
}

void BlitEncoder::endEncoding()
{
    [(__bridge id<MTLBlitCommandEncoder>)mImpl endEncoding];
}

#if !defined( CINDER_COCOA_TOUCH )
void BlitEncoder::synchronizeResource( void * mtlResource ) // MTLResource
{
    [IMPL synchronizeResource:(__bridge id <MTLResource>)mtlResource];
}

void BlitEncoder::synchronizeTexture( const TextureBufferRef & texture, uint slice, uint level)
{
    [IMPL synchronizeTexture:(__bridge id <MTLTexture>)texture->getNative() slice:slice level:level];
}
#endif

void BlitEncoder::copyFromTextureToTexture( const TextureBufferRef & sourceTexture, uint sourceSlice,
										    uint sourceLevel, ivec3 sourceOrigin, ivec3 sourceSize,
										    TextureBufferRef & destTexture, uint destSlice, uint destLevel,
										    ivec3 destOrigin )
{
    [IMPL copyFromTexture:(__bridge id <MTLTexture>)sourceTexture->getNative()
              sourceSlice:sourceSlice
              sourceLevel:sourceLevel
             sourceOrigin:MTLOriginMake(sourceOrigin.x, sourceOrigin.y, sourceOrigin.z)
               sourceSize:MTLSizeMake(sourceSize.x, sourceSize.y, sourceSize.z)
                toTexture:(__bridge id <MTLTexture>)destTexture->getNative()
         destinationSlice:destSlice
         destinationLevel:destLevel
        destinationOrigin:MTLOriginMake(destOrigin.x, destOrigin.y, destOrigin.z)];
}

void BlitEncoder::copyFromBufferToTexture( const DataBufferRef & sourceBuffer, uint sourceOffset, uint sourceBytesPerRow, uint sourceBytesPerImage, ivec3 sourceSize, TextureBufferRef & destTexture, uint destSlice, uint destLevel, ivec3 destOrigin, BlitOption options )
{
    [IMPL copyFromBuffer:(__bridge id <MTLBuffer>)sourceBuffer->getNative()
            sourceOffset:sourceOffset
       sourceBytesPerRow:sourceBytesPerRow
     sourceBytesPerImage:sourceBytesPerImage
              sourceSize:MTLSizeMake(sourceSize.x, sourceSize.y, sourceSize.z)
               toTexture:(__bridge id <MTLTexture>)destTexture->getNative()
        destinationSlice:destSlice
        destinationLevel:destLevel
       destinationOrigin:MTLOriginMake(destOrigin.x, destOrigin.y, destOrigin.z)
                 options:(MTLBlitOption)options];
}

void BlitEncoder::copyFromTextureToBuffer( const TextureBufferRef & sourceTexture, uint sourceSlice, uint sourceLevel, ivec3 sourceOrigin, ivec3 sourceSize, const DataBufferRef & destBuffer, uint destOffset, uint destBytesPerRow, uint destBytesPerImage, BlitOption options )
{
    [IMPL copyFromTexture:(__bridge id <MTLTexture>)sourceTexture->getNative()
              sourceSlice:sourceSlice
              sourceLevel:sourceLevel
             sourceOrigin:MTLOriginMake(sourceOrigin.x, sourceOrigin.y, sourceOrigin.z)
               sourceSize:MTLSizeMake(sourceSize.x, sourceSize.y, sourceSize.z)
                 toBuffer:(__bridge id <MTLBuffer>)destBuffer->getNative()
        destinationOffset:destOffset
   destinationBytesPerRow:destBytesPerRow
 destinationBytesPerImage:destBytesPerImage
                  options:options];
}

void BlitEncoder::generateMipmapsForTexture( const TextureBufferRef & texture )
{
    [IMPL generateMipmapsForTexture:(__bridge id <MTLTexture>)texture->getNative()];
}

void BlitEncoder::fillBuffer( DataBufferRef buffer, uint8_t value, uint length, uint offset )
{
    [IMPL fillBuffer:(__bridge id <MTLBuffer>)buffer->getNative()
               range:NSMakeRange(offset, length)
               value:value];
}

void BlitEncoder::copyFromBufferToBuffer( DataBufferRef & sourceBuffer, uint sourceOffset, DataBufferRef & destBuffer, uint destOffset, uint length)
{
    [IMPL copyFromBuffer:(__bridge id <MTLBuffer>)sourceBuffer->getNative()
            sourceOffset:sourceOffset
                toBuffer:(__bridge id <MTLBuffer>)destBuffer->getNative()
       destinationOffset:destOffset
                    size:length];
}
