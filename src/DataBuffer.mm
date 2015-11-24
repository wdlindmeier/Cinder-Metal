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

DataBuffer::DataBuffer( unsigned long length, const void * pointer, const std::string & label )
{
    init( length, pointer, label );
}

void DataBuffer::init( unsigned long length, const void * pointer, const std::string & label )
{
    auto device = [RendererMetalImpl sharedRenderer].device;
    
    if ( pointer == NULL )
    {
        mImpl = (__bridge_retained void *)[device newBufferWithLength:length
                                                              options:MTLResourceCPUCacheModeDefaultCache |
                                                                      MTLResourceStorageModeShared];
    }
    else
    {
        mImpl = (__bridge_retained void *)[device newBufferWithBytes:pointer
                                                              length:length
                                                             options:MTLResourceCPUCacheModeDefaultCache |
                                                                     MTLResourceStorageModeShared];
    }
    
    IMPL.label = [NSString stringWithUTF8String:label.c_str()];
}

DataBuffer::~DataBuffer()
{
    if ( mImpl )
    {
        CFRelease(mImpl);
    }
}

void * DataBuffer::contents()
{
    return [IMPL contents];
}
