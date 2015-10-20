//
//  MetalBlitEncoder.hpp
//  MetalCube
//
//  Created by William Lindmeier on 10/17/15.
//
//

#pragma once

#include "cinder/Cinder.h"

#if defined( __OBJC__ )
@class MetalBlitEncoderImpl;
#else
class MetalBlitEncoderImpl;
#endif

namespace cinder { namespace mtl {
    
    typedef std::shared_ptr<class MetalBlitEncoder> MetalBlitEncoderRef;
    
    class MetalBlitEncoder
    {
        
    public:
        
//        class Format
//        {
//            Format(){};
//            ~Format(){};
//        };
        
        // Can this be a protected/private friend function w/ MetalContext?
        static MetalBlitEncoderRef create( MetalBlitEncoderImpl * );
        
        virtual ~MetalBlitEncoder(){}
        
        // TODO: Subclass all encoders from same class that has general functions
        
    protected:
        
        MetalBlitEncoder( MetalBlitEncoderImpl * );
        
        MetalBlitEncoderImpl *mImpl;
        
    };
    
} }