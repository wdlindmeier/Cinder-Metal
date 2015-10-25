//
//  MetalBuffer.hpp
//  MetalCube
//
//  Created by William Lindmeier on 10/17/15.
//
//

#pragma once

#include "cinder/Cinder.h"

#if defined( __OBJC__ )
@class MetalBufferImpl;
#else
class MetalBufferImpl;
#endif

namespace cinder { namespace mtl {
    
    typedef std::shared_ptr<class MetalBuffer> MetalBufferRef;
    
    class MetalBuffer// : public ci::geom::Target
    {
        
        friend class MetalRenderEncoder;
        
    public:
        
        static MetalBufferRef create( unsigned long length, const void * pointer, const std::string & label );
//        static MetalBufferRef create( const ci::geom::Source & source );
        virtual ~MetalBuffer(){};
        
        void * contents();
        
        template <typename BufferType>
        void setData(BufferType *data, int inflightBufferIndex )
        {
            uint8_t *bufferPointer = (uint8_t *)this->contents() + (sizeof(BufferType) * inflightBufferIndex);
            memcpy(bufferPointer, data, sizeof(BufferType));
        }
        
//        // geom::Target subclass
//        void copyAttrib( ci::geom::Attrib attr, uint8_t dims, size_t strideBytes, const float *srcData, size_t count );
//        void copyIndices( ci::geom::Primitive primitive, const uint32_t *source, size_t numIndices, uint8_t requiredBytesPerIndex );
//        uint8_t getAttribDims( ci::geom::Attrib attr ) const;
        
    protected:
        
        MetalBuffer( unsigned long length, const void * pointer, const std::string & label );
        MetalBufferImpl *mImpl;
        
    };
    
} }