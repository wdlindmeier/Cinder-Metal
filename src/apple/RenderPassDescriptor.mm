//
//  MetalRenderPass.cpp
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
    
//    int maxNumAttachments = [RendererMetalImpl sharedRenderer].maxNumColorAttachments;
//    assert( mFormat.getNumColorAttachments() <= maxNumAttachments );
//    mColorTextureBuffers.assign(mFormat.getNumColorAttachments(), mtl::TextureBufferRef());
    int maxNumAttachments = [RendererMetalImpl sharedRenderer].maxNumColorAttachments;
    mColorTextureBuffers.assign(maxNumAttachments, mtl::TextureBufferRef());
    
    // Q: Should we allow different formats for each attachment
    // or let the user do that through the native interface?
    for ( int i = 0; i < maxNumAttachments; ++i )
    {
        setShouldClearColor(mFormat.getShouldClearColor(), i);
        setClearColor(mFormat.getClearColor(), i);
        setColorStoreAction(mFormat.getColorStoreAction(), i);
    }
    
    mHasDepth = mFormat.getHasDepth();
    mHasStencil = mFormat.getHasStencil();

    if ( mHasDepth )
    {
        setShouldClearDepth(mFormat.getShouldClearDepth());
        setClearDepth(mFormat.getClearDepth());
        setDepthStoreAction(mFormat.getDepthStoreAction());
    }

    if ( mHasStencil )
    {
        setShouldClearStencil(mFormat.getShouldClearStencil());
        setClearStencil(mFormat.getClearStencil());
        setStencilStoreAction(mFormat.getStencilStoreAction());
    }
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

void RenderPassDescriptor::setColorAttachment( TextureBufferRef & texture, int colorAttachmentIndex )
{
    mColorTextureBuffers[colorAttachmentIndex] = texture;
    applyToDrawableTexture( texture->getNative(), colorAttachmentIndex );
}

void RenderPassDescriptor::applyToDrawableTexture( void * texture, int colorAttachmentIndex )
{
    if ( mColorTextureBuffers[colorAttachmentIndex] == mtl::TextureBufferRef()  // doesnt exist
         || mColorTextureBuffers[colorAttachmentIndex]->getNative() != texture ) // isn't the same
    {
        // Store this MTLTexture as a TextureBufferRef if we haven't already so it can be accessed through getColorAttachment()
        mColorTextureBuffers[colorAttachmentIndex] =  mtl::TextureBuffer::create( texture );
    }
    
    id <MTLTexture> colorTexture = (__bridge id<MTLTexture>)texture;
    IMPL.colorAttachments[colorAttachmentIndex].texture = colorTexture;
    
    //  If we need a depth texture and don't have one, or if the depth texture we have is the wrong size
    //  Then allocate one of the proper size
    
    if ( mHasDepth &&
         ( DEPTH_TEX == nullptr ||
         ( DEPTH_TEX.width != colorTexture.width || DEPTH_TEX.height != colorTexture.height ) ) )
    {
        auto device = [RendererMetalImpl sharedRenderer].device;
        
        MTLTextureDescriptor* desc = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat: (MTLPixelFormat)mFormat.getDepthPixelFormat()
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
        
        MTLTextureDescriptor* desc = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat: (MTLPixelFormat)mFormat.getStencilPixelFormat()
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

mtl::TextureBufferRef & RenderPassDescriptor::getDepthTexture()
{
    return mDepthTextureBuffer;
}

mtl::TextureBufferRef & RenderPassDescriptor::getStencilTexture()
{
    return mStencilTextureBuffer;
}

mtl::TextureBufferRef & RenderPassDescriptor::getColorAttachment( int colorAttachmentIndex )
{    
    return mColorTextureBuffers[colorAttachmentIndex];
}
