//
//  MetalBufferImpl.h
//  MetalCube
//
//  Created by William Lindmeier on 10/17/15.
//
//

#import <Foundation/Foundation.h>
#import <QuartzCore/CAMetalLayer.h>
#import <Metal/Metal.h>
#import <simd/simd.h>

@interface MetalBufferImpl : NSObject

- (instancetype)initWithBytes:(const void *)pointer length:(unsigned long)length label:(NSString *)label;

@property (nonatomic, strong) id <MTLBuffer> buffer;

@end
