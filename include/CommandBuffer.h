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
#include "ComputeFormat.h"
#include "BlitFormat.h"

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
        
        // TODO
        // Can this be a protected/private friend function w/ RenderMetalImpl?
        static CommandBufferRef create( void * mtlCommandBuffer, void *mtlDrawable );
        
        virtual ~CommandBuffer(){};
        
        void renderTargetWithFormat( RenderFormatRef format,
                                     std::function< void ( RenderEncoderRef renderEncoder ) > renderFunc,
                                     const std::string encoderName = "RenderEncoderName" );
        void computeTargetWithFormat( ComputeFormatRef format,
                                      std::function< void ( ComputeEncoderRef computeEncoder ) > computeFunc,
                                      const std::string encoderName = "ComputeEncoderName" );
        void blitTargetWithFormat( BlitFormatRef format,
                                   std::function< void ( BlitEncoderRef blitEncoder ) > blitFunc,
                                   const std::string encoderName = "BlitEncoderName" );

    protected:
                
        CommandBuffer( void * mtlCommandBuffer, void *mtlDrawable );
        
        void * mCommandBuffer;  // <MTLCommandBuffer>
        void * mDrawable; // <CAMetalDrawable>
    };
    
} }