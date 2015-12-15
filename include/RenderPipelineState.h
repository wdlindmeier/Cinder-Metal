//
//  Pipeline.hpp
//  MetalCube
//
//  Created by William Lindmeier on 10/13/15.
//
//

#pragma once

#include "cinder/Cinder.h"
#include "MetalHelpers.hpp"
#include "MetalEnums.h"

namespace cinder { namespace mtl {
    
    typedef std::shared_ptr<class RenderPipelineState> RenderPipelineStateRef;
    
    class RenderPipelineState
    {
        
    public:
        
        struct Format
        {
            Format() :
            mSampleCount(1)
            ,mBlendingEnabled(false)
            ,mColorBlendOperation(BlendOperationAdd)
            ,mAlphaBlendOperation(BlendOperationAdd)
            ,mSrcColorBlendFactor(BlendFactorSourceAlpha)
            ,mSrcAlphaBlendFactor(BlendFactorSourceAlpha)
            ,mDstColorBlendFactor(BlendFactorOneMinusSourceAlpha)
            ,mDstAlphaBlendFactor(BlendFactorOneMinusSourceAlpha)
            ,mLabel("Default Pipeline")
            ,mPixelFormat(PixelFormatBGRA8Unorm)
            {}

        public:

            Format& sampleCount( int sampleCount ) { setSampleCount( sampleCount ); return *this; };
            void setSampleCount( int sampleCount ) { mSampleCount = sampleCount; };
            int getSampleCount() { return mSampleCount; };

            Format& blendingEnabled( bool blendingEnabled ) { setBlendingEnabled( blendingEnabled ); return *this; };
            void setBlendingEnabled( bool blendingEnabled ) { mBlendingEnabled = blendingEnabled; };
            bool getBlendingEnabled() { return mBlendingEnabled; };

            Format& colorBlendOperation( BlendOperation colorBlendOperation ) { setColorBlendOperation( colorBlendOperation ); return *this; };
            void setColorBlendOperation( BlendOperation colorBlendOperation ) { mColorBlendOperation = colorBlendOperation; };
            BlendOperation getColorBlendOperation() { return mColorBlendOperation; };

            Format& alphaBlendOperation( BlendOperation alphaBlendOperation ) { setAlphaBlendOperation( alphaBlendOperation ); return *this; };
            void setAlphaBlendOperation( BlendOperation alphaBlendOperation ) { mAlphaBlendOperation = alphaBlendOperation; };
            BlendOperation getAlphaBlendOperation() { return mAlphaBlendOperation; };

            Format& srcColorBlendFactor( BlendFactor srcColorBlendFactor ) { setSrcColorBlendFactor( srcColorBlendFactor ); return *this; };
            void setSrcColorBlendFactor( BlendFactor srcColorBlendFactor ) { mSrcColorBlendFactor = srcColorBlendFactor; };
            BlendFactor getSrcColorBlendFactor() { return mSrcColorBlendFactor; };

            Format& srcAlphaBlendFactor( BlendFactor srcAlphaBlendFactor ) { setSrcAlphaBlendFactor( srcAlphaBlendFactor ); return *this; };
            void setSrcAlphaBlendFactor( BlendFactor srcAlphaBlendFactor ) { mSrcAlphaBlendFactor = srcAlphaBlendFactor; };
            BlendFactor getSrcAlphaBlendFactor() { return mSrcAlphaBlendFactor; };

            Format& dstColorBlendFactor( BlendFactor dstColorBlendFactor ) { setDstColorBlendFactor( dstColorBlendFactor ); return *this; };
            void setDstColorBlendFactor( BlendFactor dstColorBlendFactor ) { mDstColorBlendFactor = dstColorBlendFactor; };
            BlendFactor getDstColorBlendFactor() { return mDstColorBlendFactor; };

            Format& dstAlphaBlendFactor( BlendFactor dstAlphaBlendFactor ) { setDstAlphaBlendFactor( dstAlphaBlendFactor ); return *this; };
            void setDstAlphaBlendFactor( BlendFactor dstAlphaBlendFactor ) { mDstAlphaBlendFactor = dstAlphaBlendFactor; };
            BlendFactor getDstAlphaBlendFactor() { return mDstAlphaBlendFactor; };

            Format& label( std::string label ) { setLabel( label ); return *this; };
            void setLabel( std::string label ) { mLabel = label; };
            std::string getLabel() { return mLabel; };

            Format& pixelFormat( PixelFormat pixelFormat ) { setPixelFormat( pixelFormat ); return *this; };
            void setPixelFormat( PixelFormat pixelFormat ) { mPixelFormat = pixelFormat; };
            PixelFormat getPixelFormat() { return mPixelFormat; };

        protected:
            
            int mSampleCount;
            bool mBlendingEnabled;
            BlendOperation mColorBlendOperation;
            BlendOperation mAlphaBlendOperation;
            BlendFactor mSrcColorBlendFactor;
            BlendFactor mSrcAlphaBlendFactor;
            BlendFactor mDstColorBlendFactor;
            BlendFactor mDstAlphaBlendFactor;
            std::string mLabel;
            PixelFormat mPixelFormat;
            
        };
        
        static RenderPipelineStateRef create( const std::string & vertShaderName,
                                              const std::string & fragShaderName,
                                              const Format & format = Format() )
        {
            return RenderPipelineStateRef( new RenderPipelineState(vertShaderName, fragShaderName, format) );
        }
        
        static RenderPipelineStateRef create( void * mtlRenderPipelineStateRef )
        {
            return RenderPipelineStateRef( new RenderPipelineState(mtlRenderPipelineStateRef) );
        }
        
        virtual ~RenderPipelineState();
        
        void * getNative(){ return mImpl; }

    protected:
        
        RenderPipelineState( const std::string & vertShaderName, const std::string & fragShaderName, Format format );
        RenderPipelineState( void * mtlRenderPipelineStateRef );

        void * mImpl = NULL;  // <MTLRenderPipelineState>
        Format mFormat;
        
    };
    
} }