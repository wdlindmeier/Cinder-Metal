//
//  ImageHelpers.m
//
//  Created by William Lindmeier on 11/27/15.
//
//

#include "RendererMetalImpl.h"
#include "cinder/Cinder.h"
#include "cinder/Log.h"
#include "cinder/cocoa/CinderCocoa.h"
#include "ImageHelpers.h"
#include "Scope.h"

using namespace std;
using namespace cinder;
using namespace cinder::mtl;

namespace cinder { namespace mtl {

int dataSizeForType( ImageIo::DataType dataType )
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
uint8_t* createFourChannelFromThreeChannel(ivec2 imageSize,
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

PixelFormat pixelFormatFromChannelOrder( ImageIo::ChannelOrder channelOrder,
                                         ImageIo::DataType dataType )
{
    switch (channelOrder)
    {
        case ImageIo::RGBA:
            switch (dataType)
        {
            case ImageIo::UINT8:
                return PixelFormatRGBA8Unorm;
            case ImageIo::UINT16:
                return PixelFormatRGBA16Unorm;
            case ImageIo::FLOAT16:
                return PixelFormatRGBA16Float;
            case ImageIo::FLOAT32:
                return PixelFormatRGBA32Float;
            default:
                return PixelFormatInvalid;
        }
        case ImageIo::BGRA:
            return PixelFormatBGRA8Unorm;
        case ImageIo::RGBX:
            switch (dataType)
        {
            case ImageIo::UINT8:
                return PixelFormatRGBA8Unorm;
            case ImageIo::UINT16:
                return PixelFormatRGBA16Unorm;
            case ImageIo::FLOAT16:
                return PixelFormatRGBA16Float;
            case ImageIo::FLOAT32:
                return PixelFormatRGBA32Float;
            default:
                return PixelFormatInvalid;
        }
        case ImageIo::BGRX:
            return PixelFormatBGRA8Unorm;
        case ImageIo::RGB:
            // NOTE: MTLPixelFormat doesn't have a standard RGB w/out Alpha.
            // We need to use a 4-component format and add an additional channel to the data.
            switch (dataType)
        {
            case ImageIo::UINT8:
                return PixelFormatRGBA8Unorm;
            case ImageIo::UINT16:
                return PixelFormatRGBA16Unorm;
            case ImageIo::FLOAT16:
                return PixelFormatRGBA16Float;
            case ImageIo::FLOAT32:
                return PixelFormatRGBA32Float;
            default:
                return PixelFormatInvalid;
        }
        case ImageIo::BGR:
            return PixelFormatBGRA8Unorm;
        case ImageIo::Y:
            switch (dataType)
        {
            case ImageIo::UINT8:
                return PixelFormatR8Unorm;
            case ImageIo::UINT16:
                return PixelFormatR16Unorm;
            case ImageIo::FLOAT16:
                return PixelFormatR16Float;
            case ImageIo::FLOAT32:
                return PixelFormatR32Float;
            default:
                return PixelFormatInvalid;
        }
        case ImageIo::YA:
            switch (dataType)
        {
            case ImageIo::UINT8:
                return PixelFormatRG8Unorm;
            case ImageIo::UINT16:
                return PixelFormatRG16Unorm;
            case ImageIo::FLOAT16:
                return PixelFormatRG16Float;
            case ImageIo::FLOAT32:
                return PixelFormatRG32Float;
            default:
                return PixelFormatInvalid;
        }
        default:
            CI_LOG_E("Don't know how to convert channel order " << channelOrder << " into PixelFormat");
            assert(false);
    }
}

ImageIo::ChannelOrder channelOrderFromPixelFormat( PixelFormat pixelFormat )
{
    switch( pixelFormat )
    {
        case PixelFormatRGBA8Unorm:
        case PixelFormatRGBA16Unorm:
        case PixelFormatRGBA16Float:
        case PixelFormatRGBA32Float:
            return ImageIo::RGBA;
            break;
        case PixelFormatBGRA8Unorm:
            return ImageIo::BGRA;
            break;
        case PixelFormatR8Unorm:
        case PixelFormatR16Unorm:
        case PixelFormatR16Float:
        case PixelFormatR32Float:
            return ImageIo::Y;
            break;
        case PixelFormatRG8Unorm:
        case PixelFormatRG16Unorm:
        case PixelFormatRG16Float:
        case PixelFormatRG32Float:
            return ImageIo::YA;
            break;
        default:
            CI_LOG_E("Don't know how to convert pixel format " << pixelFormat << " into ImageIo::ChannelOrder");
            assert(false);
    }
}

int channelCountFromPixelFormat( PixelFormat pixelFormat )
{
    switch( pixelFormat )
    {
        case PixelFormatRGBA8Unorm:
        case PixelFormatRGBA16Unorm:
        case PixelFormatRGBA16Float:
        case PixelFormatRGBA32Float:
        case PixelFormatBGRA8Unorm:
            return 4;
            break;
        case PixelFormatRG8Unorm:
        case PixelFormatRG16Unorm:
        case PixelFormatRG16Float:
        case PixelFormatRG32Float:
            return 2;
            break;
        case PixelFormatR8Unorm:
        case PixelFormatR16Unorm:
        case PixelFormatR16Float:
        case PixelFormatR32Float:
        case PixelFormatDepth32Float:
            return 1;
            break;
        default:
            // TODO: Add more switch cases
            CI_LOG_E("Don't know how to get channel count from pixel format " << pixelFormat );
            assert(false);
    }
    return -1;
}

    
ImageIo::ColorModel colorModelFromPixelFormat( PixelFormat pixelFormat )
{
    switch( pixelFormat )
    {
        case PixelFormatRGBA8Unorm:
        case PixelFormatRGBA16Unorm:
        case PixelFormatRGBA16Float:
        case PixelFormatRGBA32Float:
        case PixelFormatBGRA8Unorm:
            return ImageIo::CM_RGB;
            break;
        case PixelFormatR8Unorm:
        case PixelFormatR16Unorm:
        case PixelFormatR16Float:
        case PixelFormatR32Float:
            return ImageIo::CM_GRAY;
            break;
        default:
            CI_LOG_E("Don't know how to convert pixel format " << pixelFormat << " into ImageIo::ColorModel");
            return ImageIo::CM_UNKNOWN;
    }
}

ImageIo::DataType dataTypeFromPixelFormat( PixelFormat pixelFormat )
{
    switch( pixelFormat )
    {
        case PixelFormatRGBA8Unorm:
        case PixelFormatBGRA8Unorm:
        case PixelFormatR8Unorm:
        case PixelFormatRG8Unorm:
        case PixelFormatRGBA8Sint:
        case PixelFormatRGBA8Uint:
        case PixelFormatRGBA8Snorm:
        case PixelFormatRGBA8Unorm_sRGB:
            return ImageIo::UINT8;
            break;
        case PixelFormatRGBA16Unorm:
        case PixelFormatR16Unorm:
        case PixelFormatRG16Unorm:
        case PixelFormatRGBA16Sint:
        case PixelFormatRGBA16Uint:
        case PixelFormatRGBA16Snorm:
            return ImageIo::UINT16;
            break;
        case PixelFormatRGBA16Float:
        case PixelFormatR16Float:
        case PixelFormatRG16Float:
            return ImageIo::FLOAT16;
            break;
        case PixelFormatRGBA32Float:
        case PixelFormatR32Float:
        case PixelFormatRG32Float:
        case PixelFormatDepth32Float:
            return ImageIo::FLOAT32;
            break;
        default:
            // NOTE: This is not an exhaustive list—just the common formats.
            CI_LOG_E("Don't know how to convert pixel format " << pixelFormat << " into ImageIo::DataType");
            assert(false);
    }
}


ImageSourceTextureBuffer::ImageSourceTextureBuffer( TextureBuffer & texture, int slice, int mipmapLevel )
: ImageSourceMTLTexture( texture.getNative(), slice, mipmapLevel )
{
    //...
}
        
ImageSourceMTLTexture::ImageSourceMTLTexture( void *texture, int slice, int mipmapLevel )
: ImageSource()
,mTexture(texture)
,mSlice(slice)
,mMipmapLevel(mipmapLevel)
{
    assert( [(__bridge id)mTexture conformsToProtocol:@protocol(MTLTexture)] );
    mWidth = (int)((__bridge id <MTLTexture>)mTexture).width;
    mHeight = (int)((__bridge id <MTLTexture>)mTexture).height;

    MTLPixelFormat pxFormat = ((__bridge id <MTLTexture>)mTexture).pixelFormat;
    ImageIo::ChannelOrder chanOrder = channelOrderFromPixelFormat((PixelFormat)pxFormat);
    setChannelOrder( chanOrder );
    setColorModel( ImageIo::CM_RGB );
    ImageIo::DataType dataType = dataTypeFromPixelFormat((PixelFormat)pxFormat);
    setDataType( dataType );

    int dataSize = dataSizeForType(mDataType);
    mRowBytes = mWidth * ImageIo::channelOrderNumChannels( mChannelOrder ) * dataSize;
}
    
void ImageSourceMTLTexture::getPixelData()
{
    mData = unique_ptr<uint8_t[]>( new uint8_t[mRowBytes * mHeight] );

    id <MTLTexture> texture = ((__bridge id <MTLTexture>)mTexture);
    [texture getBytes:mData.get()
          bytesPerRow:mRowBytes
        bytesPerImage:mRowBytes * texture.height
           fromRegion:MTLRegionMake2D(0, 0, texture.width, texture.height)
          mipmapLevel:mMipmapLevel
                slice:mSlice];
}

void ImageSourceMTLTexture::load( ImageTargetRef target )
{
    getPixelData();
    
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

void copyTexture( TextureBufferRef & from, TextureBufferRef & to, int fromIndex, int toIndex )
{
	mtl::ScopedCommandBuffer commandBuffer(true);
	mtl::ScopedBlitEncoder blitEncoder = commandBuffer.scopedBlitEncoder();

	ivec2 textureSize = from->getSize();
	blitEncoder.copyFromTextureToTexture(from,
										 fromIndex,
										 0,
										 ivec3(0),
										 ivec3(textureSize.x, textureSize.y, 1),
										 to,
										 toIndex,
										 0,
										 ivec3(0));
}
    
}} // cinder mtl

