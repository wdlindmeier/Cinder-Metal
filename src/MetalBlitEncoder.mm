//
//  MetalBlitEncoder.cpp
//  MetalCube
//
//  Created by William Lindmeier on 10/17/15.
//
//

#include "MetalBlitEncoder.h"
#import <QuartzCore/CAMetalLayer.h>
#import <Metal/Metal.h>
#import <simd/simd.h>

using namespace ci;
using namespace ci::mtl;
using namespace ci::cocoa;

MetalBlitEncoderRef MetalBlitEncoder::create( void * mtlBlitCommandEncoder )
{
    return MetalBlitEncoderRef( new MetalBlitEncoder( mtlBlitCommandEncoder ) );
}

MetalBlitEncoder::MetalBlitEncoder( void * mtlBlitCommandEncoder )
:
mImpl(mtlBlitCommandEncoder)
{
    assert( mtlBlitCommandEncoder != NULL );
    assert( [(__bridge id)mtlBlitCommandEncoder conformsToProtocol:@protocol(MTLBlitCommandEncoder)] );
}