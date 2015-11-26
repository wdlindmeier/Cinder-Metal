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
#include "RenderPassDescriptor.h"

namespace cinder { namespace mtl {
    
    typedef std::shared_ptr<class CommandBuffer> CommandBufferRef;
    
    class CommandBuffer
    {
        
    public:

        static CommandBufferRef create( const std::string & bufferName );
        virtual ~CommandBuffer();

        void commit( std::function< void( void * mtlCommandBuffer) > completionHandler = NULL );

        void waitUntilCompleted();

        void * getNative(){ return mImpl; }

        RenderEncoderRef createRenderEncoder( RenderPassDescriptorRef descriptor,
                                              void *drawableTexture,
                                              const std::string & encoderName = "Default Render Encoder" );
        ComputeEncoderRef createComputeEncoder( const std::string & encoderName = "Default Compute Encoder" );
        BlitEncoderRef createBlitEncoder( const std::string & encoderName = "Default Blit Encoder" );
        
    protected:
                
        CommandBuffer( void * mtlCommandBuffer );
        
        void * mImpl;  // <MTLCommandBuffer>
    };
    
} }