//
//  Scope.cpp
//  MetalCube
//
//  Created by William Lindmeier on 11/4/15.
//
//

#include "Scope.h"
#include "RendererMetalImpl.h"
#include "RenderPassDescriptor.h"
#include "ComputeEncoder.h"
#include "BlitEncoder.h"

using namespace cinder;
using namespace cinder::mtl;

ScopedRenderEncoder::ScopedRenderEncoder( void * mtlRenderCommandEncoder ) :
RenderEncoder(mtlRenderCommandEncoder)
{}

ScopedRenderEncoder::~ScopedRenderEncoder()
{
    endEncoding();
}

ScopedComputeEncoder::ScopedComputeEncoder( void *mtlComputeEncoder ) :
ComputeEncoder(mtlComputeEncoder)
{}

ScopedComputeEncoder::~ScopedComputeEncoder()
{
    endEncoding();
}

ScopedBlitEncoder::ScopedBlitEncoder( void *mtlBlitEncoder ) :
BlitEncoder(mtlBlitEncoder)
{}

ScopedBlitEncoder::~ScopedBlitEncoder()
{
    endEncoding();
}

ScopedCommandBuffer::ScopedCommandBuffer( bool waitUntilCompleted, const std::string & bufferName )
:
CommandBuffer(bufferName)
,mWaitUntilCompleted(waitUntilCompleted)
,mCompletionHandler(NULL)
{};

ScopedComputeEncoder ScopedCommandBuffer::scopedComputeEncoder( const std::string & bufferName )
{
    ComputeEncoderRef computeEncoder = createComputeEncoder( bufferName );
    return ScopedComputeEncoder( computeEncoder->getNative() );
}

ScopedBlitEncoder ScopedCommandBuffer::scopedBlitEncoder( const std::string & bufferName )
{
    BlitEncoderRef blitEncoder = createBlitEncoder( bufferName );
    return ScopedBlitEncoder( blitEncoder->getNative() );
}

ScopedCommandBuffer::~ScopedCommandBuffer()
{
    commit( mCompletionHandler );
    if ( mWaitUntilCompleted )
    {
        waitUntilCompleted();
    }
};

ScopedRenderCommandBuffer::ScopedRenderCommandBuffer( bool waitUntilCompleted, const std::string & bufferName )
:
RenderCommandBuffer(bufferName)
,mWaitUntilCompleted(waitUntilCompleted)
,mCompletionHandler(NULL)
{};

ScopedRenderEncoder ScopedRenderCommandBuffer::scopedRenderEncoder( const RenderPassDescriptorRef & descriptor,
                                                                    const std::string & bufferName )
{
    RenderEncoderRef renderEncoder = createRenderEncoder(descriptor, bufferName);
    return ScopedRenderEncoder(renderEncoder->getNative());
}

ScopedRenderCommandBuffer::~ScopedRenderCommandBuffer()
{
    commitAndPresent( mCompletionHandler );
    if ( mWaitUntilCompleted )
    {
        waitUntilCompleted();
    }
};
