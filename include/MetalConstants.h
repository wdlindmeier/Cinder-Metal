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
            ciBufferIndexInstanceData = 24,
        };
        
        enum DefaultSamplerShaderIndices
        {
            ciSamplerIndex0 = 0,
            ciSamplerIndex1 = 1,
            ciSamplerIndex2 = 2,
        };

        enum DefaultTextureShaderIndices
        {
            ciTextureIndex0 = 0,
            ciTextureIndex1 = 1,
            ciTextureIndex2 = 2,
        };

        typedef struct
        {
            matrix_float4x4 ciModelMatrix;
            matrix_float4x4 ciModelMatrixInverse;
            matrix_float3x3 ciModelMatrixInverseTranspose;
            matrix_float4x4 ciViewMatrix;
            matrix_float4x4 ciViewMatrixInverse;
            matrix_float4x4 ciModelView;
            matrix_float4x4 ciModelViewInverse;
            matrix_float3x3 ciModelViewInverseTranspose;
            matrix_float4x4 ciModelViewProjection;
            matrix_float4x4 ciModelViewProjectionInverse;
            matrix_float4x4 ciProjectionMatrix;
            matrix_float4x4 ciProjectionMatrixInverse;
            matrix_float4x4 ciViewProjection;
            matrix_float3x3 ciNormalMatrix;
            matrix_float4x4 ciNormalMatrix4x4;
//            matrix_float4x4 ciViewportMatrix;
            
            vector_float3 ciPositionOffset = {0,0,0};
            vector_float3 ciPositionScale = {1,1,1};
            vector_float2 ciTexCoordOffset = {0,0};
            vector_float2 ciTexCoordScale = {1,1};

            vector_int2 ciWindowSize;
            vector_float4 ciColor = {1,1,1,1};
            float ciElapsedSeconds = 0.f;
            
        } ciUniforms_t;
    }
}

