//
//  RenderEncoder.cpp
//  MetalCube
//
//  Created by William Lindmeier on 10/16/15.
//
//

#include "RenderEncoder.h"
#include "cinder/cocoa/CinderCocoa.h"
#import <QuartzCore/CAMetalLayer.h>
#import <Metal/Metal.h>
#import <simd/simd.h>
#import "RendererMetalImpl.h"
#import "VertexBuffer.h"

using namespace ci;
using namespace ci::mtl;
using namespace ci::cocoa;

#define IMPL ((__bridge id <MTLRenderCommandEncoder>)mImpl)

RenderEncoderRef RenderEncoder::create( void * encoderImpl )
{
    return RenderEncoderRef( new RenderEncoder( encoderImpl ) );
}

RenderEncoder::RenderEncoder( void * encoderImpl )
:
CommandEncoder( encoderImpl )
{
    assert( [(__bridge id)encoderImpl conformsToProtocol:@protocol(MTLRenderCommandEncoder)] );
}

void RenderEncoder::setDepthStencilState( DepthStateRef depthState )
{
    [IMPL setDepthStencilState:(__bridge id<MTLDepthStencilState>)depthState->getNative()];
}

void RenderEncoder::setFragSamplerState( SamplerStateRef samplerState, int samplerIndex )
{
    [IMPL setFragmentSamplerState:(__bridge id<MTLSamplerState>)samplerState->getNative()
                          atIndex:samplerIndex];
}

void RenderEncoder::setPipelineState( RenderPipelineStateRef pipeline )
{
    [IMPL setRenderPipelineState:(__bridge id <MTLRenderPipelineState>)pipeline->getNative()];
}

void RenderEncoder::setTexture( TextureBufferRef texture, size_t index )
{
    [IMPL setFragmentTexture:(__bridge id <MTLTexture>)texture->getNative()
                     atIndex:index];
}

void RenderEncoder::setUniforms( DataBufferRef buffer, size_t bytesOffset, size_t bufferIndex )
{
    setBufferAtIndex(buffer, bufferIndex, bytesOffset);
}

void RenderEncoder::setBufferAtIndex( DataBufferRef buffer, size_t index, size_t bytesOffset )
{
    [IMPL setVertexBuffer:(__bridge id <MTLBuffer>)buffer->getNative()
                   offset:bytesOffset
                  atIndex:index];
}

void RenderEncoder::setViewport( vec2 origin, vec2 size, float near, float far )
{
    [IMPL setViewport:{ origin.x, origin.y, size.x, size.y, near, far }];
}

void RenderEncoder::setFrontFacingWinding( bool isClockwise )
{
    [IMPL setFrontFacingWinding:isClockwise ? MTLWindingClockwise : MTLWindingCounterClockwise];
}

void RenderEncoder::setCullMode( int mtlCullMode )
{
    [IMPL setCullMode:(MTLCullMode)mtlCullMode];
}

void RenderEncoder::setDepthClipMode( int mtlDepthClipMode )
{
    [IMPL setDepthClipMode:(MTLDepthClipMode)mtlDepthClipMode];
}

void RenderEncoder::setDepthBias( float depthBias, float slopeScale, float clamp )
{
    [IMPL setDepthBias:depthBias slopeScale:slopeScale clamp:clamp];
}

void RenderEncoder::setScissorRect( Area rect )
{
    [IMPL setScissorRect: { (NSUInteger)rect.getX1(), (NSUInteger)rect.getY1(),
                            (NSUInteger)rect.getWidth(), (NSUInteger)rect.getHeight() } ];
}

void RenderEncoder::setTriangleFillMode( int mtlTriangleFillMode )
{
    [IMPL setTriangleFillMode:(MTLTriangleFillMode)mtlTriangleFillMode];
}

void RenderEncoder::draw( ci::mtl::geom::Primitive primitive,
                          size_t vertexCount,
                          size_t vertexStart,
                          size_t instanceCount )
{
    [IMPL drawPrimitives:(MTLPrimitiveType)nativeMTLPrimitiveType(primitive)
             vertexStart:vertexStart
             vertexCount:vertexCount
           instanceCount:instanceCount];
}