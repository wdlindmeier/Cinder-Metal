//
//  Scope.hpp
//  MetalCube
//
//  Created by William Lindmeier on 11/4/15.
//
//

#pragma once

#include "cinder/Cinder.h"
#include "cinder/Noncopyable.h"
#include "CommandBuffer.h"

namespace cinder { namespace mtl {

    template < class T >
    struct ScopedT : public ci::Noncopyable {
        ScopedT(){};
        virtual ~ScopedT(){}
        virtual T & operator()(){ return mInstance; };
    protected:
        T mInstance;
    };
    
    struct ScopedCommandBuffer : public ScopedT< CommandBufferRef > {
        ScopedCommandBuffer( const std::string & bufferName = "Scoped Command Buffer" );
        ~ScopedCommandBuffer();        
    };

    struct ScopedRenderEncoder : public ScopedT< RenderEncoderRef > {
        ScopedRenderEncoder( CommandBufferRef commandBuffer,
                             const RenderFormatRef format = RenderFormatRef(),
                             const std::string & encoderName = "Scoped Render Encoder" );
        ~ScopedRenderEncoder();
    };

    struct ScopedComputeEncoder : public ScopedT< ComputeEncoderRef > {
        ScopedComputeEncoder( CommandBufferRef commandBuffer,
                              const std::string & encoderName = "Scoped Compute Encoder" );
        ~ScopedComputeEncoder();
    };
    
    struct ScopedBlitEncoder : public ScopedT< BlitEncoderRef > {
        ScopedBlitEncoder( CommandBufferRef commandBuffer,                           
                           const std::string & encoderName = "Scoped Blit Encoder" );
        ~ScopedBlitEncoder();
    };

}}
