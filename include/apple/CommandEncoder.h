//
//  CommandEncoder.hpp
//
//  Created by William Lindmeier on 11/12/15.
//
//

#pragma once

#include "cinder/Cinder.h"
#include "MetalGeom.h"
#include "DataBuffer.h"
#include "TextureBuffer.h"
#include "MetalConstants.h"
#include "DepthState.h"
#include "SamplerState.h"

namespace cinder { namespace mtl {
    
    // Super class of ComputeEncoder, RenderEncoder and BlitEncoder
    class CommandEncoder
    {
        
    public:
        
        virtual ~CommandEncoder();
        
        virtual void pushDebugGroup( const std::string & groupName );
        virtual void popDebugGroup();
        virtual void insertDebugSignpost( const std::string & name );
        virtual void setTexture( const TextureBufferRef & texture, size_t index = ciTextureIndex0 ) = 0;
        virtual void setUniforms( const DataBufferRef & buffer, size_t bytesOffset = 0, size_t bufferIndex = ciBufferIndexUniforms ) = 0;
        virtual void endEncoding();

        void * getNative(){ return mImpl; };
        
    protected:
        
        CommandEncoder( void * mtlCommandEncoder );

        void * mImpl = NULL; // <MTLRenderCommandEncoder> or <MTLComputeCommandEncoder>
    };
    
} }