//
//  Cocoa.cpp
//  MagicEraserCam
//
//  Created by William Lindmeier on 3/3/17.
//
//

#include "CinderMetalCocoa.h"
#import "ImageHelpers.h"

#ifndef CINDER_COCOA_TOUCH
#ifdef CINDER_COCOA
#import <AppKit/AppKit.h>
#endif
#endif

using namespace cinder::mtl;

namespace cinder { namespace cocoa {
    
void ReleaseTextureData( void * __nullable info, const void *data, size_t size );
void ReleaseTextureData( void * __nullable info, const void *data, size_t size )
{
    free((void *)data);
}

CGImageRef convertMTLTexture(id <MTLTexture> texture)
{
    size_t width = texture.width;
    size_t height = texture.height;
    
    PixelFormat pxFormat = (mtl::PixelFormat)texture.pixelFormat;
    ImageIo::DataType dataType = dataTypeFromPixelFormat(pxFormat);
    int numChannels = channelCountFromPixelFormat(pxFormat);
    size_t bytesPerComponent = dataSizeForType( dataType );
    size_t bitsPerComponent = bytesPerComponent * 8;
    size_t bytesPerRow = bytesPerComponent * width * numChannels;
    size_t memSize = height * bytesPerRow;
    void* data = malloc(memSize);
    
    [texture getBytes:data bytesPerRow:bytesPerRow fromRegion:MTLRegionMake2D(0, 0, width, height) mipmapLevel:0];
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    // TODO: Make this more robust to other pixel formats
    CGBitmapInfo bitmapInfo = kCGImageAlphaNoneSkipLast | kCGBitmapByteOrder32Big;
    
    CGDataProviderRef provider = CGDataProviderCreateWithData(nil, data, memSize, &ReleaseTextureData);
    
    CGImageRef cgImageRef = CGImageCreate(width, height,
                                          bitsPerComponent, // 8,
                                          bitsPerComponent * numChannels, // 32,
                                          bytesPerRow,
                                          colorSpace,
                                          bitmapInfo,
                                          provider,
                                          nil,
                                          true,
                                          kCGRenderingIntentPerceptual);
    
    CFRelease(provider);
    CFRelease(colorSpace);
    
    return cgImageRef;
}
    
#ifdef CINDER_COCOA_TOUCH
UIImage * convertTexture( ci::mtl::TextureBufferRef & texture )
{
    CGImageRef cgImage = convertMTLTexture((__bridge id<MTLTexture>)texture->getNative());
    return [UIImage imageWithCGImage:cgImage];
}
#else
#ifdef CINDER_COCOA
NSImage * convertTexture(ci::mtl::TextureBufferRef & texture)
{
	CGImageRef cgImage = convertMTLTexture((__bridge id<MTLTexture>)texture->getNative());
	return [[NSImage alloc] initWithCGImage:cgImage
									   size:(NSSize){
										   (CGFloat)texture->getWidth(),
										   (CGFloat)texture->getHeight()
									   }];
}
#endif
#endif
}}
