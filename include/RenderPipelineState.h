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

            FORMAT_OPTION(sampleCount, SampleCount, int)
            FORMAT_OPTION(blendingEnabled, BlendingEnabled, bool)
            FORMAT_OPTION(colorBlendOperation, ColorBlendOperation, BlendOperation)
            FORMAT_OPTION(alphaBlendOperation, AlphaBlendOperation, BlendOperation)
            FORMAT_OPTION(srcColorBlendFactor, SrcColorBlendFactor, BlendFactor)
            FORMAT_OPTION(srcAlphaBlendFactor, SrcAlphaBlendFactor, BlendFactor)
            FORMAT_OPTION(dstColorBlendFactor, DstColorBlendFactor, BlendFactor)
            FORMAT_OPTION(dstAlphaBlendFactor, DstAlphaBlendFactor, BlendFactor)
            FORMAT_OPTION(label, Label, std::string)
            FORMAT_OPTION(pixelFormat, PixelFormat, PixelFormat) 
        };
        
        static RenderPipelineStateRef create( const std::string & vertShaderName,
                                              const std::string & fragShaderName,
                                              const Format & format = Format() );
        virtual ~RenderPipelineState();
        
        void * getNative(){ return mImpl; }

    protected:
        
        RenderPipelineState( const std::string & vertShaderName, const std::string & fragShaderName, Format format );

        void * mImpl = NULL;  // <MTLRenderPipelineState>
        Format mFormat;
        
    };
    
} }