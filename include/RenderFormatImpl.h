//
//  MetalRenderPassImpl.h
//  MetalCube
//
//  Created by William Lindmeier on 10/17/15.
//
//

#pragma once

#import <Foundation/Foundation.h>
#import <Metal/Metal.h>
#import <simd/simd.h>

@interface RenderFormatImpl : NSObject
{
}

- (void)prepareForRenderToTexture:(id <MTLTexture>)texture;

@property (nonatomic, strong) MTLRenderPassDescriptor *renderPassDescriptor;
@property (nonatomic, strong) id <MTLTexture> depthTex;
@property (nonatomic, strong) id <MTLTexture> msaaTex;

@end


