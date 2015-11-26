//
//  RendererMetalImpl.m
//  MetalCube
//
//  Created by William Lindmeier on 10/11/15.
//
//

#import <Foundation/Foundation.h>
#import <Metal/Metal.h>
#import <simd/simd.h>

#import "metal.h"
#import "RendererMetal.h"
#import "RendererMetalImpl.h"

#import "cinder/app/cocoa/CinderViewCocoaTouch.h"

using namespace ci;
using namespace ci::mtl;

@implementation CinderViewCocoaTouch(Metal)

+ (Class)layerClass
{
    return [CAMetalLayer class];
}

@end

@implementation RendererMetalImpl
{
    dispatch_semaphore_t mInflightSemaphore;
}

static RendererMetalImpl * SharedRenderer = nil;

+ (instancetype)sharedRenderer
{
    assert( SharedRenderer != nil );
    return SharedRenderer;
}

- (dispatch_semaphore_t)inflightSemaphore
{
    return mInflightSemaphore;
}
#if defined( CINDER_MAC )
- (instancetype)initWithFrame:(CGRect)frame
                   cinderView:(NSView *)cinderView
                     renderer:(cinder::app::RendererMetal *)renderer
                      options:(cinder::app::RendererMetal::Options &)options;
#elif defined( CINDER_COCOA_TOUCH )
- (instancetype)initWithFrame:(CGRect)frame
                   cinderView:(UIView *)cinderView
                     renderer:(cinder::app::RendererMetal *)renderer
                      options:(cinder::app::RendererMetal::Options &)options
#endif
{
    if ( SharedRenderer )
    {
        return SharedRenderer;
    }
    
    self = [super init];
    
    if ( self )
    {
        mLayerSizeDidUpdate = true;
        mCinderView = cinderView;
        // Get the layer
        CAMetalLayer *metalLayer = (CAMetalLayer *)mCinderView.layer;
        assert( [metalLayer isKindOfClass:[CAMetalLayer class]] );
        [self setupMetal:options.getNumInflightBuffers()];
    }
    
    SharedRenderer = self;
    
    return self;
}

- (void)setupMetal:(int)numInflightBuffers
{
    self.device = MTLCreateSystemDefaultDevice();
    
    // Create a new command queue
    self.commandQueue = [self.device newCommandQueue];
    
    // Load all the shader files with a metal file extension in the project.
    // NOTE: If there are no .metal shaders found in the project, this will fail:
    // "failed assertion `Metal default library not found'"
    self.library = [self.device newDefaultLibrary];
    
    self.metalLayer = [CAMetalLayer layer];
    _metalLayer.device = self.device;
    
    if ( numInflightBuffers > 1 )
    {
        mInflightSemaphore = dispatch_semaphore_create(numInflightBuffers);
    }
    else
    {
        mInflightSemaphore = nil;
    }

    // Setup metal layer and add as sub layer to view

    _metalLayer.pixelFormat = MTLPixelFormatBGRA8Unorm;
    // Change this to NO if the compute encoder is used as the last pass on the drawable texture
    _metalLayer.framebufferOnly = YES;

    // Add metal layer to the views layer hierarchy
    [_metalLayer setFrame:mCinderView.layer.bounds];
    [mCinderView.layer addSublayer:_metalLayer];
    mCinderView.opaque = YES;
    mCinderView.backgroundColor = nil;
    mCinderView.contentScaleFactor = [UIScreen mainScreen].scale;
}

- (void)setFrameSize:(CGSize)newSize
{
    self.metalLayer.frame = CGRectMake(0, 0, newSize.width, newSize.height);
    mLayerSizeDidUpdate = YES;
}

- (void)startDraw
{
    CGFloat nativeScale = mCinderView.window.screen.nativeScale;
    CGSize drawableSize = mCinderView.bounds.size;
    drawableSize.width *= nativeScale;
    drawableSize.height *= nativeScale;
    self.metalLayer.drawableSize = drawableSize;
    mLayerSizeDidUpdate = NO;

    if ( mInflightSemaphore )
    {
        dispatch_semaphore_wait(mInflightSemaphore, DISPATCH_TIME_FOREVER);
    }
}

- (void)finishDraw
{
    //...
}

@end