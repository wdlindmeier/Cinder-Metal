//
//  CommandBuffer.hpp
//  MetalCube
//
//  Created by William Lindmeier on 10/17/15.
//
//

#pragma once

#include "cinder/Cinder.h"
#include "RenderEncoder.h"
#include "ComputeEncoder.h"
#include "BlitEncoder.h"
#include "RenderFormat.h"

#if defined( __OBJC__ )
@class CommandBufferImpl;
#else
class CommandBufferImpl;
#endif

namespace cinder { namespace mtl {
    
    typedef std::shared_ptr<class CommandBuffer> CommandBufferRef;
    
    class CommandBuffer
    {
        
        friend struct ScopedCommandBuffer;
        friend struct ScopedRenderEncoder;
        friend struct ScopedComputeEncoder;
        friend struct ScopedBlitEncoder;
        
    public:
        
        // TODO
        // Can this be a protected/private friend function w/ RenderMetalImpl?
        static CommandBufferRef create( void * mtlCommandBuffer, void *mtlDrawable );        
        virtual ~CommandBuffer(){};

    protected:
                
        CommandBuffer( void * mtlCommandBuffer, void *mtlDrawable );
        
        void * mCommandBuffer;  // <MTLCommandBuffer>
        void * mDrawable; // <CAMetalDrawable>
    };
    
} }