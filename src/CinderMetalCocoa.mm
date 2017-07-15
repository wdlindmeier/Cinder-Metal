//
//  CinderMetalCocoa.mm
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
    
    CGBitmapInfo bitmapInfo = kCGBitmapByteOrder32Big;
	switch (pxFormat)
	{
        case mtl::PixelFormatRGBA8Unorm:
		case mtl::PixelFormatRGBA8Unorm_sRGB:
		case mtl::PixelFormatRGBA8Snorm:
		case mtl::PixelFormatRGBA8Uint:
		case mtl::PixelFormatRGBA8Sint:
		{
			bitmapInfo = kCGImageAlphaNoneSkipLast | kCGBitmapByteOrder32Big;
		}
			break;
		case PixelFormatBGRA8Unorm:
		case PixelFormatBGRA8Unorm_sRGB:
		{
			bitmapInfo = kCGBitmapByteOrder32Little | kCGImageAlphaNoneSkipFirst;
		}
			break;
		default:
			// TODO: Make this more robust to other pixel formats
			NSLog(@"WARNING: Unsupported pixel format. TODO: Add support for %i", (int)pxFormat);
			break;
	}

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
