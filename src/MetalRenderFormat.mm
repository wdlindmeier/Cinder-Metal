//
//  MetalRenderPass.cpp
//  MetalCube
//
//  Created by William Lindmeier on 10/13/15.
//
//

#include "MetalRenderFormat.h"
#include "MetalRenderFormatImpl.h"

using namespace ci;
using namespace ci::mtl;

MetalRenderFormatRef MetalRenderFormat::create()
{
    return MetalRenderFormatRef( new MetalRenderFormat() );
}

MetalRenderFormat::MetalRenderFormat()
{
    mImpl = [MetalRenderFormatImpl new];
}

void MetalRenderFormat::setShouldClear( bool shouldClear )
{
    mImpl.renderPassDescriptor.colorAttachments[0].loadAction = shouldClear ? MTLLoadActionClear : MTLLoadActionDontCare;
    mImpl.renderPassDescriptor.depthAttachment.loadAction = shouldClear ? MTLLoadActionClear : MTLLoadActionDontCare;
};

void MetalRenderFormat::setClearColor( const ColorAf clearColor )
{
    mImpl.renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(clearColor.r,
                                                                                  clearColor.g,
                                                                                  clearColor.b,
                                                                                  clearColor.a);
};

void MetalRenderFormat::setClearDepth( float clearDepth )
{
    mImpl.renderPassDescriptor.depthAttachment.clearDepth = clearDepth;
};
