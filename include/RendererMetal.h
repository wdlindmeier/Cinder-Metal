#pragma once

#include "cinder/Cinder.h"
#include "cinder/app/Renderer.h"

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
        class CommandBuffer;
    }
    
    namespace app {
    
        typedef std::shared_ptr<class RendererMetal> RendererMetalRef;
        

        class RendererMetal : public Renderer {
            
        public:
            
            struct Options
            {
            public:
                
                Options() : mMaxInflightBuffers(3) {}
                
                Options & numInflightBuffers( int numInflightBuffers ){ mMaxInflightBuffers = numInflightBuffers; return *this; };
                const int getNumInflightBuffers() const { return mMaxInflightBuffers; }
                
            protected:
                
                int mMaxInflightBuffers;
                
            };
            
            RendererMetal( const Options & options = Options() );
            virtual ~RendererMetal();
            
            // TODO
            // How do I cast this?
            // Why does this need to be casted?
            RendererRef clone() const override { return std::dynamic_pointer_cast<Renderer>(RendererMetalRef( new RendererMetal( *this ) ) ); }
            
#if defined( CINDER_COCOA )
#if defined( CINDER_MAC )
            void setup( CGRect frame, NSView *cinderView, RendererRef sharedRenderer, bool retinaEnabled )  override;
#elif defined( CINDER_COCOA_TOUCH )
            void setup( const Area &frame, UIView *cinderView, RendererRef sharedRenderer )  override;
            
            // NOTE: We're not technically an EAGL layer, but we can pretent to be for the same callback / loop behavior
            bool isEaglLayer() const override { return true; }
#endif
#endif
            void setFrameSize( int width, int height )  override;
            const Options&	getOptions() const { return mOptions; }
            
            Surface8u copyWindowSurface( const Area &area, int32_t windowHeightPixels )  override;
            
            void startDraw() override;
            void finishDraw() override;
            

        protected:

            RendererMetalImpl *mImpl;

            Options mOptions;

        };
        
    } // app
    
    namespace mtl {
        
        class RenderEncoder;
        class CommandBuffer;
        
        void commandBufferBlock( std::function< void ( std::shared_ptr<CommandBuffer> cmdBuffer ) > commandFunc );
        
    }
}

