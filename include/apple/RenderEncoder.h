//
//  RenderEncoder.hpp
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
#include "MetalEnums.h"

namespace cinder { namespace mtl {

    class Instance;
    
    typedef std::shared_ptr<class RenderEncoder> RenderEncoderRef;
    
    class VertexBuffer;
    typedef std::shared_ptr<VertexBuffer> VertexBufferRef;
    
    class Batch;
    typedef std::shared_ptr<Batch> BatchRef;
    
    class RenderEncoder : public CommandEncoder
    {

    public:
        
        // NOTE:
        // Generally RenderEncoders should be created via the RenderCommandBuffer or CommandBuffer
        // using RenderCommandBuffer::createRenderEncoder.
        static RenderEncoderRef create( void * mtlRenderCommandEncoder ); // <MTLRenderCommandEncoder>
        
        virtual ~RenderEncoder(){};
        
        virtual void setPipelineState( const RenderPipelineStateRef & pipeline );
        // NOTE: setTexture is an alias for setFragmentTextureAtIndex
        virtual void setTexture( const TextureBufferRef & texture, size_t index = ciTextureIndex0 );
        virtual void setFragmentTexture( const TextureBufferRef & texture, size_t index );
        virtual void setVertexTexture( const TextureBufferRef & texture, size_t index );
        // Sets buffer at ciBufferIndexUniforms for both vertex and fragment shaders
        virtual void setUniforms( const DataBufferRef & buffer, size_t bytesOffset = 0, size_t bufferIndex = ciBufferIndexUniforms );
        
        void setVertexBufferAtIndex( const DataBufferRef & buffer, size_t bufferIndex , size_t bytesOffset = 0 );
        void setFragmentBufferAtIndex( const DataBufferRef & buffer, size_t bufferIndex , size_t bytesOffset = 0 );
        
        void setVertexBytesAtIndex( const void * bytes, size_t length , size_t index );
        void setFragmentBytesAtIndex( const void * bytes, size_t length , size_t index );

        // Pass in single POD values to a shader param index
        template <typename T>
        void setVertexValueAtIndex( const T * bytes, size_t index )
        {
            setVertexBytesAtIndex( bytes, sizeof(T), index );
        }
        template <typename T>
        void setFragmentValueAtIndex( const T * bytes, size_t index )
        {
            setFragmentBytesAtIndex( bytes, sizeof(T), index );
        }

        void setFragSamplerState( const SamplerStateRef & samplerState, int samplerIndex = 0 );
        void setDepthStencilState( const DepthStateRef & depthState );
        
        void setViewport( vec2 origin, vec2 size, float near = 0.0, float far = 1.f );
        void setFrontFacingWinding( bool isClockwise );
        void setCullMode( int mtlCullMode );
#if !defined( CINDER_COCOA_TOUCH )
        void setDepthClipMode( int mtlDepthClipMode );
#endif
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
        
        void drawIndexed( ci::mtl::geom::Primitive primitive, const DataBufferRef & indexBuffer,
                          size_t indexCount, size_t instanceCount = 1, size_t bufferOffset = 0,
                          IndexType indexType = IndexTypeUInt32, size_t baseVertex = 0, size_t baseInstance = 0 );
#if !defined( CINDER_COCOA_TOUCH )
        void textureBarrier();
#endif
        
        
        // Convenience functions for setting encoder state
        
        void operator<<( mtl::DepthStateRef & depthState )
        {
            setDepthStencilState(depthState);
        }
        
        void operator<<( mtl::SamplerStateRef & samplerState )
        {
            setFragSamplerState(samplerState);
        }
        
        void operator<<( mtl::RenderPipelineStateRef & renderPipeline )
        {
            setPipelineState(renderPipeline);
        }
        
#pragma mark - Drawing Convenience Functions

