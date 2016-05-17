#pragma once

#include "cinder/Cinder.h"
#include "cinder/app/Renderer.h"
#include "MetalEnums.h"

#if defined( CINDER_COCOA )
//#include "CinderViewCocoaTouch+Metal.h"
#if defined __OBJC__
@class RendererMetalImpl;
#else
class RendererMetalImpl;
#endif
#endif

namespace cinder {
    
    namespace mtl {

        const static int DEFAULT_NUM_INFLIGHT_BUFFERS = 3;

        class CommandBuffer;
    }
    
    
    namespace app {
    
        typedef std::shared_ptr<class RendererMetal> RendererMetalRef;
        
        class RendererMetal : public Renderer {
            
        public:
            
            struct Options
            {
            public:
                
                Options() :
                mMaxInflightBuffers( mtl::DEFAULT_NUM_INFLIGHT_BUFFERS )
                ,mFramebufferOnly(true)
                {}
                
                Options & numInflightBuffers( int numInflightBuffers ){ mMaxInflightBuffers = numInflightBuffers; return *this; };
                const int getNumInflightBuffers() const { return mMaxInflightBuffers; }
                Options & framebufferOnly( bool framebufferOnly ){ mFramebufferOnly = framebufferOnly; return *this; };
                const int getFramebufferOnly() const { return mFramebufferOnly; }
                Options & pixelFormat( mtl::PixelFormat format ){ mPixelFormat = format; return *this; };
                const mtl::PixelFormat getPixelFormat() const { return mPixelFormat; }
                
            protected:
                
                int mMaxInflightBuffers;
                bool mFramebufferOnly;
                mtl::PixelFormat mPixelFormat = mtl::PixelFormatBGRA8Unorm;
                
            };
            
            RendererMetal( const Options & options = Options() );
            
            RendererRef clone() const override { return RendererMetalRef( new RendererMetal( *this ) ); }
            
#if defined( CINDER_MAC )
            void setup( CGRect frame, NSView *cinderView, RendererRef sharedRenderer, bool retinaEnabled )  override;
#elif defined( CINDER_COCOA_TOUCH )
            void setup( const Area &frame, UIView *cinderView, RendererRef sharedRenderer )  override;
            
            // NOTE: We're not technically an EAGL layer, but we can pretent to be for the same callback / loop behavior
            bool isEaglLayer() const override { return true; }
#endif
            void setFrameSize( int width, int height )  override;
            const Options&	getOptions() const { return mOptions; }
            
            Surface8u copyWindowSurface( const Area &area, int32_t windowHeightPixels )  override;
            
            void startDraw() override;
            void finishDraw() override;
            
            void makeCurrentContext( bool force = false ) override;
            
            int getNumInflightBuffers(){ return mOptions.getNumInflightBuffers(); };
            
        protected:

            RendererMetalImpl *mImpl;

            Options mOptions;

        };
        
    } // app    
}

