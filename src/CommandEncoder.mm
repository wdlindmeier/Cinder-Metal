//
//  CommandEncoder.cpp
//  ParticleSorting
//
//  Created by William Lindmeier on 11/12/15.
//
//

#include "CommandEncoder.h"

#include "cinder/cocoa/CinderCocoa.h"
#import <QuartzCore/CAMetalLayer.h>
#import <Metal/Metal.h>
#import <simd/simd.h>
#import "RendererMetalImpl.h"
#import "VertexBuffer.h"

using namespace ci;
using namespace ci::mtl;
using namespace ci::cocoa;

#define IMPL ((__bridge id <MTLCommandEncoder>)mImpl)

CommandEncoder::CommandEncoder( void * mtlCommandEncoder ) :
mImpl(mtlCommandEncoder)
{
    CFRetain(mImpl);
}

CommandEncoder::~CommandEncoder()
{
    if ( mImpl )
    {
        CFRelease(mImpl);
    }
}

void CommandEncoder::pushDebugGroup( const std::string & groupName )
{
    //[IMPL pushDebugGroup:(__bridge NSString *)createCfString(groupName)];
    [IMPL pushDebugGroup:[NSString stringWithUTF8String:groupName.c_str()]];
}

void CommandEncoder::endEncoding()
{
    [(__bridge id<MTLRenderCommandEncoder>)mImpl endEncoding];
}

void CommandEncoder::popDebugGroup()
{
    [IMPL popDebugGroup];
}
