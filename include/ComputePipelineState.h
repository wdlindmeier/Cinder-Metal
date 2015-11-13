//
//  ComputePipelineState.hpp
//  ParticleSorting
//
//  Created by William Lindmeier on 11/13/15.
//
//

#pragma once

#include "cinder/Cinder.h"
#include "MetalHelpers.hpp"

namespace cinder { namespace mtl {
    
    typedef std::shared_ptr<class ComputePipelineState> ComputePipelineStateRef;
    
    class ComputePipelineState
    {
        
        public:

        static ComputePipelineStateRef create( const std::string & computeShaderName );
        virtual ~ComputePipelineState();
        
        void * getNative(){ return mImpl; }
        
        protected:
        
        ComputePipelineState( const std::string & computeShaderName );
        
        void * mImpl = NULL;  // <MTLComputePipelineState>

    };
    
} }