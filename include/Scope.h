//
//  Scope.hpp
//  Cinder-Metal
//
//  Created by William Lindmeier on 11/4/15.
//
//

#pragma once

#include "cinder/Cinder.h"
#include "cinder/Noncopyable.h"
#include "CommandBuffer.h"
#include "RenderCommandBuffer.h"
#include "Context.h"

namespace cinder { namespace mtl {

    class ScopedRenderEncoder : public RenderEncoder
    {
        friend class ScopedRenderCommandBuffer;
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
    
    class ScopedRenderCommandBuffer : public RenderCommandBuffer
    {
    public:
        ScopedRenderCommandBuffer( bool waitUntilCompleted = false,
                                   const std::string & bufferName = "Scoped Render Buffer" );
        ~ScopedRenderCommandBuffer();
        
        void addCompletionHandler( std::function< void( void * mtlCommandBuffer) > handler ){
            mCompletionHandler = handler;
        }
        
        ScopedRenderEncoder scopedRenderEncoder( const RenderPassDescriptorRef & descriptor,
                                                 const std::string & bufferName = "Scoped Render Encoder" );
        
    private:
        bool mWaitUntilCompleted;
        std::function< void( void * mtlCommandBuffer) > mCompletionHandler;        
    };
    
    // Context Scopes
    
    struct ScopedModelMatrix : private Noncopyable
    {
        ScopedModelMatrix()		{ pushModelMatrix(); }
        ~ScopedModelMatrix()	{ popModelMatrix(); }
    };
    
    struct ScopedViewMatrix : private Noncopyable
    {
        ScopedViewMatrix()	{ pushViewMatrix(); }
        ~ScopedViewMatrix()	{ popViewMatrix(); }
    };
    
    struct ScopedProjectionMatrix : private Noncopyable
    {
        ScopedProjectionMatrix()	{ pushProjectionMatrix(); }
        ~ScopedProjectionMatrix()	{ popProjectionMatrix(); }
    };
    
    //! Preserves all matrices
    struct ScopedMatrices : private Noncopyable
    {
        ScopedMatrices()	{ pushMatrices(); }
        ~ScopedMatrices()	{ popMatrices(); }
    };
    
    struct ScopedColor : private Noncopyable
    {
        ScopedColor();
        ScopedColor( const ColorAf &color );
        ScopedColor( float red, float green, float blue, float alpha = 1 );
        ~ScopedColor();
        
    private:
        Context		*mCtx;
        ColorAf		mColor;
    };


}}
