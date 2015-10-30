//
//  BlitEncoder.hpp
//  MetalCube
//
//  Created by William Lindmeier on 10/17/15.
//
//

#pragma once

#include "cinder/Cinder.h"

namespace cinder { namespace mtl {
    
    typedef std::shared_ptr<class BlitEncoder> BlitEncoderRef;
    
    class BlitEncoder
    {
        
        friend class CommandBuffer;
        
    public:

        virtual ~BlitEncoder(){}

    protected:
        
        static BlitEncoderRef create( void * mtlBlitCommandEncoder );
        
        BlitEncoder( void * mtlBlitCommandEncoder );
        
        void * mImpl;
        
    };
    
} }