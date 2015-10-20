//
//  MetalBlitEncoder.cpp
//  MetalCube
//
//  Created by William Lindmeier on 10/17/15.
//
//

#include "MetalBlitEncoder.h"
#import "MetalBlitEncoderImpl.h"
#import <QuartzCore/CAMetalLayer.h>
#import <Metal/Metal.h>
#import <simd/simd.h>

using namespace ci;
using namespace ci::mtl;
using namespace ci::cocoa;

MetalBlitEncoderRef MetalBlitEncoder::create( MetalBlitEncoderImpl * encoderImpl )
{
    return MetalBlitEncoderRef( new MetalBlitEncoder( encoderImpl ) );
}

MetalBlitEncoder::MetalBlitEncoder( MetalBlitEncoderImpl * encoderImpl )
:
mImpl(encoderImpl)
{
}