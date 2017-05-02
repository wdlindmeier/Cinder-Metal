//
//  RenderCommandBuffer.hpp
//
//  Created by William Lindmeier on 11/15/15.
//
//

#pragma once

#include "cinder/Cinder.h"
#include "CommandBuffer.h"

namespace cinder { namespace mtl {
    
    typedef std::shared_ptr<class RenderCommandBuffer> RenderCommandBufferRef;
    
    // NOTE: a RenderBuffer is just a CommandBuffer that
    // stores a reference to the device's "nextDrawable" and
    // presents it on commit.
    // It also synchronizes it's execution with the
    // shared inflight semaphore.
    
    class RenderCommandBuffer : public CommandBuffer
    {
        
    public:
        
        static RenderCommandBufferRef create( const std::string & bufferName )
        {
            return RenderCommandBufferRef( new RenderCommandBuffer( bufferName ) );
        }
        
        ~RenderCommandBuffer();
        
        void commitAndPresent( std::function< void( void * mtlCommandBuffer) > completionHandler = NULL );
                
        // Creates a render encoder for the main draw loop using the next "drawable".
        RenderEncoderRef createRenderEncoder( RenderPassDescriptorRef & renderDescriptor,
                                              const std::string & encoderName = "Default Render Encoder" );
        
        virtual RenderEncoderRef createRenderEncoder( RenderPassDescriptorRef & descriptor,
                                                      void *drawableTexture,
                                                      const std::string & encoderName = "Default Render Encoder" )
        {
            return CommandBuffer::createRenderEncoder(descriptor, drawableTexture, encoderName);
        }

        void * getDrawable(){ return mDrawable; }
        
    protected:
        
        RenderCommandBuffer( const std::string & bufferName );
        
        
        void * mDrawable; // <CAMetalDrawable>
    };
    
} }
