//
//  TextureBuffer.cpp
//
//  Created by William Lindmeier on 10/30/15.
//
//

#include "TextureBuffer.h"
#include "RendererMetalImpl.h"
#include "cinder/Log.h"
#include "cinder/cocoa/CinderCocoa.h"
#include "ImageHelpers.h"
#include "Scope.h"

using namespace std;
using namespace cinder;
using namespace cinder::mtl;

#define IMPL ((__bridge id <MTLTexture>)mImpl)

#pragma mark - Constructors

TextureBuffer::TextureBuffer( uint width, uint height, Format format ) :
mFormat(format)
{
    PixelFormat pxFormat = format.getPixelFormat();
    
    MTLTextureDescriptor *desc = [[MTLTextureDescriptor alloc] init];
    desc.textureType = (MTLTextureType)mFormat.getTextureType();
    desc.pixelFormat = (MTLPixelFormat)pxFormat;
    desc.width = width;
    desc.height = height;
    desc.depth = mFormat.getDepth();
    desc.arrayLength = mFormat.getArrayLength();
    desc.usage = mFormat.getUsage();
    desc.mipmapLevelCount = mFormat.getMipmapLevel();
    desc.sampleCount = mFormat.getSampleCount();
    desc.storageMode = (MTLStorageMode)mFormat.getStorageMode();
    desc.cpuCacheMode = (MTLCPUCacheMode)mFormat.getCacheMode();
    
    mDataType = dataTypeFromPixelFormat(pxFormat);
    
    int numChannels = channelCountFromPixelFormat(pxFormat);
    assert( numChannels > 0 && numChannels != 3 );
    mBytesPerRow = dataSizeForType( mDataType ) * width * numChannels;

    mImpl = (__bridge_retained void *)[[RendererMetalImpl sharedRenderer].device
                                       newTextureWithDescriptor:desc];
    assert(mImpl != nil);
}

TextureBuffer::TextureBuffer( void * mtlTexture )
{
    update( mtlTexture );
    
    PixelFormat pxFormat = (PixelFormat)[IMPL pixelFormat];
    mDataType = dataTypeFromPixelFormat(pxFormat);
    
    int numChannels = channelCountFromPixelFormat(pxFormat);
    assert( numChannels > 0 && numChannels != 3 );

    mBytesPerRow = dataSizeForType( mDataType ) * [IMPL width] * numChannels;

    mFormat = Format()
                .pixelFormat(pxFormat)
                .mipmapLevel((int)[IMPL mipmapLevelCount])
                .sampleCount((int)[IMPL sampleCount])
                .depth((int)[IMPL depth])
                .arrayLength((int)[IMPL arrayLength])
                .usage((mtl::TextureUsage)[IMPL usage])
                .storageMode((mtl::StorageMode)[IMPL storageMode])
                .cacheMode((mtl::CPUCacheMode)[IMPL cpuCacheMode]);
}

