//
//  Argument.cpp
//
//  Created by William Lindmeier on 1/10/16.
//
//

#include "Argument.h"
#include "cinder/Log.h"
#import <Metal/Metal.h>
#import <simd/simd.h>

using namespace cinder;
using namespace cinder::mtl;

#define IMPL ((__bridge MTLArgument *)mImpl)

Argument::Argument( void * mtlArgument ) :
mImpl(mtlArgument)
{
    assert( mImpl && [IMPL isKindOfClass:[MTLArgument class] ] );
}

const std::string Argument::getName() const { return std::string([IMPL.name UTF8String]); }

mtl::ArgumentType Argument::getType() const { return (mtl::ArgumentType)IMPL.type; };

mtl::ArgumentAccess Argument::getAccess() const { return (mtl::ArgumentAccess)IMPL.access; };

unsigned long Argument::getIndex() const { return IMPL.index; };

bool Argument::isActive() const { return IMPL.active; };

unsigned long Argument::getBufferAlignment() const { return IMPL.bufferAlignment; };

unsigned long Argument::getBufferDataSize() const { return IMPL.bufferDataSize; };

mtl::DataType Argument::getBufferDataType() const { return (mtl::DataType)IMPL.bufferDataType; };

mtl::StructType Argument::getBufferStructType()
{
    if ( (getBufferDataType() == mtl::DataTypeStruct) &&
         (mCachedStructType.members.size() == 0) )
    {
        MTLStructType *st = IMPL.bufferStructType;
        for ( MTLStructMember *sm in st.members )
        {
            StructMember m;
            m.name = std::string([sm.name UTF8String]);
            m.dataType = (mtl::DataType)sm.dataType;
            m.offset = sm.offset;
            mCachedStructType.members.push_back(m);
        }
    }
    return mCachedStructType;
};

unsigned long Argument::getThreadgroupMemoryAlignment() const { return IMPL.threadgroupMemoryAlignment; };

unsigned long Argument::threadgroupMemoryDataSize() const { return IMPL.threadgroupMemoryDataSize; };

mtl::TextureType Argument::getTextureType() const { return (mtl::TextureType)IMPL.textureType; };

mtl::DataType Argument::getTextureDataType() const { return (mtl::DataType)IMPL.textureDataType; };
