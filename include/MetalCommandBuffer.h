//
//  MetalCommandBuffer.hpp
//  MetalCube
//
//  Created by William Lindmeier on 10/17/15.
//
//

#pragma once

#include "cinder/Cinder.h"
#include "MetalRenderEncoder.h"
#include "MetalComputeEncoder.h"
#include "MetalBlitEncoder.h"
#include "MetalRenderFormat.h"
#include "MetalComputeFormat.h"
#include "MetalBlitFormat.h"

#if defined( __OBJC__ )
@class MetalCommandBufferImpl;
#else
class MetalCommandBufferImpl;
#endif

namespace cinder { namespace mtl {
    
    typedef std::shared_ptr<class MetalCommandBuffer> MetalCommandBufferRef;
    
    class MetalCommandBuffer
    {
        
    public:
        
        // Can this be a protected/private friend function w/ MetalContext?
        static MetalCommandBufferRef create( MetalCommandBufferImpl * impl );
        
        virtual ~MetalCommandBuffer(){};
        
        void renderTargetWithFormat( MetalRenderFormatRef format,
                                     std::function< void ( MetalRenderEncoderRef renderEncoder ) > renderFunc,
                                     const std::string encoderName = "RenderEncoderName" );
        void computeTargetWithFormat( MetalComputeFormatRef format,
                                      std::function< void ( MetalComputeEncoderRef computeEncoder ) > computeFunc,
                                      const std::string encoderName = "ComputeEncoderName" );
        void blitTargetWithFormat( MetalBlitFormatRef format,
                                   std::function< void ( MetalBlitEncoderRef blitEncoder ) > blitFunc,
                                   const std::string encoderName = "BlitEncoderName" );

    protected:
        
        MetalCommandBuffer( MetalCommandBufferImpl * impl );
        
        MetalCommandBufferImpl *mImpl;        
    };
    
} }