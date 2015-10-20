//
//  MetalBlitFormatImpl.h
//  MetalCube
//
//  Created by William Lindmeier on 10/19/15.
//
//

#import <Foundation/Foundation.h>
#import <Metal/Metal.h>
#import <simd/simd.h>

@interface MetalBlitFormatImpl : NSObject

@property (nonatomic, assign) MTLBlitOption blitOption;

@end
