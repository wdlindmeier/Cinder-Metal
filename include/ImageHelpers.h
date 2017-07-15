//
//  ImageHelpers.h
//
//  Created by William Lindmeier on 11/27/15.
//
//

#pragma once

#include "cinder/Cinder.h"
#include "MetalEnums.h"
#include "TextureBuffer.h"

namespace cinder { namespace mtl {
    
extern int dataSizeForType( ImageIo::DataType dataType );

extern uint8_t* createFourChannelFromThreeChannel( ivec2 imageSize,
                                                   ImageIo::DataType dataType,
                                                   const uint8_t* rgbData );

extern PixelFormat pixelFormatFromChannelOrder( ImageIo::ChannelOrder channelOrder,
                                                ImageIo::DataType dataType );

extern ImageIo::ChannelOrder channelOrderFromPixelFormat( PixelFormat pixelFormat );
    
extern int channelCountFromPixelFormat( PixelFormat pixelFormat );

extern ImageIo::ColorModel colorModelFromPixelFormat( PixelFormat pixelFormat );
    
extern ImageIo::DataType dataTypeFromPixelFormat( PixelFormat pixelFormat );
    
class ImageSourceMTLTexture : public ImageSource
{    
public:
    
    ImageSourceMTLTexture( void * mtlTexture, int slice = 0, int mipmapLevel = 0 ); // <MTLTexture>
    void load( ImageTargetRef target );
    
protected:

    void getPixelData();
    
    std::unique_ptr<uint8_t[]>	mData;
    int32_t						mRowBytes;
    int                         mSlice;
    int                         mMipmapLevel;
    void *                      mTexture; // <MTLTexture>
};
    
    
class ImageSourceTextureBuffer : public ImageSourceMTLTexture
{
public:
    
    ImageSourceTextureBuffer( TextureBuffer & texture, int slice = 0, int mipmapLevel = 0 );

};

void copyTexture( TextureBufferRef & from, TextureBufferRef & to, int fromIndex = 0, int toIndex = 0 );

}} // cinder mtl

