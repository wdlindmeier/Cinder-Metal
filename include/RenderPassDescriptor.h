//
//  MetalRenderPass.hpp
//  MetalCube
//
//  Created by William Lindmeier on 10/13/15.
//
//

#pragma once

#include "cinder/Cinder.h"
#include "MetalHelpers.hpp"

namespace cinder { namespace mtl {
    
    typedef std::shared_ptr<class RenderPassDescriptor> RenderPassDescriptorRef;
    
    class RenderPassDescriptor
    {
        
        friend class CommandBuffer;
        friend class RenderBuffer;
        
    public:
        
        struct Format
        {
            Format() :
            mShouldClearColor(true)
            ,mShouldClearDepth(true)
            ,mClearColor(0.f,0.f,0.f,1.f)
            ,mClearDepth(1.f)
            ,mColorStoreAction(-1) // MTLStoreActionStore
            ,mDepthStoreAction(-1) // MTLStoreActionDontCare
            {};
            
            FORMAT_OPTION(shouldClearColor, ShouldClearColor, bool)
            FORMAT_OPTION(clearColor, ClearColor, ci::ColorAf)
            FORMAT_OPTION(colorStoreAction, ColorStoreAction, int) // MTLStoreAction
            FORMAT_OPTION(shouldClearDepth, ShouldClearDepth, bool)
            FORMAT_OPTION(clearDepth, ClearDepth, float)
            FORMAT_OPTION(depthStoreAction, DepthStoreAction, int) // MTLStoreAction
        };
        
        static RenderPassDescriptorRef create( const Format & format = Format() );
        ~RenderPassDescriptor();
        
        void * getNative(){ return mImpl; };
        
    protected:

        RenderPassDescriptor( Format format );
        
        void applyToDrawableTexture( void * texture, int colorAttachmentIndex = 0 ); // <MTLTexture>
        
        void setShouldClearColor( bool shouldClear, int colorAttachementIndex = 0 );
        void setClearColor( const ColorAf clearColor, int colorAttachementIndex = 0 );
        void setColorStoreAction( int storeAction, int colorAttachementIndex = 0 ); // MTLStoreAction
        void setShouldClearDepth( bool shouldClear );
        void setClearDepth( float clearDepth );
        void setDepthStoreAction( int storeAction ); // MTLStoreAction

        void * mImpl = NULL; // MTLRenderPassDescriptor *
        void * mDepthTexture = NULL; // <MTLTexture>
        
    };
    
} }