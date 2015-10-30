//
//  Buffer.cpp
//  MetalCube
//
//  Created by William Lindmeier on 10/17/15.
//
//

#include "Buffer.h"
#include "BufferImpl.h"
#import "cinder/Log.h"
#include "cinder/GeomIo.h"
#import "metal.h"

using namespace cinder;
using namespace cinder::mtl;
using namespace cinder::cocoa;

template <typename T>
mtl::Buffer::Buffer( const std::vector<T> & dataVector, const std::string & label )
{
    unsigned long vectorSize = sizeof(dataVector) + (sizeof(T) * dataVector.size());
    mImpl = [[BufferImpl alloc] initWithBytes:dataVector.data()
                                            length:vectorSize
                                             label:(__bridge NSString *)createCfString(label)];
}
// Allowed specializations
template mtl::Buffer::Buffer( const std::vector<vec2> & dataVector, const std::string & label );
template mtl::Buffer::Buffer( const std::vector<vec3> & dataVector, const std::string & label );
template mtl::Buffer::Buffer( const std::vector<vec4> & dataVector, const std::string & label );
template mtl::Buffer::Buffer( const std::vector<unsigned int> & dataVector, const std::string & label );
template mtl::Buffer::Buffer( const std::vector<float> & dataVector, const std::string & label );
template mtl::Buffer::Buffer( const std::vector<mat3> & dataVector, const std::string & label );
template mtl::Buffer::Buffer( const std::vector<mat4> & dataVector, const std::string & label );

mtl::Buffer::Buffer( unsigned long length, const void * pointer, const std::string & label )
{
    mImpl = [[BufferImpl alloc] initWithBytes:pointer length:length label:(__bridge NSString *)createCfString(label)];
}

void * mtl::Buffer::contents()
{
    return [mImpl.buffer contents];
}

