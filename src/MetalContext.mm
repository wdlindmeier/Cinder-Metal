//
//  MetalContext.cpp
//  MetalCube
//
//  Created by William Lindmeier on 10/13/15.
//
//

#include "MetalContext.h"

#import <QuartzCore/CAMetalLayer.h>
#import <Metal/Metal.h>
#import <simd/simd.h>
#import "metal.h"
#import "RendererMetal.h"
#import "MetalRenderPass.h"

using namespace cinder;
using namespace ci::app;
using namespace cinder::mtl;

@interface MetalContext()
{
    dispatch_semaphore_t mInflightSemaphore;
//    id <MTLCommandBuffer> mCurrentCommandBuffer;
//    id <CAMetalDrawable> mCurrentDrawable;
    MetalRenderPassImpl *mRenderPass;
}

@end

@implementation MetalContext

static MetalContext * SharedContext = nil;

- (instancetype)init
{
    self = [super init];
    if ( self )
    {
        self.device = MTLCreateSystemDefaultDevice();

        // Create a new command queue
        self.commandQueue = [self.device newCommandQueue];

        // Load all the shader files with a metal file extension in the project.
        // NOTE: If there are no .metal shaders found in the project, this will fail:
        // "failed assertion `Metal default library not found'"
        self.library = [self.device newDefaultLibrary];
        
        self.metalLayer = [CAMetalLayer layer];
        self.metalLayer.device = self.device;
        
        mInflightSemaphore = dispatch_semaphore_create(MAX_INFLIGHT_BUFFERS);

//        mRenderPass = MetalRenderPass::create( MetalRenderPass::Format() );
        mRenderPass = [MetalRenderPassImpl new];
        
    }
    return self;
}

- (void)startDraw
{
    dispatch_semaphore_wait(mInflightSemaphore, DISPATCH_TIME_FOREVER);
}

//- (void)commandBufferDraw:(void (^)(id <CAMetalDrawable>, id <MTLCommandBuffer> ))drawingBlock
//- (void)commandBufferDraw:(void (^)(id <MTLCommandBuffer> ))drawingBlock
//- (void)commandBufferDraw:(void (^)( id <MTLCommandBuffer> commandBuffer,
//                                     MTLRenderPassDescriptor * renderPassDescriptor ))drawingBlock
- (void)commandBufferDraw:(void (^)( id <MTLRenderCommandEncoder> renderEncoder ))drawingBlock
{
    id <MTLCommandBuffer> commandBuffer = [self.commandQueue commandBuffer];
    commandBuffer.label = @"MyCommands";

    id <CAMetalDrawable> drawable = [self.metalLayer nextDrawable];
    
    // NOTE: The render pass has the clear color.
    // How can we pass this in?
    // Maybe in commandBufferDraw?
    [mRenderPass prepareForRenderToTexture:drawable.texture];

    //drawingBlock(commandBuffer);
    id <MTLRenderCommandEncoder> renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:mRenderPass.renderPassDescriptor];
    renderEncoder.label = @"MyRenderEncoder";

    drawingBlock(renderEncoder);

    // We're done encoding commands
    [renderEncoder endEncoding];

    __block dispatch_semaphore_t block_sema = mInflightSemaphore;
    [commandBuffer addCompletedHandler:^(id<MTLCommandBuffer> buffer) {
        NSLog(@"Draw complete. Signaling semaphore.");
        dispatch_semaphore_signal(block_sema);
    }];

    [commandBuffer presentDrawable:drawable];

    // Finalize rendering here & push the command buffer to the GPU
    [commandBuffer commit];
}

- (void)finishDraw
{
    // Nothing to see here
}

+ (instancetype) sharedContext
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        SharedContext = [MetalContext new];
    });
    return SharedContext;
}

@end