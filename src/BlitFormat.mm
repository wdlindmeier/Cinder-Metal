//
//  BlitFormat.cpp
//  MetalCube
//
//  Created by William Lindmeier on 10/19/15.
//
//

#include "BlitFormat.h"

using namespace ci;
using namespace ci::mtl;

BlitFormatRef BlitFormat::create()
{
    return BlitFormatRef( new BlitFormat() );
}

BlitFormat::BlitFormat()
{
//    mImpl = MTLBlitOption();
}
