//
//  Argument.hpp
//
//  Created by William Lindmeier on 1/10/16.
//
//

#pragma once

#include "MetalEnums.h"

namespace cinder { namespace mtl {
    
    struct StructMember
    {
        std::string name;
        mtl::DataType dataType;
        unsigned long offset;
    };
    
    struct StructType
    {
        //std::map<std::string, mtl::StructMember> members;
        std::vector<mtl::StructMember> members;
    };

    struct Argument
    {
        Argument( void * mtlArgument );
        
        virtual ~Argument(){};
        
        void * getNative(){ return mImpl; }
        
        // General
        const std::string getName() const;
        mtl::ArgumentType getType() const;
        mtl::ArgumentAccess getAccess() const;
        unsigned long getIndex() const;
        bool isActive() const;

        // For buffer arguments
        unsigned long getBufferAlignment() const; // min alignment of starting offset in the buffer
        unsigned long getBufferDataSize() const;
        mtl::DataType  getBufferDataType() const;
        // NOTE: If the MTLStructType is nil, this will return a mtl::StructType with empty `members`
        mtl::StructType getBufferStructType();
        
        // For threadgroup memory arguments
        unsigned long getThreadgroupMemoryAlignment() const;
        unsigned long threadgroupMemoryDataSize() const;
        
        // For texture arguments
        mtl::TextureType getTextureType() const;
        mtl::DataType getTextureDataType() const;
        
    protected:

        void * mImpl = NULL; // MTLArgument *
        
        mtl::StructType mCachedStructType;
        
    };
    
} }