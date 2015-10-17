//
//  MetalBuffer.hpp
//  MetalCube
//
//  Created by William Lindmeier on 10/17/15.
//
//

#pragma once

#include "cinder/Cinder.h"

#if defined( __OBJC__ )
@class MetalBufferImpl;
#else
class MetalBufferImpl;
#endif

namespace cinder { namespace mtl {
    
    typedef std::shared_ptr<class MetalBuffer> MetalBufferRef;
    
    class MetalBuffer
    {
        
        friend class MetalRenderEncoder;
        
    public:
        
        static MetalBufferRef create( unsigned long length, const void * pointer, const std::string & label );
        virtual ~MetalBuffer(){};
        
        void * contents();

    protected:
        
        MetalBuffer( unsigned long length, const void * pointer, const std::string & label );
        MetalBufferImpl *mImpl;
        
    };
    
} }