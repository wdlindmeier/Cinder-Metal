//
//  MetalPipelineImpl.h
//  MetalCube
//
//  Created by William Lindmeier on 10/17/15.
//
//

#import <Foundation/Foundation.h>
#import <Metal/Metal.h>
#import "MetalPipeline.h"

@interface MetalPipelineImpl : NSObject
{
}

- (instancetype)initWithVert:(NSString *)vertShaderName
                        frag:(NSString *)fragShaderName
                      format:(ci::mtl::MetalPipeline::Format &)format;

@property (nonatomic, strong) id <MTLRenderPipelineState> pipelineState;
@property (nonatomic, strong) id <MTLDepthStencilState> depthState;

@end