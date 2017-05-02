//
//  CommandBuffer.hpp
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

        static CommandBufferRef create( const std::string & bufferName )
        {
            return CommandBufferRef( new CommandBuffer( bufferName ) );
        }
        
        static CommandBufferRef create( void * mtlCommandBuffer )
        {
            return CommandBufferRef( new CommandBuffer( mtlCommandBuffer ) );
        }
        
        virtual ~CommandBuffer();

        void addCompletionHandler( std::function< void( void * mtlCommandBuffer) > completionHandler );
        
        void commit( std::function< void( void * mtlCommandBuffer) > completionHandler = NULL );
        
        void waitUntilCompleted();

        void * getNative(){ return mImpl; }

        virtual RenderEncoderRef createRenderEncoder( RenderPassDescriptorRef & descriptor,
                                                     const std::string & encoderName = "Default Render Encoder" );
        // Create a render encoder and apply the texture to the RenderPassDescriptor
        virtual RenderEncoderRef createRenderEncoder( RenderPassDescriptorRef & descriptor,
                                                     void *drawableTexture,
                                                     const std::string & encoderName = "Default Render Encoder" );
        virtual ComputeEncoderRef createComputeEncoder( const std::string & encoderName = "Default Compute Encoder" );
        virtual BlitEncoderRef createBlitEncoder( const std::string & encoderName = "Default Blit Encoder" );
        
    protected:
                
        CommandBuffer( const std::string & bufferName );
        CommandBuffer( void * mtlCommandBuffer );

        void init( void * mtlCommandBuffer );
        
        void * mImpl;  // <MTLCommandBuffer>
    };
    
} }