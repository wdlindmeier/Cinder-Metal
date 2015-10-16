//
//  MetalRenderPass.cpp
//  MetalCube
//
//  Created by William Lindmeier on 10/13/15.
//
//

#include "MetalRenderPass.h"

#import <QuartzCore/CAMetalLayer.h>
#import <Metal/Metal.h>
#import <simd/simd.h>
#import "MetalContext.h"

using namespace ci;
using namespace ci::mtl;

//@interface MetalRenderPassImpl : NSObject
//{
//}
//
//- (instancetype)initWithFormat:( MetalRenderPass::Format & )format;
//
//@property (nonatomic, strong) MTLRenderPassDescriptor *renderPassDescriptor;
//@property (nonatomic, strong) id <MTLTexture> depthTex;
//@property (nonatomic, strong) id <MTLTexture> msaaTex;
//
//@end

@implementation MetalRenderPassImpl

- (instancetype)init//WithFormat:( MetalRenderPass::Format & )format
{
    self = [super init];
    if ( self )
    {
        MTLRenderPassDescriptor *renderPassDesc = [MTLRenderPassDescriptor renderPassDescriptor];
        
        renderPassDesc.colorAttachments[0].loadAction = MTLLoadActionClear;
        
        // TODO: How / where do we set the clear color?
        
//        renderPassDesc.colorAttachments[0].clearColor = MTLClearColorMake(format.clearColor.r,
//                                                                          format.clearColor.g,
//                                                                          format.clearColor.b,
//                                                                          format.clearColor.a);
        
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
    // AT DRAW
    _renderPassDescriptor.colorAttachments[0].texture = texture;
    
    if (!_depthTex || (_depthTex && (_depthTex.width != texture.width || _depthTex.height != texture.height)))
    {
        auto device = [MetalContext sharedContext].device;
        
        //  If we need a depth texture and don't have one, or if the depth texture we have is the wrong size
        //  Then allocate one of the proper size
        NSLog(@"Updating depth texture");
        
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

//
//MetalRenderPass::MetalRenderPass( Format & format )
//:
//mFormat(format)
//{
//    mImpl = [[MetalRenderPassImpl alloc] initWithFormat:format];
//};
//
//MetalRenderPassRef MetalRenderPass::create( Format format )
//{
//    return MetalRenderPassRef( new MetalRenderPass(format) );
//}
//
//void MetalRenderPass::prepareRenderToTexture(id <MTLTexture> texture )
//{    
//    // AT DRAW
//    mImpl.renderPassDescriptor.colorAttachments[0].texture = texture;
//    
//    if (!mImpl.depthTex || (mImpl.depthTex && (mImpl.depthTex.width != texture.width || mImpl.depthTex.height != texture.height)))
//    {
//        auto device = [MetalContext sharedContext].device;
//        
//        //  If we need a depth texture and don't have one, or if the depth texture we have is the wrong size
//        //  Then allocate one of the proper size
//        NSLog(@"Updating depth texture");
//        
//        MTLTextureDescriptor* desc = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat: MTLPixelFormatDepth32Float
//                                                                                        width: texture.width
//                                                                                       height: texture.height
//                                                                                    mipmapped: NO];
//        mImpl.depthTex = [device newTextureWithDescriptor: desc];
//        mImpl.depthTex.label = @"Depth";
//        
//        mImpl.renderPassDescriptor.depthAttachment.texture = mImpl.depthTex.depthTex;
//    }
//}