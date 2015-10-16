//
//  MetalContext.hpp
//  MetalCube
//
//  Created by William Lindmeier on 10/13/15.
//
//

#pragma once

#import <Foundation/Foundation.h>
#import <QuartzCore/CAMetalLayer.h>
#import <Metal/Metal.h>
#import <simd/simd.h>

#include "cinder/Cinder.h"

@interface MetalContext : NSObject
{
    
}

@property (nonatomic, strong) id <MTLDevice> device;
@property (nonatomic, strong) id <MTLCommandQueue> commandQueue;
@property (nonatomic, strong) id <MTLLibrary> library;
@property (nonatomic, strong) CAMetalLayer *metalLayer;

//- (void)commandBufferDraw:(void (^)(id <CAMetalDrawable>, id <MTLCommandBuffer> ))drawingBlock;
//- (void)commandBufferDraw:(void (^)(id <MTLCommandBuffer> ))drawingBlock;
//- (void)commandBufferDraw:(void (^)( id <MTLCommandBuffer> commandBuffer,
//                                     MTLRenderPassDescriptor * renderPassDescriptor ))drawingBlock;
- (void)commandBufferDraw:(void (^)( id <MTLRenderCommandEncoder> renderEncoder ))drawingBlock;

- (void)startDraw;
- (void)finishDraw;

+ (instancetype) sharedContext;

@end