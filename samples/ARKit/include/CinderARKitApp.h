//
//  CinderARKitApp.h
//  CinderARKit
//

//  Created by William Lindmeier on 7/6/17.
//

#pragma once

#include "cinder/app/App.h"
#include "metal.h"
#import "RendererMetalImpl.h"
#import "Batch.h"
#import "Shader.h"
#import <ARKit/ARKit.h>

@class NativeBridge;

class CinderARKitApp : public cinder::app::App
{
public:
    
    CinderARKitApp() :
    mPlanePosition(-1)
    ,mHumanPosition(-1)
    ,mNumTouches(0)
    {}
    
    void setup() override;
    void resize() override;
    void restart();
    void update() override;
    void draw() override;
    void tapped(int numTaps);
    void swipe(int direction);
    void addAnchor();
    void touchesBegan( cinder::app::TouchEvent event ) override;
    void touchesEnded( cinder::app::TouchEvent event ) override;
    
    id <MTLTexture> createTextureFromPixelBuffer( CVPixelBufferRef pixelBuffer,
                                                 MTLPixelFormat pixelFormat, NSInteger planeIndex );
    void createOrUpdateTextureFromPixelBuffer( ci::mtl::TextureBufferRef & texture, CVPixelBufferRef pixelBuffer,
                                               ci::mtl::PixelFormat pxFormat, NSInteger planeIndex );
    
    // ARKit
    ARSession *mARSession;
    
    // Native Delegate
    NativeBridge *mObjcDelegate;
    
    ci::mtl::RenderPassDescriptorRef mRenderDescriptor;
    
    CVMetalTextureCacheRef mCapturedImageTextureCache;
    ci::mtl::TextureBufferRef mTextureLuma;
    ci::mtl::TextureBufferRef mTextureChroma;
    
    ci::mtl::RenderPipelineStateRef mPipelineVideo;
    ci::mtl::BatchRef mBatchCamera;
    
    std::vector<ci::mat4> mPlaneIntersections;
    ci::mat4 mLastHorizontalPlane;
    ci::vec3 mPlanePosition;
    ci::vec3 mHumanPosition;
    
    int mNumTouches;
};

