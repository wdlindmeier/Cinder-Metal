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
#include "RenderBuffer.h"

namespace cinder { namespace mtl {

    class ScopedRenderEncoder : public RenderEncoder
    {
        friend class ScopedRenderBuffer;
    public:
        ~ScopedRenderEncoder();
    private:
        ScopedRenderEncoder( void * mtlRenderCommandEncoder );
    };
    
    class ScopedComputeEncoder : public ComputeEncoder
    {
        friend class ScopedCommandBuffer;
    public:
        ~ScopedComputeEncoder();
    private:
        ScopedComputeEncoder( void * mtlComputeEncoder );
    };
    
    class ScopedBlitEncoder : public BlitEncoder
    {
        friend class ScopedCommandBuffer;
    public:
        ~ScopedBlitEncoder();
    private:
        ScopedBlitEncoder( void * mtlBlitEncoder );
    };
    
    class ScopedCommandBuffer : public CommandBuffer
    {
    public:
        ScopedCommandBuffer( bool waitUntilCompleted = false,
                             const std::string & bufferName = "Scoped Command Buffer" );
        ~ScopedCommandBuffer();
        
        void addCompletionHandler( std::function< void( void * mtlCommandBuffer) > handler ){
            mCompletionHandler = handler;
        }
        
        ScopedComputeEncoder scopedComputeEncoder( const std::string & bufferName = "Scoped Compute Encoder" );
        ScopedBlitEncoder scopedBlitEncoder( const std::string & bufferName = "Scoped Blit Encoder" );
        
    private:
        bool mWaitUntilCompleted;
        std::function< void( void * mtlCommandBuffer) > mCompletionHandler;
    };
    
    class ScopedRenderBuffer : public RenderBuffer
    {
    public:
        ScopedRenderBuffer( bool waitUntilCompleted = false,
                            const std::string & bufferName = "Scoped Render Buffer" );
        ~ScopedRenderBuffer();
        
        void addCompletionHandler( std::function< void( void * mtlCommandBuffer) > handler ){
            mCompletionHandler = handler;
        }
        
        ScopedRenderEncoder scopedRenderEncoder( const RenderPassDescriptorRef & descriptor,
                                                 const std::string & bufferName = "Scoped Render Encoder" );
        
    private:
        bool mWaitUntilCompleted;
        std::function< void( void * mtlCommandBuffer) > mCompletionHandler;        
    };

}}
