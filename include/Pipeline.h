//
//  Pipeline.hpp
//  MetalCube
//
//  Created by William Lindmeier on 10/13/15.
//
//

#pragma once

#include "cinder/Cinder.h"

#if defined( __OBJC__ )
@class PipelineImpl;
#else
class PipelineImpl;
#endif

namespace cinder { namespace mtl {
    
    typedef std::shared_ptr<class Pipeline> PipelineRef;
    
    class Pipeline
    {
        
        friend class RenderEncoder;
        
    public:
        
        class Format
        {
            
            bool mEnableDepth;
            int mSampleCount;
            
        public:
            
            Format() :
            mEnableDepth(true)
            ,mSampleCount(1)
            {}
            ~Format(){}
            
            Format & depth( bool depthIsEnabled ){ mEnableDepth = depthIsEnabled; return *this; };
            bool depth(){ return mEnableDepth; };
            
            Format & sampleCount( int numSamples ){ mSampleCount = numSamples; return *this; };
            int sampleCount(){ return mSampleCount; }
            
            // TODO: Add alpha here
            //MTLRenderPipelineColorAttachmentDescriptor *renderbufferAttachment = pipelineDescriptor.colorAttachments[0];
            
        };
        
        static PipelineRef create(  const std::string & vertShaderName, const std::string & fragShaderName, Format format );
        virtual ~Pipeline(){}

    protected:
        
        Pipeline( const std::string & vertShaderName, const std::string & fragShaderName, Format format );
        
        PipelineImpl *mImpl;
        Format mFormat;
        
    };
    
} }