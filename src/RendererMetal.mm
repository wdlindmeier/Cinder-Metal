#include "RendererMetal.h"
#include "RendererMetalImpl.h"
#include "RenderEncoder.h"
#include "ImageHelpers.h"
#include "cinder/ip/resize.h"
#include "cinder/cocoa/CinderCocoa.h"

using namespace cinder;
using namespace cinder::app;
using namespace cinder::mtl;
    
RendererMetal::RendererMetal( const Options & options ) :
mImpl( nullptr )
,mOptions(options)
{}

#if defined( CINDER_COCOA )
#if defined( CINDER_MAC )
void RendererMetal::setup( CGRect frame, NSView *cinderView, RendererRef sharedRenderer, bool retinaEnabled )
{
    mImpl = [[RendererMetalImpl alloc] initWithFrame: frame
                                          cinderView: cinderView
                                            renderer: this
                                             options: mOptions ];
};
#elif defined( CINDER_COCOA_TOUCH )
void RendererMetal::setup( const Area &frame, UIView *cinderView, RendererRef sharedRenderer )
{
    mImpl = [[RendererMetalImpl alloc] initWithFrame: cocoa::createCgRect( frame )
                                          cinderView: cinderView
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
    id <CAMetalDrawable> drawable = [RendererMetalImpl sharedRenderer].currentDrawable;
    assert( drawable != nil );
    // NOTE: The metal layer framebufferOnly must be false.
    // This can be set in the Renderer Options.
    assert( ![RendererMetalImpl sharedRenderer].metalLayer.framebufferOnly );
    ImageSourceRef drawableImage( new ImageSourceMTLTexture( (__bridge void *)drawable.texture ) );
    Surface8u windowContents( drawableImage );
    if ( windowContents.getBounds() != area )
    {
        // Crop it
        return ip::resizeCopy( windowContents, area, area.getSize() );
    }
    return windowContents;
};

void RendererMetal::startDraw()
{
    [mImpl startDraw];
}

void RendererMetal::finishDraw()
{
    [mImpl finishDraw];
}

void RendererMetal::makeCurrentContext( bool force )
{
    [mImpl makeCurrentContext:force];
}
