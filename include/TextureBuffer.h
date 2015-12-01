//
//  TextureBuffer.hpp
//  MetalCube
//
//  Created by William Lindmeier on 10/30/15.
//
//

#pragma once

#include "cinder/Cinder.h"
#include "cinder/ImageIo.h"
#include "MetalHelpers.hpp"

namespace cinder { namespace mtl {
    
    typedef std::shared_ptr<class TextureBuffer> TextureBufferRef;
    
    // http://metalbyexample.com/textures-and-samplers/
    
    class TextureBuffer
    {
        
        friend class ImageSourceTextureBuffer;
        
    public:
        
        struct Format
        {
            Format() :
            mMipmapLevel(1)
            ,mSampleCount(1)
            ,mTextureType(2) // defaults to MTLTextureType2D
            ,mPixelFormat(0) // defaults to MTLPixelFormatInvalid
            ,mDepth(1)
            ,mArrayLength(1)
            ,mUsage(0) // defaults to MTLTextureUsageUnknown
            {};
            
            FORMAT_OPTION(mipmapLevel, MipmapLevel, int)
            FORMAT_OPTION(sampleCount, SampleCount, int)
            FORMAT_OPTION(textureType, TextureType, int) // MTLTextureType
            FORMAT_OPTION(pixelFormat, PixelFormat, int) // MTLPixelFormat
            FORMAT_OPTION(depth, Depth, int)
            FORMAT_OPTION(arrayLength, ArrayLength, int)
            FORMAT_OPTION(usage, Usage, int)
        };
        
        static TextureBufferRef create( ImageSourceRef imageSource, Format format = Format() )
        {
            return TextureBufferRef( new TextureBuffer(imageSource, format) );
        }

        virtual ~TextureBuffer();

        void update( ImageSourceRef imageSource );
        void setPixelData( void *pixelBytes );
        
        // Getting Data
        void getPixelData( void *pixelBytes );
        ci::ImageSourceRef createSource();

        // Accessors
        Format      getFormat() const;
        long		getWidth() const;
        long		getHeight() const;
        long		getDepth() const;
        ci::ivec2	getSize() const { return ivec2( getWidth(), getHeight() ); }
        long        getMipmapLevelCount();
        long        getSampleCount();
        long        getArrayLength();
        bool        getFramebufferOnly();
        int         getUsage(); // <MTLTextureUsage>
        
        void *      getNative(){ return mImpl; };

    protected:

        TextureBuffer( ImageSourceRef imageSource,
                       Format format );

        void updateWidthCGImage( void * );
        void generateMipmap();
        
        void *mImpl = NULL; // <MTLTexture>
        long mBytesPerRow;
        Format mFormat;
        
        ImageIo::ChannelOrder mChannelOrder;
        ImageIo::ColorModel mColorModel;
        ImageIo::DataType mDataType;

    };
    
} }