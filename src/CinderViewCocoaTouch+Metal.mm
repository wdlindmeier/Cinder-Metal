#include "cinder/app/cocoa/CinderViewCocoaTouch.h"
#import <QuartzCore/CAMetalLayer.h>

@implementation CinderViewCocoaTouch(Metal)

+ (Class)layerClass
{
    NSLog(@"Setting CAMetalLayer");
    return [CAMetalLayer class];
}

@end