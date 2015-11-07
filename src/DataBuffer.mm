//
//  Buffer.cpp
//  MetalCube
//
//  Created by William Lindmeier on 10/17/15.
//
//

#include "DataBuffer.h"
#include "RendererMetalImpl.h"
#import "cinder/Log.h"
#include "cinder/GeomIo.h"
#import "metal.h"

using namespace cinder;
using namespace cinder::mtl;
using namespace cinder::cocoa;

#define IMPL ((__bridge id <MTLBuffer>)mImpl)

template <typename T>
DataBuffer::DataBuffer( const std::vector<T> & dataVector, const std::string & label )
{
    unsigned long vectorSize = sizeof(dataVector) + (sizeof(T) * dataVector.size());
    init(vectorSize, dataVector.data(), label);
}

// Allowed specializations
template DataBuffer::DataBuffer( const std::vector<vec2> & dataVector, const std::string & label );
template DataBuffer::DataBuffer( const std::vector<vec3> & dataVector, const std::string & label );
template DataBuffer::DataBuffer( const std::vector<vec4> & dataVector, const std::string & label );
template DataBuffer::DataBuffer( const std::vector<unsigned int> & dataVector, const std::string & label );
template DataBuffer::DataBuffer( const std::vector<float> & dataVector, const std::string & label );
template DataBuffer::DataBuffer( const std::vector<mat3> & dataVector, const std::string & label );
template DataBuffer::DataBuffer( const std::vector<mat4> & dataVector, const std::string & label );

DataBuffer::DataBuffer( unsigned long length, const void * pointer, const std::string & label )
{
    init( length, pointer, label );
}

void DataBuffer::init( unsigned long length, const void * pointer, const std::string & label )
{
    auto device = [RendererMetalImpl sharedRenderer].device;
    
    if ( pointer == NULL )
    {
        mImpl = (__bridge_retained void *)[device newBufferWithLength:length options:0];
    }
    else
    {
        mImpl = (__bridge_retained void *)[device newBufferWithBytes:pointer
                                                              length:length
                                                             options:MTLResourceCPUCacheModeDefaultCache];
    }
    
    IMPL.label = (__bridge NSString *)cocoa::createCfString(label);
}

DataBuffer::~DataBuffer()
{
    CFRelease(mImpl);
}

void * DataBuffer::contents()
{
    return [IMPL contents];
}
