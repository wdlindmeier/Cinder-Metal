//
//  MetalBlitEncoderImpl.hpp
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

@interface MetalBlitEncoderImpl : NSObject

- (instancetype)initWithBlitCommandEncoder:(id <MTLBlitCommandEncoder>)blitEncoder;

@property (nonatomic, strong) id <MTLBlitCommandEncoder> blitEncoder;

@end
