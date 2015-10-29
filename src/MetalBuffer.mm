//
//  MetalBuffer.cpp
//  MetalCube
//
//  Created by William Lindmeier on 10/17/15.
//
//

#include "MetalBuffer.h"
#include "MetalBufferImpl.h"
#import "cinder/Log.h"
#include "cinder/GeomIo.h"
#import "metal.h"

using namespace cinder;
using namespace cinder::mtl;
using namespace cinder::cocoa;

template <typename T>
MetalBuffer::MetalBuffer( const std::vector<T> & dataVector, const std::string & label )
{
    unsigned long vectorSize = sizeof(dataVector) + (sizeof(T) * dataVector.size());
    mImpl = [[MetalBufferImpl alloc] initWithBytes:dataVector.data()
                                            length:vectorSize
                                             label:(__bridge NSString *)createCfString(label)];
}
// Allowed specializations
template MetalBuffer::MetalBuffer( const std::vector<vec2> & dataVector, const std::string & label );
template MetalBuffer::MetalBuffer( const std::vector<vec3> & dataVector, const std::string & label );
template MetalBuffer::MetalBuffer( const std::vector<vec4> & dataVector, const std::string & label );
template MetalBuffer::MetalBuffer( const std::vector<unsigned int> & dataVector, const std::string & label );
template MetalBuffer::MetalBuffer( const std::vector<float> & dataVector, const std::string & label );
template MetalBuffer::MetalBuffer( const std::vector<mat3> & dataVector, const std::string & label );
template MetalBuffer::MetalBuffer( const std::vector<mat4> & dataVector, const std::string & label );

MetalBuffer::MetalBuffer( unsigned long length, const void * pointer, const std::string & label )
{
    mImpl = [[MetalBufferImpl alloc] initWithBytes:pointer length:length label:(__bridge NSString *)createCfString(label)];
}

void * MetalBuffer::contents()
{
    return [mImpl.buffer contents];
}

