//
//  RenderEncoder.hpp
//  MetalCube
//
//  Created by William Lindmeier on 10/16/15.
//
//

#pragma once

#include "cinder/Cinder.h"
#include "MetalGeom.h"
#include "RenderPipelineState.h"
#include "DataBuffer.h"
#include "TextureBuffer.h"
#include "DepthState.h"
#include "SamplerState.h"
#include "MetalConstants.h"
#include "CommandEncoder.h"

namespace cinder { namespace mtl {
    
    typedef std::shared_ptr<class RenderEncoder> RenderEncoderRef;
    
    class VertexBuffer;
    typedef std::shared_ptr<VertexBuffer> VertexBufferRef;
    
    class RenderEncoder : public CommandEncoder
    {

        friend class CommandBuffer;
        
    public:
        
        virtual ~RenderEncoder(){};
        
        virtual void setPipelineState( RenderPipelineStateRef pipeline );
        virtual void setTexture( TextureBufferRef texture, size_t index = ciTextureIndex0 );
        virtual void setBufferAtIndex( DataBufferRef buffer, size_t bufferIndex , size_t bytesOffset = 0 );
        virtual void setUniforms( DataBufferRef buffer, size_t bytesOffset = 0, size_t bufferIndex = ciBufferIndexUniforms );

        void setFragSamplerState( SamplerStateRef samplerState, int samplerIndex = 0 );
        void setDepthStencilState( DepthStateRef depthState );

        void draw( ci::mtl::geom::Primitive primitive, size_t vertexCount, size_t vertexStart = 0,
                   size_t instanceCount = 1);

    protected:

        static RenderEncoderRef create( void * mtlRenderCommandEncoder ); // <MTLRenderCommandEncoder>
        
        RenderEncoder( void * mtlRenderCommandEncoder );

    };
    
} }