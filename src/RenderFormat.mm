//
//  MetalRenderPass.cpp
//  MetalCube
//
//  Created by William Lindmeier on 10/13/15.
//
//

#include "RenderFormat.h"
#include "RenderFormatImpl.h"

using namespace ci;
using namespace ci::mtl;

RenderFormatRef RenderFormat::create()
{
    return RenderFormatRef( new RenderFormat() );
}

RenderFormat::RenderFormat()
{
    mImpl = [RenderFormatImpl new];
}

void RenderFormat::setShouldClear( bool shouldClear )
{
    mImpl.renderPassDescriptor.colorAttachments[0].loadAction = shouldClear ? MTLLoadActionClear : MTLLoadActionDontCare;
    mImpl.renderPassDescriptor.depthAttachment.loadAction = shouldClear ? MTLLoadActionClear : MTLLoadActionDontCare;
};

void RenderFormat::setClearColor( const ColorAf clearColor )
{
    mImpl.renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(clearColor.r,
                                                                                  clearColor.g,
                                                                                  clearColor.b,
                                                                                  clearColor.a);
};

void RenderFormat::setClearDepth( float clearDepth )
{
    mImpl.renderPassDescriptor.depthAttachment.clearDepth = clearDepth;
};
