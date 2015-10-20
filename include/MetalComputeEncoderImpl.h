//
//  MetalComputeEncoderImpl.hpp
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

@interface MetalComputeEncoderImpl : NSObject

- (instancetype)initWithComputeCommandEncoder:(id <MTLComputeCommandEncoder>)computeEncoder;

@property (nonatomic, strong) id <MTLComputeCommandEncoder> computeEncoder;

@end