TextureBuffer::TextureBuffer( const ImageSourceRef & imageSource, Format format ) :
mFormat(format)
{
    CGImageRef imageRef = cocoa::createCgImage( imageSource, ImageTarget::Options() );

    MTLPixelFormat pxFormat = (MTLPixelFormat)mFormat.getPixelFormat();
    
    mDataType = imageSource->getDataType();
    ImageIo::ChannelOrder channelOrder = imageSource->getChannelOrder();
    
    if ( pxFormat == MTLPixelFormatInvalid )
    {
        pxFormat = (MTLPixelFormat)pixelFormatFromChannelOrder(channelOrder, mDataType);
        mFormat.setPixelFormat((PixelFormat)pxFormat);
    }
    
    NSUInteger width = CGImageGetWidth(imageRef);
    NSUInteger height = CGImageGetHeight(imageRef);
    
    // Get the image data
    mBytesPerRow = CGImageGetBytesPerRow(imageRef);
    // NOTE: channelOrderNumChannels can return the wrong number of channels.
    // int numChannels = ImageIo::channelOrderNumChannels( mChannelOrder );
    long numCalculatedChannels = mBytesPerRow / width / dataSizeForType(mDataType);
    if ( numCalculatedChannels == 3 )
    {
        // Add another channel to the byte size.
        mBytesPerRow += mBytesPerRow / 3;
    }

    MTLTextureDescriptor *desc = [[MTLTextureDescriptor alloc] init];
    desc.textureType = (MTLTextureType)mFormat.getTextureType();
    desc.pixelFormat = pxFormat;
    desc.width = width;
    desc.height = height;
    desc.depth = mFormat.getDepth();
    desc.arrayLength = mFormat.getArrayLength();
    desc.usage = mFormat.getUsage();
    desc.mipmapLevelCount = mFormat.getMipmapLevel();
    desc.sampleCount = mFormat.getSampleCount();

    // Does this need to be CFRetained?
    mImpl = (__bridge_retained void *)[[RendererMetalImpl sharedRenderer].device newTextureWithDescriptor:desc];
    assert(mImpl != nil);
    
    updateWithCGImage( imageRef, mFormat.getFlipVertically() );
    
    CFRelease(imageRef);
}

TextureBufferRef TextureBuffer::clone()
{
	TextureBufferRef myClone = mtl::TextureBuffer::create((int)getWidth(), (int)getHeight(), getFormat());
	TextureBufferRef myRef(this);
	copyTexture(myRef, myClone);
	return myClone;
}

TextureBuffer::~TextureBuffer()
{
    if ( mImpl )
    {
        CFRelease(mImpl);
    }
}

#pragma mark - Getting data

ImageSourceRef TextureBuffer::createSource( int slice, int mipmapLevel )
{
    return ImageSourceRef( new ImageSourceTextureBuffer( *this, slice, mipmapLevel ) );
}

void TextureBuffer::getPixelData( void *pixelBytes, const ivec2 & origin, const ivec2 & size,
                                  unsigned int slice, unsigned int mipmapLevel )
{
    [IMPL getBytes:pixelBytes
       bytesPerRow:mBytesPerRow
     bytesPerImage:mBytesPerRow * getHeight()
        fromRegion:MTLRegionMake2D(origin.x, origin.y, size.x, size.y)
       mipmapLevel:mipmapLevel
             slice:slice];
}

void TextureBuffer::getPixelData( void *pixelBytes, unsigned int slice, unsigned int mipmapLevel )
{
    [IMPL getBytes:pixelBytes
       bytesPerRow:mBytesPerRow
     bytesPerImage:mBytesPerRow * getHeight()
        fromRegion:MTLRegionMake2D(0, 0, getWidth(), getHeight())
       mipmapLevel:mipmapLevel
             slice:slice];
}

#pragma mark - Setting Data

void TextureBuffer::update( const ImageSourceRef & imageSource, unsigned int slice, unsigned int mipmapLevel )
{
    CGImageRef imageRef = cocoa::createCgImage( imageSource );
    updateWithCGImage( imageRef, mFormat.getFlipVertically(), slice, mipmapLevel );
    CFRelease(imageRef);
}

void TextureBuffer::update( void * mtlTexture )
{
    if ( mImpl )
    {
        CFRelease(mImpl);
        mImpl = NULL;
    }
    assert( mtlTexture != NULL );
    assert( [(__bridge id)mtlTexture conformsToProtocol:@protocol(MTLTexture)] );
    mImpl = mtlTexture;
    CFRetain(mImpl);
    // NOTE:
    // This is called from the MTLTexture * constructor. Don't do anything too fancy.
}

