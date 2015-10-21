//
//  metal.h
//  MetalCube
//
//  Created by William Lindmeier on 10/13/15.
//
//

#pragma once

#include "cinder/Cinder.h"
#include "RendererMetal.h"
#include "MetalPipeline.h"
#include "MetalCommandBuffer.h"
#include "MetalBuffer.h"
#include "MetalRenderFormat.h"
#include "MetalComputeFormat.h"
#include "MetalBlitFormat.h"
#include "MetalRenderEncoder.h"
#include "MetalComputeEncoder.h"
#include "MetalBlitEncoder.h"
#include "MetalGeom.h"

namespace cinder {

    namespace mtl {
        
        // TODO: Make these Options (in the renderer?)
        
        // Max number of concurrent command buffers
        static const int MAX_INFLIGHT_BUFFERS = 3;
                
    }
}
