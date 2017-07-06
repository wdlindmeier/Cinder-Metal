//
//  NativeBridge.m
//  CinderARKit
//
//  Created by William Lindmeier on 7/6/17.
//

#import "NativeBridge.h"
#import "CinderARKitApp.h"

@implementation NativeBridge

- (instancetype)initWithApp:(CinderARKitApp *)app
{
    self = [super init];
    if ( self )
    {
        _app = app;
    }
    return self;
}

- (void)handleTap:(UITapGestureRecognizer*)gestureRecognize
{
    _app->tapped(1);
}

- (void)handleDoubleTap:(UITapGestureRecognizer*)gestureRecognize
{
    _app->tapped(2);
}

- (void)handleSwipe:(UISwipeGestureRecognizer*)gestureRecognize
{
    _app->swipe((int)gestureRecognize.direction);
}

- (void)session:(ARSession *)session didAddAnchors:(NSArray<ARAnchor *> *)anchors
{
    for ( ARAnchor * anchor in anchors )
    {
        if ( [anchor isKindOfClass:[ARPlaneAnchor class]] )
        {
            NSLog(@"Added plane anchor: %@", anchor);
        }
    }
}

- (void)session:(ARSession *)session didRemoveAnchors:(nonnull NSArray<ARAnchor *> *)anchors
{
    
}

- (void)session:(ARSession *)session didUpdateAnchors:(nonnull NSArray<ARAnchor *> *)anchors
{
    for ( ARAnchor * anchor in anchors )
    {
        if ( [anchor isKindOfClass:[ARPlaneAnchor class]] )
        {
            NSLog(@"Removed plane anchor: %@", anchor);
        }
    }
}

@end
