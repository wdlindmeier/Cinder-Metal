//
//  MetalBlitEncoder.hpp
//  MetalCube
//
//  Created by William Lindmeier on 10/17/15.
//
//

#pragma once

#include "cinder/Cinder.h"

namespace cinder { namespace mtl {
    
    typedef std::shared_ptr<class MetalBlitEncoder> MetalBlitEncoderRef;
    
    class MetalBlitEncoder
    {
        
        friend class MetalCommandBuffer;
        
    public:

        virtual ~MetalBlitEncoder(){}

    protected:
        
        static MetalBlitEncoderRef create( void * mtlBlitCommandEncoder );
        
        MetalBlitEncoder( void * mtlBlitCommandEncoder );
        
        void * mImpl;
        
    };
    
} }