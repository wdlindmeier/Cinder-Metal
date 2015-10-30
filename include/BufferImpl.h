//
//  BufferImpl.h
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

@interface BufferImpl : NSObject

- (instancetype)initWithBytes:(const void *)pointer length:(unsigned long)length label:(NSString *)label;

@property (nonatomic, strong) id <MTLBuffer> buffer;

@end
