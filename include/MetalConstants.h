//
//  MetalConstants.h
//  MetalCube
//
//  Created by William Lindmeier on 11/8/15.
//
//

#pragma once

// Default Metal shader indices

#define ciBufferIndexUniforms           0
#define ciBufferIndexInterleavedVerts   1
#define ciBufferIndexIndicies           2
#define ciBufferIndexPositions          3
#define ciBufferIndexColors             4
#define ciBufferIndexTexCoords0         5
#define ciBufferIndexTexCoords1         6
#define ciBufferIndexTexCoords2         7
#define ciBufferIndexTexCoords3         8
#define ciBufferIndexNormals            9
#define ciBufferIndexTangents           10
#define ciBufferIndexBitangents         11
#define ciBufferIndexBoneIndices        12
#define ciBufferIndexBoneWeight         13
#define ciBufferIndexCustom0            14
#define ciBufferIndexCustom1            15
#define ciBufferIndexCustom2            16
#define ciBufferIndexCustom3            17
#define ciBufferIndexCustom4            18
#define ciBufferIndexCustom5            19
#define ciBufferIndexCustom6            20
#define ciBufferIndexCustom7            21
#define ciBufferIndexCustom8            22
#define ciBufferIndexCustom9            23

#define ciSamplerIndex0                 0
#define ciSamplerIndex1                 1
#define ciSamplerIndex2                 2

#define ciTextureIndex0                 0
#define ciTextureIndex1                 1
#define ciTextureIndex2                 2

#include <simd/simd.h>
typedef struct
{
    float elapsedSeconds;
    matrix_float4x4 projectionMatrix;
    matrix_float4x4 viewMatrix;
    matrix_float4x4 modelMatrix;
    matrix_float4x4 inverseModelMatrix;
    matrix_float4x4 modelViewMatrix;
    matrix_float4x4 modelViewProjectionMatrix;
    matrix_float4x4 normalMatrix;
    matrix_float4x4 inverseViewMatrix;
} ciUniforms_t;