//
//  MetalCommandBufferImpl.cpp
//  MetalCube
//
//  Created by William Lindmeier on 10/17/15.
//
//

#include "MetalCommandBufferImpl.h"

@implementation MetalCommandBufferImpl

- (instancetype)initWithCommandBuffer:(id<MTLCommandBuffer>)buffer
{
    self = [super init];
    if ( self )
    {
        _commandBuffer = buffer;
    }
    return self;
}

@end
