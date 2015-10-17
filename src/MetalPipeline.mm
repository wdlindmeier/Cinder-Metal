//
//  MetalPipeline.cpp
//  MetalCube
//
//  Created by William Lindmeier on 10/13/15.
//
//

#include "MetalPipeline.h"
#include "MetalPipelineImpl.h"
#import "cinder/cocoa/CinderCocoa.h"

using namespace ci;
using namespace ci::mtl;
using namespace ci::cocoa;

MetalPipelineRef MetalPipeline::create(const std::string & vertShaderName,
                                       const std::string & fragShaderName,
                                       Format format )
{
    return MetalPipelineRef( new MetalPipeline(vertShaderName, fragShaderName, format) );
}

MetalPipeline::MetalPipeline(const std::string & vertShaderName,
                             const std::string & fragShaderName,
                             Format format ) :
mFormat(format)
{
    mImpl = [[MetalPipelineImpl alloc] initWithVert:(__bridge NSString *)createCfString(vertShaderName)
                                               frag:(__bridge NSString *)createCfString(fragShaderName)
                                             format:format];
}