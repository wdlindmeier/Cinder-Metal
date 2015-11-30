//
//  ImageHelpers.m
//  ParticleSorting
//
//  Created by William Lindmeier on 11/27/15.
//
//

#include "RendererMetalImpl.h"
#include "cinder/Cinder.h"
#include "cinder/Log.h"
#include "cinder/cocoa/CinderCocoa.h"
#include "ImageHelpers.h"

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

MTLPixelFormat mtlPixelFormatFromChannelOrder( ImageIo::ChannelOrder channelOrder,
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

ImageIo::ChannelOrder ciChannelOrderFromMtlPixelFormat( MTLPixelFormat pixelFormat )
{
    switch( pixelFormat )
    {
        case MTLPixelFormatRGBA8Unorm:
        case MTLPixelFormatRGBA16Unorm:
        case MTLPixelFormatRGBA16Float:
        case MTLPixelFormatRGBA32Float:
            return ImageIo::RGBA;
            break;
        case MTLPixelFormatBGRA8Unorm:
            return ImageIo::BGRA;
            break;
        case MTLPixelFormatR8Unorm:
        case MTLPixelFormatR16Unorm:
        case MTLPixelFormatR16Float:
        case MTLPixelFormatR32Float:
            return ImageIo::Y;
            break;
        case MTLPixelFormatRG8Unorm:
        case MTLPixelFormatRG16Unorm:
        case MTLPixelFormatRG16Float:
        case MTLPixelFormatRG32Float:
            return ImageIo::YA;
            break;
        default:
            CI_LOG_E("Don't know how to convert pixel format " << pixelFormat << " into ImageIo::ChannelOrder");
            assert(false);
    }
}

ImageIo::DataType ciDataTypeFromMtlPixelFormat( MTLPixelFormat pixelFormat )
{
    switch( pixelFormat )
    {
        case MTLPixelFormatRGBA8Unorm:
        case MTLPixelFormatBGRA8Unorm:
        case MTLPixelFormatR8Unorm:
        case MTLPixelFormatRG8Unorm:
        case MTLPixelFormatRGBA8Sint:
        case MTLPixelFormatRGBA8Uint:
        case MTLPixelFormatRGBA8Snorm:
        case MTLPixelFormatRGBA8Unorm_sRGB:
            return ImageIo::UINT8;
            break;
        case MTLPixelFormatRGBA16Unorm:
        case MTLPixelFormatR16Unorm:
        case MTLPixelFormatRG16Unorm:
        case MTLPixelFormatRGBA16Sint:
        case MTLPixelFormatRGBA16Uint:
        case MTLPixelFormatRGBA16Snorm:
            return ImageIo::UINT16;
            break;
        case MTLPixelFormatRGBA16Float:
        case MTLPixelFormatR16Float:
        case MTLPixelFormatRG16Float:
            return ImageIo::FLOAT16;
            break;
        case MTLPixelFormatRGBA32Float:
        case MTLPixelFormatR32Float:
        case MTLPixelFormatRG32Float:
            return ImageIo::FLOAT32;
            break;
        default:
            // NOTE: This is not an exhaustive list—just the common formats.
            CI_LOG_E("Don't know how to convert pixel format " << pixelFormat << " into ImageIo::DataType");
            assert(false);
    }
}


ImageSourceTextureBuffer::ImageSourceTextureBuffer( TextureBuffer & texture )
: ImageSourceMTLTexture( ( __bridge id <MTLTexture> )texture.getNative() )
{
    setChannelOrder( texture.mChannelOrder );
    setColorModel( texture.mColorModel );
    setDataType( texture.mDataType );
}
        
ImageSourceMTLTexture::ImageSourceMTLTexture( id <MTLTexture> texture )
: ImageSource()
,mTexture(texture)
{
    mWidth = (int)texture.width;
    mHeight = (int)texture.height;

    MTLPixelFormat pxFormat = texture.pixelFormat;
    ImageIo::ChannelOrder chanOrder = ciChannelOrderFromMtlPixelFormat(pxFormat);
    setChannelOrder( chanOrder );
    setColorModel( ImageIo::CM_RGB );
    ImageIo::DataType dataType = ciDataTypeFromMtlPixelFormat(pxFormat);
    setDataType( dataType );

    int dataSize = dataSizeForType(mDataType);
    mRowBytes = mWidth * ImageIo::channelOrderNumChannels( mChannelOrder ) * dataSize;
}
    
void ImageSourceMTLTexture::getPixelData()
{
    mData = unique_ptr<uint8_t[]>( new uint8_t[mRowBytes * mHeight] );

    [mTexture getBytes:mData.get()
           bytesPerRow:mRowBytes
         bytesPerImage:mRowBytes * mTexture.height
            fromRegion:MTLRegionMake2D(0, 0, mTexture.width, mTexture.height)
           mipmapLevel:0
                 slice:0];
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
    
}} // cinder mtl

