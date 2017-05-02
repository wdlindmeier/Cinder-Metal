//
//  CinderMetalCocoa.h
//
//  Created by William Lindmeier on 3/3/17.
//
//

#pragma once

#ifdef CINDER_COCOA_TOUCH
#import <UIKit/UIKit.h>
#endif
#import <Metal/Metal.h>
#include "cinder/Cinder.h"
#include "metal.h"

namespace cinder { namespace cocoa {

    CGImageRef convertMTLTexture(id <MTLTexture> texture);

#ifdef CINDER_COCOA_TOUCH
    UIImage * convertTexture(ci::mtl::TextureBufferRef & texture);
#else
#ifdef CINDER_COCOA
	NSImage * convertTexture(ci::mtl::TextureBufferRef & texture);
#endif
#endif
    
}}
