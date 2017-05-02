//
//  Buffer.hpp
//
//  Created by William Lindmeier on 10/17/15.
//
//

#pragma once

#include "cinder/Cinder.h"
#include "MetalHelpers.hpp"
#include "MetalEnums.h"

namespace cinder { namespace mtl {
    
    typedef std::shared_ptr<class DataBuffer> DataBufferRef;
    
    class DataBuffer
    {

    public:
        
        struct Format
        {
            Format() :
#if defined( CINDER_COCOA_TOUCH )
            mStorageMode( StorageModeShared )
#else
            // NOTE: On OS X, programs run faster in "Shared" mode when using the integrated GPU,
            // and faster in "Managed" mode when using the descreet GPU.
            mStorageMode( StorageModeManaged )
#endif
            ,mCacheMode( CPUCacheModeDefaultCache )
            ,mLabel("Default Data Buffer")
            ,mIsConstant(false) // used when measuring data allocation. Verts should be `false`, uniforms should be `true`.
            {};

        public:

            Format& storageMode( StorageMode storageMode ) { setStorageMode( storageMode ); return *this; };
            void setStorageMode( StorageMode storageMode ) { mStorageMode = storageMode; };
            StorageMode getStorageMode() const { return mStorageMode; };

            Format& cacheMode( CPUCacheMode cacheMode ) { setCacheMode( cacheMode ); return *this; };
            void setCacheMode( CPUCacheMode cacheMode ) { mCacheMode = cacheMode; };
            CPUCacheMode getCacheMode() const { return mCacheMode; };

            Format& label( std::string label ) { setLabel( label ); return *this; };
            void setLabel( std::string label ) { mLabel = label; };
            std::string getLabel() const { return mLabel; };

            Format& isConstant( bool isConstant = true ) { setIsConstant( isConstant ); return *this; };
            void setIsConstant( bool isConstant ) { mIsConstant = isConstant; };
            bool getIsConstant() const { return mIsConstant; };

        protected:
            
            StorageMode mStorageMode;
            CPUCacheMode mCacheMode;
            std::string mLabel;
            bool mIsConstant;
        };

        // Data stored at pointer will be copied into the buffer
        static DataBufferRef create( unsigned long length, const void * pointer, const Format & format = Format() )
        {
            return DataBufferRef( new DataBuffer(length, pointer, format) );
        }
        
        // Create with a native MTLBuffer
        static DataBufferRef create( void * mtlDataBuffer )
        {
            return DataBufferRef( new DataBuffer( mtlDataBuffer ) );
        }
        
        template <typename T>
        static DataBufferRef create( const std::vector<T> & dataVector, const Format & format = Format() )
        {
            return DataBufferRef( new DataBuffer(dataVector, format) );
        }
        
        virtual ~DataBuffer();
        
        // A pointer to the data
        void * contents();

        size_t getLength();
        
        // Mark data changed.
        // NOTE: Only relevant to Managed storage on OS X
        void didModifyRange( size_t location, size_t length );
        
        template <typename T>
        void update( const T * newData, const size_t lengthBytes, const size_t offsetBytes = 0 )
        {
            uint8_t *bufferPointer = (uint8_t *)this->contents() + offsetBytes;
            memcpy( bufferPointer, newData, lengthBytes );
            didModifyRange(offsetBytes, lengthBytes);
        }
        
        template <typename T>
        void update( const std::vector<T> & vectorData, const size_t offsetBytes = 0 )
        {
            size_t length = sizeof(T) * vectorData.size();
            if ( mFormat.getIsConstant() )
            {
                length = mtlConstantBufferSize(length);
            }
            update(vectorData.data(), length, offsetBytes);
        }
        
        template <typename BufferObjectType>
        void setDataAtIndex( BufferObjectType *dataObject, int inflightBufferIndex )
        {
            size_t dataSize = sizeof(BufferObjectType);
            if ( mFormat.getIsConstant() )
            {
                dataSize = mtlConstantBufferSize(dataSize);
            }
            update( dataObject, dataSize, dataSize * inflightBufferIndex );
        }
                
        void * getNative(){ return mImpl; }

    protected:
        
        DataBuffer( unsigned long length, const void * pointer, Format format );
        DataBuffer( void *mtlDataBuffer );
        void init( unsigned long length, const void * pointer, Format format );
        
        template <typename T>
        DataBuffer( const std::vector<T> & dataVector, Format format )
        {
            size_t dataSize = sizeof(T) * dataVector.size();
            if ( format.getIsConstant() )
            {
                dataSize = mtlConstantBufferSize(dataSize);
            }
            init(dataSize, dataVector.data(), format);
        }

        void * mImpl = NULL; // <MTLBuffer>
        Format mFormat;
        
    };
    
} }