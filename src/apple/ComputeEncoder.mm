//
//  ComputeEncoder.cpp
//
//  Created by William Lindmeier on 10/17/15.
//
//

#include "ComputeEncoder.h"
#include "cinder/cocoa/CinderCocoa.h"
#import <QuartzCore/CAMetalLayer.h>
#import <Metal/Metal.h>
#import <simd/simd.h>

using namespace ci;
using namespace ci::mtl;
using namespace ci::cocoa;

#define IMPL ((__bridge id <MTLComputeCommandEncoder>)mImpl)

ComputeEncoderRef ComputeEncoder::create( void * mtlComputeCommandEncoder )
{
    return ComputeEncoderRef( new ComputeEncoder( mtlComputeCommandEncoder ) );
}

ComputeEncoder::ComputeEncoder( void * mtlComputeCommandEncoder )
:
CommandEncoder::CommandEncoder(mtlComputeCommandEncoder)
{
    assert( mtlComputeCommandEncoder != NULL );
    assert([(__bridge id)mtlComputeCommandEncoder conformsToProtocol:@protocol(MTLComputeCommandEncoder)]);
}

void ComputeEncoder::setPipelineState( const ComputePipelineStateRef & pipeline )
{
    [IMPL setComputePipelineState:(__bridge id <MTLComputePipelineState>)pipeline->getNative()];
};

void ComputeEncoder::setSamplerState( const SamplerStateRef & samplerState, int samplerIndex )
{
    [IMPL setSamplerState:(__bridge id<MTLSamplerState>)samplerState->getNative()
                  atIndex:samplerIndex];
}

void ComputeEncoder::setTexture( const TextureBufferRef & texture, size_t index )
{
    [IMPL setTexture:(__bridge id <MTLTexture>)texture->getNative()
             atIndex:index];
}

void ComputeEncoder::setUniforms( const DataBufferRef & buffer, size_t bytesOffset, size_t bufferIndex )
{
    setBufferAtIndex(buffer, bufferIndex, bytesOffset);
}

void ComputeEncoder::setBufferAtIndex( const DataBufferRef & buffer, size_t index, size_t bytesOffset )
{
    [IMPL setBuffer:(__bridge id <MTLBuffer>)buffer->getNative()
             offset:bytesOffset
            atIndex:index];
}

void ComputeEncoder::setBytesAtIndex( const void * bytes, size_t length, size_t index )
{
    [IMPL setBytes:bytes length:length atIndex:index];
}

void ComputeEncoder::setThreadgroupMemoryLength( size_t byteLength, size_t groupMemoryIndex )
{
    [IMPL setThreadgroupMemoryLength:byteLength atIndex:groupMemoryIndex];
}

void ComputeEncoder::dispatch( ivec3 dataDimensions, ivec3 threadDimensions )
{
    MTLSize threadgroupCounts = MTLSizeMake(threadDimensions.x, threadDimensions.y, threadDimensions.z);
    MTLSize threadgroups = MTLSizeMake( ceil(float(dataDimensions.x) / threadDimensions.x),
                                        ceil(float(dataDimensions.y) / threadDimensions.y),
                                        ceil(float(dataDimensions.z) / threadDimensions.z) );

    [IMPL dispatchThreadgroups:threadgroups threadsPerThreadgroup:threadgroupCounts];
}
