//
//  DepthState.cpp
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

DepthState::DepthState( void *mtlDepthStencilState ) :
mImpl(mtlDepthStencilState)
{
    assert(mImpl != NULL);
    assert([(__bridge id)mImpl conformsToProtocol:@protocol(MTLDepthStencilState)]);
    CFRetain(mImpl);
}

DepthState::~DepthState()
{
    if ( mImpl )
    {
        CFRelease(mImpl);
    }
}