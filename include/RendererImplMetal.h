//
//  RendererMetalImpl.h
//  MetalCube
//
//  Created by William Lindmeier on 10/11/15.
//
//

#pragma once

#include "RendererMetal.h"
#import <QuartzCore/CAMetalLayer.h>
#import <Metal/Metal.h>
#import <simd/simd.h>

@interface RendererImplMetal : NSObject
{
    // TODO: Move these to RendererMetalImpl
    // layer
    BOOL _layerSizeDidUpdate;
//    MTLRenderPassDescriptor *_renderPassDescriptor;
    
    // controller
//    CADisplayLink *_timer;
//    BOOL _gameLoopPaused;
//    dispatch_semaphore_t _inflight_semaphore;
//    id <MTLBuffer> _dynamicConstantBuffer;
//    uint8_t _constantDataBufferIndex;
    
    // renderer
//    id <MTLLibrary> _defaultLibrary;
//    id <MTLRenderPipelineState> _pipelineState;
//    id <MTLBuffer> _vertexBuffer;
//    id <MTLDepthStencilState> _depthState;
//    id <MTLTexture> _depthTex;
//    id <MTLTexture> _msaaTex;
    
    cinder::app::RendererMetal			*mRenderer; // equivalent of a weak_ptr; 'renderer' owns this // TODO: remove, this is unused
    UIView							*mCinderView;
//    EAGLContext						*mContext;
//    cinder::gl::ContextRef			mCinderContext;
    
    // The pixel dimensions of the CAEAGLLayer
//    int 			mBackingWidth, mBackingHeight;
        
    // The OpenGL names for the framebuffer and renderbuffer used to render to this view
//    GLuint 			mViewFramebuffer, mViewRenderbuffer, mDepthRenderbuffer;
//    GLuint			mMsaaFramebuffer, mMsaaRenderbuffer;
//    GLint			mColorInternalFormat, mDepthInternalFormat;
//    BOOL			mUsingMsaa;
//    BOOL            mUsingStencil;
//    BOOL			mObjectTracking;
//    int				mMsaaSamples;
    
    // uniforms
//    matrix_float4x4 _projectionMatrix;
//    matrix_float4x4 _viewMatrix;
//    uniforms_t _uniform_buffer;
//    float _rotation;
}

- (id)initWithFrame:(CGRect)frame cinderView:(UIView *)cinderView renderer:(cinder::app::RendererMetal *)renderer;
- (void)setFrameSize:(CGSize)newSize;
- (void)startDraw;
- (void)finishDraw;

@property (nonatomic, strong) id <MTLDevice> device;
@property (nonatomic, strong) CAMetalLayer * metalLayer;
@property (nonatomic, strong) id <MTLCommandQueue> commandQueue;

@end
