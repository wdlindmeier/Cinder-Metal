//
//  SamplerState.hpp
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

        public:

            Format& mipFilter( SamplerMipFilter mipFilter ) { setMipFilter( mipFilter ); return *this; };
            void setMipFilter( SamplerMipFilter mipFilter ) { mMipFilter = mipFilter; };
            SamplerMipFilter getMipFilter() const { return mMipFilter; };

            Format& maxAnisotropy( int maxAnisotropy ) { setMaxAnisotropy( maxAnisotropy ); return *this; };
            void setMaxAnisotropy( int maxAnisotropy ) { mMaxAnisotropy = maxAnisotropy; };
            int getMaxAnisotropy() const { return mMaxAnisotropy; };

            Format& minFilter( SamplerMinMagFilter minFilter ) { setMinFilter( minFilter ); return *this; };
            void setMinFilter( SamplerMinMagFilter minFilter ) { mMinFilter = minFilter; };
            SamplerMinMagFilter getMinFilter() const { return mMinFilter; };

            Format& magFilter( SamplerMinMagFilter magFilter ) { setMagFilter( magFilter ); return *this; };
            void setMagFilter( SamplerMinMagFilter magFilter ) { mMagFilter = magFilter; };
            SamplerMinMagFilter getMagFilter() const { return mMagFilter; };

            Format& sAddressMode( SamplerAddressMode sAddressMode ) { setSAddressMode( sAddressMode ); return *this; };
            void setSAddressMode( SamplerAddressMode sAddressMode ) { mSAddressMode = sAddressMode; };
            SamplerAddressMode getSAddressMode() const { return mSAddressMode; };

            Format& tAddressMode( SamplerAddressMode tAddressMode ) { setTAddressMode( tAddressMode ); return *this; };
            void setTAddressMode( SamplerAddressMode tAddressMode ) { mTAddressMode = tAddressMode; };
            SamplerAddressMode getTAddressMode() const { return mTAddressMode; };

            Format& rAddressMode( SamplerAddressMode rAddressMode ) { setRAddressMode( rAddressMode ); return *this; };
            void setRAddressMode( SamplerAddressMode rAddressMode ) { mRAddressMode = rAddressMode; };
            SamplerAddressMode getRAddressMode() const { return mRAddressMode; };

            Format& normalizedCoordinates( int normalizedCoordinates ) { setNormalizedCoordinates( normalizedCoordinates ); return *this; };
            void setNormalizedCoordinates( int normalizedCoordinates ) { mNormalizedCoordinates = normalizedCoordinates; };
            int getNormalizedCoordinates() const { return mNormalizedCoordinates; };

            Format& lodMinClamp( int lodMinClamp ) { setLodMinClamp( lodMinClamp ); return *this; };
            void setLodMinClamp( int lodMinClamp ) { mLodMinClamp = lodMinClamp; };
            int getLodMinClamp() const { return mLodMinClamp; };

            Format& lodMaxClamp( int lodMaxClamp ) { setLodMaxClamp( lodMaxClamp ); return *this; };
            void setLodMaxClamp( int lodMaxClamp ) { mLodMaxClamp = lodMaxClamp; };
            int getLodMaxClamp() const { return mLodMaxClamp; };
#if defined( CINDER_COCOA_TOUCH )
            Format& lodAverage( int lodAverage ) { setLodAverage( lodAverage ); return *this; };
            void setLodAverage( int lodAverage ) { mLodAverage = lodAverage; };
            int getLodAverage() const { return mLodAverage; };
#endif
            Format& compareFunction( CompareFunction compareFunction ) { setCompareFunction( compareFunction ); return *this; };
            void setCompareFunction( CompareFunction compareFunction ) { mCompareFunction = compareFunction; };
            CompareFunction getCompareFunction() const { return mCompareFunction; };

            Format& label( std::string label ) { setLabel( label ); return *this; };
            void setLabel( std::string label ) { mLabel = label; };
            std::string getLabel() const { return mLabel; };

        protected:
            
            SamplerMipFilter mMipFilter;
            int mMaxAnisotropy;
            SamplerMinMagFilter mMinFilter;
            SamplerMinMagFilter mMagFilter;
            SamplerAddressMode mSAddressMode;
            SamplerAddressMode mTAddressMode;
            SamplerAddressMode mRAddressMode;
            int mNormalizedCoordinates;
            int mLodMinClamp;
            int mLodMaxClamp;
#if defined( CINDER_COCOA_TOUCH )
            int mLodAverage;
#endif
            CompareFunction mCompareFunction;
            std::string mLabel;

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