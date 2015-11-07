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

    // Set some defaults so the user doesnt have to call these
    setFragSamplerState( SamplerState() );
    setDepthStencilState( DepthState() );

    CFRetain(mImpl);
}

RenderEncoder::~RenderEncoder()
{
    CFRelease(mImpl);
}

void RenderEncoder::setDepthStencilState( const DepthState & depthState )
{
    MTLDepthStencilDescriptor *depthStateDesc = [[MTLDepthStencilDescriptor alloc] init];
    depthStateDesc.depthCompareFunction = (MTLCompareFunction)depthState.depthCompareFunction;
    depthStateDesc.depthWriteEnabled = depthState.depthWriteEnabled;
    if ( depthState.frontFaceStencil != nullptr )
    {
        depthStateDesc.frontFaceStencil = (__bridge MTLStencilDescriptor *)depthState.frontFaceStencil;
    }
    if ( depthState.backFaceStencil != nullptr )
    {
        depthStateDesc.backFaceStencil = (__bridge MTLStencilDescriptor *)depthState.backFaceStencil;
    }
    id<MTLDepthStencilState> mtlDepthState = [[RendererMetalImpl sharedRenderer].device
                                            newDepthStencilStateWithDescriptor:depthStateDesc];
    [IMPL setDepthStencilState:mtlDepthState];
}

void RenderEncoder::setFragSamplerState( const SamplerState & samplerState, int samplerIndex )
{
    MTLSamplerDescriptor *samplerDescriptor = [MTLSamplerDescriptor new];
    samplerDescriptor.mipFilter = (MTLSamplerMipFilter)samplerState.mipFilter;
    samplerDescriptor.maxAnisotropy = samplerState.maxAnisotropy;// 3;
    samplerDescriptor.minFilter = (MTLSamplerMinMagFilter)samplerState.minFilter;
    samplerDescriptor.magFilter = (MTLSamplerMinMagFilter)samplerState.magFilter;
    samplerDescriptor.sAddressMode = (MTLSamplerAddressMode)samplerState.sAddressMode;
    samplerDescriptor.tAddressMode = (MTLSamplerAddressMode)samplerState.tAddressMode;
    samplerDescriptor.rAddressMode = (MTLSamplerAddressMode)samplerState.rAddressMode;
    samplerDescriptor.normalizedCoordinates = samplerState.normalizedCoordinates;
    samplerDescriptor.lodMinClamp = samplerState.lodMinClamp;
    samplerDescriptor.lodMaxClamp = samplerState.lodMaxClamp;
    samplerDescriptor.lodAverage = samplerState.lodAverage;
    samplerDescriptor.compareFunction = (MTLCompareFunction)samplerState.compareFunction;

    id <MTLSamplerState> linearMipSamplerState = [[RendererMetalImpl sharedRenderer].device
                                                  newSamplerStateWithDescriptor:samplerDescriptor];
    [IMPL setFragmentSamplerState:linearMipSamplerState atIndex:samplerIndex];
}

void RenderEncoder::setPipelineState( PipelineRef pipeline )
{
    [IMPL setRenderPipelineState:(__bridge id <MTLRenderPipelineState>)pipeline->getNative()];
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
