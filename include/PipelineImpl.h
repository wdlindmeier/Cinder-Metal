//
//  PipelineImpl.h
//  MetalCube
//
//  Created by William Lindmeier on 10/17/15.
//
//

#pragma once

#import <Foundation/Foundation.h>
#import <Metal/Metal.h>
#import "Pipeline.h"

@interface PipelineImpl : NSObject
{
}

- (instancetype)initWithVert:(NSString *)vertShaderName
                        frag:(NSString *)fragShaderName
                      format:(ci::mtl::Pipeline::Format &)format;

@property (nonatomic, strong) id <MTLRenderPipelineState> pipelineState;
@property (nonatomic, strong) id <MTLDepthStencilState> depthState;

@end