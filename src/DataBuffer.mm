//
//  Buffer.cpp
//  MetalCube
//
//  Created by William Lindmeier on 10/17/15.
//
//

#include "DataBuffer.h"
#include "DataBufferImpl.h"
#import "cinder/Log.h"
#include "cinder/GeomIo.h"
#import "metal.h"

using namespace cinder;
using namespace cinder::mtl;
using namespace cinder::cocoa;

template <typename T>
DataBuffer::DataBuffer( const std::vector<T> & dataVector, const std::string & label )
{
    unsigned long vectorSize = sizeof(dataVector) + (sizeof(T) * dataVector.size());
    mImpl = [[DataBufferImpl alloc] initWithBytes:dataVector.data()
                                            length:vectorSize
                                             label:(__bridge NSString *)createCfString(label)];
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
    mImpl = [[DataBufferImpl alloc] initWithBytes:pointer length:length label:(__bridge NSString *)createCfString(label)];
}

void * DataBuffer::contents()
{
    return [mImpl.buffer contents];
}

