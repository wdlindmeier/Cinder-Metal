//
//  MetalBlitFormat.hpp
//  MetalCube
//
//  Created by William Lindmeier on 10/19/15.
//
//

#pragma once

#include "cinder/Cinder.h"

namespace cinder { namespace mtl {
    
    typedef std::shared_ptr<class MetalBlitFormat> MetalBlitFormatRef;
    
    class MetalBlitFormat
    {
        
        friend class MetalCommandBuffer;
        
    public:
        
        static MetalBlitFormatRef create();
        ~MetalBlitFormat(){};
        
    protected:
        
        MetalBlitFormat();
        // TODO: Add some options
        // MTLBlitOption mImpl;
        
    };
    
} }