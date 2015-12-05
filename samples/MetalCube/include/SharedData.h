//
//  SharedData.h
//  MetalCube
//
//  Created by William Lindmeier on 12/5/15.
//
//

#pragma once

#include <simd/simd.h>

using namespace metal;

typedef struct
{
    packed_float3 position;
    packed_float3 normal;
    packed_float2 texCoord0;
} CubeVertex;
