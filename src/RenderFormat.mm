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

RenderFormatRef RenderFormat::create( Format format )
{
    return RenderFormatRef( new RenderFormat( format ) );
}

RenderFormat::RenderFormat( Format format )
{
    mImpl = [RenderFormatImpl new];
    setShouldClear(format.getShouldClear());
    setClearDepth(format.getClearDepth());
    setClearColor(format.getClearColor());
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

void RenderFormat::prepareForTexture( void * texture )
{
    [mImpl prepareForRenderToTexture:(__bridge id<MTLTexture>)texture];
}
     
void * RenderFormat::getNative()
{
    return (__bridge void *)mImpl.renderPassDescriptor;
}