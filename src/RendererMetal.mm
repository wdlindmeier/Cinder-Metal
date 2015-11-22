#include "RendererMetal.h"
#include "CinderViewCocoaTouch+Metal.h"
#include "RendererMetalImpl.h"
#include "RenderEncoder.h"

using namespace cinder;
using namespace cinder::app;
using namespace cinder::mtl;
    
RendererMetal::RendererMetal( const Options & options ) :
mImpl( nullptr )
,mOptions(options)
{
    ci::app::console() << "Creating renderer with " << mOptions.getNumInflightBuffers() << " inflight buffers.\n";
}

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
    console() << "TODO: Setup for mac\n";
};
#elif defined( CINDER_COCOA_TOUCH )
void RendererMetal::setup( const Area &frame, UIView *cinderView, RendererRef sharedRenderer )
{
    mImpl = [[RendererMetalImpl alloc] initWithFrame: cocoa::createCgRect( frame )
                                          cinderView: (UIView *)cinderView
                                            renderer: this
                                             options: mOptions ];
};
#endif
#endif

void RendererMetal::setFrameSize( int width, int height )
{
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
