//
//  TextureBuffer.cpp
//  MetalCube
//
//  Created by William Lindmeier on 10/30/15.
//
//

#include "TextureBuffer.h"
#include "RendererMetalImpl.h"
#include "cinder/Log.h"
#include "cinder/cocoa/CinderCocoa.h"

using namespace std;
using namespace cinder;
using namespace cinder::mtl;

static inline int dataSizeForType( ImageIo::DataType dataType )
{
    switch (dataType)
    {
        case ImageIo::UINT8:
            return 1;
            break;
        case ImageIo::UINT16:
        case ImageIo::FLOAT16:
            return 2;
            break;
        case ImageIo::FLOAT32:
            return 4;
            break;
        default:
            return 1;
            break;
    }
}

// Metal textures don't appear to have 3-component formats, so we'll
// convert RGB image data to RGBA.
// NOTE: This always adds a 4th component to the end of the order.
static inline uint8_t* createFourChannelFromThreeChannel(ivec2 imageSize,
                                                         ImageIo::DataType dataType,
                                                         const uint8_t* rgbData )
{
    const size_t dataSize = dataSizeForType(dataType);
    const size_t bytesPer3ChannelPx = 3 * dataSize;
    const size_t bytesPer4ChannelPx = 4 * dataSize;
    const size_t rowBytes = imageSize.x * bytesPer4ChannelPx;
    size_t rgbaSize = rowBytes * imageSize.y;
    uint8_t* rgbaData = new uint8_t[rgbaSize];
    memset(rgbaData, 0xFF, rgbaSize); // fill with white, alpha = 1
    size_t pxCount = imageSize.x * imageSize.y;
    for(size_t i = 0; i < pxCount; ++i)
    {
        memcpy(&rgbaData[i * bytesPer4ChannelPx],
               &((const uint8_t*)rgbData)[i * bytesPer3ChannelPx],
               bytesPer3ChannelPx);
    }
    return rgbaData;
}

static inline MTLPixelFormat mtlPixelFormatFromChannelOrder( ImageIo::ChannelOrder channelOrder,
                                                             ImageIo::DataType dataType )
{
    switch (channelOrder)
    {
        case ImageIo::RGBA:
            switch (dataType)
            {
                case ImageIo::UINT8:
                    return MTLPixelFormatRGBA8Unorm;
                case ImageIo::UINT16:
                    return MTLPixelFormatRGBA16Unorm;
                case ImageIo::FLOAT16:
                    return MTLPixelFormatRGBA16Float;
                case ImageIo::FLOAT32:
                    return MTLPixelFormatRGBA32Float;
                default:
                    return MTLPixelFormatInvalid;
            }
        case ImageIo::BGRA:
            return MTLPixelFormatBGRA8Unorm;
        case ImageIo::RGBX:
            switch (dataType)
            {
                case ImageIo::UINT8:
                    return MTLPixelFormatRGBA8Unorm;
                case ImageIo::UINT16:
                    return MTLPixelFormatRGBA16Unorm;
                case ImageIo::FLOAT16:
                    return MTLPixelFormatRGBA16Float;
                case ImageIo::FLOAT32:
                    return MTLPixelFormatRGBA32Float;
                default:
                    return MTLPixelFormatInvalid;
            }
        case ImageIo::BGRX:
            return MTLPixelFormatBGRA8Unorm;
        case ImageIo::RGB:
            // NOTE: MTLPixelFormat doesn't have a standard RGB w/out Alpha.
            // We need to use a 4-component format and add an additional channel to the data.
            switch (dataType)
            {
                case ImageIo::UINT8:
                    return MTLPixelFormatRGBA8Unorm;
                case ImageIo::UINT16:
                    return MTLPixelFormatRGBA16Unorm;
                case ImageIo::FLOAT16:
                    return MTLPixelFormatRGBA16Float;
                case ImageIo::FLOAT32:
                    return MTLPixelFormatRGBA32Float;
                default:
                    return MTLPixelFormatInvalid;
            }
        case ImageIo::BGR:
            return MTLPixelFormatBGRA8Unorm;
        case ImageIo::Y:
            switch (dataType)
            {
                case ImageIo::UINT8:
                    return MTLPixelFormatR8Unorm;
                case ImageIo::UINT16:
                    return MTLPixelFormatR16Unorm;
                case ImageIo::FLOAT16:
                    return MTLPixelFormatR16Float;
                case ImageIo::FLOAT32:
                    return MTLPixelFormatR32Float;
                default:
                    return MTLPixelFormatInvalid;
            }
        case ImageIo::YA:
            switch (dataType)
            {
                case ImageIo::UINT8:
                    return MTLPixelFormatRG8Unorm;
                case ImageIo::UINT16:
                    return MTLPixelFormatRG16Unorm;
                case ImageIo::FLOAT16:
                    return MTLPixelFormatRG16Float;
                case ImageIo::FLOAT32:
                    return MTLPixelFormatRG32Float;
                default:
                    return MTLPixelFormatInvalid;
            }
        default:
            CI_LOG_E("Don't know how to convert channel order " << channelOrder << " into MTLPixelFormat");
            assert(false);
    }
}

namespace cinder { namespace mtl {
    
class ImageSourceMTLTexture : public ImageSource
{

public:
    
