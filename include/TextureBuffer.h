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
//#include <boost/enable_shared_from_this.hpp>

namespace cinder { namespace mtl {
    
    typedef std::shared_ptr<class TextureBuffer> TextureBufferRef;
    
    // http://metalbyexample.com/textures-and-samplers/
    
    class TextureBuffer
    {
        
        friend class RenderEncoder;
        friend class ImageSourceMTLTexture;
        
    public:
        
        class Format // Maps to MTLTextureDescriptor
        {
        public:
            Format(){};
            int mipmapLevel = 1;
            int sampleCount = 1;
            int textureType = 2; // MTLTextureType (defaults to MTLTextureType2D)
            int pixelFormat = 0; // MTLPixelFormat (defaults to MTLPixelFormatInvalid)
//            const ImageIo::ChannelOrder channelOrder = ImageIo::RGBA;
//            const ImageIo::ColorModel colorModel = ImageIo::CM_RGB;
//            const ImageIo::DataType dataType = ImageIo::UINT8;
        };
        
        static TextureBufferRef create( ImageSourceRef imageSource, Format format = Format() )
        {
            return TextureBufferRef( new TextureBuffer(imageSource, format) );
        }

        virtual ~TextureBuffer()
        {}

//        void update( SurfaceRef surface );
        void setPixelData( void *pixelBytes );
        
        // Getting Data
        void getPixelData( void *pixelBytes );
        ci::ImageSourceRef	createSource();

        // Accessors
        Format      getFormat() const;
        long		getWidth() const;
        long		getHeight() const;
        long		getDepth() const;
        ci::ivec2	getSize() const { return ivec2( getWidth(), getHeight() ); }

    protected:

        TextureBuffer( ImageSourceRef imageSource,
                       Format format );

        void *mImpl; // <MTLTexture>
        long mBytesPerRow;
        Format mFormat;
        
        ImageIo::ChannelOrder mChannelOrder;
        ImageIo::ColorModel mColorModel;
        ImageIo::DataType mDataType;

    };
    
} }