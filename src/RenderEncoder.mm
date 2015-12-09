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

void RenderEncoder::setDepthStencilState( const DepthStateRef & depthState )
{
    [IMPL setDepthStencilState:(__bridge id<MTLDepthStencilState>)depthState->getNative()];
}

void RenderEncoder::setFragSamplerState( const SamplerStateRef & samplerState, int samplerIndex )
{
    [IMPL setFragmentSamplerState:(__bridge id<MTLSamplerState>)samplerState->getNative()
                          atIndex:samplerIndex];
}

void RenderEncoder::setPipelineState( const RenderPipelineStateRef & pipeline )
{
    [IMPL setRenderPipelineState:(__bridge id <MTLRenderPipelineState>)pipeline->getNative()];
}

void RenderEncoder::setTexture( const TextureBufferRef & texture, size_t index )
{
    [IMPL setFragmentTexture:(__bridge id <MTLTexture>)texture->getNative()
                     atIndex:index];
}

void RenderEncoder::setUniforms( const DataBufferRef & buffer, size_t bytesOffset, size_t bufferIndex )
{
    setVertexBufferAtIndex(buffer, bufferIndex, bytesOffset);
    setFragmentBufferAtIndex(buffer, bufferIndex, bytesOffset);
}

void RenderEncoder::setVertexBufferAtIndex( const DataBufferRef & buffer, size_t index, size_t bytesOffset )
{
    [IMPL setVertexBuffer:(__bridge id <MTLBuffer>)buffer->getNative()
                   offset:bytesOffset
                  atIndex:index];
}

void RenderEncoder::setFragmentBufferAtIndex( const DataBufferRef & buffer, size_t index, size_t bytesOffset )
{
    [IMPL setFragmentBuffer:(__bridge id <MTLBuffer>)buffer->getNative()
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

void RenderEncoder::setScissor( Area scissor )
{
    [IMPL setScissorRect: { (NSUInteger)scissor.getX1(), (NSUInteger)scissor.getY1(),
                            (NSUInteger)scissor.getWidth(), (NSUInteger)scissor.getHeight() } ];
}

void RenderEncoder::setTriangleFillMode( int mtlTriangleFillMode )
{
    [IMPL setTriangleFillMode:(MTLTriangleFillMode)mtlTriangleFillMode];
}

void RenderEncoder::setVertexBufferOffsetAtIndex( size_t offset, size_t index )
{
    [IMPL setVertexBufferOffset:offset atIndex:index];
}

void RenderEncoder::setFragmentBufferOffsetAtIndex( size_t offset, size_t index )
{
    [IMPL setFragmentBufferOffset:offset atIndex:index];
}

void RenderEncoder::setBlendColor( ColorAf blendColor )
{
    [IMPL setBlendColorRed:blendColor.r green:blendColor.g blue:blendColor.b alpha:blendColor.a];
}

void RenderEncoder::setStencilReferenceValue( uint32_t frontReferenceValue, uint32_t backReferenceValue )
{
    [IMPL setStencilFrontReferenceValue:frontReferenceValue backReferenceValue:backReferenceValue];
}

void RenderEncoder::setVisibilityResultMode( int mtlVisibilityResultMode, size_t offset )
{
    [IMPL setVisibilityResultMode:(MTLVisibilityResultMode)mtlVisibilityResultMode offset:offset];
}

void RenderEncoder::draw( ci::mtl::geom::Primitive primitive, size_t vertexCount, size_t vertexStart,
                          size_t instanceCount, size_t baseInstance )
{
    [IMPL drawPrimitives:(MTLPrimitiveType)nativeMTLPrimitiveType(primitive)
             vertexStart:vertexStart
             vertexCount:vertexCount
           instanceCount:instanceCount
            baseInstance:baseInstance];
}

void RenderEncoder::drawIndexed( ci::mtl::geom::Primitive primitive, const DataBufferRef & indexBuffer,
                                 size_t indexCount, int mtlIndexType, size_t bufferOffset,
                                 size_t instanceCount, size_t baseVertex, size_t baseInstance )
{
    [IMPL drawIndexedPrimitives:(MTLPrimitiveType)nativeMTLPrimitiveType(primitive)
                     indexCount:indexCount
                      indexType:(MTLIndexType)mtlIndexType
                    indexBuffer:( __bridge id <MTLBuffer> )indexBuffer->getNative()
              indexBufferOffset:bufferOffset
                  instanceCount:instanceCount
                     baseVertex:baseVertex
                   baseInstance:baseInstance];
}

#if !defined( CINDER_COCOA_TOUCH )
void RenderEncoder::textureBarrier()
{
    [IMPL textureBarrier];
}
#endif
