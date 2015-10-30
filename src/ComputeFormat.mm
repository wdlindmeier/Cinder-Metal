//
//  ComputeFormat.cpp
//  MetalCube
//
//  Created by William Lindmeier on 10/19/15.
//
//

#include "ComputeFormat.h"

using namespace ci;
using namespace ci::mtl;

ComputeFormatRef ComputeFormat::create()
{
    return ComputeFormatRef( new ComputeFormat() );
}

ComputeFormat::ComputeFormat()
{
//    mImpl = Create some options
}
