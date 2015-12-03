//
//  Buffer.hpp
//  MetalCube
//
//  Created by William Lindmeier on 10/17/15.
//
//

#pragma once

#include "cinder/Cinder.h"
#include "MetalHelpers.hpp"

namespace cinder { namespace mtl {
    
    typedef std::shared_ptr<class DataBuffer> DataBufferRef;
    
    class DataBuffer
    {

    public:
        
        struct Format
        {
            Format() :
            mStorageMode(-1) // defaults to MTLResourceStorageModeManaged
            ,mCacheMode(-1) // defaults to MTLResourceCPUCacheModeDefaultCache
            ,mLabel("Default Data Buffer")
            {};
            
            FORMAT_OPTION(storageMode, StorageMode, int)
            FORMAT_OPTION(cacheMode, CacheMode, int)
            FORMAT_OPTION(label, Label, std::string)
        };

        // Data stored at pointer will be copied into the buffer
        static DataBufferRef create( unsigned long length, const void * pointer, const Format & format = Format() )
        {
            return DataBufferRef( new DataBuffer(length, pointer, format) );
        }
        
        template <typename T>
        static DataBufferRef create( const std::vector<T> & dataVector, const Format & format = Format() )
        {
            return DataBufferRef( new DataBuffer(dataVector, format) );
        }
        
        virtual ~DataBuffer();
        
        // A pointer to the data
        void * contents();
        
        // Mark data changed
        void didModifyRange( size_t location, size_t length );
        
        template <typename T>
        void update( const T * newData, const size_t lengthBytes, const size_t offsetBytes = 0 )
        {
            uint8_t *bufferPointer = (uint8_t *)this->contents() + offsetBytes;
            memcpy( bufferPointer, newData, lengthBytes );
            didModifyRange(offsetBytes, lengthBytes);
        }
        
        template <typename T>
        void update( const std::vector<T> & vectorData, bool isConstant = false )
        {
            size_t length = sizeof(T) * vectorData.size();
            update(vectorData.data(), length);
        }
        
        template <typename BufferObjectType>
        void setDataAtIndex( BufferObjectType *dataObject, int inflightBufferIndex, bool isConstant )
        {
            size_t dataSize;
            if ( isConstant )
            {
                dataSize = mtlConstantSize(BufferObjectType);
            }
            else
            {
                dataSize = sizeof(BufferObjectType);
            }
            update( dataObject, sizeof(BufferObjectType), dataSize * inflightBufferIndex );
        }
                
        void * getNative(){ return mImpl; }

    protected:
        
        DataBuffer( unsigned long length, const void * pointer, Format format );
        void init( unsigned long length, const void * pointer, Format format );
        
        template <typename T>
        DataBuffer( const std::vector<T> & dataVector, Format format )
        {
            unsigned long vectorSize = sizeof(dataVector) + (sizeof(T) * dataVector.size());
            init(vectorSize, dataVector.data(), format);
        }

        void * mImpl = NULL; // <MTLBuffer>
        
    };
    
} }