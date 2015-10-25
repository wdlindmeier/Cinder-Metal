//
//  MetalComputeEncoder.cpp
//  MetalCube
//
//  Created by William Lindmeier on 10/17/15.
//
//

#include "MetalComputeEncoder.h"
#import <QuartzCore/CAMetalLayer.h>
#import <Metal/Metal.h>
#import <simd/simd.h>

using namespace ci;
using namespace ci::mtl;
using namespace ci::cocoa;

MetalComputeEncoderRef MetalComputeEncoder::create( void * mtlComputeCommandEncoder )
{
    return MetalComputeEncoderRef( new MetalComputeEncoder( mtlComputeCommandEncoder ) );
}

MetalComputeEncoder::MetalComputeEncoder( void * mtlComputeCommandEncoder )
:
mImpl(mtlComputeCommandEncoder)
{
    assert([(__bridge id)mtlComputeCommandEncoder conformsToProtocol:@protocol(MTLComputeCommandEncoder)]);
}