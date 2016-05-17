//
//  MetalRenderPass.cpp
//  Cinder-Metal
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

#define IMPL ((__bridge MTLRenderPassDescriptor *)mImpl)
#define DEPTH_TEX ((__bridge id <MTLTexture>)mDepthTexture)
#define STENCIL_TEX ((__bridge id <MTLTexture>)mStencilTexture)

RenderPassDescriptor::RenderPassDescriptor( Format format ) :
mDepthTexture(nullptr)
,mFormat(format)
{
    mImpl = (__bridge void *)[MTLRenderPassDescriptor renderPassDescriptor];
    CFRetain(mImpl);
    
    // TODO: Apply to multiple color attachments
    setShouldClearColor(mFormat.getShouldClearColor());
    setClearColor(mFormat.getClearColor());
    setColorStoreAction(mFormat.getColorStoreAction());
    
    setShouldClearDepth(mFormat.getShouldClearDepth());
    setClearDepth(mFormat.getClearDepth());
    setDepthStoreAction(mFormat.getDepthStoreAction());
    
    setShouldClearStencil(mFormat.getShouldClearStencil());
    setClearStencil(mFormat.getClearStencil());
    setStencilStoreAction(mFormat.getStencilStoreAction());
    
    mHasDepth = mFormat.getHasDepth();
    mHasStencil = mFormat.getHasStencil();
}

RenderPassDescriptor::RenderPassDescriptor( void * mtlRenderPassDescriptor ) :
mImpl(mtlRenderPassDescriptor)
{
    assert(mImpl != NULL);
    assert([(__bridge id)mImpl isKindOfClass:[MTLRenderPassDescriptor class]]);
    CFRetain(mImpl);
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

void RenderPassDescriptor::setColorStoreAction( StoreAction storeAction, int colorAttachementIndex )
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

void RenderPassDescriptor::setDepthStoreAction( StoreAction storeAction )
{
    IMPL.depthAttachment.storeAction = (MTLStoreAction)storeAction;
}

void RenderPassDescriptor::setShouldClearStencil( bool shouldClear )
{
    IMPL.stencilAttachment.loadAction = shouldClear ? MTLLoadActionClear : MTLLoadActionDontCare;
}

void RenderPassDescriptor::setClearStencil( uint32_t clearStencil )
{
    IMPL.stencilAttachment.clearStencil = clearStencil;
};

void RenderPassDescriptor::setStencilStoreAction( StoreAction storeAction )
{
    IMPL.stencilAttachment.storeAction = (MTLStoreAction)storeAction;
}

void RenderPassDescriptor::applyToDrawableTexture( void * texture, int colorAttachmentIndex )
{
    id <MTLTexture> colorTexture = (__bridge id<MTLTexture>)texture;
    IMPL.colorAttachments[colorAttachmentIndex].texture = colorTexture;
    
    //  If we need a depth texture and don't have one, or if the depth texture we have is the wrong size
    //  Then allocate one of the proper size
    
    if ( mHasDepth &&
         ( DEPTH_TEX == nullptr ||
         ( DEPTH_TEX.width != colorTexture.width || DEPTH_TEX.height != colorTexture.height ) ) )
    {
        auto device = [RendererMetalImpl sharedRenderer].device;
        
        MTLTextureDescriptor* desc = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat: MTLPixelFormatDepth32Float // this is the only format
                                                                                        width: colorTexture.width
                                                                                       height: colorTexture.height
                                                                                    mipmapped: NO];
        
#if defined( CINDER_MAC )
        desc.resourceOptions = MTLResourceStorageModePrivate;
#endif
        desc.usage = (MTLTextureUsage)mFormat.getDepthUsage();

        mDepthTexture = (__bridge_retained void *)[device newTextureWithDescriptor: desc];
        DEPTH_TEX.label = @"Default Depth Texture";
        
        IMPL.depthAttachment.texture = DEPTH_TEX; // NOTE: we dont have to retain
        
        mDepthTextureBuffer = mtl::TextureBuffer::create( mDepthTexture );
    }
    
    if ( mHasStencil &&
         ( STENCIL_TEX == nullptr ||
         ( STENCIL_TEX.width != colorTexture.width || DEPTH_TEX.height != colorTexture.height ) ) )
    {
        auto device = [RendererMetalImpl sharedRenderer].device;
        
        MTLTextureDescriptor* desc = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat: MTLPixelFormatStencil8 // this is the only format
                                                                                        width: colorTexture.width
                                                                                       height: colorTexture.height
                                                                                    mipmapped: NO];
        
#if defined( CINDER_MAC )
        desc.resourceOptions = MTLResourceStorageModePrivate;
#endif
        desc.usage = (MTLTextureUsage)mFormat.getStencilUsage();
        
        mStencilTexture = (__bridge_retained void *)[device newTextureWithDescriptor: desc];
        STENCIL_TEX.label = @"Default Stencil Texture";
        
        IMPL.stencilAttachment.texture = STENCIL_TEX; // NOTE: we dont have to retain
        
        mStencilTextureBuffer = mtl::TextureBuffer::create( mStencilTexture );
    }
}

mtl::TextureBufferRef RenderPassDescriptor::getDepthTexture()
{
    return mDepthTextureBuffer;
}

mtl::TextureBufferRef RenderPassDescriptor::getStencilTexture()
{
    return mStencilTextureBuffer;
}
