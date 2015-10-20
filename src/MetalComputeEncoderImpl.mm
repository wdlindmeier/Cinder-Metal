//
//  MetalComputeEncoderImpl.cpp
//  MetalCube
//
//  Created by William Lindmeier on 10/17/15.
//
//

#include "MetalComputeEncoderImpl.h"

@implementation MetalComputeEncoderImpl

- (instancetype)initWithComputeCommandEncoder:(id<MTLComputeCommandEncoder>)computeEncoder
{
    self = [super init];
    if ( self )
    {
        _computeEncoder = computeEncoder;
    }
    return self;
}

@end
