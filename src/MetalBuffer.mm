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

MetalBufferRef MetalBuffer::create( unsigned long length, const void * pointer, const std::string & label )
{
    return MetalBufferRef( new MetalBuffer(length, pointer, label) );
}

MetalBuffer::MetalBuffer( unsigned long length, const void * pointer, const std::string & label )
{
    mImpl = [[MetalBufferImpl alloc] initWithBytes:pointer length:length label:(__bridge NSString *)createCfString(label)];
}

void * MetalBuffer::contents()
{
    return [mImpl.buffer contents];
}

