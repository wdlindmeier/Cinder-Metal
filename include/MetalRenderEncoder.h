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

        friend class MetalCommandBuffer;
        
    public:

        virtual ~MetalRenderEncoder(){}
        
        void pushDebugGroup( const std::string & groupName);
        void popDebugGroup();

        void setPipeline( MetalPipelineRef pipeline );
        void setVertexBuffer( MetalBufferRef buffer, int offset, int bufferIndex );
        // A convenience method for setVertexBuffer that takes the inflight buffer index instead of an offset
        template <typename BufferType>
        void setVertexBufferForInflightIndex( MetalBufferRef buffer, int inflightBufferIndex, int bufferIndex )
        {
            uint offset = (sizeof(BufferType) * inflightBufferIndex);
            this->setVertexBuffer( buffer, offset, bufferIndex);
        }

        void draw( ci::mtl::geom::Primitive primitive, int vertexStart, int vertexCount, int instanceCount );
        
    protected:

        static MetalRenderEncoderRef create( id mtlRenderCommandEncoder );
        
        MetalRenderEncoder( id mtlRenderCommandEncoder );
        
        id mImpl;

//        static MetalRenderEncoderRef create( MetalRenderEncoderImpl * );
//        
//        MetalRenderEncoder( MetalRenderEncoderImpl * );
//        
//        MetalRenderEncoderImpl *mImpl;
        
    };
    
} }