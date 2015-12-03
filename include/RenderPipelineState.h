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
            ,mColorBlendOperation(-1) // defaults to MTLBlendOperationAdd
            ,mAlphaBlendOperation(-1) // defaults to MTLBlendOperationAdd
            ,mSrcColorBlendFactor(-1) // defaults to MTLBlendFactorSourceAlpha
            ,mSrcAlphaBlendFactor(-1) // defaults to MTLBlendFactorSourceAlpha
            ,mDstColorBlendFactor(-1) // defaults to MTLBlendFactorOneMinusSourceAlpha
            ,mDstAlphaBlendFactor(-1) // defaults to MTLBlendFactorOneMinusSourceAlpha
            ,mLabel("Default Pipeline")
            ,mPixelFormat(-1) // defaults to MTLPixelFormatBGRA8Unorm
            {}

            FORMAT_OPTION(sampleCount, SampleCount, int)
            FORMAT_OPTION(blendingEnabled, BlendingEnabled, bool)
            FORMAT_OPTION(colorBlendOperation, ColorBlendOperation, int)
            FORMAT_OPTION(alphaBlendOperation, AlphaBlendOperation, int)
            FORMAT_OPTION(srcColorBlendFactor, SrcColorBlendFactor, int)
            FORMAT_OPTION(srcAlphaBlendFactor, SrcAlphaBlendFactor, int)
            FORMAT_OPTION(dstColorBlendFactor, DstColorBlendFactor, int)
            FORMAT_OPTION(dstAlphaBlendFactor, DstAlphaBlendFactor, int)
            FORMAT_OPTION(label, Label, std::string)
            FORMAT_OPTION(pixelFormat, PixelFormat, int) // MTLPixelFormat
        };
        
        static RenderPipelineStateRef create( const std::string & vertShaderName,
                                             const std::string & fragShaderName,
                                             Format format = Format() );
        virtual ~RenderPipelineState();
        
        void * getNative(){ return mImpl; }

    protected:
        
        RenderPipelineState( const std::string & vertShaderName, const std::string & fragShaderName, Format format );

        void * mImpl = NULL;  // <MTLRenderPipelineState>
        Format mFormat;
        
    };
    
} }