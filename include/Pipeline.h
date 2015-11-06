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

#if defined( __OBJC__ )
@class PipelineImpl;
#else
class PipelineImpl;
#endif

namespace cinder { namespace mtl {
    
    typedef std::shared_ptr<class Pipeline> PipelineRef;
    
    class Pipeline
    {
        
//        friend class RenderEncoder;
        
    public:
        
        struct Format
        {
            Format() :
            mSampleCount(1)
            ,mDepthEnabled(false)
            ,mBlendingEnabled(false)
            ,mColorBlendOperation(0) // MTLBlendOperationAdd
            ,mAlphaBlendOperation(0) // MTLBlendOperationAdd
            ,mSrcColorBlendFactor(4) // MTLBlendFactorSourceAlpha
            ,mSrcAlphaBlendFactor(4) // MTLBlendFactorSourceAlpha
            ,mDstColorBlendFactor(5) // MTLBlendFactorOneMinusSourceAlpha
            ,mDstAlphaBlendFactor(5) // MTLBlendFactorOneMinusSourceAlpha
            {}
            ~Format(){}

            FORMAT_OPTION(sampleCount, SampleCount, int)
            FORMAT_OPTION(depthEnabled, DepthEnabled, bool)
            FORMAT_OPTION(blendingEnabled, BlendingEnabled, bool)
            FORMAT_OPTION(colorBlendOperation, ColorBlendOperation, int)
            FORMAT_OPTION(alphaBlendOperation, AlphaBlendOperation, int)
            FORMAT_OPTION(srcColorBlendFactor, SrcColorBlendFactor, int)
            FORMAT_OPTION(srcAlphaBlendFactor, SrcAlphaBlendFactor, int)
            FORMAT_OPTION(dstColorBlendFactor, DstColorBlendFactor, int)
            FORMAT_OPTION(dstAlphaBlendFactor, DstAlphaBlendFactor, int)
        };
        
        static PipelineRef create(  const std::string & vertShaderName, const std::string & fragShaderName, Format format );
        virtual ~Pipeline(){}
        
        void * getNative(); // <MTLRenderPipelineState>
        
        
        // TODO: Refactor
        // TODO: Remove these
        void * getPipelineState(); // <MTLRenderPipelineState>
        void * getDepthState(); // <MTLRenderDepthStencilState>

    protected:
        
        Pipeline( const std::string & vertShaderName, const std::string & fragShaderName, Format format );
        
        PipelineImpl *mImpl;
        Format mFormat;
        
    };
    
} }