//
//  MetalRenderEncoderImpl.h
//  MetalCube
//
//  Created by William Lindmeier on 10/16/15.
//
//

#pragma once

#import <Foundation/Foundation.h>
#import <QuartzCore/CAMetalLayer.h>
#import <Metal/Metal.h>
#import <simd/simd.h>

@interface MetalRenderEncoderImpl : NSObject
{
}

- (instancetype)initWithRenderCommandEncoder:(id <MTLRenderCommandEncoder>)renderEncoder;

@property (nonatomic, readonly) id <MTLRenderCommandEncoder> renderEncoder;

@end