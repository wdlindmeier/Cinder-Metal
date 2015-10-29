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
    
    //template <typename T>
    class MetalBuffer
    {
        
        friend class MetalRenderEncoder;
        
    public:
        
        // Data stored at pointer will be copied into the buffer
        // static MetalBufferRef create( unsigned long length, const void * pointer, const std::string & label );
        static MetalBufferRef create( unsigned long length, const void * pointer, const std::string & label = "Vert Buffer" ){
            return MetalBufferRef( new MetalBuffer(length, pointer, label) );
        }
        
        template <typename T>
        static MetalBufferRef create( const std::vector<T> & dataVector, const std::string & label = "Vert Buffer" ){
            return MetalBufferRef( new MetalBuffer(dataVector, label) );
        }
        
        virtual ~MetalBuffer(){};
        
        void * contents();
        
        template <typename BufferType>
        void setData(BufferType *data, int inflightBufferIndex )
        {
            uint8_t *bufferPointer = (uint8_t *)this->contents() + (sizeof(BufferType) * inflightBufferIndex);
            memcpy(bufferPointer, data, sizeof(BufferType));
        }

    protected:
        
        MetalBuffer( unsigned long length, const void * pointer, const std::string & label );
        
        template <typename T>
        MetalBuffer( const std::vector<T> & dataVector, const std::string & label );

        MetalBufferImpl *mImpl;
        
    };
    
} }