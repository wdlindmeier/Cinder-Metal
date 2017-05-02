//
//  SamplerState.cpp
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

SamplerState::SamplerState( void * mtlSamplerState ) :
mImpl(mtlSamplerState)
{
    assert(mImpl != NULL);
    assert([(__bridge id)mImpl conformsToProtocol:@protocol(MTLSamplerState)]);
    CFRetain(mImpl);
}

SamplerState::~SamplerState()
{
    if ( mImpl )
    {
        CFRelease(mImpl);
    }
}