static CGImageRef createCGImageFlippedVertically( CGImageRef imageRef )
{
    NSUInteger width = CGImageGetWidth((CGImageRef)imageRef);
    NSUInteger height = CGImageGetHeight((CGImageRef)imageRef);
    CGColorSpaceRef colorSpace = CGImageGetColorSpace((CGImageRef)imageRef);
    CGColorSpaceModel colorModel = CGColorSpaceGetModel(colorSpace);
    CGContextRef context;
    CGColorSpaceRef contextColorSpace;
    if ( colorModel == kCGColorSpaceModelMonochrome )
    {
        contextColorSpace = CGColorSpaceCreateDeviceGray();
        context = CGBitmapContextCreate(nil,
                                        width,
                                        height,
                                        8,
                                        1 * width,
                                        contextColorSpace,
                                        kCGImageAlphaNone);
    }
    else
    {
        contextColorSpace = CGColorSpaceCreateDeviceRGB();
        context = CGBitmapContextCreate(nil,
                                                 width,
                                                 height,
                                                 8,
                                                 4 * width,
                                                 contextColorSpace,
                                                 kCGImageAlphaPremultipliedLast);
    }
    
    CGRect bounds = CGRectMake(0, 0, width, height);
    CGContextClearRect(context, bounds);
    CGContextTranslateCTM(context, 0, CGFloat(height));
    CGContextScaleCTM(context, 1.0, -1.0);
    CGContextDrawImage(context, bounds, (CGImageRef)imageRef);
    CGImageRef imgRef = CGBitmapContextCreateImage(context);
    assert(imgRef);
    CGContextRelease(context);
    CGColorSpaceRelease(contextColorSpace);

    return imgRef;
}

void TextureBuffer::updateWithCGImage( void * imageRef, bool flipVertically, unsigned int slice, unsigned int mipmapLevel ) // CGImageRef
{
    NSUInteger width = CGImageGetWidth((CGImageRef)imageRef);
    NSUInteger height = CGImageGetHeight((CGImageRef)imageRef);
    assert(width == getWidth());
    assert(height == getHeight());
    
    if ( flipVertically )
    {
        imageRef = createCGImageFlippedVertically((CGImageRef)imageRef);
    }
    
    CFDataRef imgData = CGDataProviderCopyData( CGImageGetDataProvider( (CGImageRef)imageRef ) );
    
    uint8_t *rawData = (uint8_t *) CFDataGetBytePtr(imgData);
    bool shouldFreeData = false;
    
    long bytesPerImageRow = CGImageGetBytesPerRow((CGImageRef)imageRef);
    long numCalculatedChannels = bytesPerImageRow / width / dataSizeForType(mDataType);
    if ( numCalculatedChannels == 3 )
    {
        uint8_t *newRawData = createFourChannelFromThreeChannel( ivec2(width, height), mDataType, rawData);
        CFRelease(imgData);
        shouldFreeData = true;
        rawData = newRawData;
    }
    else
    {
        assert( bytesPerImageRow == mBytesPerRow );
    }
    
    setPixelData(rawData, slice, mipmapLevel);
    
    if ( shouldFreeData )
    {
        delete [] rawData;
    }
    else
    {
        CFRelease(imgData);
    }
    
    if ( flipVertically )
    {
        CGImageRelease((CGImageRef)imageRef);
    }
    
    if ( [IMPL mipmapLevelCount] > 1 )
    {
        generateMipmap();
    }
}

void TextureBuffer::generateMipmap()
{
    id<MTLDevice> device = [RendererMetalImpl sharedRenderer].device;
    id<MTLCommandQueue> commandQueue = [device newCommandQueue];
    id<MTLCommandBuffer> commandBuffer = [commandQueue commandBuffer];
    id<MTLBlitCommandEncoder> commandEncoder = [commandBuffer blitCommandEncoder];
    [commandEncoder generateMipmapsForTexture:IMPL];
    [commandEncoder endEncoding];
    [commandBuffer addCompletedHandler:^(id<MTLCommandBuffer> _Nonnull) {
        //NSLog(@"mipmap generation complete");
    }];
    [commandBuffer commit];
}

