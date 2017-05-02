//
//  MetalConstants.h
//
//  Created by William Lindmeier on 11/8/15.
//
//

#pragma once

#include <simd/simd.h>

#define MetalConstants \
\
namespace cinder { \
    namespace mtl { \
        enum DefaultBufferShaderIndices \
        { \
            ciBufferIndexUniforms = 0, \
            ciBufferIndexInterleavedVerts = 1, \
            ciBufferIndexIndices = 2, \
            ciBufferIndexPositions = 3, \
            ciBufferIndexColors = 4, \
            ciBufferIndexTexCoords0 = 5, \
            ciBufferIndexTexCoords1 = 6, \
            ciBufferIndexTexCoords2 = 7, \
            ciBufferIndexTexCoords3 = 8, \
            ciBufferIndexNormals = 9, \
            ciBufferIndexTangents = 10, \
            ciBufferIndexBitangents = 11, \
            ciBufferIndexBoneIndices = 12, \
            ciBufferIndexBoneWeight = 13, \
            ciBufferIndexCustom0 = 14, \
            ciBufferIndexCustom1 = 15, \
            ciBufferIndexCustom2 = 16, \
            ciBufferIndexCustom3 = 17, \
            ciBufferIndexCustom4 = 18, \
            ciBufferIndexCustom5 = 19, \
            ciBufferIndexCustom6 = 20, \
            ciBufferIndexCustom7 = 21, \
            ciBufferIndexCustom8 = 22, \
            ciBufferIndexCustom9 = 23, \
            ciBufferIndexInstanceData = 24, \
        }; \
        \
        enum DefaultSamplerShaderIndices \
        { \
            ciSamplerIndex0 = 0, \
            ciSamplerIndex1 = 1, \
            ciSamplerIndex2 = 2, \
        }; \
        \
        enum DefaultTextureShaderIndices \
        { \
            ciTextureIndex0 = 0, \
            ciTextureIndex1 = 1, \
            ciTextureIndex2 = 2, \
        }; \
    } \
}

#define ShaderTypes \
\
namespace cinder { \
    namespace mtl { \
        typedef struct \
        { \
            matrix_float4x4 ciModelMatrix; \
            matrix_float4x4 ciModelMatrixInverse; \
            matrix_float3x3 ciModelMatrixInverseTranspose; \
            matrix_float4x4 ciViewMatrix; \
            matrix_float4x4 ciViewMatrixInverse; \
            matrix_float4x4 ciModelView; \
            matrix_float4x4 ciModelViewInverse; \
            matrix_float3x3 ciModelViewInverseTranspose; \
            matrix_float4x4 ciModelViewProjection; \
            matrix_float4x4 ciModelViewProjectionInverse; \
            matrix_float4x4 ciProjectionMatrix; \
            matrix_float4x4 ciProjectionMatrixInverse; \
            matrix_float4x4 ciViewProjection; \
            matrix_float3x3 ciNormalMatrix; \
            matrix_float4x4 ciNormalMatrix4x4; \
            vector_float3 ciPositionOffset = {0,0,0}; \
            vector_float3 ciPositionScale = {1,1,1}; \
            vector_float2 ciTexCoordOffset = {0,0}; \
            vector_float2 ciTexCoordScale = {1,1}; \
            vector_int2 ciWindowSize; \
            vector_float4 ciColor = {1,1,1,1}; \
            float ciElapsedSeconds = 0.f; \
        } ciUniforms_t; \
        \
        typedef struct Instance \
        { \
            float scale = 1.f; \
            vector_float4 color = {1,1,1,1}; \
            vector_float3 position = {0,0,0}; \
            bool isTextured = false; \
            int textureSlice = 0; \
            vector_float4 texCoordRect = {0.f,0.f,1.f,1.f}; \
            float floats[5] = {0.f,0.f,0.f,0.f,0.f}; \
            int ints[5] = {0,0,0,0,0}; \
            matrix_float4x4 modelMatrix = { \
                (vector_float4){1,0,0,0}, \
                (vector_float4){0,1,0,0}, \
                (vector_float4){0,0,1,0}, \
                (vector_float4){0,0,0,1} \
            }; \
            matrix_float4x4 normalMatrix = { \
                (vector_float4){1,0,0,0}, \
                (vector_float4){0,1,0,0}, \
                (vector_float4){0,0,1,0}, \
                (vector_float4){0,0,0,1} \
            }; \
        } Instance; \
        \
        typedef struct \
        { \
            vector_float4 position [[position]]; \
            float pointSize [[point_size]]; \
            vector_float3 normal; \
            vector_float4 color; \
            vector_float2 texCoords; \
            int texIndex; \
        } ciVertOut_t; \
        \
    } \
} 

#define ShaderUtils \
\
namespace cinder { \
    namespace mtl { \
        using namespace metal; \
        inline vector_float3 rgb2hsv(vector_float3 c) \
        { \
            vector_float4 K = vector_float4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0); \
            vector_float4 p = c.g < c.b ? vector_float4(c.bg, K.wz) : vector_float4(c.gb, K.xy); \
            vector_float4 q = c.r < p.x ? vector_float4(p.xyw, c.r) : vector_float4(c.r, p.yzx); \
            float d = q.x - min(q.w, q.y); \
            float e = 1.0e-10; \
            return vector_float3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x); \
        } \
        \
        inline vector_float3 hsv2rgb(float3 c) \
        { \
            vector_float4 K = vector_float4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0); \
            vector_float3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www); \
            return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y); \
        } \
        \
        inline matrix_float3x3 mat3( const matrix_float4x4 m ) \
        { \
            return matrix_float3x3((vector_float3){m[0][0], m[0][1], m[0][2]}, \
                                   (vector_float3){m[1][0], m[1][1], m[1][2]}, \
                                   (vector_float3){m[2][0], m[2][1], m[2][2]} ); \
        } \
        \
        inline matrix_float4x4 rotationMatrix( const matrix_float4x4 m ) \
        { \
            return matrix_float4x4((vector_float4){m[0][0], m[0][1], m[0][2], 0}, \
                                   (vector_float4){m[1][0], m[1][1], m[1][2], 0}, \
                                   (vector_float4){m[2][0], m[2][1], m[2][2], 0}, \
                                   (vector_float4){0,       0,       0,       1} ); \
        } \
    } \
}