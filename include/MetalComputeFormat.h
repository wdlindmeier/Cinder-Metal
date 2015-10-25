//
//  MetalComputeFormat.hpp
//  MetalCube
//
//  Created by William Lindmeier on 10/19/15.
//
//

#pragma once

#include "cinder/Cinder.h"

namespace cinder { namespace mtl {
    
    typedef std::shared_ptr<class MetalComputeFormat> MetalComputeFormatRef;
    
    class MetalComputeFormat
    {
        
        friend class MetalCommandBuffer;
        
    public:
        
        static MetalComputeFormatRef create();
        ~MetalComputeFormat(){};
        
    protected:
        
        MetalComputeFormat();
        // TODO: Create some options
        
    };
    
} }