//
//  PipelineImpl.m
//  MetalCube
//
//  Created by William Lindmeier on 10/17/15.
//
//

#import "PipelineImpl.h"

#import <QuartzCore/CAMetalLayer.h>
#import <Metal/Metal.h>
#import <simd/simd.h>
#import "RendererMetalImpl.h"

using namespace ci;
using namespace ci::mtl;

@implementation PipelineImpl

// TODO: Add option to enable depth
- (instancetype)initWithVert:(NSString *)vertShaderName
                        frag:(NSString *)fragShaderName
                      format:(Pipeline::Format &)format
{
    self = [super init];
    if ( self )
    {
        id <MTLDevice> device = [RendererMetalImpl sharedRenderer].device;
        id <MTLLibrary> library = [RendererMetalImpl sharedRenderer].library;
        
        // Load the fragment program into the library
        id <MTLFunction> fragmentProgram = [library newFunctionWithName:fragShaderName];
        
        // Load the vertex program into the library
        id <MTLFunction> vertexProgram = [library newFunctionWithName:vertShaderName];
        
        // Create a reusable pipeline state
        MTLRenderPipelineDescriptor *pipelineStateDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
        // TODO: Add to format
        pipelineStateDescriptor.label = @"MyPipeline";
        [pipelineStateDescriptor setSampleCount: format.sampleCount()];
        [pipelineStateDescriptor setVertexFunction:vertexProgram];
        [pipelineStateDescriptor setFragmentFunction:fragmentProgram];
        // TODO: Add to format
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;
        // TODO: Add to format
        pipelineStateDescriptor.depthAttachmentPixelFormat = MTLPixelFormatDepth32Float;
        
        NSError* error = NULL;
        self.pipelineState = [device newRenderPipelineStateWithDescriptor:pipelineStateDescriptor error:&error];
        if (!_pipelineState) {
            NSLog(@"Failed to created pipeline state, error %@", error);
        }
        
        MTLDepthStencilDescriptor *depthStateDesc = [[MTLDepthStencilDescriptor alloc] init];
        depthStateDesc.depthCompareFunction = MTLCompareFunctionLess;
        depthStateDesc.depthWriteEnabled = format.depth();
        self.depthState = [device newDepthStencilStateWithDescriptor:depthStateDesc];
    }
    
    return self;
}

@end
