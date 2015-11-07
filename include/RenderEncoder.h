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
#include "Pipeline.h"
#include "DataBuffer.h"
#include "TextureBuffer.h"

namespace cinder { namespace mtl {
    
    typedef std::shared_ptr<class RenderEncoder> RenderEncoderRef;
    
    class RenderEncoder
    {

        friend class CommandBuffer;
        
    public:
        
        struct DepthState
        {
            int depthCompareFunction = 1; // MTLCompareFunction = MTLCompareFunctionLess
            bool depthWriteEnabled = true;
            void * frontFaceStencil = nullptr; // MTLStencilDescriptor
            void * backFaceStencil = nullptr; // MTLStencilDescriptor
            std::string label = "Default Depth State";
        };
        
        struct SamplerState
        {
            int mipFilter = 2; // MTLSamplerMipFilter = MTLSamplerMipFilterLinear
            int maxAnisotropy = 3;
            int minFilter = 1; // MTLSamplerMinMagFilter = MTLSamplerMinMagFilterLinear
            int magFilter = 1; // MTLSamplerMinMagFilter = MTLSamplerMinMagFilterLinear
            int sAddressMode = 0; // MTLSamplerAddressMode = MTLSamplerAddressModeClampToEdge
            int tAddressMode = 0; // MTLSamplerAddressMode = MTLSamplerAddressModeClampToEdge
            int rAddressMode = 0; // MTLSamplerAddressMode = MTLSamplerAddressModeClampToEdge
            bool normalizedCoordinates = true;
            float lodMinClamp = 0.f;
            float lodMaxClamp = FLT_MAX;
            bool lodAverage = false;
            int compareFunction = 0; // MTLCompareFunction = MTLCompareFunctionNever
            std::string label = "Default Sampler State";
        };

        virtual ~RenderEncoder();
        
        void pushDebugGroup( const std::string & groupName);
        void popDebugGroup();

        void setPipelineState( PipelineRef pipeline );
        void setFragSamplerState( const SamplerState & samplerState, int samplerIndex = 0 );
        void setDepthStencilState( const DepthState & depthState );

        void setTextureAtIndex( TextureBufferRef texture, size_t index = 0 );
        void setBufferAtIndex( DataBufferRef buffer, size_t bufferIndex , size_t bytesOffset = 0 );

        void draw( ci::mtl::geom::Primitive primitive, size_t vertexStart, size_t vertexCount, size_t instanceCount );
        
        void endEncoding();
        
        void * getNative(){ return mImpl; }
        
    protected:

        static RenderEncoderRef create( void * mtlRenderCommandEncoder ); // <MTLRenderCommandEncoder>
        
        RenderEncoder( void * mtlRenderCommandEncoder );
        
        void * mImpl; // <MTLRenderCommandEncoder>
    };
    
} }