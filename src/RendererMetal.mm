#include "RendererMetal.h"
#include "RendererImplMetal.h"
//
//// TEST
//// TMP
//#include "cinder/app/cocoa/AppImplCocoaTouch.h"
//@implementation AppImplCocoaTouch(CRASH_TEST)
//
//- (void)displayLinkDraw:(id)sender
//{
//    // issue initial resizes if that's necessary (only once)
//    for( auto &win : mWindows ) {
//        if( ! win->mResizeHasFired )
//            [win resize];
//    }
//    
//    NSLog(@"OVERRIDE displayLinkDraw");
//    @autoreleasepool {
//        mApp->privateUpdate__();
//        mUpdateHasFired = YES;
//        
//        for( auto &win : mWindows ) {
//            [win->mCinderView drawView];
//        }
//    }
//}
//@end

using namespace cinder;
using namespace cinder::app;
    
RendererMetal::RendererMetal() : mImpl( nullptr ) {}

#if defined( CINDER_MAC )
RendererGl::~RendererGl()
{
    if( mImpl )
        ::CFRelease( mImpl );
}
#else
RendererMetal::~RendererMetal(){}
#endif

#if defined( CINDER_COCOA )
#if defined( CINDER_MAC )
void RendererMetal::setup( CGRect frame, NSView *cinderView, RendererRef sharedRenderer, bool retinaEnabled )
{
    // TODO
    console() << "TODO: Setup\n";
};
#elif defined( CINDER_COCOA_TOUCH )
void RendererMetal::setup( const Area &frame, UIView *cinderView, RendererRef sharedRenderer )
{
//    RendererMetalRef sharedRendererMetal = std::dynamic_pointer_cast<RendererMetal>( sharedRenderer );
    mImpl = [[RendererImplMetal alloc] initWithFrame: cocoa::createCgRect( frame )
                                          cinderView: (UIView *)cinderView
                                            renderer: this];
};
#endif
#endif

void RendererMetal::setFrameSize( int width, int height )
{
    // TODO
    [mImpl setFrameSize:CGSizeMake( width, height )];
}

Surface8u RendererMetal::copyWindowSurface( const Area &area, int32_t windowHeightPixels )
{
    // TODO
    return Surface8u(area.getWidth(), area.getHeight(), false);
};

void RendererMetal::startDraw()
{
    [mImpl startDraw];
}

void RendererMetal::finishDraw()
{
    [mImpl finishDraw];
}

CAMetalLayer * RendererMetal::getLayer()
{
    return [mImpl metalLayer];
}

id <MTLDevice> RendererMetal::getDevice()
{
    return [mImpl device];
}
