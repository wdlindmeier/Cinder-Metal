//
//  Buffer.hpp
//  MetalCube
//
//  Created by William Lindmeier on 10/17/15.
//
//

#pragma once

#include "cinder/Cinder.h"

#if defined( __OBJC__ )
@class BufferImpl;
#else
class BufferImpl;
#endif

namespace cinder { namespace mtl {
    
    class Buffer;
    
    typedef std::shared_ptr<class Buffer> BufferRef;
    
    class Buffer
    {
        
        friend class RenderEncoder;
        
    public:
        
        // Data stored at pointer will be copied into the buffer
        // static BufferRef create( unsigned long length, const void * pointer, const std::string & label );
        static BufferRef create( unsigned long length, const void * pointer, const std::string & label = "Vert Buffer" ){
            return BufferRef( new mtl::Buffer(length, pointer, label) );
        }
        
        template <typename T>
        static BufferRef create( const std::vector<T> & dataVector, const std::string & label = "Vert Buffer" ){
            return BufferRef( new Buffer(dataVector, label) );
        }
        
        virtual ~Buffer(){};
        
        void * contents();
        
        template <typename T>
        void update( const T * newData, const size_t lengthBytes, const size_t offsetBytes = 0 )
        {
            uint8_t *bufferPointer = (uint8_t *)this->contents() + offsetBytes;
            memcpy( bufferPointer, newData, lengthBytes );
        }
        
        template <typename T>
        void update( const std::vector<T> & vectorData )
        {
            update(vectorData.data(), sizeof(T) * vectorData.size());
        }

        template <typename BufferType>
        void setData(BufferType *data, int inflightBufferIndex )
        {
            uint8_t *bufferPointer = (uint8_t *)this->contents() + (sizeof(BufferType) * inflightBufferIndex);
            memcpy(bufferPointer, data, sizeof(BufferType));
        }

    protected:
        
        Buffer( unsigned long length, const void * pointer, const std::string & label );
        
        template <typename T>
        Buffer( const std::vector<T> & dataVector, const std::string & label );

        BufferImpl *mImpl;
        
    };
    
} }