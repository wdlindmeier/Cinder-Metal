//
//  RendererMetalImpl.h
//  MetalCube
//
//  Created by William Lindmeier on 10/11/15.
//
//

#pragma once

#include "RendererMetal.h"

@interface RendererImplMetal : NSObject
{
    BOOL _layerSizeDidUpdate;
    cinder::app::RendererMetal  *mRenderer; // equivalent of a weak_ptr; 'renderer' owns this
    UIView  *mCinderView;
}

- (id)initWithFrame:(CGRect)frame cinderView:(UIView *)cinderView renderer:(cinder::app::RendererMetal *)renderer;
- (void)setFrameSize:(CGSize)newSize;
- (void)startDraw;
- (void)finishDraw;

//@property (nonatomic, strong) CAMetalLayer * metalLayer;

@end
