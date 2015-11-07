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

ScopedCommandBuffer::ScopedCommandBuffer( const std::string & bufferName )
{
    mInstance = CommandBuffer::createForRenderLoop(bufferName);
};

ScopedCommandBuffer::~ScopedCommandBuffer()
{
    mInstance->commitAndPresentForRendererLoop();
};

ScopedRenderEncoder::ScopedRenderEncoder( CommandBufferRef commandBuffer,
                                          const RenderPassDescriptorRef descriptor,
                                          const std::string & encoderName )
{
    mInstance = commandBuffer->createRenderEncoderWithDescriptor(descriptor, encoderName);
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