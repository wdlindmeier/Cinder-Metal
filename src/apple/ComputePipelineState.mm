//
//  ComputePipelineState.cpp
//
//  Created by William Lindmeier on 11/13/15.
//
//

#include "ComputePipelineState.h"
#include "RendererMetalImpl.h"
#import "cinder/cocoa/CinderCocoa.h"

using namespace ci;
using namespace ci::mtl;
using namespace ci::cocoa;

ComputePipelineState::ComputePipelineState( void * mtlComputePipelineState ) :
mImpl(mtlComputePipelineState)
{
    assert( mtlComputePipelineState != NULL );
    assert( [(__bridge id)mtlComputePipelineState conformsToProtocol:@protocol(MTLComputePipelineState)] );
    CFRetain(mImpl);
}

ComputePipelineState::ComputePipelineState( const std::string & computeShaderName, void * mtlLibrary ) :
mImpl(nullptr)
{
    id <MTLDevice> device = [RendererMetalImpl sharedRenderer].device;
    id <MTLLibrary> library = (__bridge id<MTLLibrary>)mtlLibrary;
    if ( library == nullptr )
    {
        library = [RendererMetalImpl sharedRenderer].library;
    }
    else
    {
        // Make sure the user passed in a valid library
        assert( [library conformsToProtocol:@protocol(MTLLibrary)] );
    }
    id <MTLFunction> kernelFunction = [library newFunctionWithName:[NSString stringWithUTF8String:computeShaderName.c_str()]];
    NSError* error = NULL;
    mImpl = (__bridge_retained void *)[device newComputePipelineStateWithFunction:kernelFunction
                                                                            error:&error];
    if ( error )
    {
        NSLog(@"Failed to created pipeline state, error %@", error);
    }
}

ComputePipelineState::~ComputePipelineState()
{
    if ( mImpl )
    {
        CFRelease(mImpl);
    }
}