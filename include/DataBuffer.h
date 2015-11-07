//
//  Buffer.hpp
//  MetalCube
//
//  Created by William Lindmeier on 10/17/15.
//
//

#pragma once

#include "cinder/Cinder.h"

//#if defined( __OBJC__ )
//@class DataBufferImpl;
//#else
//class DataBufferImpl;
//#endif

namespace cinder { namespace mtl {
    
    typedef std::shared_ptr<class DataBuffer> DataBufferRef;
    
    class DataBuffer
    {
        
        // friend class RenderEncoder;
        
    public:
        
        // Data stored at pointer will be copied into the buffer
        // static DataBufferRef create( unsigned long length, const void * pointer, const std::string & label );
        static DataBufferRef create( unsigned long length, const void * pointer, const std::string & label = "Default Vert Buffer" ){
            return DataBufferRef( new DataBuffer(length, pointer, label) );
        }
        
        template <typename T>
        static DataBufferRef create( const std::vector<T> & dataVector, const std::string & label = "Default Vert Buffer" ){
            return DataBufferRef( new DataBuffer(dataVector, label) );
        }
        
        virtual ~DataBuffer();
        
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
                
        void * getNative(){ return mImpl; }

    protected:
        
        DataBuffer( unsigned long length, const void * pointer, const std::string & label );
        void init( unsigned long length, const void * pointer, const std::string & label );
        template <typename T>
        DataBuffer( const std::vector<T> & dataVector, const std::string & label );

        void * mImpl; // <MTLBuffer>
        
    };
    
} }