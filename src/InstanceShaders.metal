//
//  InstanceShaders.metal
//  CascadeTimeline
//
//  Created by William Lindmeier on 2/27/16.
//
//

//  A collection of useful shaders that use the instance pattern

#include <metal_stdlib>
#include <simd/simd.h>

#include "InstanceTypes.h"
#include "ShaderUtils.h"
#include "MetalConstants.h"

using namespace metal;
using namespace cinder;
using namespace cinder::mtl;