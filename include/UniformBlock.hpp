//
//  UniformBlock.hpp
//  CinderVuforiaMTL
//
//  Created by William Lindmeier on 1/3/16.
//
//

#pragma once

#include "cinder/Cinder.h"
#include "cinder/app/App.h"
#include "DataBuffer.h"
#include "RenderEncoder.h"
#include "metal.h"

namespace cinder { namespace mtl {
    
    template <typename T>
    class UniformBlock
    {
        
    public:
        
        // TODO: How can we make a shared pointer with a templated class?
        UniformBlock( const std::string & name = "Uniforms" ) :
        mInflightBufferIndex(0)
        {
            app::RendererMetalRef metalRenderer = std::static_pointer_cast<app::RendererMetal>(ci::app::getWindow()->getRenderer());
            assert( metalRenderer );
            mNumInflightBuffers = metalRenderer->getNumInflightBuffers();
            mDynamicUniformBuffer = DataBuffer::create(mtlConstantSizeOf(T) * mNumInflightBuffers,
                                                       nullptr,
                                                       mtl::DataBuffer::Format()
                                                       .label(name)
                                                       .isConstant());
        }

        void sendToEncoder( CommandEncoder & commandEncoder,
                            int shaderBufferIndex = ciBufferIndexUniforms )
        {
            size_t constantsOffset = mtlConstantSizeOf(T) * mInflightBufferIndex;
            commandEncoder.setUniforms(mDynamicUniformBuffer, constantsOffset, shaderBufferIndex);
        }
        
        void updateData( std::function<T (T data)> func )
        {
            mData = func( mData );
            sync();
        }
        
        const T getData() const { return mData; };
        
    protected:

        void sync()
        {
            mInflightBufferIndex = (mInflightBufferIndex + 1) % mNumInflightBuffers;
            mDynamicUniformBuffer->setDataAtIndex(&mData, mInflightBufferIndex);
        }

        T mData;
        
        ci::mtl::DataBufferRef  mDynamicUniformBuffer;
        int mInflightBufferIndex;
        int mNumInflightBuffers;
        
    };
    
    template <typename T>
    void operator<<( mtl::RenderEncoder & renderEncoder, mtl::UniformBlock<T> & uniformBlock )
    {
        uniformBlock.sendToEncoder( renderEncoder );
    }
    
}}