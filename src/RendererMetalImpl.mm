//
//  RendererMetalImpl.m
//
//  Created by William Lindmeier on 10/11/15.
//
//

#import <Foundation/Foundation.h>
#import <Metal/Metal.h>
#import <QuartzCore/CAMetalLayer.h>
#import <simd/simd.h>

#import "metal.h"
#import "RendererMetal.h"
#import "RendererMetalImpl.h"
#include "cinder/Log.h"

#if defined( CINDER_MAC )
#import <AppKit/AppKit.h>
#import "cinder/app/cocoa/CinderViewMac.h"
@implementation CinderViewMac(Metal)
- (CALayer *)makeBackingLayer
{
    return [CAMetalLayer layer];
}
@end
#elif defined( CINDER_COCOA_TOUCH )
#import "cinder/app/cocoa/CinderViewCocoaTouch.h"
@implementation CinderViewCocoaTouch(Metal)
+ (Class)layerClass
{
    return [CAMetalLayer class];
}
@end
#endif

using namespace ci;
using namespace ci::mtl;

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
#if defined( CINDER_MAC )
        mCinderView.wantsLayer = YES;
#endif
        self.metalLayer = (CAMetalLayer *)mCinderView.layer;
        assert( [self.metalLayer isKindOfClass:[CAMetalLayer class]] );
        [self setupMetal:options];
    }
    else
    {
        return nil;
    }
    
    SharedRenderer = self;
    
    std::shared_ptr<cinder::mtl::Context::PlatformData> platformData( new cinder::mtl::Context::PlatformData() );
    mCinderContext = cinder::mtl::Context::createFromExisting( platformData );
    
    return self;
}

// https://developer.apple.com/library/ios/documentation/Miscellaneous/Conceptual/MetalProgrammingGuide/MetalFeatureSetTables/MetalFeatureSetTables.html
- (int)maxNumColorAttachments
{
#ifdef CINDER_COCOA_TOUCH
    if ( ![self.device supportsFeatureSet:MTLFeatureSet_iOS_GPUFamily2_v1] )
    {
        return 4;
    }
#endif
    return 8;
}

- (void)setupMetal:(cinder::app::RendererMetal::Options &)options
{
    // TODO: Add device picking to options.
    // Example of how to pick a specific GPU:
    /*
    NSArray<id<MTLDevice>> * devices = MTLCopyAllDevices();
    for ( id<MTLDevice> d in devices )
    {
       NSLog(@"device: %@", d);
       //if ( [d.name rangeOfString:@"750"].location != NSNotFound )
       if ( [d.name rangeOfString:@"Iris"].location != NSNotFound )
       {
           self.device = d;
       }
    }

    assert(self.device);
    */
    self.device = MTLCreateSystemDefaultDevice();
    
#if DEBUG
#ifdef CINDER_COCOA_TOUCH
    CI_LOG_I("Metal Device Support:");
    CI_LOG_I("MTLFeatureSet_iOS_GPUFamily1_v1 " << [self.device supportsFeatureSet:MTLFeatureSet_iOS_GPUFamily1_v1]);
    CI_LOG_I("MTLFeatureSet_iOS_GPUFamily1_v2 " << [self.device supportsFeatureSet:MTLFeatureSet_iOS_GPUFamily1_v2]);
    CI_LOG_I("MTLFeatureSet_iOS_GPUFamily2_v1 " << [self.device supportsFeatureSet:MTLFeatureSet_iOS_GPUFamily2_v1]);
    CI_LOG_I("MTLFeatureSet_iOS_GPUFamily2_v2 " << [self.device supportsFeatureSet:MTLFeatureSet_iOS_GPUFamily2_v2]);
    CI_LOG_I("MTLFeatureSet_iOS_GPUFamily3_v1 " << [self.device supportsFeatureSet:MTLFeatureSet_iOS_GPUFamily3_v1]);
#else
    CI_LOG_I("MTLFeatureSet_OSX_GPUFamily1_v1 " << [self.device supportsFeatureSet:MTLFeatureSet_OSX_GPUFamily1_v1]);
#endif
#endif

    // Create a new command queue
    self.commandQueue = [self.device newCommandQueue];
    
    // Load all the shader files with a metal file extension in the project.
    // NOTE: If there are no .metal shaders found in the project, this will fail:
    // "failed assertion `Metal default library not found'"
    self.library = [self.device newDefaultLibrary];
    
    _metalLayer.device = self.device;
    
    int numInflightBuffers = options.getNumInflightBuffers();
    CI_LOG_I("Creating renderer with " << numInflightBuffers << " inflight buffers.");

    if ( numInflightBuffers > 1 )
    {
        mInflightSemaphore = dispatch_semaphore_create(numInflightBuffers);
    }
    else
    {
        mInflightSemaphore = nil;
    }

    // Pixel format could be an option.
    _metalLayer.pixelFormat = (MTLPixelFormat)options.getPixelFormat();
    
    // Change this to NO if the compute encoder is used as the last pass on the drawable texture,
    // or if you wish to copy the layer contents to an image.
    _metalLayer.framebufferOnly = options.getFramebufferOnly();
}

- (void)setFrameSize:(CGSize)newSize
{
    self.metalLayer.frame = CGRectMake(0, 0, newSize.width, newSize.height);
    mLayerSizeDidUpdate = YES;
}

- (void)startDraw
{
#if defined( CINDER_COCOA_TOUCH )
    CGFloat nativeScale = mCinderView.window.screen.nativeScale;
#else 
    CGFloat nativeScale = mCinderView.window.backingScaleFactor;
#endif
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

- (void)makeCurrentContext:(bool)force
{
//    CI_LOG_I("Making current context");
    mCinderContext->makeCurrent( force );
}

@end
