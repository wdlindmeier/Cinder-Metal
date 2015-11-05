//
//  CommandBuffer.cpp
//  MetalCube
//
//  Created by William Lindmeier on 10/17/15.
//
//

#include "CommandBuffer.h"
#import "RenderFormatImpl.h"
#import <QuartzCore/CAMetalLayer.h>

using namespace ci;
using namespace ci::mtl;

#define CMD_BUFFER ((__bridge id <MTLCommandBuffer>)mCommandBuffer)
#define DRAWABLE ((__bridge id <CAMetalDrawable>)mDrawable)

CommandBufferRef CommandBuffer::create( void * mtlCommandBuffer, void * mtlDrawable )
{
    return CommandBufferRef( new CommandBuffer( mtlCommandBuffer, mtlDrawable ) );
}

CommandBuffer::CommandBuffer( void * mtlCommandBuffer, void * mtlDrawable )
:
mCommandBuffer(mtlCommandBuffer)
,mDrawable(mtlDrawable)
{
     // <MTLCommandBuffer>
    assert( mtlCommandBuffer != NULL );
    assert( [(__bridge id)mtlCommandBuffer conformsToProtocol:@protocol(MTLCommandBuffer)] );
    assert( mtlDrawable != NULL );
    assert( [(__bridge id)mtlDrawable conformsToProtocol:@protocol(CAMetalDrawable)] );
}
