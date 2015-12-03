//
//  MetalRenderPass.cpp
//  MetalCube
//
//  Created by William Lindmeier on 10/13/15.
//
//

#include "RenderPassDescriptor.h"
#include "RendererMetalImpl.h"
#import <Metal/Metal.h>
#import <simd/simd.h>

using namespace ci;
using namespace ci::mtl;

RenderPassDescriptorRef RenderPassDescriptor::create( Format format )
{
    return RenderPassDescriptorRef( new RenderPassDescriptor( format ) );
}

#define IMPL ((__bridge MTLRenderPassDescriptor *)mImpl)
#define DEPTH_TEX ((__bridge id <MTLTexture>)mDepthTexture)

RenderPassDescriptor::RenderPassDescriptor( Format format ) :
mDepthTexture(nullptr)
{
    mImpl = (__bridge void *)[MTLRenderPassDescriptor renderPassDescriptor];
    CFRetain(mImpl);
    
    SET_FORMAT_DEFAULT(format, ColorStoreAction, MTLStoreActionStore);
    SET_FORMAT_DEFAULT(format, DepthStoreAction, MTLStoreActionDontCare);

    setShouldClearColor(format.getShouldClearColor());
    setClearColor(format.getClearColor());
    setColorStoreAction(format.getColorStoreAction());
    setShouldClearDepth(format.getShouldClearDepth());
    setClearDepth(format.getClearDepth());
    setDepthStoreAction(format.getDepthStoreAction());
}

RenderPassDescriptor::~RenderPassDescriptor()
{
    if ( mImpl )
    {
        CFRelease(mImpl);
    }
    if ( mDepthTexture )
    {
        CFRelease(mDepthTexture);
    }
}


void RenderPassDescriptor::setShouldClearColor( bool shouldClear, int colorAttachementIndex )
{
    IMPL.colorAttachments[colorAttachementIndex].loadAction = shouldClear ? MTLLoadActionClear : MTLLoadActionDontCare;
};

void RenderPassDescriptor::setClearColor( const ColorAf clearColor, int colorAttachementIndex )
{
    IMPL.colorAttachments[colorAttachementIndex].clearColor = MTLClearColorMake(clearColor.r,
                                                                                 clearColor.g,
                                                                                 clearColor.b,
                                                                                 clearColor.a);
};

void RenderPassDescriptor::setColorStoreAction( int storeAction, int colorAttachementIndex ) // MTLStoreAction
{
    IMPL.colorAttachments[colorAttachementIndex].storeAction = (MTLStoreAction)storeAction;
}

void RenderPassDescriptor::setShouldClearDepth( bool shouldClear )
{
    IMPL.depthAttachment.loadAction = shouldClear ? MTLLoadActionClear : MTLLoadActionDontCare;
}

void RenderPassDescriptor::setClearDepth( float clearDepth )
{
    IMPL.depthAttachment.clearDepth = clearDepth;
};

void RenderPassDescriptor::setDepthStoreAction( int storeAction ) // MTLStoreAction
{
    IMPL.depthAttachment.storeAction = (MTLStoreAction)storeAction;
}

void RenderPassDescriptor::applyToDrawableTexture( void * texture, int colorAttachmentIndex )
{
    id <MTLTexture> colorTexture = (__bridge id<MTLTexture>)texture;
    IMPL.colorAttachments[colorAttachmentIndex].texture = colorTexture;
    
    //  If we need a depth texture and don't have one, or if the depth texture we have is the wrong size
    //  Then allocate one of the proper size
    
    if ( DEPTH_TEX == nullptr || // no depth
         ( DEPTH_TEX.width != colorTexture.width || DEPTH_TEX.height != colorTexture.height ) ) // different size
    {
        auto device = [RendererMetalImpl sharedRenderer].device;
        
        MTLTextureDescriptor* desc = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat: MTLPixelFormatDepth32Float // this is the only format
                                                                                        width: colorTexture.width
                                                                                       height: colorTexture.height
                                                                                    mipmapped: NO];
#if defined( CINDER_MAC )
        desc.resourceOptions = MTLResourceStorageModePrivate;
        desc.usage = MTLTextureUsageRenderTarget;
#endif
        mDepthTexture = (__bridge_retained void *)[device newTextureWithDescriptor: desc];
        DEPTH_TEX.label = @"Default Depth Texture";
        
        IMPL.depthAttachment.texture = DEPTH_TEX; // NOTE: we dont have to retain
    }
}
