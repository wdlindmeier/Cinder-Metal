//
//  MetalRenderEncoder.hpp
//  MetalCube
//
//  Created by William Lindmeier on 10/16/15.
//
//

#pragma once

#include "cinder/Cinder.h"
#include "MetalGeom.h"
#include "MetalPipeline.h"
#include "MetalBuffer.h"

#if defined( __OBJC__ )
@class MetalRenderEncoderImpl;
#else
class MetalRenderEncoderImpl;
#endif

namespace cinder { namespace mtl {
    
    typedef std::shared_ptr<class MetalRenderEncoder> MetalRenderEncoderRef;
    
    class MetalRenderEncoder
    {

    public:
        
        // Can this be a protected/private friend function w/ MetalContext?
        static MetalRenderEncoderRef create( MetalRenderEncoderImpl * );
        virtual ~MetalRenderEncoder(){}
        
        void pushDebugGroup( const std::string & groupName);
        void popDebugGroup();

        void beginPipeline( MetalPipelineRef pipeline );
        void setVertexBuffer( MetalBufferRef buffer, int offset, int index);
        void draw( ci::mtl::geom::Primitive primitive, int vertexStart, int vertexCount, int instanceCount );

        
    protected:
        
        MetalRenderEncoder( MetalRenderEncoderImpl * );
        
        MetalRenderEncoderImpl *mImpl;
        
    };
    
} }