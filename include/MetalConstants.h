//
//  MetalConstants.h
//  Cinder-Metal
//
//  Created by William Lindmeier on 11/8/15.
//
//

#pragma once

#include <simd/simd.h>

// Default Metal shader indices

namespace cinder {
    
    namespace mtl {
        
        enum DefaultBufferShaderIndices
        {
            ciBufferIndexUniforms = 0,
            ciBufferIndexInterleavedVerts = 1,
            ciBufferIndexIndicies = 2,
            ciBufferIndexPositions = 3,
            ciBufferIndexColors = 4,
            ciBufferIndexTexCoords0 = 5,
            ciBufferIndexTexCoords1 = 6,
            ciBufferIndexTexCoords2 = 7,
            ciBufferIndexTexCoords3 = 8,
            ciBufferIndexNormals = 9,
            ciBufferIndexTangents = 10,
            ciBufferIndexBitangents = 11,
            ciBufferIndexBoneIndices = 12,
            ciBufferIndexBoneWeight = 13,
            ciBufferIndexCustom0 = 14,
            ciBufferIndexCustom1 = 15,
            ciBufferIndexCustom2 = 16,
            ciBufferIndexCustom3 = 17,
            ciBufferIndexCustom4 = 18,
            ciBufferIndexCustom5 = 19,
            ciBufferIndexCustom6 = 20,
            ciBufferIndexCustom7 = 21,
            ciBufferIndexCustom8 = 22,
            ciBufferIndexCustom9 = 23,
        };
//        
//#define ciBufferIndexUniforms           0
//#define ciBufferIndexInterleavedVerts   1
//#define ciBufferIndexIndicies           2
//#define ciBufferIndexPositions          3
//#define ciBufferIndexColors             4
//#define ciBufferIndexTexCoords0         5
//#define ciBufferIndexTexCoords1         6
//#define ciBufferIndexTexCoords2         7
//#define ciBufferIndexTexCoords3         8
//#define ciBufferIndexNormals            9
//#define ciBufferIndexTangents           10
//#define ciBufferIndexBitangents         11
//#define ciBufferIndexBoneIndices        12
//#define ciBufferIndexBoneWeight         13
//#define ciBufferIndexCustom0            14
//#define ciBufferIndexCustom1            15
//#define ciBufferIndexCustom2            16
//#define ciBufferIndexCustom3            17
//#define ciBufferIndexCustom4            18
//#define ciBufferIndexCustom5            19
//#define ciBufferIndexCustom6            20
//#define ciBufferIndexCustom7            21
//#define ciBufferIndexCustom8            22
//#define ciBufferIndexCustom9            23

        enum DefaultSamplerShaderIndices
        {
            ciSamplerIndex0 = 0,
            ciSamplerIndex1 = 1,
            ciSamplerIndex2 = 2,
        };
        
//#define ciSamplerIndex0                 0
//#define ciSamplerIndex1                 1
//#define ciSamplerIndex2                 2

        enum DefaultTextureShaderIndices
        {
            ciTextureIndex0 = 0,
            ciTextureIndex1 = 1,
            ciTextureIndex2 = 2,
        };
        
//#define ciTextureIndex0                 0
//#define ciTextureIndex1                 1
//#define ciTextureIndex2                 2
        
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
    }
}

