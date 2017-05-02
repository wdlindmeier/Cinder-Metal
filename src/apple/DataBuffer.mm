//
//  Buffer.cpp
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

DataBuffer::DataBuffer( unsigned long length, const void * pointer, Format format )
{
    init( length, pointer, format );
}

void DataBuffer::init( unsigned long length, const void * pointer, Format format )
{
    mFormat = format;
    auto device = [RendererMetalImpl sharedRenderer].device;
    
    if ( pointer == NULL )
    {
        mImpl = (__bridge_retained void *)[device newBufferWithLength:length
                                                              options:mFormat.getCacheMode() |
                                                                      mFormat.getStorageMode() ];
    }
    else
    {
        if ( mFormat.getStorageMode() == StorageModePrivate )
        {
            CI_LOG_E("DataBuffer with Private storage mode cannot be constructed with data from \
                     the CPU. Data must be sent via a blit command.");
            // https://developer.apple.com/library/mac/documentation/Miscellaneous/Conceptual/MetalProgrammingGuide/WhatsNewinOSXandiOS/WhatsNewinOSXandiOS.html
        }
        mImpl = (__bridge_retained void *)[device newBufferWithBytes:pointer
                                                              length:length
                                                             options:mFormat.getCacheMode() |
                                                                     mFormat.getStorageMode() ];
        
        didModifyRange(0, length);
    }
    
    IMPL.label = [NSString stringWithUTF8String:mFormat.getLabel().c_str()];
}

DataBuffer::DataBuffer( void *mtlDataBuffer ) :
mImpl(mtlDataBuffer)
{
    assert( mtlDataBuffer != NULL );
    assert([(__bridge id)mtlDataBuffer conformsToProtocol:@protocol(MTLBuffer)]);
    CFRetain(mImpl);
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

size_t DataBuffer::getLength()
{
    return [IMPL length];
}

void DataBuffer::didModifyRange( size_t location, size_t length )
{
#if !defined( CINDER_COCOA_TOUCH )
    if ( [IMPL storageMode] == MTLStorageModeManaged )
    {
        [IMPL didModifyRange:NSMakeRange(location, length)];
    }
#endif
}
