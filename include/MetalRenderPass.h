//
//  MetalRenderPass.hpp
//  MetalCube
//
//  Created by William Lindmeier on 10/13/15.
//
//

#pragma once

#include "cinder/Cinder.h"

#if defined( __OBJC__ )
@class MetalRenderPassImpl;
#else
class MetalRenderPassImpl;
#endif

namespace cinder { namespace mtl {
    
    class MetalRenderPass
    {
        
    public:
        
        // TODO: Add state accessors
        class Format
        {
            
        public:
            
            Format() :
            shouldClear(true),
            clearColor(0.f,0.f,0.f,1.f),
            hasDepth(true),
            clearDepth(1.f)
            {}
            
            bool shouldClear;
            bool hasDepth;
            ColorAf clearColor;
            float clearDepth;
        };
        
    };
    
} }