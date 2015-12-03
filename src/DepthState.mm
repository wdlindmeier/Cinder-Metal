//
//  DepthState.cpp
//  MetalCube
//
//  Created by William Lindmeier on 11/7/15.
//
//

#include "DepthState.h"
#include <Metal/Metal.h>
#include "RendererMetalImpl.h"

using namespace ci;
using namespace ci::mtl;

DepthState::DepthState( Format format )
{    
    SET_FORMAT_DEFAULT(format, DepthCompareFunction, MTLCompareFunctionLessEqual);
    
    MTLDepthStencilDescriptor *depthStateDesc = [[MTLDepthStencilDescriptor alloc] init];
    depthStateDesc.depthCompareFunction = (MTLCompareFunction)format.getDepthCompareFunction();
    depthStateDesc.depthWriteEnabled = format.getDepthWriteEnabled();
    if ( format.getFrontFaceStencil() != nullptr )
    {
        depthStateDesc.frontFaceStencil = (__bridge MTLStencilDescriptor *)format.getFrontFaceStencil();
    }
    if ( format.getBackFaceStencil() != nullptr )
    {
        depthStateDesc.backFaceStencil = (__bridge MTLStencilDescriptor *)format.getBackFaceStencil();
    }
    mImpl = (__bridge_retained void *)[[RendererMetalImpl sharedRenderer].device
                                       newDepthStencilStateWithDescriptor:depthStateDesc];
}

DepthState::~DepthState()
{
    if ( mImpl )
    {
        CFRelease(mImpl);
    }
}