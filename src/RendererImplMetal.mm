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
#import <QuartzCore/CAMetalLayer.h>

#include "metal.h"
#include "RendererMetal.h"
#include "MetalContext.h"
#include "RendererImplMetal.h"
#include "cinder/app/cocoa/CinderViewCocoaTouch.h"

@implementation CinderViewCocoaTouch(Metal)

+ (Class)layerClass
{
    NSLog(@"Setting CAMetalLayer");
    return [CAMetalLayer class];
}

@end

@implementation RendererImplMetal
{
}

- (id)initWithFrame:(CGRect)frame cinderView:(UIView *)cinderView renderer:(cinder::app::RendererMetal *)renderer
{
    self = [super init];
    if ( self )
    {
        _layerSizeDidUpdate = true;
        mCinderView = cinderView;
        // Get the layer
        CAMetalLayer *metalLayer = (CAMetalLayer *)mCinderView.layer;
        assert( [metalLayer isKindOfClass:[CAMetalLayer class]] );
        [self setupMetal];
    }
    return self;
}

- (void)setupMetal
{
    // Setup metal layer and add as sub layer to view
    CAMetalLayer *metalLayer = [MetalContext sharedContext].metalLayer;
    metalLayer.pixelFormat = MTLPixelFormatBGRA8Unorm;
    // Change this to NO if the compute encoder is used as the last pass on the drawable texture
    metalLayer.framebufferOnly = YES;

    // Add metal layer to the views layer hierarchy
    [metalLayer setFrame:mCinderView.layer.bounds];
    [mCinderView.layer addSublayer:metalLayer];
    mCinderView.opaque = YES;
    mCinderView.backgroundColor = nil;
    mCinderView.contentScaleFactor = [UIScreen mainScreen].scale;
}

- (void)setFrameSize:(CGSize)newSize
{
    CAMetalLayer *metalLayer = [MetalContext sharedContext].metalLayer;
    metalLayer.frame = CGRectMake(0, 0, newSize.width, newSize.height);
    _layerSizeDidUpdate = YES;
}

- (void)startDraw
{
    CGFloat nativeScale = mCinderView.window.screen.nativeScale;
    CGSize drawableSize = mCinderView.bounds.size;
    drawableSize.width *= nativeScale;
    drawableSize.height *= nativeScale;
    [MetalContext sharedContext].metalLayer.drawableSize = drawableSize;
    _layerSizeDidUpdate = NO;
    [[MetalContext sharedContext] startDraw];
    ci::app::console() << "start render\n";
}

- (void)finishDraw
{
    //...
    [[MetalContext sharedContext] finishDraw];//:(id<MTLCommandBuffer>)
    ci::app::console() << "finish render\n";
}

@end