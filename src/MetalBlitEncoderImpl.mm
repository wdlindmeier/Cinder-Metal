//
//  MetalBlitEncoderImpl.cpp
//  MetalCube
//
//  Created by William Lindmeier on 10/17/15.
//
//

#include "MetalBlitEncoderImpl.h"

@implementation MetalBlitEncoderImpl

- (instancetype)initWithBlitCommandEncoder:(id <MTLBlitCommandEncoder>)blitEncoder
{
    self = [super init];
    if ( self )
    {
        _blitEncoder = blitEncoder;
    }
    return self;
}

@end
