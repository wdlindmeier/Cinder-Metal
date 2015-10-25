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
        void setVertexBuffer( MetalBufferRef buffer, size_t bytesOffset, size_t bufferIndex );
        // A convenience method for setVertexBuffer that takes the inflight buffer index instead of an offset
        template <typename BufferType>
        void setVertexBufferForInflightIndex( MetalBufferRef buffer, size_t inflightBufferIndex, size_t bufferIndex )
        {
            uint offset = (sizeof(BufferType) * inflightBufferIndex);
            this->setVertexBuffer( buffer, offset, bufferIndex);
        }

        void draw( ci::mtl::geom::Primitive primitive, size_t vertexStart, size_t vertexCount, size_t instanceCount );
        
    protected:

        static MetalRenderEncoderRef create( void * mtlRenderCommandEncoder ); // <MTLRenderCommandEncoder>
        
        MetalRenderEncoder( void * mtlRenderCommandEncoder );
        
        void * mImpl;
    };
    
} }