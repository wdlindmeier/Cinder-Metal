//
//  MetalComputeFormat.cpp
//  MetalCube
//
//  Created by William Lindmeier on 10/19/15.
//
//

#include "MetalComputeFormat.h"
#include "MetalComputeFormatImpl.h"

using namespace ci;
using namespace ci::mtl;

MetalComputeFormatRef MetalComputeFormat::create()
{
    return MetalComputeFormatRef( new MetalComputeFormat() );
}

MetalComputeFormat::MetalComputeFormat()
{
    mImpl = [MetalComputeFormatImpl new];
}
