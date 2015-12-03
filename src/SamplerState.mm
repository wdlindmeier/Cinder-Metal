//
//  SamplerState.cpp
//  MetalCube
//
//  Created by William Lindmeier on 11/7/15.
//
//

#include "SamplerState.h"
#include <Metal/Metal.h>
#include "RendererMetalImpl.h"

using namespace ci;
using namespace ci::mtl;

SamplerState::SamplerState( Format format )
{
    SET_FORMAT_DEFAULT(format, MipFilter, MTLSamplerMipFilterLinear);
    SET_FORMAT_DEFAULT(format, MinFilter, MTLSamplerMinMagFilterLinear);
    SET_FORMAT_DEFAULT(format, MagFilter, MTLSamplerMinMagFilterLinear);
    SET_FORMAT_DEFAULT(format, SAddressMode, MTLSamplerAddressModeClampToEdge);
    SET_FORMAT_DEFAULT(format, TAddressMode, MTLSamplerAddressModeClampToEdge);
    SET_FORMAT_DEFAULT(format, RAddressMode, MTLSamplerAddressModeClampToEdge);
    SET_FORMAT_DEFAULT(format, CompareFunction, MTLCompareFunctionNever);
    
    MTLSamplerDescriptor *samplerDescriptor = [MTLSamplerDescriptor new];
    samplerDescriptor.mipFilter = (MTLSamplerMipFilter)format.getMipFilter();
    samplerDescriptor.maxAnisotropy = format.getMaxAnisotropy();
    samplerDescriptor.minFilter = (MTLSamplerMinMagFilter)format.getMinFilter();
    samplerDescriptor.magFilter = (MTLSamplerMinMagFilter)format.getMagFilter();
    samplerDescriptor.sAddressMode = (MTLSamplerAddressMode)format.getSAddressMode();
    samplerDescriptor.tAddressMode = (MTLSamplerAddressMode)format.getTAddressMode();
    samplerDescriptor.rAddressMode = (MTLSamplerAddressMode)format.getRAddressMode();
    samplerDescriptor.normalizedCoordinates = format.getNormalizedCoordinates();
    samplerDescriptor.lodMinClamp = format.getLodMinClamp();
    samplerDescriptor.lodMaxClamp = format.getLodMaxClamp();
#if defined( CINDER_COCOA_TOUCH )
    samplerDescriptor.lodAverage = format.getLodAverage();
#endif
    samplerDescriptor.compareFunction = (MTLCompareFunction)format.getCompareFunction();
    
    mImpl = (__bridge_retained void *)[[RendererMetalImpl sharedRenderer].device
                                       newSamplerStateWithDescriptor:samplerDescriptor];
}

SamplerState::~SamplerState()
{
    if ( mImpl )
    {
        CFRelease(mImpl);
    }
}