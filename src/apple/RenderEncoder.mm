//
//  RenderEncoder.cpp
//  Cinder-Metal
//
//  Created by William Lindmeier on 10/16/15.
//
//

#import "RenderEncoder.h"
#include "cinder/cocoa/CinderCocoa.h"
#include "cinder/Log.h"
#import <QuartzCore/CAMetalLayer.h>
#import <Metal/Metal.h>
#import <simd/simd.h>
#import "RendererMetalImpl.h"
#import "VertexBuffer.h"
#import "Batch.h"
#import "InstanceTypes.h"
#import "Draw.h"

using namespace std;
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
    setFragmentTexture(texture, index);
}

void RenderEncoder::setFragmentTexture( const TextureBufferRef & texture, size_t index )
{
    [IMPL setFragmentTexture:(__bridge id <MTLTexture>)texture->getNative()
                     atIndex:index];
}

void RenderEncoder::setVertexTexture( const TextureBufferRef & texture, size_t index )
{
    [IMPL setVertexTexture:(__bridge id <MTLTexture>)texture->getNative()
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

void RenderEncoder::setVertexBytesAtIndex( const void * bytes, size_t length , size_t index )
{
    [IMPL setVertexBytes:bytes length:length atIndex:index];
}

void RenderEncoder::setFragmentBytesAtIndex( const void * bytes, size_t length , size_t index )
{
    [IMPL setFragmentBytes:bytes length:length atIndex:index];
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
    if ( [[RendererMetalImpl sharedRenderer].device supportsFeatureSet:MTLFeatureSet_iOS_GPUFamily3_v1] )
    {
        [IMPL drawPrimitives:(MTLPrimitiveType)nativeMTLPrimitiveType(primitive)
                 vertexStart:vertexStart
                 vertexCount:vertexCount
               instanceCount:instanceCount
                baseInstance:baseInstance];
    }
    else
    {
        if ( baseInstance > 1 )
        {
            CI_LOG_F("This device does not support baseInstance.");
            // https://developer.apple.com/library/ios/documentation/Miscellaneous/Conceptual/MetalProgrammingGuide/WhatsNewinOSXandiOS/WhatsNewinOSXandiOS.html
        }
        assert(baseInstance <= 1);
        [IMPL drawPrimitives:(MTLPrimitiveType)nativeMTLPrimitiveType(primitive)
                 vertexStart:vertexStart
                 vertexCount:vertexCount
               instanceCount:instanceCount];
    }
}

void RenderEncoder::drawIndexed( ci::mtl::geom::Primitive primitive, const DataBufferRef & indexBuffer,
                                 size_t indexCount, IndexType indexType, size_t bufferOffset,
                                 size_t instanceCount, size_t baseVertex, size_t baseInstance )
{
    if ( [[RendererMetalImpl sharedRenderer].device supportsFeatureSet:MTLFeatureSet_iOS_GPUFamily3_v1] )
    {
        [IMPL drawIndexedPrimitives:(MTLPrimitiveType)nativeMTLPrimitiveType(primitive)
                         indexCount:indexCount
                          indexType:(MTLIndexType)indexType
                        indexBuffer:( __bridge id <MTLBuffer> )indexBuffer->getNative()
                  indexBufferOffset:bufferOffset
                      instanceCount:instanceCount
                         baseVertex:baseVertex
                       baseInstance:baseInstance];
    }
    else
    {
        if ( baseInstance > 1 )
        {
            CI_LOG_F("This device does not support baseInstance.");
            // https://developer.apple.com/library/ios/documentation/Miscellaneous/Conceptual/MetalProgrammingGuide/WhatsNewinOSXandiOS/WhatsNewinOSXandiOS.html
        }
        assert(baseInstance <= 1);
        if ( baseVertex > 0 )
        {
            CI_LOG_F("This device does not support baseVertex.");
            // https://developer.apple.com/library/ios/documentation/Miscellaneous/Conceptual/MetalProgrammingGuide/WhatsNewinOSXandiOS/WhatsNewinOSXandiOS.html
        }
        assert(baseVertex == 0);
        [IMPL drawIndexedPrimitives:(MTLPrimitiveType)nativeMTLPrimitiveType(primitive)
                         indexCount:indexCount
                          indexType:(MTLIndexType)indexType
                        indexBuffer:( __bridge id <MTLBuffer> )indexBuffer->getNative()
                  indexBufferOffset:bufferOffset
                      instanceCount:instanceCount];
    }
}

#if !defined( CINDER_COCOA_TOUCH )
void RenderEncoder::textureBarrier()
{
    [IMPL textureBarrier];
}
#endif



#pragma mark - Drawing Convenience Functions

void RenderEncoder::draw( ci::mtl::VertexBufferRef vertBuffer,
                          ci::mtl::RenderPipelineStateRef pipeline,
                          //bool shouldSetIdentityInstance,
                          ci::mtl::DataBufferRef instanceBuffer,
                          unsigned int numInstances )
{
    setDefaultShaderVars(*this, pipeline);
    if ( !instanceBuffer )
    {
        assert( numInstances == 1 );
        setIdentityInstance();
    }
    else
    {
        setInstanceData(instanceBuffer);
    }
    setPipelineState(pipeline);
    vertBuffer->drawInstanced(*this, numInstances);
}

#pragma mark - Instancing Draw Calls

static ci::mtl::DataBufferRef sInstanceBuffer;

void RenderEncoder::setInstanceData( ci::mtl::DataBufferRef & instanceBuffer )
{
    setVertexBufferAtIndex(instanceBuffer, ci::mtl::ciBufferIndexInstanceData);
}

void RenderEncoder::setIdentityInstance()
{
    if ( !sInstanceBuffer )
    {
        // Cache the vanilla buffer.
        Instance i;
        std::vector<Instance> is = {i};
        sInstanceBuffer = ci::mtl::DataBuffer::create(is);
    }
    setInstanceData(sInstanceBuffer);
}

void RenderEncoder::draw( ci::mtl::BatchRef batch, size_t vertexLength, size_t vertexStart,
                          ci::mtl::DataBufferRef instanceBuffer, unsigned int numInstances )
{
    if ( !instanceBuffer )
    {
        assert( numInstances == 1 );
        setIdentityInstance();
    }
    else
    {
        setInstanceData(instanceBuffer);
    }
    batch->draw(*this, vertexStart, vertexLength, numInstances);
}

void RenderEncoder::draw( ci::mtl::BatchRef batch,
                          ci::mtl::DataBufferRef instanceBuffer, unsigned int numInstances )
{
    if ( !instanceBuffer )
    {
        assert( numInstances == 1 );
        setIdentityInstance();
    }
    else
    {
        setInstanceData(instanceBuffer);
    }
    batch->drawInstanced(*this, numInstances);
}

void RenderEncoder::drawOne( ci::mtl::BatchRef batch, const Instance & i )
{
    std::vector<Instance> is = {i};
    ci::mtl::DataBufferRef iBuffer = ci::mtl::DataBuffer::create(is);
    setInstanceData(iBuffer);
    batch->drawInstanced(*this, 1);
}

void RenderEncoder::drawStrokedCircle( ci::vec3 position, float radius,
                                       ci::mtl::DataBufferRef instanceBuffer, unsigned int numInstances )
{
    mtl::ScopedModelMatrix matModel;
    mtl::translate(position);
    mtl::scale(vec3(radius));
    draw( mtl::getStockBatchWireCircle(), instanceBuffer, numInstances );
}

void RenderEncoder::drawSolidCircle( ci::vec3 position, float radius,
                                    ci::mtl::DataBufferRef instanceBuffer, unsigned int numInstances )
{
    mtl::ScopedModelMatrix matModel;
    mtl::translate(position);
    mtl::scale(vec3(radius));
    const float circleInnerRadius = 0.f;
    setVertexBytesAtIndex(&circleInnerRadius, sizeof(float), ciBufferIndexCustom0);
    draw( mtl::getStockBatchRing(), instanceBuffer, numInstances );
}

void RenderEncoder::drawBillboardCircle( ci::vec3 position, float radius,
                                         ci::mtl::DataBufferRef instanceBuffer, unsigned int numInstances )
{
    mtl::ScopedModelMatrix matModel;
    mtl::translate(position);
    mtl::scale(vec3(radius));
    const float circleInnerRadius = 0.f;
    setVertexBytesAtIndex(&circleInnerRadius, sizeof(float), ciBufferIndexCustom0);
    draw( mtl::getStockBatchBillboardRing(), instanceBuffer, numInstances );
}

void RenderEncoder::drawRing( ci::vec3 position, float outerRadius, float innerRadius,
                              ci::mtl::DataBufferRef instanceBuffer, unsigned int numInstances )
{
    mtl::ScopedModelMatrix matModel;
    mtl::translate(position);
    mtl::scale(vec3(outerRadius));
    const float circleInnerRadius = innerRadius / outerRadius;
    setVertexBytesAtIndex(&circleInnerRadius, sizeof(float), ciBufferIndexCustom0);
    draw( mtl::getStockBatchRing(), instanceBuffer, numInstances );
}

void RenderEncoder::drawStrokedRect( ci::Rectf rect,
                                     ci::mtl::DataBufferRef instanceBuffer, unsigned int numInstances )
{
    mtl::ScopedModelMatrix matModel;
    mtl::translate(ci::vec3(rect.getCenter(), 0));
    mtl::scale(vec3(rect.getWidth(), rect.getHeight(), 1));
    draw( mtl::getStockBatchWireRect(), instanceBuffer, numInstances );
}

void RenderEncoder::drawSolidRect( ci::Rectf rect,
                                   ci::mtl::DataBufferRef instanceBuffer, unsigned int numInstances )
{
    mtl::ScopedModelMatrix matModel;
    mtl::translate(ci::vec3(rect.getCenter(), 0));
    mtl::scale(vec3(rect.getWidth(), rect.getHeight(), 1));
    draw( mtl::getStockBatchSolidRect(), instanceBuffer, numInstances );
}

void RenderEncoder::drawCube( ci::vec3 position, ci::vec3 size,
                              ci::mtl::DataBufferRef instanceBuffer, unsigned int numInstances )
{
    mtl::ScopedModelMatrix matModel;
    mtl::translate(position);
    mtl::scale(size);
    draw( mtl::getStockBatchCube(), instanceBuffer, numInstances );
}

void RenderEncoder::drawSphere( ci::vec3 position, float radius,
                                ci::mtl::DataBufferRef instanceBuffer, unsigned int numInstances )
{
    mtl::ScopedModelMatrix matModel;
    mtl::translate(position);
    mtl::scale(vec3(radius * 2.f)); // NOTE: default sphere radius is 0.5
    draw( mtl::getStockBatchSphere(), instanceBuffer, numInstances );
}

void RenderEncoder::drawLines( std::vector<ci::vec3> lines, bool isLineStrip,
                               ci::mtl::DataBufferRef instanceBuffer, unsigned int numInstances )
{
    vector<unsigned int> indices;
    for ( int i = 0; i < lines.size(); ++i )
    {
        indices.push_back(i);
    }
    auto lineBuffer = mtl::VertexBuffer::create(lines.size(),
                                                mtl::DataBuffer::create(lines, mtl::DataBuffer::Format().label("LineVerts")),
                                                mtl::DataBuffer::create(indices),
                                                isLineStrip ? mtl::geom::LINE_STRIP : mtl::geom::LINE);
    setIdentityInstance();
    draw( lineBuffer, mtl::getStockPipelineWire(), instanceBuffer, numInstances );
}

void RenderEncoder::drawLine( ci::vec3 from, ci::vec3 to,
                              ci::mtl::DataBufferRef instanceBuffer, unsigned int numInstances )
{
    drawLines({{from, to}}, false, instanceBuffer, numInstances );
}

static mtl::VertexBufferRef sColoredCubeBuffer;
void RenderEncoder::drawColoredCube( ci::vec3 position, ci::vec3 size,
                                     ci::mtl::DataBufferRef instanceBuffer, unsigned int numInstances )
{
    if ( !sColoredCubeBuffer )
    {
        sColoredCubeBuffer = mtl::VertexBuffer::create( ci::geom::Cube()
                                                       .size(vec3(1.f))
                                                       .colors(Color(1,0,0),Color(0,1,0),Color(0,0,1),
                                                               Color(1,1,0),Color(0,1,1),Color(1,0,1)),
                                                       {{ ci::geom::POSITION, ci::geom::NORMAL, ci::geom::COLOR }});
    }
    mtl::ScopedModelMatrix matModel;
    mtl::translate(position);
    mtl::scale(size);
    setIdentityInstance();
    draw(sColoredCubeBuffer, mtl::getStockPipelineColoredGeom(), instanceBuffer, numInstances);
}

// Draw a texture
void RenderEncoder::draw( mtl::TextureBufferRef & texture, ci::Rectf rect,
                          ci::mtl::DataBufferRef instanceBuffer, unsigned int numInstances )
{
    mtl::ScopedModelMatrix matModel;
    if ( rect.getWidth() != 0 && rect.getHeight() != 0 )
    {
        mtl::translate(ci::vec3(rect.getCenter(), 0));
        mtl::scale(vec3(rect.getWidth(), rect.getHeight(), 1));
    }
    else
    {
        mtl::scale(vec3(texture->getWidth(), texture->getHeight(), 1));
    }
    
    setTexture(texture);
    
    switch ( texture->getFormat().getTextureType() )
    {
        case mtl::TextureType2DArray:
            draw(mtl::getStockBatchMultiTexturedRect(), instanceBuffer, numInstances);
            break;
        case mtl::TextureType2D:
            draw(mtl::getStockBatchTexturedRect(), instanceBuffer, numInstances);
            break;
        default:
            CI_LOG_E("No default shader for texture type " << texture->getFormat().getTextureType());
            assert(false);
            break;
    }
}

// Draw a texture facing the cam
void RenderEncoder::drawBillboard( mtl::TextureBufferRef & texture,
                                   ci::mtl::DataBufferRef instanceBuffer, unsigned int numInstances )
{
    setTexture(texture);
    
    switch ( texture->getFormat().getTextureType() )
    {
        case mtl::TextureType2DArray:
            draw(mtl::getStockBatchMultiBillboard(), instanceBuffer, numInstances);
            break;
        case mtl::TextureType2D:
             draw(mtl::getStockBatchBillboard(), instanceBuffer, numInstances);
            break;
        default:
            CI_LOG_E("No default shader for texture type " << texture->getFormat().getTextureType());
            assert(false);
            break;
    }
}

static mtl::DepthStateRef sDepthEnabledState;
void RenderEncoder::enableDepth()
{
    if ( !sDepthEnabledState )
    {
        sDepthEnabledState = mtl::DepthState::create(mtl::DepthState::Format()
                                                     .depthWriteEnabled(true));
        
    }
    setDepthStencilState(sDepthEnabledState);
}

static mtl::DepthStateRef sDepthDisabledState;
void RenderEncoder::disableDepth()
{
    if ( !sDepthDisabledState )
    {
        sDepthDisabledState = mtl::DepthState::create(mtl::DepthState::Format()
                                                      .depthWriteEnabled(false)
                                                      .depthCompareFunction(mtl::CompareFunctionAlways));
    }
    setDepthStencilState(sDepthDisabledState);
}
