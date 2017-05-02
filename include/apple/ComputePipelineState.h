//
//  ComputePipelineState.hpp
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

        static ComputePipelineStateRef create( const std::string & computeShaderName,
                                               void * mtlLibrary = nullptr) // native <MTLLibrary>
        {
            return ComputePipelineStateRef( new ComputePipelineState( computeShaderName, mtlLibrary ) );
        }

        static ComputePipelineStateRef create( void * mtlComputePipelineState )
        {
            return ComputePipelineStateRef( new ComputePipelineState(mtlComputePipelineState) );
        }
        
        virtual ~ComputePipelineState();
        
        void * getNative(){ return mImpl; }
        
        protected:
        
        ComputePipelineState( const std::string & computeShaderName, void * mtlLibrary = nullptr );
        ComputePipelineState( void * mtlComputePipelineState );
        
        void * mImpl = NULL;  // <MTLComputePipelineState>

    };
    
} }