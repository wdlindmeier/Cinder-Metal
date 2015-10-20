//
//  MetalRenderPassImpl.m
//  MetalCube
//
//  Created by William Lindmeier on 10/17/15.
//
//

#import "MetalRenderFormatImpl.h"
#import <QuartzCore/CAMetalLayer.h>
#import <Metal/Metal.h>
#import <simd/simd.h>
#import "MetalContext.h"

using namespace ci;
using namespace ci::mtl;

@implementation MetalRenderFormatImpl

- (instancetype)init
{
    self = [super init];
    if ( self )
    {
        MTLRenderPassDescriptor *renderPassDesc = [MTLRenderPassDescriptor renderPassDescriptor];
        
        renderPassDesc.colorAttachments[0].loadAction = MTLLoadActionClear;

        renderPassDesc.colorAttachments[0].clearColor = MTLClearColorMake(0.5,0.5,0.5,1);
        
        renderPassDesc.colorAttachments[0].storeAction = MTLStoreActionStore;
        
        renderPassDesc.depthAttachment.loadAction = MTLLoadActionClear;
        renderPassDesc.depthAttachment.clearDepth = 1.f;//format.clearDepth;
        renderPassDesc.depthAttachment.storeAction = MTLStoreActionDontCare;
        
        self.renderPassDescriptor = renderPassDesc;
    }
    return self;
}

- (void)prepareForRenderToTexture:(id<MTLTexture>)texture
{
    _renderPassDescriptor.colorAttachments[0].texture = texture;
    
    //  If we need a depth texture and don't have one, or if the depth texture we have is the wrong size
    //  Then allocate one of the proper size
    
    if (!_depthTex || (_depthTex && (_depthTex.width != texture.width || _depthTex.height != texture.height)))
    {
        auto device = [MetalContext sharedContext].device;
        
        MTLTextureDescriptor* desc = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat: MTLPixelFormatDepth32Float
                                                                                        width: texture.width
                                                                                       height: texture.height
                                                                                    mipmapped: NO];
        _depthTex = [device newTextureWithDescriptor: desc];
        _depthTex.label = @"Depth";
        
        _renderPassDescriptor.depthAttachment.texture = _depthTex;
    }
}

@end