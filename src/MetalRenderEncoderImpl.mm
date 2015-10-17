//
//  MetalRenderEncoderImpl.m
//  MetalCube
//
//  Created by William Lindmeier on 10/16/15.
//
//

#import <Foundation/Foundation.h>
#import "MetalRenderEncoderImpl.h"

@implementation MetalRenderEncoderImpl

- (instancetype)initWithRenderCommandEncoder:(id <MTLRenderCommandEncoder>)renderEncoder
{
    self = [super init];
    if ( self )
    {
        _renderEncoder = renderEncoder;
    }
    return self;
}

@end
