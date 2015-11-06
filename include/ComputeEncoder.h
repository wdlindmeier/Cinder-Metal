//
//  ComputeEncoder.hpp
//  MetalCube
//
//  Created by William Lindmeier on 10/17/15.
//
//

#pragma once

#include "cinder/Cinder.h"
//#include "CommandBuffer.h"

namespace cinder { namespace mtl {
    
    typedef std::shared_ptr<class ComputeEncoder> ComputeEncoderRef;
    
    class ComputeEncoder
    {
     
        friend class CommandBuffer;
        
    public:

        virtual ~ComputeEncoder();
        
        void * getNative(){ return mImpl; }
        
        void endEncoding();

    protected:
        
        static ComputeEncoderRef create( void * mtlComputeCommandEncoder );
        
        ComputeEncoder( void * mtlComputeCommandEncoder );
        
        void * mImpl; // <MTLComputeCommandEncoder>
        
    };
    
} }