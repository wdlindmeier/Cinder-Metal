#pragma once

#include "cinder/Cinder.h"
#include "cinder/app/Renderer.h"

#if defined( CINDER_COCOA )
#include "CinderViewCocoaTouch+Metal.h"
#if defined __OBJC__
@class RendererImplMetal;
#else
class RendererImplMetal;
#endif
#endif

namespace cinder { namespace app {
    
    typedef std::shared_ptr<class RendererMetal> RendererMetalRef;
    
    class RendererMetal : public Renderer {
        
    public:
        
        RendererMetal();
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
//        virtual CGContextRef	getCgContext() { throw; } // the default behavior is failure
        void setFrameSize( int width, int height )  override;
        
        Surface8u copyWindowSurface( const Area &area, int32_t windowHeightPixels )  override;
        
        void startDraw() override;
        void finishDraw() override;

    protected:

        RendererImplMetal *mImpl;
        
    };
  
}}