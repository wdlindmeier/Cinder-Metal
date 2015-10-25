//
//  MetalRenderEncoder.cpp
//  MetalCube
//
//  Created by William Lindmeier on 10/16/15.
//
//

#include "MetalRenderEncoder.h"
#include "cinder/cocoa/CinderCocoa.h"
#import <QuartzCore/CAMetalLayer.h>
#import <Metal/Metal.h>
#import <simd/simd.h>
#import "MetalBufferImpl.h"
#import "MetalPipelineImpl.h"

using namespace ci;
using namespace ci::mtl;
using namespace ci::cocoa;

#define IMPL ((__bridge id <MTLRenderCommandEncoder>)mImpl)

MetalRenderEncoderRef MetalRenderEncoder::create( void * encoderImpl )
{
    return MetalRenderEncoderRef( new MetalRenderEncoder( encoderImpl ) );
}

MetalRenderEncoder::MetalRenderEncoder( void * encoderImpl )
:
mImpl(encoderImpl)
{
    assert( [(__bridge id)encoderImpl conformsToProtocol:@protocol(MTLRenderCommandEncoder)] );
}

void MetalRenderEncoder::setPipeline( MetalPipelineRef pipeline )
{
    [IMPL setDepthStencilState:pipeline->mImpl.depthState];
    [IMPL setRenderPipelineState:pipeline->mImpl.pipelineState];
}

void MetalRenderEncoder::pushDebugGroup( const std::string & groupName )
{
    [IMPL pushDebugGroup:(__bridge NSString *)createCfString(groupName)];
}

void MetalRenderEncoder::setVertexBuffer( MetalBufferRef buffer, size_t bytesOffset, size_t index)
{
    [IMPL setVertexBuffer:buffer->mImpl.buffer
                   offset:bytesOffset
                  atIndex:index];
}

void MetalRenderEncoder::draw( ci::mtl::geom::Primitive primitive, size_t vertexStart, size_t vertexCount, size_t instanceCount )
{
    [IMPL drawPrimitives:(MTLPrimitiveType)nativeMTLPrimitiveType(primitive)
             vertexStart:vertexStart
             vertexCount:vertexCount
           instanceCount:instanceCount];
}

void MetalRenderEncoder::popDebugGroup()
{
    [IMPL popDebugGroup];
}
