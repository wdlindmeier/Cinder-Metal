//
//  SharedTypes.h
//  Batch
//
//  Created by William Lindmeier on 1/10/16.
//
//

#pragma once

#include <simd/simd.h>
//
//typedef struct
//{
//    matrix_float4x4 ciProjectionMatrix;
//} myUniforms_t;

typedef struct
{
    metal::packed_float3 ciPosition;
    metal::packed_float3 ciNormal;
    metal::packed_float2 ciTexCoord0;
} CubeVertex;

//struct myUniforms_t {
//    
//};