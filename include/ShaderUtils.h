//
//  ShaderUtils.h
//  MetalBasic
//
//  Created by William Lindmeier on 2/20/16.
//
//

#pragma once

#include "ShaderTypes.h"

#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

// This is a macro. We've defined them this way so they can be rolled into
// online shaders (which don't accept user includes).
ShaderUtils