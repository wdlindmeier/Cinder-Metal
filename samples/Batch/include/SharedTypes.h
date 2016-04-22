//
//  SharedTypes.h
//  Batch
//
//  Created by William Lindmeier on 1/10/16.
//
//

#pragma once

#include <simd/simd.h>

typedef struct
{
    metal::packed_float4 ciPosition;
    metal::packed_float3 ciNormal;
    metal::packed_float2 ciTexCoord0;
} CubeVertex;