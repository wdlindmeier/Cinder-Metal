//
//  MetalPipeline.hpp
//  MetalCube
//
//  Created by William Lindmeier on 10/13/15.
//
//

#pragma once

#include "cinder/Cinder.h"

#if defined( __OBJC__ )
@class MetalPipelineImpl;
#else
class MetalPipelineImpl;
#endif

namespace cinder { namespace mtl {
    
    typedef std::shared_ptr<class MetalPipeline> MetalPipelineRef;
    
    class MetalPipeline
    {
        
        friend class MetalRenderEncoder;
        
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
            
        };
        
        static MetalPipelineRef create(  const std::string & vertShaderName, const std::string & fragShaderName, Format format );
        virtual ~MetalPipeline(){}

    protected:
        
        MetalPipeline( const std::string & vertShaderName, const std::string & fragShaderName, Format format );
        
        MetalPipelineImpl *mImpl;
        Format mFormat;
        
    };
    
} }