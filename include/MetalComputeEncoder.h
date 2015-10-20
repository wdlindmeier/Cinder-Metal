//
//  MetalComputeEncoder.hpp
//  MetalCube
//
//  Created by William Lindmeier on 10/17/15.
//
//

#pragma once

#include "cinder/Cinder.h"

#if defined( __OBJC__ )
@class MetalComputeEncoderImpl;
#else
class MetalComputeEncoderImpl;
#endif

namespace cinder { namespace mtl {
    
    typedef std::shared_ptr<class MetalComputeEncoder> MetalComputeEncoderRef;
    
    class MetalComputeEncoder
    {
        
    public:
        
//        class Format
//        {
//            Format(){};
//            ~Format(){};
//        };
        
        // Can this be a protected/private friend function w/ MetalContext?
        static MetalComputeEncoderRef create( MetalComputeEncoderImpl * );
        
        virtual ~MetalComputeEncoder(){}
        
        // TODO: Subclass all encoders from same class that has general functions
        
    protected:
        
        MetalComputeEncoder( MetalComputeEncoderImpl * );
        
        MetalComputeEncoderImpl *mImpl;
        
    };
    
} }