        // Drawing helpers
        void draw( ci::mtl::VertexBufferRef vertBuffer, ci::mtl::RenderPipelineStateRef pipeline,
                   ci::mtl::DataBufferRef instanceBuffer = ci::mtl::DataBufferRef(), unsigned int numInstances = 1 );
        void draw( ci::mtl::BatchRef batch,
                  ci::mtl::DataBufferRef instanceBuffer = ci::mtl::DataBufferRef(), unsigned int numInstances = 1 );
        void draw( ci::mtl::BatchRef batch, size_t vertexLength, size_t vertexStart,
                  ci::mtl::DataBufferRef instanceBuffer = ci::mtl::DataBufferRef(), unsigned int numInstances = 1 );
        void drawOne( ci::mtl::BatchRef batch, const ci::mtl::Instance & i);
        void drawStrokedCircle( ci::vec3 position, float radius,
                               ci::mtl::DataBufferRef instanceBuffer = ci::mtl::DataBufferRef(), unsigned int numInstances = 1 );
        void drawSolidCircle( ci::vec3 position, float radius,
                              ci::mtl::DataBufferRef instanceBuffer = ci::mtl::DataBufferRef(), unsigned int numInstances = 1 );
        void drawBillboardCircle( ci::vec3 position, float radius,
                                 ci::mtl::DataBufferRef instanceBuffer = ci::mtl::DataBufferRef(), unsigned int numInstances = 1 );
        void drawRing( ci::vec3 position, float outerRadius, float innerRadius,
                       ci::mtl::DataBufferRef instanceBuffer = ci::mtl::DataBufferRef(), unsigned int numInstances = 1 );
        void drawStrokedRect( ci::Rectf rect,
                             ci::mtl::DataBufferRef instanceBuffer = ci::mtl::DataBufferRef(), unsigned int numInstances = 1 );
        void drawSolidRect( ci::Rectf rect,
                           ci::mtl::DataBufferRef instanceBuffer = ci::mtl::DataBufferRef(), unsigned int numInstances = 1 );
        void drawCube( ci::vec3 position, ci::vec3 size,
                      ci::mtl::DataBufferRef instanceBuffer = ci::mtl::DataBufferRef(), unsigned int numInstances = 1 );
        void drawStrokedCube( ci::vec3 position, ci::vec3 size,
                             ci::mtl::DataBufferRef instanceBuffer = ci::mtl::DataBufferRef(), unsigned int numInstances = 1 );
        void drawSphere( ci::vec3 position, float radius,
                        ci::mtl::DataBufferRef instanceBuffer = ci::mtl::DataBufferRef(), unsigned int numInstances = 1 );
        // NOTE: This is not designed to be fast—just convenient
        void drawLines( std::vector<ci::vec3> lines, bool isLineStrip = false,
                        ci::mtl::DataBufferRef instanceBuffer = ci::mtl::DataBufferRef(), unsigned int numInstances = 1 );
        // NOTE: This is not designed to be fast—just convenient
        void drawLine( ci::vec3 from, ci::vec3 to,
                       ci::mtl::DataBufferRef instanceBuffer = ci::mtl::DataBufferRef(), unsigned int numInstances = 1 );
        void drawColoredCube( ci::vec3 position, ci::vec3 size,
                              ci::mtl::DataBufferRef instanceBuffer = ci::mtl::DataBufferRef(), unsigned int numInstances = 1 );
        void draw( ci::mtl::TextureBufferRef & texture, ci::Rectf rect = ci::Rectf(0,0,0,0),
                   ci::mtl::DataBufferRef instanceBuffer = ci::mtl::DataBufferRef(), unsigned int numInstances = 1 );
        void drawBillboard( mtl::TextureBufferRef & texture,
                            ci::mtl::DataBufferRef instanceBuffer = ci::mtl::DataBufferRef(), unsigned int numInstances = 1 );

        // Instance data
        void setIdentityInstance();

        void setInstanceData( ci::mtl::DataBufferRef & instanceBuffer );
        
        // Basic state changes
        
        void enableDepth();
        void disableDepth();

    protected:

        RenderEncoder( void * mtlRenderCommandEncoder );

    };
    
} }
