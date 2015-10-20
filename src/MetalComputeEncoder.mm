//
//  MetalComputeEncoder.cpp
//  MetalCube
//
//  Created by William Lindmeier on 10/17/15.
//
//

#include "MetalComputeEncoder.h"
#import "MetalComputeEncoderImpl.h"
#import <QuartzCore/CAMetalLayer.h>
#import <Metal/Metal.h>
#import <simd/simd.h>

using namespace ci;
using namespace ci::mtl;
using namespace ci::cocoa;

MetalComputeEncoderRef MetalComputeEncoder::create( MetalComputeEncoderImpl * encoderImpl )
{
    return MetalComputeEncoderRef( new MetalComputeEncoder( encoderImpl ) );
}

MetalComputeEncoder::MetalComputeEncoder( MetalComputeEncoderImpl * encoderImpl )
:
mImpl(encoderImpl)
{
}