//
//  ImageHelpers.h
//  ParticleSorting
//
//  Created by William Lindmeier on 11/27/15.
//
//

#pragma once

#include "cinder/Cinder.h"
#include "MetalEnums.h"

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
    
    ImageSourceMTLTexture( void * mtlTexture ); // <MTLTexture>
    void load( ImageTargetRef target );
    
protected:

    void getPixelData();
    
    std::unique_ptr<uint8_t[]>	mData;
    int32_t						mRowBytes;
    void *                      mTexture; // <MTLTexture>
};
    
    
class ImageSourceTextureBuffer : public ImageSourceMTLTexture
{
public:
    
    ImageSourceTextureBuffer( TextureBuffer & texture );

};
    
}} // cinder mtl

