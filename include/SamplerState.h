//
//  SamplerState.hpp
//  MetalCube
//
//  Created by William Lindmeier on 11/7/15.
//
//

#pragma once

#include "cinder/Cinder.h"
#include "MetalHelpers.hpp"
#include "MetalEnums.h"

namespace cinder { namespace mtl {
    
    typedef std::shared_ptr<class SamplerState> SamplerStateRef;
    
    class SamplerState
    {
        
    public:
        
        struct Format
        {
            Format() :
            mMipFilter(SamplerMipFilterLinear)
            ,mMaxAnisotropy(3)
            ,mMinFilter(SamplerMinMagFilterLinear)
            ,mMagFilter(SamplerMinMagFilterLinear)
            ,mSAddressMode(SamplerAddressModeClampToEdge)
            ,mTAddressMode(SamplerAddressModeClampToEdge)
            ,mRAddressMode(SamplerAddressModeClampToEdge)
            ,mNormalizedCoordinates(true)
            ,mLodMinClamp(0.f)
            ,mLodMaxClamp(FLT_MAX)
#if defined( CINDER_COCOA_TOUCH )
            ,mLodAverage(false)
#endif
            ,mCompareFunction(CompareFunctionNever)
            ,mLabel("Default Sampler State")
            {}
            
            FORMAT_OPTION(mipFilter, MipFilter, SamplerMipFilter)
            FORMAT_OPTION(maxAnisotropy, MaxAnisotropy, int)
            FORMAT_OPTION(minFilter, MinFilter, SamplerMinMagFilter)
            FORMAT_OPTION(magFilter, MagFilter, SamplerMinMagFilter)
            FORMAT_OPTION(sAddressMode, SAddressMode, SamplerAddressMode)
            FORMAT_OPTION(tAddressMode, TAddressMode, SamplerAddressMode)
            FORMAT_OPTION(rAddressMode, RAddressMode, SamplerAddressMode)
            FORMAT_OPTION(normalizedCoordinates, NormalizedCoordinates, int)
            FORMAT_OPTION(lodMinClamp, LodMinClamp, int)
            FORMAT_OPTION(lodMaxClamp, LodMaxClamp, int)
#if defined( CINDER_COCOA_TOUCH )
            FORMAT_OPTION(lodAverage, LodAverage, int)
#endif
            FORMAT_OPTION(compareFunction, CompareFunction, CompareFunction)
            FORMAT_OPTION(label, Label, std::string)
        };
        
        static SamplerStateRef create( const Format & format = Format() )
        {
            return SamplerStateRef( new SamplerState(format) );
        }
        
        static SamplerStateRef create( void * mtlSamplerState )
        {
            return SamplerStateRef( new SamplerState(mtlSamplerState) );
        }

        virtual ~SamplerState();
        
        void * getNative(){ return mImpl; }
        
    protected:
        
        SamplerState( Format format );
        SamplerState( void * mtlSamplerState );
        
        void * mImpl = NULL; // <MTLSamplerState>
        Format mFormat;
        
    };    
} }