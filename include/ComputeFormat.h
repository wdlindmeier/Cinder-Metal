//
//  ComputeFormat.hpp
//  MetalCube
//
//  Created by William Lindmeier on 10/19/15.
//
//

#pragma once

#include "cinder/Cinder.h"

namespace cinder { namespace mtl {
    
    typedef std::shared_ptr<class ComputeFormat> ComputeFormatRef;
    
    class ComputeFormat
    {
        
        friend class CommandBuffer;
        
    public:
        
        static ComputeFormatRef create();
        ~ComputeFormat(){};
        
    protected:
        
        ComputeFormat();
        // TODO: Create some options
        
    };
    
} }