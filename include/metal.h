//
//  metal.h
//  MetalCube
//
//  Created by William Lindmeier on 10/13/15.
//
//

#ifndef metal_h
#define metal_h

#include "cinder/Cinder.h"
// Don't include. This is Objective-C
//#include "MetalContext.h"
#include "MetalPipeline.h"
//#include "MetalRenderPass.h"

namespace cinder {
    namespace mtl {
        
        // TODO: Make this an Option (in the renderer?)
        // Max number of concurrent command buffers
        static const int MAX_INFLIGHT_BUFFERS = 3;
        // Max API memory buffer size.
        static const size_t MAX_BYTES_PER_FRAME = 1024*1024;
    }
}

#endif /* metal_h */
