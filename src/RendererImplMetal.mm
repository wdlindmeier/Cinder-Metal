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

#include "RendererMetal.h"
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
//        mBackingWidth = frame.size.width;
//        mBackingHeight = frame.size.height;
        [self setupMetal];
    }
    return self;
}

- (void)setupMetal
{
    // Find a usable device
    self.device = MTLCreateSystemDefaultDevice();
    
    // Create a new command queue
    self.commandQueue = [self.device newCommandQueue];
    
//    // Load all the shader files with a metal file extension in the project.
//    // NOTE: If there are no .metal shaders found in the project, this will fail:
//    // "failed assertion `Metal default library not found'"
//    _defaultLibrary = [_device newDefaultLibrary];
    
    // Setup metal layer and add as sub layer to view
    self.metalLayer = [CAMetalLayer layer];
    self.metalLayer.device = self.device;
    self.metalLayer.pixelFormat = MTLPixelFormatBGRA8Unorm;
    
    // Change this to NO if the compute encoder is used as the last pass on the drawable texture
    self.metalLayer.framebufferOnly = YES;
    
    // Add metal layer to the views layer hierarchy
    [self.metalLayer setFrame:mCinderView.layer.bounds];
    [mCinderView.layer addSublayer:self.metalLayer];
    mCinderView.opaque = YES;
    mCinderView.backgroundColor = nil;
    mCinderView.contentScaleFactor = [UIScreen mainScreen].scale;
}

- (void)setFrameSize:(CGSize)newSize
{    
    self.metalLayer.frame = CGRectMake(0, 0, newSize.width, newSize.height);
    _layerSizeDidUpdate = YES;
    [_metalLayer setFrame:mCinderView.layer.bounds];
}

- (void)startDraw
{
    CGFloat nativeScale = mCinderView.window.screen.nativeScale;
    CGSize drawableSize = mCinderView.bounds.size;
    drawableSize.width *= nativeScale;
    drawableSize.height *= nativeScale;
    self.metalLayer.drawableSize = drawableSize;
    _layerSizeDidUpdate = NO;
    ci::app::console() << "start render\n";
}

- (void)finishDraw
{
    //...
    ci::app::console() << "finish render\n";
}

@end