//
//  MetalBlitFormat.cpp
//  MetalCube
//
//  Created by William Lindmeier on 10/19/15.
//
//

#include "MetalBlitFormat.h"
#include "MetalBlitFormatImpl.h"

using namespace ci;
using namespace ci::mtl;

MetalBlitFormatRef MetalBlitFormat::create()
{
    return MetalBlitFormatRef( new MetalBlitFormat() );
}

MetalBlitFormat::MetalBlitFormat()
{
    mImpl = [MetalBlitFormatImpl new];
}
