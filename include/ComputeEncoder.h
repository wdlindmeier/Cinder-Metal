//
//  ComputeEncoder.hpp
//  MetalCube
//
//  Created by William Lindmeier on 10/17/15.
//
//

#pragma once

#include "cinder/Cinder.h"

namespace cinder { namespace mtl {
    
    typedef std::shared_ptr<class ComputeEncoder> ComputeEncoderRef;
    
    class ComputeEncoder
    {
     
        //friend class CommandBuffer;
        friend struct ScopedComputeEncoder;
        
    public:
        
        virtual ~ComputeEncoder(){}

    protected:
        
        static ComputeEncoderRef create( void * mtlComputeCommandEncoder );
        
        ComputeEncoder( void * mtlComputeCommandEncoder );
        
        void * mImpl;
        
    };
    
} }