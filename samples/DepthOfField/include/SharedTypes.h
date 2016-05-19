//
//  SharedTypes.h
//  FoldingCube
//
//  Created by William Lindmeier on 1/30/16.
//
//

#pragma once

// Add structs and types here that will be shared between your App and your Shaders

#include <simd/simd.h>

typedef struct
{
    // float progress;
} myUniforms_t;

typedef struct TeapotInstance
{
    vector_float3 position = {0,0,0};
    vector_float3 axis = {0,0,0};
    matrix_float4x4 modelMatrix = {
        (vector_float4){1,0,0,0},
        (vector_float4){0,1,0,0},
        (vector_float4){0,0,1,0},
        (vector_float4){0,0,0,1}
    };
} TeapotInstance;