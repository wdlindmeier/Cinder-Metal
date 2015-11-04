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
}

void RenderEncoder::setPipeline( PipelineRef pipeline )
{
    // TEST
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
    
    [IMPL setDepthStencilState:pipeline->mImpl.depthState];
    [IMPL setRenderPipelineState:pipeline->mImpl.pipelineState];
}

void RenderEncoder::pushDebugGroup( const std::string & groupName )
{
    [IMPL pushDebugGroup:(__bridge NSString *)createCfString(groupName)];
}

void RenderEncoder::setTextureAtIndex( TextureBufferRef texture, size_t index )
{
    [IMPL setFragmentTexture:(__bridge id <MTLTexture>)texture->mImpl
                     atIndex:index];
}

void RenderEncoder::setBufferAtIndex( DataBufferRef buffer, size_t index, size_t bytesOffset )
{
    [IMPL setVertexBuffer:buffer->mImpl.buffer
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

void RenderEncoder::popDebugGroup()
{
    [IMPL popDebugGroup];
}
