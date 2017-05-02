//
//  RenderCommandBuffer.cpp
//
//  Created by William Lindmeier on 11/15/15.
//
//

#include "RenderCommandBuffer.h"
#include "RendererMetalImpl.h"
#include "ImageHelpers.h"

using namespace std;
using namespace ci;
using namespace ci::mtl;

#define IMPL ((__bridge id <MTLCommandBuffer>)mImpl)
#define DRAWABLE ((__bridge id <CAMetalDrawable>)mDrawable)

RenderCommandBuffer::RenderCommandBuffer( const std::string & bufferName )
:
CommandBuffer( bufferName )
{
    RendererMetalImpl *renderer = [RendererMetalImpl sharedRenderer];
    CGRect layerFrame = renderer.metalLayer.frame;
    assert(!CGSizeEqualToSize(layerFrame.size, CGSizeZero));
    mDrawable = (__bridge_retained void *)[renderer.metalLayer nextDrawable];
    assert( mImpl != NULL );
    assert( mDrawable != NULL );
    assert( [(__bridge id)mDrawable conformsToProtocol:@protocol(CAMetalDrawable)] );
}

RenderCommandBuffer::~RenderCommandBuffer()
{
    // CFRelease(mDrawable);
    mDrawable = nil;
}

RenderEncoderRef RenderCommandBuffer::createRenderEncoder( RenderPassDescriptorRef & descriptor,
                                                           const std::string & encoderName )
{
    return CommandBuffer::createRenderEncoder(descriptor, (__bridge void *)DRAWABLE.texture);
}

void RenderCommandBuffer::commitAndPresent( std::function< void( void * mtlCommandBuffer) > completionHandler )
{
    RendererMetalImpl *renderer = [RendererMetalImpl sharedRenderer];
    renderer.currentDrawable = DRAWABLE;

    // clean up the command buffer
    __block dispatch_semaphore_t block_sema = [renderer inflightSemaphore];
    if ( block_sema != nil )
    {
        [IMPL addCompletedHandler:^(id<MTLCommandBuffer> buffer)
         {
             if ( completionHandler != NULL )
             {
                 completionHandler( (__bridge void *) buffer );
             }
             dispatch_semaphore_signal(block_sema);
         }];
    }
    [IMPL presentDrawable:DRAWABLE];
    // Finalize rendering here & push the command buffer to the GPU
    [IMPL commit];
}
