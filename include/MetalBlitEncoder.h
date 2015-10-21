//
//  MetalBlitEncoder.hpp
//  MetalCube
//
//  Created by William Lindmeier on 10/17/15.
//
//

#pragma once

#include "cinder/Cinder.h"

#if defined( __OBJC__ )
@class MetalBlitEncoderImpl;
#else
class MetalBlitEncoderImpl;
#endif

namespace cinder { namespace mtl {
    
    typedef std::shared_ptr<class MetalBlitEncoder> MetalBlitEncoderRef;
    
    class MetalBlitEncoder
    {
        
        friend class MetalCommandBuffer;
        
    public:

        virtual ~MetalBlitEncoder(){}

    protected:
        
        static MetalBlitEncoderRef create( MetalBlitEncoderImpl * );
        
        MetalBlitEncoder( MetalBlitEncoderImpl * );
        
        MetalBlitEncoderImpl *mImpl;
        
    };
    
} }