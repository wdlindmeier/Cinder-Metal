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
        
    public:

        static CommandBufferRef createForRenderLoop( const std::string & bufferName );
        virtual ~CommandBuffer();

        void commitAndPresentForRendererLoop();

        void * getNative(){ return mCommandBuffer; }

        RenderEncoderRef createRenderEncoderWithFormat( RenderFormatRef renderFormat,
                                                        const std::string & encoderName = "Render Encoder" );
        ComputeEncoderRef createComputeEncoder( const std::string & encoderName = "Compute Encoder" );
        BlitEncoderRef createBlitEncoder( const std::string & encoderName = "Blit Encoder" );
        
    protected:
                
        CommandBuffer( void * mtlCommandBuffer, void *mtlDrawable );
        
        void * mCommandBuffer;  // <MTLCommandBuffer>
        void * mDrawable; // <CAMetalDrawable>
    };
    
} }