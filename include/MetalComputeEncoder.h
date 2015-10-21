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
     
        friend class MetalCommandBuffer;
        
    public:
        
        virtual ~MetalComputeEncoder(){}

    protected:
        
        static MetalComputeEncoderRef create( MetalComputeEncoderImpl * );
        
        MetalComputeEncoder( MetalComputeEncoderImpl * );
        
        MetalComputeEncoderImpl *mImpl;
        
    };
    
} }