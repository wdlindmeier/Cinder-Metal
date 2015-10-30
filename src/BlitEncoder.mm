//
//  BlitEncoder.cpp
//  MetalCube
//
//  Created by William Lindmeier on 10/17/15.
//
//

#include "BlitEncoder.h"
#import <QuartzCore/CAMetalLayer.h>
#import <Metal/Metal.h>
#import <simd/simd.h>

using namespace ci;
using namespace ci::mtl;
using namespace ci::cocoa;

BlitEncoderRef BlitEncoder::create( void * mtlBlitCommandEncoder )
{
    return BlitEncoderRef( new BlitEncoder( mtlBlitCommandEncoder ) );
}

BlitEncoder::BlitEncoder( void * mtlBlitCommandEncoder )
:
mImpl(mtlBlitCommandEncoder)
{
    assert( mtlBlitCommandEncoder != NULL );
    assert( [(__bridge id)mtlBlitCommandEncoder conformsToProtocol:@protocol(MTLBlitCommandEncoder)] );
}