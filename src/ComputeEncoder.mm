//
//  ComputeEncoder.cpp
//  MetalCube
//
//  Created by William Lindmeier on 10/17/15.
//
//

#include "ComputeEncoder.h"
#import <QuartzCore/CAMetalLayer.h>
#import <Metal/Metal.h>
#import <simd/simd.h>

using namespace ci;
using namespace ci::mtl;
using namespace ci::cocoa;

ComputeEncoderRef ComputeEncoder::create( void * mtlComputeCommandEncoder )
{
    return ComputeEncoderRef( new ComputeEncoder( mtlComputeCommandEncoder ) );
}

ComputeEncoder::ComputeEncoder( void * mtlComputeCommandEncoder )
:
mImpl(mtlComputeCommandEncoder)
{
    CFRetain(mImpl);
    assert([(__bridge id)mtlComputeCommandEncoder conformsToProtocol:@protocol(MTLComputeCommandEncoder)]);
}

ComputeEncoder::~ComputeEncoder()
{
    if ( mImpl )
    {
        CFRelease(mImpl);
    }
}

void ComputeEncoder::endEncoding()
{
    [(__bridge id<MTLComputeCommandEncoder>)mImpl endEncoding];
}