//
//  Pipeline.cpp
//  MetalCube
//
//  Created by William Lindmeier on 10/13/15.
//
//

#include "Pipeline.h"
//#include "PipelineImpl.h"
#include "RendererMetalImpl.h"
#import "cinder/cocoa/CinderCocoa.h"

using namespace ci;
using namespace ci::mtl;
using namespace ci::cocoa;

PipelineRef Pipeline::create(const std::string & vertShaderName,
                                       const std::string & fragShaderName,
                                       Format format )
{
    return PipelineRef( new Pipeline(vertShaderName, fragShaderName, format) );
}

Pipeline::Pipeline(const std::string & vertShaderName,
                   const std::string & fragShaderName,
                   Format format ) :
mFormat(format)
,mImpl(nullptr)
{
    id <MTLDevice> device = [RendererMetalImpl sharedRenderer].device;
    id <MTLLibrary> library = [RendererMetalImpl sharedRenderer].library;
    
    // Load the fragment program into the library
    id <MTLFunction> fragmentProgram = [library newFunctionWithName:
                                        (__bridge NSString *)createCfString(fragShaderName)];
    
    // Load the vertex program into the library
    id <MTLFunction> vertexProgram = [library newFunctionWithName:
                                      (__bridge NSString *)createCfString(vertShaderName)];
    
    // Create a reusable pipeline state
    MTLRenderPipelineDescriptor *pipelineStateDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
    pipelineStateDescriptor.label = (__bridge NSString *)createCfString(format.getLabel());
    [pipelineStateDescriptor setSampleCount: format.getSampleCount()];
    [pipelineStateDescriptor setVertexFunction:vertexProgram];
    [pipelineStateDescriptor setFragmentFunction:fragmentProgram];
    
    pipelineStateDescriptor.colorAttachments[0].pixelFormat = (MTLPixelFormat)format.getPixelFormat();
    pipelineStateDescriptor.depthAttachmentPixelFormat = MTLPixelFormatDepth32Float; // this is the only depth format

    MTLRenderPipelineColorAttachmentDescriptor *renderbufferAttachment = pipelineStateDescriptor.colorAttachments[0];
    renderbufferAttachment.blendingEnabled = format.getBlendingEnabled();
    renderbufferAttachment.rgbBlendOperation = (MTLBlendOperation)format.getColorBlendOperation();
    renderbufferAttachment.alphaBlendOperation = (MTLBlendOperation)format.getAlphaBlendOperation();
    renderbufferAttachment.sourceRGBBlendFactor = (MTLBlendFactor)format.getSrcColorBlendFactor();
    renderbufferAttachment.sourceAlphaBlendFactor = (MTLBlendFactor)format.getSrcAlphaBlendFactor();
    renderbufferAttachment.destinationRGBBlendFactor = (MTLBlendFactor)format.getDstColorBlendFactor();
    renderbufferAttachment.destinationAlphaBlendFactor = (MTLBlendFactor)format.getDstAlphaBlendFactor();
    
    NSError* error = NULL;
    mImpl = (__bridge_retained void *)[device newRenderPipelineStateWithDescriptor:pipelineStateDescriptor error:&error];
    if ( error )
    {
        NSLog(@"Failed to created pipeline state, error %@", error);
    }
}

Pipeline::~Pipeline()
{
    CFRelease(mImpl);
}
//
//void * Pipeline::getDepthState()
//{
//    printf("TOOD: Remove getDepthState()\n");
//    return (__bridge void *)mImpl.depthState;
//}
