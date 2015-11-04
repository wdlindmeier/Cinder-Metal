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

- (instancetype)initWithFrame:(CGRect)frame
                   cinderView:(UIView *)cinderView
                     renderer:(cinder::app::RendererMetal *)renderer
                      options:(cinder::app::RendererMetal::Options &)options
{
    if ( SharedRenderer )
    {
        return SharedRenderer;
    }
    
    self = [super init];
    
    if ( self )
    {
        _layerSizeDidUpdate = true;
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
    
    mInflightSemaphore = dispatch_semaphore_create(numInflightBuffers);

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
    _layerSizeDidUpdate = YES;
}

- (void)startDraw
{
    CGFloat nativeScale = mCinderView.window.screen.nativeScale;
    CGSize drawableSize = mCinderView.bounds.size;
    drawableSize.width *= nativeScale;
    drawableSize.height *= nativeScale;
    self.metalLayer.drawableSize = drawableSize;
    _layerSizeDidUpdate = NO;

    dispatch_semaphore_wait(mInflightSemaphore, DISPATCH_TIME_FOREVER);
}

- (void)commandBufferBlock:(void (^)( ci::mtl::CommandBufferRef commandBuffer ))commandBlock
{
    id <MTLCommandBuffer> commandBuffer = [self.commandQueue commandBuffer];
    // TODO: Pass in an optional name
    commandBuffer.label = @"FrameCommands";
    id <CAMetalDrawable> drawable = [self.metalLayer nextDrawable];

    CommandBufferRef ciCommandBuffer = CommandBuffer::create((__bridge void *)commandBuffer,
                                                             (__bridge void *)drawable);
    
    commandBlock( ciCommandBuffer );
    
    __block dispatch_semaphore_t block_sema = mInflightSemaphore;
    [commandBuffer addCompletedHandler:^(id<MTLCommandBuffer> buffer) {
        dispatch_semaphore_signal(block_sema);
    }];
    
    [commandBuffer presentDrawable:drawable];
    
    // Finalize rendering here & push the command buffer to the GPU
    [commandBuffer commit];
}

- (void)finishDraw
{
    //...
}

@end