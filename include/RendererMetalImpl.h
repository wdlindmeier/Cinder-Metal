//
//  RendererMetalImpl.h
//  MetalCube
//
//  Created by William Lindmeier on 10/11/15.
//
//

#pragma once

#include <Metal/Metal.h>
#include "RendererMetal.h"
#include "CommandBuffer.h"
#import <QuartzCore/CAMetalLayer.h>

@interface RendererMetalImpl : NSObject
{
    BOOL mLayerSizeDidUpdate;
    cinder::app::RendererMetal  *mRenderer;
    UIView  *mCinderView;
}

@property (nonatomic, strong) id <MTLDevice> device;
@property (nonatomic, strong) id <MTLCommandQueue> commandQueue;
@property (nonatomic, strong) id <MTLLibrary> library;
@property (nonatomic, strong) CAMetalLayer *metalLayer;

+ (instancetype)sharedRenderer;
- (instancetype)initWithFrame:(CGRect)frame
                   cinderView:(UIView *)cinderView
                     renderer:(cinder::app::RendererMetal *)renderer
                      options:(cinder::app::RendererMetal::Options &)options;

- (void)setFrameSize:(CGSize)newSize;

- (void)startDraw;
- (void)finishDraw;
- (dispatch_semaphore_t)inflightSemaphore;

@end
