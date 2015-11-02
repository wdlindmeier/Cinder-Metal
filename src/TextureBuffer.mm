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
            // Odd. MTLPixelFormat doesn't have a standard RGB w/out Alpha.
            // I guess it just ignores the alpha component...?
            // TODO: Investigate.
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
    CGImageRef imageRef  = cocoa::createCgImage( imageSource, ImageTarget::Options() );
    
    mBytesPerRow = CGImageGetBytesPerRow(imageRef);
    
    MTLPixelFormat pxFormat = (MTLPixelFormat)mFormat.pixelFormat;
    
    mChannelOrder = imageSource->getChannelOrder();
    mDataType = imageSource->getDataType();
    mColorModel = imageSource->getColorModel();
    
    if ( pxFormat == MTLPixelFormatInvalid )
    {
        pxFormat = mtlPixelFormatFromChannelOrder(mChannelOrder, mDataType);
        mFormat.pixelFormat = pxFormat;
    }

    // Get the image
    NSUInteger width = CGImageGetWidth(imageRef);
    NSUInteger height = CGImageGetHeight(imageRef);
    CFDataRef imgData = CGDataProviderCopyData( CGImageGetDataProvider(imageRef) );
    uint8_t *rawData = (uint8_t *) CFDataGetBytePtr(imgData);
    
    CI_LOG_I("TODO: Account for non 2D textures.");
    assert( format.textureType == MTLTextureType2D );
    MTLTextureDescriptor *desc = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:pxFormat
                                                                                    width:width
                                                                                   height:height
                                                                                mipmapped:mFormat.mipmapLevel > 1];
    desc.mipmapLevelCount = mFormat.mipmapLevel;
    desc.sampleCount = format.sampleCount;

    mImpl = (__bridge_retained void *)[[RendererMetalImpl sharedRenderer].device newTextureWithDescriptor:desc];
    
    setPixelData(rawData);
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

//#pragma mark - Image Target subclass
//
//void * TextureBuffer::getRowPointer( int32_t row )
//{
//    size_t rowLength = getWidth() * mFormat.numChannels * mDataSize;
//    //return mDataBuffer.get() + rowLength * row;
//    return mDataBuffer + rowLength * row;
//}
//
//// Do I have to do this?
//// void TextureBuffer::setRow( int32_t row, const void *data )
//// {
////     mCpy
//// }
//
//void TextureBuffer::finalize()
//{
//    assert( mDataBuffer != NULL );
//    //setPixelData( mDataBuffer.get() );
//    setPixelData( mDataBuffer );
//    free(mDataBuffer);
////    mDataBuffer = NULL;
//}
//

#pragma mark - Setting Data

//
//void TextureBuffer::update( SurfaceRef surface )
//{
////    assert( mDataSize == dataSizeForType( imageSource->getDataType() ) );
////    assert( mDataBuffer == NULL );
//    
////    auto surfRef = Surface::create(imageSource);
//    setPixelData( surface->getData() );
//
////    // We're temporarily storing the data in a buffer, because the memory layout
////    // of the MTLTexture isn't exposed to us. Once we store it, we'll
////    // pass the buffer into setPixelData and then free it.
////    // This may be inefficient since the data might already exist in a buffer if
////    // it's in a Channel or Surface, but we want to handle it in a generic way.
////    size_t rowBytes = getWidth() * mFormat.numChannels * mDataSize;
////    mDataBuffer = new uint8_t[rowBytes * getHeight()];
////    //mDataBuffer = unique_ptr<uint8_t[]>( new uint8_t[rowBytes * getHeight()] );
////    
////
////    auto ptr = std::shared_ptr<ImageTarget>( this, [](TextureBuffer*){} );
////    //imageSource->load( ImageTargetRef( ptr ) );
////    imageSource->load( shared_from_this() );//ImageTargetRef( shared_from_this() ) );
//}
//
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

// Unimplemented for now

//mipmapLevelCount
//arrayLength
//sampleCount
//framebufferOnly
//rootResource
//usage
