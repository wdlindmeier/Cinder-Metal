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
        friend class RenderBuffer;
        
    public:
        
        virtual ~RenderEncoder(){};
        
        virtual void setPipelineState( RenderPipelineStateRef pipeline );
        virtual void setTexture( TextureBufferRef texture, size_t index = ciTextureIndex0 );
        // Sets buffer at ciBufferIndexUniforms for both vertex and fragment shaders
        virtual void setUniforms( DataBufferRef buffer, size_t bytesOffset = 0, size_t bufferIndex = ciBufferIndexUniforms );
        void setVertexBufferAtIndex( DataBufferRef buffer, size_t bufferIndex , size_t bytesOffset = 0 );
        void setFragmentBufferAtIndex( DataBufferRef buffer, size_t bufferIndex , size_t bytesOffset = 0 );
        
        void setFragSamplerState( SamplerStateRef samplerState, int samplerIndex = 0 );
        void setDepthStencilState( DepthStateRef depthState );
        
        void setViewport( vec2 origin, vec2 size, float near = 0.1, float far = 1000.f );
        void setFrontFacingWinding( bool isClockwise );
        void setCullMode( int mtlCullMode );
        void setDepthClipMode( int mtlDepthClipMode );
        void setDepthBias( float depthBias, float slopeScale, float clamp );
        void setScissor( Area scissor );
        void setTriangleFillMode( int mtlTriangleFillMode );
        
        void setVertexBufferOffsetAtIndex( size_t offset, size_t index );
        void setFragmentBufferOffsetAtIndex( size_t offset, size_t index );

        void setBlendColor( ColorAf blendColor );

        void setStencilReferenceValue( uint32_t frontReferenceValue, uint32_t backReferenceValue );

        void setVisibilityResultMode( int mtlVisibilityResultMode, size_t offset );

        void draw( ci::mtl::geom::Primitive primitive, size_t vertexCount, size_t vertexStart = 0,
                   size_t instanceCount = 1, size_t baseInstance = 0 );
        
        void drawIndexed( ci::mtl::geom::Primitive primitive, DataBufferRef indexBuffer,
                          size_t indexCount, int mtlIndexType = 1, size_t bufferOffset = 0,
                          size_t instanceCount = 1, size_t baseVertex = 0, size_t baseInstance = 0 );

        void textureBarrier();

    protected:

        static RenderEncoderRef create( void * mtlRenderCommandEncoder ); // <MTLRenderCommandEncoder>
        
        RenderEncoder( void * mtlRenderCommandEncoder );

    };
    
} }