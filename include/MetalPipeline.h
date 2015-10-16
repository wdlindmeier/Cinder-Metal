//
//  MetalPipeline.hpp
//  MetalCube
//
//  Created by William Lindmeier on 10/13/15.
//
//

#pragma once

#include "cinder/Cinder.h"

namespace cinder { namespace mtl {
    
    typedef std::shared_ptr<class MetalPipeline> MetalPipelineRef;
    
    class MetalPipeline
    {
    public:
        MetalPipeline();
        ~MetalPipeline(){}
    };
    
} }