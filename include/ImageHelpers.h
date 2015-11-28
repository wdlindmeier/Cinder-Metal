//
//  ImageHelpers.h
//  ParticleSorting
//
//  Created by William Lindmeier on 11/27/15.
//
//

#pragma once

#include "cinder/Cinder.h"

using namespace std;
using namespace cinder;
using namespace cinder::mtl;

namespace cinder { namespace mtl {

    
extern int dataSizeForType( ImageIo::DataType dataType );

extern uint8_t* createFourChannelFromThreeChannel(ivec2 imageSize,
                                                         ImageIo::DataType dataType,
                                                         const uint8_t* rgbData );

extern MTLPixelFormat mtlPixelFormatFromChannelOrder( ImageIo::ChannelOrder channelOrder,
                                                            ImageIo::DataType dataType );

extern ImageIo::ChannelOrder ciChannelOrderFromMtlPixelFormat( MTLPixelFormat pixelFormat );

extern ImageIo::DataType ciDataTypeFromMtlPixelFormat( MTLPixelFormat pixelFormat );

    
class ImageSourceMTLTexture : public ImageSource
{    
public:
    
    ImageSourceMTLTexture( id <MTLTexture> texture );
    void load( ImageTargetRef target );
    
protected:

    void getPixelData();
    
    std::unique_ptr<uint8_t[]>	mData;
    int32_t						mRowBytes;
    id <MTLTexture>             mTexture;
};
    
    
class ImageSourceTextureBuffer : public ImageSourceMTLTexture
{
public:
    
    ImageSourceTextureBuffer( TextureBuffer & texture );

};
    
}} // cinder mtl

