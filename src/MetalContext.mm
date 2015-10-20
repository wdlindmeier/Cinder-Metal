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
#import "MetalCommandBufferImpl.h"
#import "MetalRenderEncoder.h"
#import "MetalRenderEncoderImpl.h"

using namespace cinder;
using namespace ci::app;
using namespace cinder::mtl;

@interface MetalContext()
{
    dispatch_semaphore_t mInflightSemaphore;
//    MetalRenderPassImpl *mRenderPass;
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
//        mRenderPass = [MetalRenderPassImpl new];
        
    }
    return self;
}

- (void)startDraw
{
    dispatch_semaphore_wait(mInflightSemaphore, DISPATCH_TIME_FOREVER);
}

//- (void)commandBufferDraw:(void (^)( MetalRenderEncoderRef renderEncoder ))drawingBlock
//{
//    id <MTLCommandBuffer> commandBuffer = [self.commandQueue commandBuffer];
//    commandBuffer.label = @"MyCommands";
//
//    id <CAMetalDrawable> drawable = [self.metalLayer nextDrawable];
//    
//    // NOTE: The render pass has the clear color.
//    // How can we pass this in?
//    // Maybe in commandBufferDraw?
//    [mRenderPass prepareForRenderToTexture:drawable.texture];
//
//    // TODO: There should be an option to create multiple encoders PER frame.
//    
//    
//    // This seems like a lot of hoops to jump through to pass the encoder into a
//    // c++ app. Is there a cleaner way to do this?
//    id <MTLRenderCommandEncoder> renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:mRenderPass.renderPassDescriptor];
//    renderEncoder.label = @"MyRenderEncoder";
//    MetalRenderEncoderImpl *encoderImpl = [[MetalRenderEncoderImpl alloc] initWithRenderCommandEncoder:renderEncoder];
//    MetalRenderEncoderRef encoder = MetalRenderEncoder::create(encoderImpl);
//
//    drawingBlock(encoder);
//
//    // We're done encoding commands
//    [renderEncoder endEncoding];
//
//    __block dispatch_semaphore_t block_sema = mInflightSemaphore;
//    [commandBuffer addCompletedHandler:^(id<MTLCommandBuffer> buffer) {
//        dispatch_semaphore_signal(block_sema);
//    }];
//
//    [commandBuffer presentDrawable:drawable];
//
//    // Finalize rendering here & push the command buffer to the GPU
//    [commandBuffer commit];
//}

- (void)commandBufferBlock:(void (^)( ci::mtl::MetalCommandBufferRef commandBuffer ))commandBlock
{
    id <MTLCommandBuffer> commandBuffer = [self.commandQueue commandBuffer];
    // TODO: Pass in an optional name
    commandBuffer.label = @"FrameCommands";
    
//
//    // NOTE: The render pass has the clear color.
//    // How can we pass this in?
//    // Maybe in commandBufferDraw?
//    [mRenderPass prepareForRenderToTexture:drawable.texture];
//    
//    // TODO: There should be an option to create multiple encoders PER frame.
//    
//    
//    // This seems like a lot of hoops to jump through to pass the encoder into a
//    // c++ app. Is there a cleaner way to do this?
//    id <MTLRenderCommandEncoder> renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:mRenderPass.renderPassDescriptor];
//    renderEncoder.label = @"MyRenderEncoder";
//    MetalRenderEncoderImpl *encoderImpl = [[MetalRenderEncoderImpl alloc] initWithRenderCommandEncoder:renderEncoder];
//    MetalRenderEncoderRef encoder = MetalRenderEncoder::create(encoderImpl);
    
//    drawingBlock(encoder);
    
    id <CAMetalDrawable> drawable = [self.metalLayer nextDrawable];

    MetalCommandBufferImpl *commandBufferImpl = [[MetalCommandBufferImpl alloc] initWithCommandBuffer:commandBuffer];
    commandBufferImpl.drawable = drawable;
    MetalCommandBufferRef ciCommandBuffer = MetalCommandBuffer::create(commandBufferImpl);
    commandBlock( ciCommandBuffer );
    
//    // We're done encoding commands
//    [renderEncoder endEncoding];
    
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