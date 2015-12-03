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

namespace cinder { namespace mtl {
    
    typedef std::shared_ptr<class SamplerState> SamplerStateRef;
    
    class SamplerState
    {
        
    public:
        
        struct Format
        {
            Format() :
            mMipFilter(-1) // defaults to MTLSamplerMipFilterLinear
            ,mMaxAnisotropy(3)
            ,mMinFilter(-1) // defaults to MTLSamplerMinMagFilterLinear
            ,mMagFilter(-1) // defaults to MTLSamplerMinMagFilterLinear
            ,mSAddressMode(-1) // defaults to MTLSamplerAddressModeClampToEdge
            ,mTAddressMode(-1) // defaults to MTLSamplerAddressModeClampToEdge
            ,mRAddressMode(-1) // defaults to MTLSamplerAddressModeClampToEdge
            ,mNormalizedCoordinates(true)
            ,mLodMinClamp(0.f)
            ,mLodMaxClamp(FLT_MAX)
#if defined( CINDER_COCOA_TOUCH )
            ,mLodAverage(false)
#endif
            ,mCompareFunction(-1) // defaults to MTLCompareFunctionNever
            ,mLabel("Default Sampler State")
            {}
            
            FORMAT_OPTION(mipFilter, MipFilter, int) // MTLSamplerMipFilter
            FORMAT_OPTION(maxAnisotropy, MaxAnisotropy, int)
            FORMAT_OPTION(minFilter, MinFilter, int) // MTLSamplerMinMagFilter
            FORMAT_OPTION(magFilter, MagFilter, int) // MTLSamplerMinMagFilter
            FORMAT_OPTION(sAddressMode, SAddressMode, int) // MTLSamplerAddressMode
            FORMAT_OPTION(tAddressMode, TAddressMode, int) // MTLSamplerAddressMode
            FORMAT_OPTION(rAddressMode, RAddressMode, int) // MTLSamplerAddressMode
            FORMAT_OPTION(normalizedCoordinates, NormalizedCoordinates, int)
            FORMAT_OPTION(lodMinClamp, LodMinClamp, int)
            FORMAT_OPTION(lodMaxClamp, LodMaxClamp, int)
#if defined( CINDER_COCOA_TOUCH )
            FORMAT_OPTION(lodAverage, LodAverage, int)
#endif
            FORMAT_OPTION(compareFunction, CompareFunction, int) // MTLCompareFunction
            FORMAT_OPTION(label, Label, std::string)
        };
        
        static SamplerStateRef create( const Format & format = Format() )
        {
            return SamplerStateRef( new SamplerState(format) );
        }
        virtual ~SamplerState();
        
        void * getNative(){ return mImpl; }
        
    protected:
        
        SamplerState( Format format );
        
        void * mImpl = NULL; // <MTLSamplerState>
        Format mFormat;
        
    };
    
} }