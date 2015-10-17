//
//  metal.h
//  MetalCube
//
//  Created by William Lindmeier on 10/13/15.
//
//

#pragma once

#include "cinder/Cinder.h"
#include "MetalPipeline.h"
#include "MetalRenderEncoder.h"
#include "MetalGeom.h"
#include "MetalBuffer.h"

namespace cinder {

    namespace mtl {
        
        // TODO: Make these Options (in the renderer?)
        
        // Max number of concurrent command buffers
        static const int MAX_INFLIGHT_BUFFERS = 3;
                
    }
}
