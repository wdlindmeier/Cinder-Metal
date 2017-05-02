//
//  BlitEncoder.hpp
//
//  Created by William Lindmeier on 10/17/15.
//
//

#pragma once

#include "cinder/Cinder.h"
#include "TextureBuffer.h"
#include "DataBuffer.h"

namespace cinder { namespace mtl {
    
    typedef std::shared_ptr<class BlitEncoder> BlitEncoderRef;
    
    class BlitEncoder
    {

    public:

        // NOTE:
        // Generally BlitEncoders should be created via the CommandBuffer
        // using CommandBuffer::createBlitEncoder.
        static BlitEncoderRef create( void * mtlBlitCommandEncoder );
        
        virtual ~BlitEncoder();
        
        void * getNative(){ return mImpl; }
        
        void endEncoding();
#if !defined( CINDER_COCOA_TOUCH )
        void synchronizeResource( void * mtlResource ); // MTLResource
        
        void synchronizeTexture( const TextureBufferRef & texture, uint slice, uint level);
#endif
        void copyFromTextureToTexture(const TextureBufferRef & sourceTexture, uint sourceSlice, uint sourceLevel, ivec3 sourceOrigin, ivec3 sourceSize, TextureBufferRef & destTexture, uint destSlice, uint destLevel, ivec3 destOrigin);

        void copyFromBufferToTexture( const DataBufferRef & sourceBuffer, uint sourceOffset, uint sourceBytesPerRow, uint sourceBytesPerImage, ivec3 sourceSize, TextureBufferRef & destTexture, uint destSlice, uint destLevel, ivec3 destOrigin, BlitOption options = BlitOptionNone );

        void copyFromTextureToBuffer( const TextureBufferRef & sourceTexture, uint sourceSlice, uint sourceLevel, ivec3 sourceOrigin, ivec3 sourceSize, const DataBufferRef & destinationBuffer, uint destinationOffset, uint destinationBytesPerRow, uint destinationBytesPerImage, BlitOption options = BlitOptionNone );

        void generateMipmapsForTexture( const TextureBufferRef & texture );

        void fillBuffer( DataBufferRef buffer, uint8_t value, uint length, uint offset = 0 );

        void copyFromBufferToBuffer( DataBufferRef & sourceBuffer, uint sourceOffset, DataBufferRef & destBuffer, uint destOffset, uint length);

    protected:
        
        BlitEncoder( void * mtlBlitCommandEncoder );
        
        void * mImpl = NULL; // <MTLBlitCommandEncoder>
        
    };
    
} }