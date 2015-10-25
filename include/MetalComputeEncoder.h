//
//  MetalComputeEncoder.hpp
//  MetalCube
//
//  Created by William Lindmeier on 10/17/15.
//
//

#pragma once

#include "cinder/Cinder.h"

namespace cinder { namespace mtl {
    
    typedef std::shared_ptr<class MetalComputeEncoder> MetalComputeEncoderRef;
    
    class MetalComputeEncoder
    {
     
        friend class MetalCommandBuffer;
        
    public:
        
        virtual ~MetalComputeEncoder(){}

    protected:
        
        static MetalComputeEncoderRef create( void * mtlComputeCommandEncoder );
        
        MetalComputeEncoder( void * mtlComputeCommandEncoder );
        
        void * mImpl;
        
    };
    
} }