//
//  ComputeEncoder.hpp
//  MetalCube
//
//  Created by William Lindmeier on 10/17/15.
//
//

#pragma once

#include "cinder/Cinder.h"
#include "CommandEncoder.h"
#include "ComputePipelineState.h"

namespace cinder { namespace mtl {
    
    typedef std::shared_ptr<class ComputeEncoder> ComputeEncoderRef;
    
    class ComputeEncoder : public CommandEncoder
    {
     
        friend class CommandBuffer;
        
    public:

        virtual ~ComputeEncoder(){};
        
        virtual void setPipelineState( ComputePipelineStateRef pipeline );
        virtual void setTexture( TextureBufferRef texture, size_t index = ciTextureIndex0 );
        virtual void setBufferAtIndex( DataBufferRef buffer, size_t bufferIndex , size_t bytesOffset = 0 );
        virtual void setUniforms( DataBufferRef buffer, size_t bytesOffset = 0, size_t bufferIndex = ciBufferIndexUniforms );

        void setSamplerState( SamplerStateRef samplerState, int samplerIndex = 0 );
        void setThreadgroupMemoryLength( size_t byteLength, size_t groupMemoryIndex );
        
        void dispatch( ivec3 dataDimensions, ivec3 threadDimensions = ivec3(8,8,1) );
        
    protected:
        
        static ComputeEncoderRef create( void * mtlComputeCommandEncoder );
        
        ComputeEncoder( void * mtlComputeCommandEncoder );

    };
    
} }