//
//  MetalRenderPass.hpp
//  MetalCube
//
//  Created by William Lindmeier on 10/13/15.
//
//

#pragma once

#include "cinder/Cinder.h"
#import <Metal/Metal.h>
#import <simd/simd.h>

#if defined( __OBJC__ )
@class MetalRenderPassImpl;
#else
class MetalRenderPassImpl;
#endif

namespace cinder { namespace mtl {
    
//    typedef std::shared_ptr<class MetalRenderPass> MetalRenderPassRef;
    
    class MetalRenderPass
    {
        
    public:
        
        // TODO: Add state accessors
        class Format
        {
            
        public:
            
            Format() :
            shouldClear(true),
            clearColor(0.f,0.f,0.f,1.f),
            hasDepth(true),
            clearDepth(1.f)
            {}
            
            bool shouldClear;
            bool hasDepth;
            ColorAf clearColor;
            float clearDepth;
        };
        
//        static MetalRenderPassRef create( Format format = Format() );
//
//    protected:
//        
//        MetalRenderPassImpl *mImpl;
//        Format mFormat;
//
//        MetalRenderPass( Format & format );
//        ~MetalRenderPass(){}

    };
} }

@interface MetalRenderPassImpl : NSObject
{
}

//- (instancetype)initWithFormat:( ci::mtl::MetalRenderPass::Format & )format;
- (void)prepareForRenderToTexture:(id <MTLTexture>)texture;

@property (nonatomic, strong) MTLRenderPassDescriptor *renderPassDescriptor;
@property (nonatomic, strong) id <MTLTexture> depthTex;
@property (nonatomic, strong) id <MTLTexture> msaaTex;

@end


