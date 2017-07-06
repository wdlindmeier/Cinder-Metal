//
//  NativeBridge.h
//  CinderARKit
//
//  Created by William Lindmeier on 7/6/17.
//

#import <Foundation/Foundation.h>
#import <ARKit/ARKit.h>
#import "CinderARKitApp.h"

@interface NativeBridge : NSObject <ARSessionDelegate>
{
    CinderARKitApp *_app;
}

- (instancetype)initWithApp:(CinderARKitApp *)app;
- (void)handleTap:(UITapGestureRecognizer*)gestureRecognize;
- (void)handleDoubleTap:(UITapGestureRecognizer*)gestureRecognize;
- (void)handleSwipe:(UISwipeGestureRecognizer*)gestureRecognize;

@end
