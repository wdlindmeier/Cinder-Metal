//
//  SharedData.h
//  Cinder-Metal
//
//  Created by William Lindmeier on 12/5/15.
//
//

#pragma once

#include <simd/simd.h>

typedef struct
{
    metal::packed_float3 position;
    metal::packed_float3 normal;
    metal::packed_float2 texCoord0;
} CubeVertex;
