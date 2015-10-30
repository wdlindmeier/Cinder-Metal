//
//  BlitFormat.hpp
//  MetalCube
//
//  Created by William Lindmeier on 10/19/15.
//
//

#pragma once

#include "cinder/Cinder.h"

namespace cinder { namespace mtl {
    
    typedef std::shared_ptr<class BlitFormat> BlitFormatRef;
    
    class BlitFormat
    {
        
        friend class CommandBuffer;
        
    public:
        
        static BlitFormatRef create();
        ~BlitFormat(){};
        
    protected:
        
        BlitFormat();
        // TODO: Add some options
        // MTLBlitOption mImpl;
        
    };
    
} }