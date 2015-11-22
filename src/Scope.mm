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

ScopedCommandBuffer::ScopedCommandBuffer( bool waitUntilCompleted, const std::string & bufferName )
:
mWaitUntilCompleted(waitUntilCompleted)
,mCompletionHandler(NULL)
{
    mInstance = CommandBuffer::create(bufferName);
};

ScopedCommandBuffer::~ScopedCommandBuffer()
{
    mInstance->commit( mCompletionHandler );
    if ( mWaitUntilCompleted )
    {
        mInstance->waitUntilCompleted();
    }
};

ScopedRenderBuffer::ScopedRenderBuffer( bool waitUntilCompleted, const std::string & bufferName )
:
mWaitUntilCompleted(waitUntilCompleted)
{
    mInstance = RenderBuffer::create(bufferName);
};

ScopedRenderBuffer::~ScopedRenderBuffer()
{
    mInstance->commitAndPresent();
    if ( mWaitUntilCompleted )
    {
        mInstance->waitUntilCompleted();
    }
};

ScopedRenderEncoder::ScopedRenderEncoder( RenderBufferRef renderBuffer,
                                          const RenderPassDescriptorRef descriptor,
                                          const std::string & encoderName )
{
    mInstance = renderBuffer->createRenderEncoderWithDescriptor(descriptor, encoderName);
}

ScopedRenderEncoder::~ScopedRenderEncoder()
{
    mInstance->endEncoding();
}

ScopedComputeEncoder::ScopedComputeEncoder( CommandBufferRef commandBuffer,
                                            const std::string & encoderName )
{
    mInstance = commandBuffer->createComputeEncoder( encoderName );
}

ScopedComputeEncoder::~ScopedComputeEncoder()
{
    mInstance->endEncoding();
}

ScopedBlitEncoder::ScopedBlitEncoder( CommandBufferRef commandBuffer,
                                      const std::string & encoderName )
{
    mInstance = commandBuffer->createBlitEncoder( encoderName );
}

ScopedBlitEncoder::~ScopedBlitEncoder()
{
    mInstance->endEncoding();
}