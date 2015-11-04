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
        
        struct Format // Maps to MTLTextureDescriptor
        {
            Format() :
            mMipmapLevel(1), mSampleCount(1), mTextureType(2), mPixelFormat(0)
            {};
            
            Format& mipmapLevel( int mipmapLevel ) { setMipmapLevel( mipmapLevel ); return *this; }
            Format& sampleCount( int sampleCount ) { setSampleCount( sampleCount ); return *this; }
            // MTLTextureType (defaults to MTLTextureType2D)
            Format& textureType( int textureType ) { setTextureType( textureType ); return *this; }
            // MTLPixelFormat (defaults to MTLPixelFormatInvalid)
            Format& pixelFormat( int pixelFormat ) { setPixelFormat( pixelFormat ); return *this; }

            void setMipmapLevel( int mipmapLevel ) { mMipmapLevel = mipmapLevel; }
            void setSampleCount( int sampleCount ) { mSampleCount = sampleCount; }
            void setTextureType( int textureType ) { mTextureType = textureType; }
            void setPixelFormat( int pixelFormat ) { mPixelFormat = pixelFormat; }

            int getMipmapLevel() { return mMipmapLevel; }
            int getSampleCount() { return mSampleCount; }
            int getTextureType() { return mTextureType; }
            int getPixelFormat() { return mPixelFormat; }

        protected:
            
            int mMipmapLevel;
            int mSampleCount;
            int mTextureType;
            int mPixelFormat;
        };
        
        static TextureBufferRef create( ImageSourceRef imageSource, Format format = Format() )
        {
            return TextureBufferRef( new TextureBuffer(imageSource, format) );
        }

        virtual ~TextureBuffer()
        {}

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
        int         getUsage(); // return type is MTLTextureUsage

    protected:

        TextureBuffer( ImageSourceRef imageSource,
                       Format format );

        void updateWidthCGImage( void * );
        void generateMipmap();
        
        void *mImpl; // <MTLTexture>
        long mBytesPerRow;
        Format mFormat;
        
        ImageIo::ChannelOrder mChannelOrder;
        ImageIo::ColorModel mColorModel;
        ImageIo::DataType mDataType;
        
//        // TMP
//        // Testing mipmaps
//        void * createResizedImageDataForImage( CGImageRef image,
//                                               CGSize size,
//                                               void *tintColor,
//                                               CGImageRef *outImage );
//        void * generateTintedMipmapsForTexture( void *texture,
//                                                CGImageRef image);
//        void * tintColorAtIndex( size_t index );
//
    };
    
} }