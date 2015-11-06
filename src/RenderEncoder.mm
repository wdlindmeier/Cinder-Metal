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
#import "DataBufferImpl.h"
#import "PipelineImpl.h"

// TMP
#import "RendererMetalImpl.h"

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
mImpl(encoderImpl)
{
    assert( [(__bridge id)encoderImpl conformsToProtocol:@protocol(MTLRenderCommandEncoder)] );
    CFRetain(mImpl);
}

RenderEncoder::~RenderEncoder()
{
    CFRelease(mImpl);
}

void RenderEncoder::setPipeline( PipelineRef pipeline )
{
    // TODO:Refactor
    MTLSamplerDescriptor *samplerDescriptor = [MTLSamplerDescriptor new];
    samplerDescriptor.mipFilter = MTLSamplerMipFilterLinear;
    samplerDescriptor.maxAnisotropy = 3;
    samplerDescriptor.minFilter = MTLSamplerMinMagFilterLinear;
    samplerDescriptor.magFilter = MTLSamplerMinMagFilterLinear;
    samplerDescriptor.sAddressMode = MTLSamplerAddressModeClampToEdge;
    samplerDescriptor.tAddressMode = MTLSamplerAddressModeClampToEdge;
    id <MTLSamplerState> linearMipSamplerState = [[RendererMetalImpl sharedRenderer].device
                                                  newSamplerStateWithDescriptor:samplerDescriptor];
    [IMPL setFragmentSamplerState:linearMipSamplerState atIndex:0];
    
    // TODO: Refactor
    [IMPL setDepthStencilState:(__bridge id <MTLDepthStencilState>)pipeline->getDepthState()];
    [IMPL setRenderPipelineState:(__bridge id <MTLRenderPipelineState>)pipeline->getPipelineState()];
}

void RenderEncoder::pushDebugGroup( const std::string & groupName )
{
    [IMPL pushDebugGroup:(__bridge NSString *)createCfString(groupName)];
}

void RenderEncoder::setTextureAtIndex( TextureBufferRef texture, size_t index )
{
    [IMPL setFragmentTexture:(__bridge id <MTLTexture>)texture->getNative()
                     atIndex:index];
}

void RenderEncoder::setBufferAtIndex( DataBufferRef buffer, size_t index, size_t bytesOffset )
{
    [IMPL setVertexBuffer:(__bridge id <MTLBuffer>)buffer->getNative()
                   offset:bytesOffset
                  atIndex:index];
}

void RenderEncoder::draw( ci::mtl::geom::Primitive primitive, size_t vertexStart, size_t vertexCount, size_t instanceCount )
{
    [IMPL drawPrimitives:(MTLPrimitiveType)nativeMTLPrimitiveType(primitive)
             vertexStart:vertexStart
             vertexCount:vertexCount
           instanceCount:instanceCount];
}

void RenderEncoder::endEncoding()
{
    [(__bridge id<MTLRenderCommandEncoder>)mImpl endEncoding];
}

void RenderEncoder::popDebugGroup()
{
    [IMPL popDebugGroup];
}