    ImageSourceMTLTexture( TextureBuffer & texture )
    : ImageSource()
    {
        mWidth = (int)texture.getWidth();
        mHeight = (int)texture.getHeight();

        setChannelOrder( texture.mChannelOrder );
        setColorModel( texture.mColorModel );
        setDataType( texture.mDataType );

        int dataSize = dataSizeForType(mDataType);

        mRowBytes = mWidth * ImageIo::channelOrderNumChannels( mChannelOrder ) * dataSize;
        mData = unique_ptr<uint8_t[]>( new uint8_t[mRowBytes * mHeight] );
        
        texture.getPixelData(mData.get());
    }
    
    // NOTE: I just copied this from ImageSourceTexture. Not sure if it's correct.
    void load( ImageTargetRef target )
    {
        // get a pointer to the ImageSource function appropriate for handling our data configuration
        ImageSource::RowFunc func = setupRowFunc( target );
        
        const uint8_t *data = mData.get();
        if( mRowBytes < 0 )
            data = data + ( mHeight - 1 ) * (-mRowBytes);
        for( int32_t row = 0; row < mHeight; ++row ) {
            ((*this).*func)( target, row, data );
            data += mRowBytes;
        }
    }
    
    std::unique_ptr<uint8_t[]>	mData;
    int32_t						mRowBytes;
};
}} // cinder mtl

#define IMPL ((__bridge id <MTLTexture>)mImpl)

#pragma mark - Constructors

TextureBuffer::TextureBuffer( ImageSourceRef imageSource, Format format ) :
mFormat(format)
{
    CGImageRef imageRef = cocoa::createCgImage( imageSource, ImageTarget::Options() );

    MTLPixelFormat pxFormat = (MTLPixelFormat)mFormat.getPixelFormat();
    
    mChannelOrder = imageSource->getChannelOrder();
    mDataType = imageSource->getDataType();
    mColorModel = imageSource->getColorModel();
    
    if ( pxFormat == MTLPixelFormatInvalid )
    {
        pxFormat = mtlPixelFormatFromChannelOrder(mChannelOrder, mDataType);
        mFormat.setPixelFormat(pxFormat);
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

    CI_LOG_I("TODO: Account for non 2D textures.");
    assert( format.getTextureType() == MTLTextureType2D );
    MTLTextureDescriptor *desc = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:pxFormat
                                                                                    width:width
                                                                                   height:height
                                                                                mipmapped:mFormat.getMipmapLevel() > 1];
    desc.mipmapLevelCount = mFormat.getMipmapLevel();
    desc.sampleCount = format.getSampleCount();

    // Does this need to be CFRetained?
    mImpl = (__bridge_retained void *)[[RendererMetalImpl sharedRenderer].device newTextureWithDescriptor:desc];
    
    updateWidthCGImage( imageRef );
}

TextureBuffer::~TextureBuffer()
{
    CFRelease(mImpl);
}

#pragma mark - Getting data

ImageSourceRef TextureBuffer::createSource()
{
    return ImageSourceRef( new ImageSourceMTLTexture( *this ) );
}

void TextureBuffer::getPixelData( void *pixelBytes )
{
     // TODO: Account for cubes and arrays
    [IMPL getBytes:pixelBytes
       bytesPerRow:mBytesPerRow
     bytesPerImage:mBytesPerRow * getHeight()
        fromRegion:MTLRegionMake2D(0, 0, getWidth(), getHeight())
       mipmapLevel:0
             slice:0];
}

#pragma mark - Setting Data

void TextureBuffer::update( ImageSourceRef imageSource )
{
    CGImageRef imageRef = cocoa::createCgImage( imageSource, ImageTarget::Options() );
    assert(mChannelOrder == imageSource->getChannelOrder());
    assert(mDataType == imageSource->getDataType());
    assert(mColorModel == imageSource->getColorModel());
    updateWidthCGImage( imageRef );
}

void TextureBuffer::updateWidthCGImage( void * imageRef ) // CGImageRef
{
    NSUInteger width = CGImageGetWidth((CGImageRef)imageRef);
    NSUInteger height = CGImageGetHeight((CGImageRef)imageRef);
    assert(width == getWidth());
    assert(height == getHeight());
    
    CFDataRef imgData = CGDataProviderCopyData( CGImageGetDataProvider( (CGImageRef)imageRef ) );
    
    uint8_t *rawData = (uint8_t *) CFDataGetBytePtr(imgData);
    
    long bytesPerImageRow = CGImageGetBytesPerRow((CGImageRef)imageRef);
    long numCalculatedChannels = bytesPerImageRow / width / dataSizeForType(mDataType);
    if ( numCalculatedChannels == 3 )
    {
        uint8_t *newRawData = createFourChannelFromThreeChannel( ivec2(width, height), mDataType, rawData);
        free( rawData );
        rawData = newRawData;
    }
    
    setPixelData(rawData);
    
    free(rawData);
    
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
//    [commandBuffer addCompletedHandler:^(id<MTLCommandBuffer> buffer) {
//        CI_LOG_I("Mipmapping Complete");
//    }];
    [commandBuffer commit];
}

void TextureBuffer::setPixelData( void *pixelBytes )
{
    ivec2 size = getSize();
    assert( size.x > 0 );
    assert( size.y > 0 );

    [IMPL replaceRegion:MTLRegionMake2D(0, 0, size.x, size.y)
            mipmapLevel:0
                  slice:0
              withBytes:pixelBytes
            bytesPerRow:mBytesPerRow
          bytesPerImage:mBytesPerRow * size.y];
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

int TextureBuffer::getUsage() // AKA MTLTextureUsage
{
    return (int)[IMPL usage];
}

// Not implemented
// rootResource

