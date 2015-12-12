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
#include "MetalEnums.h"

namespace cinder { namespace mtl {
    
    typedef std::shared_ptr<class RenderPassDescriptor> RenderPassDescriptorRef;
    
    class RenderPassDescriptor
    {
        
        friend class CommandBuffer;
        friend class RenderCommandBuffer;
        
    public:
        
        struct Format
        {
            Format() :
            mShouldClearColor(true)
            ,mShouldClearDepth(true)
            ,mClearColor(0.f,0.f,0.f,1.f)
            ,mClearDepth(1.f)
            ,mColorStoreAction(StoreActionStore)
            ,mDepthStoreAction(StoreActionDontCare)
            {};
            
            FORMAT_OPTION(shouldClearColor, ShouldClearColor, bool)
            FORMAT_OPTION(clearColor, ClearColor, ci::ColorAf)
            FORMAT_OPTION(colorStoreAction, ColorStoreAction, StoreAction)
            FORMAT_OPTION(shouldClearDepth, ShouldClearDepth, bool)
            FORMAT_OPTION(clearDepth, ClearDepth, float)
            FORMAT_OPTION(depthStoreAction, DepthStoreAction, StoreAction)
        };
        
        static RenderPassDescriptorRef create( const Format & format = Format() )
        {
            return RenderPassDescriptorRef( new RenderPassDescriptor( format ) );
        }
        
        static RenderPassDescriptorRef create( void * mtlRenderPassDescriptor )
        {
            return RenderPassDescriptorRef( new RenderPassDescriptor( mtlRenderPassDescriptor ) );
        }

        ~RenderPassDescriptor();
        
        void * getNative(){ return mImpl; };
        
    protected:

        RenderPassDescriptor( Format format );
        RenderPassDescriptor( void * mtlRenderPassDescriptor );
        
        void applyToDrawableTexture( void * texture, int colorAttachmentIndex = 0 ); // <MTLTexture>
        
        void setShouldClearColor( bool shouldClear, int colorAttachementIndex = 0 );
        void setClearColor( const ColorAf clearColor, int colorAttachementIndex = 0 );
        void setColorStoreAction( StoreAction storeAction, int colorAttachementIndex = 0 );
        void setShouldClearDepth( bool shouldClear );
        void setClearDepth( float clearDepth );
        void setDepthStoreAction( StoreAction storeAction );

        void * mImpl = NULL; // MTLRenderPassDescriptor *
        void * mDepthTexture = NULL; // <MTLTexture>
        
    };
    
} }