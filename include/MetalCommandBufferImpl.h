//
//  MetalCommandBufferImpl.hpp
//  MetalCube
//
//  Created by William Lindmeier on 10/17/15.
//
//

#pragma once

#import <Foundation/Foundation.h>
#import <QuartzCore/CAMetalLayer.h>
#import <Metal/Metal.h>
#import <simd/simd.h>

@interface MetalCommandBufferImpl : NSObject

- (instancetype)initWithCommandBuffer:(id <MTLCommandBuffer>)buffer;

@property (nonatomic, strong) id <MTLCommandBuffer> commandBuffer;
@property (nonatomic, strong) id <CAMetalDrawable> drawable;

@end