void TextureBuffer::setPixelData( const void *pixelBytes, unsigned int slice, unsigned int mipmapLevel )
{
    ivec2 size = getSize();
    assert( size.x > 0 );
    assert( size.y > 0 );

    [IMPL replaceRegion:MTLRegionMake2D(0, 0, size.x, size.y)
            mipmapLevel:mipmapLevel
                  slice:slice
              withBytes:pixelBytes
            bytesPerRow:mBytesPerRow
          bytesPerImage:mBytesPerRow * size.y];

	if ( [IMPL mipmapLevelCount] > 1 )
	{
		generateMipmap();
	}
}

#pragma mark - Accessors

TextureBuffer::Format TextureBuffer::getFormat() const
{
    return mFormat;
}

long TextureBuffer::getWidth() const
{
    return [IMPL width];
}

long TextureBuffer::getHeight() const
{
    return [IMPL height];
}

long TextureBuffer::getDepth() const
{
    return [IMPL depth];
}

long TextureBuffer::getMipmapLevelCount()
{
    return [IMPL mipmapLevelCount];
}

long TextureBuffer::getSampleCount()
{
    return [IMPL sampleCount];
}

long TextureBuffer::getArrayLength()
{
    return [IMPL arrayLength];
}

bool TextureBuffer::getFramebufferOnly()
{
    return [IMPL isFramebufferOnly];
}

TextureUsage TextureBuffer::getUsage() // AKA MTLTextureUsage
{
    return (TextureUsage)[IMPL usage];
}

// Not implemented
// rootResource

static inline MTLRegion mtlRegion( const glm::ivec2 regionOrigin, const glm::ivec2 regionSize )
{
    return MTLRegionMake2D( regionOrigin.x, regionOrigin.y, regionSize.x, regionSize.y);
}

static inline MTLRegion mtlRegion( const glm::ivec3 regionOrigin, const glm::ivec3 regionSize )
{
    return MTLRegionMake3D( regionOrigin.x, regionOrigin.y, regionOrigin.z,
                            regionSize.x, regionSize.y, regionSize.z );
}

void TextureBuffer::getBytes( void * pixelBytes, const ivec3 regionOrigin, const ivec3 regionSize,
                              uint bytesPerRow, uint bytesPerImage, uint mipmapLevel, uint slice )
{
    [IMPL getBytes:pixelBytes
       bytesPerRow:bytesPerRow
     bytesPerImage:bytesPerImage
        fromRegion:mtlRegion(regionOrigin, regionSize)
       mipmapLevel:mipmapLevel
             slice:slice];
}

void TextureBuffer::replaceRegion(const ivec3 regionOrigin, const ivec3 regionSize, const void * newBytes, uint bytesPerRow, uint bytesPerImage, uint mipmapLevel, uint slice)
{
    [IMPL replaceRegion:mtlRegion(regionOrigin, regionSize)
            mipmapLevel:mipmapLevel
                  slice:slice
              withBytes:newBytes
            bytesPerRow:bytesPerRow
          bytesPerImage:bytesPerImage];
}

void TextureBuffer::replaceRegion(const ivec2 regionOrigin, const ivec2 regionSize, const void * newBytes, uint bytesPerRow, uint mipmapLevel)
{
    [IMPL replaceRegion:mtlRegion(regionOrigin, regionSize)
            mipmapLevel:mipmapLevel
              withBytes:newBytes
            bytesPerRow:bytesPerRow];
}

TextureBufferRef TextureBuffer::newTexture( PixelFormat pixelFormat, TextureType type,
                                            uint levelOffset, uint levelLength, uint sliceOffset,
                                            uint sliceLength )
{
    id <MTLTexture> newTex = [IMPL newTextureViewWithPixelFormat:(MTLPixelFormat)pixelFormat
                                                     textureType:(MTLTextureType)type
                                                          levels:NSMakeRange(levelOffset, levelLength)
                                                          slices:NSMakeRange(sliceOffset, sliceLength)];
    return TextureBufferRef( new TextureBuffer( (__bridge void *)newTex) );
}

