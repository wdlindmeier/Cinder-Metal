//
//  MetalRenderPass.hpp
//  Cinder-Metal
//
//  Created by William Lindmeier on 10/13/15.
//
//

#pragma once

#include "cinder/Cinder.h"
#include "MetalHelpers.hpp"
#include "MetalEnums.h"
#include "TextureBuffer.h"

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
            ,mDepthUsage(TextureUsageRenderTarget)            
            {};
            
            // Format Options

        public:

            Format& shouldClearColor( bool shouldClearColor ) { setShouldClearColor( shouldClearColor ); return *this; };
            void setShouldClearColor( bool shouldClearColor ) { mShouldClearColor = shouldClearColor; };
            bool getShouldClearColor() { return mShouldClearColor; };

            Format& clearColor( ci::ColorAf clearColor ) { setClearColor( clearColor ); return *this; };
            void setClearColor( ci::ColorAf clearColor ) { mClearColor = clearColor; };
            ci::ColorAf getClearColor() { return mClearColor; };

            Format& colorStoreAction( StoreAction colorStoreAction ) { setColorStoreAction( colorStoreAction ); return *this; };
            void setColorStoreAction( StoreAction colorStoreAction ) { mColorStoreAction = colorStoreAction; };
            StoreAction getColorStoreAction() { return mColorStoreAction; };

            Format& shouldClearDepth( bool shouldClearDepth ) { setShouldClearDepth( shouldClearDepth ); return *this; };
            void setShouldClearDepth( bool shouldClearDepth ) { mShouldClearDepth = shouldClearDepth; };
            bool getShouldClearDepth() { return mShouldClearDepth; };

            Format& clearDepth( float clearDepth ) { setClearDepth( clearDepth ); return *this; };
            void setClearDepth( float clearDepth ) { mClearDepth = clearDepth; };
            float getClearDepth() { return mClearDepth; };

            Format& depthStoreAction( StoreAction depthStoreAction ) { setDepthStoreAction( depthStoreAction ); return *this; };
            void setDepthStoreAction( StoreAction depthStoreAction ) { mDepthStoreAction = depthStoreAction; };
            StoreAction getDepthStoreAction() { return mDepthStoreAction; };

            Format& depthUsage( TextureUsage depthUsage ) { setDepthUsage( depthUsage ); return *this; };
            void setDepthUsage( TextureUsage depthUsage ) { mDepthUsage = depthUsage; };
            TextureUsage getDepthUsage() { return mDepthUsage; };

        protected:
            
            bool mShouldClearColor;
            ci::ColorAf mClearColor;
            StoreAction mColorStoreAction;
            bool mShouldClearDepth;
            float mClearDepth;
            StoreAction mDepthStoreAction;
            TextureUsage mDepthUsage;
            
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

        mtl::TextureBufferRef getDepthTexture();
        
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
        mtl::TextureBufferRef mDepthTextureBuffer;
        
        Format mFormat;
    };
    
} }