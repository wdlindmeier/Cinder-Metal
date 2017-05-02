//
//  MetalRenderPass.hpp
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
            ,mShouldClearStencil(true)
            ,mClearColor(0.f,0.f,0.f,1.f)
            ,mClearDepth(1.f)
            ,mClearStencil(0)
            ,mColorStoreAction(StoreActionStore)
            ,mDepthStoreAction(StoreActionDontCare)
            ,mStencilStoreAction(StoreActionDontCare)
            ,mDepthUsage(TextureUsageRenderTarget)
            ,mStencilUsage(TextureUsageRenderTarget)
            ,mHasDepth(true)
            ,mHasStencil(false)
            ,mDepthPixelFormat(PixelFormatDepth32Float)
            ,mStencilPixelFormat(PixelFormatStencil8)
            {};            

        public:

            Format& shouldClearColor( bool shouldClearColor ) { setShouldClearColor( shouldClearColor ); return *this; };
            void setShouldClearColor( bool shouldClearColor ) { mShouldClearColor = shouldClearColor; };
            bool getShouldClearColor() const { return mShouldClearColor; };

            Format& clearColor( ci::ColorAf clearColor ) { setClearColor( clearColor ); return *this; };
            void setClearColor( ci::ColorAf clearColor ) { mClearColor = clearColor; };
            ci::ColorAf getClearColor() const { return mClearColor; };

            Format& colorStoreAction( StoreAction colorStoreAction ) { setColorStoreAction( colorStoreAction ); return *this; };
            void setColorStoreAction( StoreAction colorStoreAction ) { mColorStoreAction = colorStoreAction; };
            StoreAction getColorStoreAction() const { return mColorStoreAction; };

            Format& shouldClearDepth( bool shouldClearDepth ) { setShouldClearDepth( shouldClearDepth ); return *this; };
            void setShouldClearDepth( bool shouldClearDepth ) { mShouldClearDepth = shouldClearDepth; };
            bool getShouldClearDepth() const { return mShouldClearDepth; };

            Format& clearDepth( float clearDepth ) { setClearDepth( clearDepth ); return *this; };
            void setClearDepth( float clearDepth ) { mClearDepth = clearDepth; };
            float getClearDepth() const { return mClearDepth; };

            Format& depthStoreAction( StoreAction depthStoreAction ) { setDepthStoreAction( depthStoreAction ); return *this; };
            void setDepthStoreAction( StoreAction depthStoreAction ) { mDepthStoreAction = depthStoreAction; };
            StoreAction getDepthStoreAction() const { return mDepthStoreAction; };

            Format& depthUsage( TextureUsage depthUsage ) { setDepthUsage( depthUsage ); return *this; };
            void setDepthUsage( TextureUsage depthUsage ) { mDepthUsage = depthUsage; };
            TextureUsage getDepthUsage() const { return mDepthUsage; };

            Format& shouldClearStencil( bool shouldClearStencil ) { setShouldClearStencil( shouldClearStencil ); return *this; };
            void setShouldClearStencil( bool shouldClearStencil ) { mShouldClearStencil = shouldClearStencil; };
            bool getShouldClearStencil() const { return mShouldClearStencil; };
            
            Format& clearStencil( uint32_t clearStencil ) { setClearStencil( clearStencil ); return *this; };
            void setClearStencil( uint32_t clearStencil ) { mClearStencil = clearStencil; };
            uint32_t getClearStencil() const { return mClearStencil; };
            
            Format& stencilStoreAction( StoreAction stencilStoreAction ) { setStencilStoreAction( stencilStoreAction ); return *this; };
            void setStencilStoreAction( StoreAction stencilStoreAction ) { mStencilStoreAction = stencilStoreAction; };
            StoreAction getStencilStoreAction() const { return mStencilStoreAction; };
            
            Format& stencilUsage( TextureUsage stencilUsage ) { setStencilUsage( stencilUsage ); return *this; };
            void setStencilUsage( TextureUsage stencilUsage ) { mStencilUsage = stencilUsage; };
            TextureUsage getStencilUsage() const { return mStencilUsage; };

            Format& hasDepth( bool hasDepth ) { setHasDepth( hasDepth ); return *this; };
            void setHasDepth( bool hasDepth ) { mHasDepth = hasDepth; };
            bool getHasDepth() const { return mHasDepth; };

            Format& hasStencil( bool hasStencil ) { setHasStencil( hasStencil ); return *this; };
            void setHasStencil( bool hasStencil ) { mHasStencil = hasStencil; };
            bool getHasStencil() const { return mHasStencil; };
            
            Format& depthPixelFormat( PixelFormat pixelFormat ) { setDepthPixelFormat( pixelFormat ); return *this; };
            void setDepthPixelFormat( PixelFormat pixelFormat ) { mDepthPixelFormat = pixelFormat; };
            PixelFormat getDepthPixelFormat() const { return mDepthPixelFormat; };
            
            Format& stencilPixelFormat( PixelFormat pixelFormat ) { setStencilPixelFormat( pixelFormat ); return *this; };
            void setStencilPixelFormat( PixelFormat pixelFormat ) { mStencilPixelFormat = pixelFormat; };
            PixelFormat getStencilPixelFormat() const { return mStencilPixelFormat; };

        protected:
            
            bool mShouldClearColor;
            ci::ColorAf mClearColor;
            StoreAction mColorStoreAction;
            
            bool mHasDepth;
            bool mShouldClearDepth;
            float mClearDepth;
            StoreAction mDepthStoreAction;
            TextureUsage mDepthUsage;
            PixelFormat mDepthPixelFormat;
            
            bool mHasStencil;
            bool mShouldClearStencil;
            uint32_t mClearStencil;
            StoreAction mStencilStoreAction;
            TextureUsage mStencilUsage;
            PixelFormat mStencilPixelFormat;
            
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

        mtl::TextureBufferRef & getDepthTexture();
        mtl::TextureBufferRef & getStencilTexture();
        mtl::TextureBufferRef & getColorAttachment( int colorAttachmentIndex = 0 );
        
        void setColorAttachment( TextureBufferRef & texture, int colorAttachmentIndex = 0 );
        
    protected:

        RenderPassDescriptor( Format format );
        RenderPassDescriptor( void * mtlRenderPassDescriptor );
        
        void applyToDrawableTexture( void * texture, int colorAttachmentIndex = 0 ); // <MTLTexture>
        
        void setShouldClearColor( bool shouldClear, int colorAttachementIndex = 0 );
        void setClearColor( const ColorAf clearColor, int colorAttachementIndex = 0 );
        void setColorStoreAction( StoreAction storeAction, int colorAttachementIndex = 0 );

        void setShouldClearDepth( bool shouldClear );
        void setClearDepth( float clearValue );
        void setDepthStoreAction( StoreAction storeAction );

        void setShouldClearStencil( bool shouldClear );
        void setClearStencil( uint32_t clearValue );
        void setStencilStoreAction( StoreAction storeAction );

        void * mImpl = NULL; // MTLRenderPassDescriptor *
        void * mDepthTexture = NULL; // <MTLTexture>
        void * mStencilTexture = NULL; // <MTLTexture>
        
        mtl::TextureBufferRef mDepthTextureBuffer;
        mtl::TextureBufferRef mStencilTextureBuffer;
        std::vector<mtl::TextureBufferRef> mColorTextureBuffers;
        
        Format mFormat;
        
        bool mHasDepth;
        bool mHasStencil;
        
    };
    
} }