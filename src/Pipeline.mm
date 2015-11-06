//
//  Pipeline.cpp
//  MetalCube
//
//  Created by William Lindmeier on 10/13/15.
//
//

#include "Pipeline.h"
#include "PipelineImpl.h"
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
{
    mImpl = [[PipelineImpl alloc] initWithVert:(__bridge NSString *)createCfString(vertShaderName)
                                          frag:(__bridge NSString *)createCfString(fragShaderName)
                                        format:format];
}

void * Pipeline::getNative()
{
    return (__bridge void *)mImpl.pipelineState;
}

void * Pipeline::getPipelineState()
{
    printf("TOOD: Remove getPipelineState()\n");
    return (__bridge void *)mImpl.pipelineState;
}

void * Pipeline::getDepthState()
{
    printf("TOOD: Remove getDepthState()\n");
    return (__bridge void *)mImpl.depthState;
}
