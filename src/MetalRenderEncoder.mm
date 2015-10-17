//
//  MetalRenderEncoder.cpp
//  MetalCube
//
//  Created by William Lindmeier on 10/16/15.
//
//

#include "MetalRenderEncoder.h"
#include "cinder/cocoa/CinderCocoa.h"
#import <QuartzCore/CAMetalLayer.h>
#import <Metal/Metal.h>
#import <simd/simd.h>
#import "MetalContext.h"
#import "MetalRenderEncoderImpl.h"
#import "MetalBufferImpl.h"
#import "cinder/cocoa/CinderCocoa.h"
#import "MetalPipelineImpl.h"

// TODO: Move this
static MTLPrimitiveType getMTLPrimitiveType( ci::mtl::geom::Primitive primitive )
{
    using namespace ci::mtl::geom;
    
    switch ( primitive )
    {
        case POINT:
            return MTLPrimitiveTypePoint;
        case LINE:
            return MTLPrimitiveTypeLine;
        case LINE_STRIP:
            return MTLPrimitiveTypeLineStrip;
        case TRIANGLE:
            return MTLPrimitiveTypeTriangle;
        case TRIANGLE_STRIP:
            return MTLPrimitiveTypeTriangleStrip;
        case NUM_PRIMITIVES:
            break;
    }
    printf( "ERROR: Unknown primitive type %i", primitive );
    assert( false );
}

using namespace ci;
using namespace ci::mtl;
using namespace ci::cocoa;

MetalRenderEncoderRef MetalRenderEncoder::create( MetalRenderEncoderImpl * encoderImpl )
{
    return MetalRenderEncoderRef( new MetalRenderEncoder( encoderImpl ) );
}

MetalRenderEncoder::MetalRenderEncoder( MetalRenderEncoderImpl * encoderImpl )
:
mImpl(encoderImpl)
{
}

void MetalRenderEncoder::beginPipeline( MetalPipelineRef pipeline )
{
    [mImpl.renderEncoder setDepthStencilState:pipeline->mImpl.depthState];
    [mImpl.renderEncoder setRenderPipelineState:pipeline->mImpl.pipelineState];
}

void MetalRenderEncoder::pushDebugGroup( const std::string & groupName )
{
    [mImpl.renderEncoder pushDebugGroup:(__bridge NSString *)createCfString(groupName)];
}

void MetalRenderEncoder::setVertexBuffer( MetalBufferRef buffer, int offset, int index)
{
    [mImpl.renderEncoder setVertexBuffer:buffer->mImpl.buffer
                                  offset:offset
                                 atIndex:index];
}

void MetalRenderEncoder::draw( ci::mtl::geom::Primitive primitive, int vertexStart, int vertexCount, int instanceCount )
{
    [mImpl.renderEncoder drawPrimitives:getMTLPrimitiveType(primitive)
                            vertexStart:vertexStart
                            vertexCount:vertexCount
                          instanceCount:instanceCount];
}

void MetalRenderEncoder::popDebugGroup()
{
    [mImpl.renderEncoder popDebugGroup];
}
