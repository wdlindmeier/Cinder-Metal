//
//  ShaderUtils.h
//  MetalBasic
//
//  Created by William Lindmeier on 2/20/16.
//
//

#pragma once

#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

typedef struct
{
    float4 position [[position]];
    float pointSize [[point_size]];
    float3 normal;
    float4 color;
    float2 texCoords;
    int texIndex;
} ciVertOut_t;

inline float3 rgb2hsv(float3 c)
{
    float4 K = float4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    float4 p = c.g < c.b ? float4(c.bg, K.wz) : float4(c.gb, K.xy);
    float4 q = c.r < p.x ? float4(p.xyw, c.r) : float4(c.r, p.yzx);
    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return float3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

inline float3 hsv2rgb(float3 c)
{
    float4 K = float4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    float3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

inline matrix_float4x4 rotationMatrix( const matrix_float4x4 m )
{
    return matrix_float4x4((vector_float4){m[0][0], m[0][1], m[0][2], 0},
                           (vector_float4){m[1][0], m[1][1], m[1][2], 0},
                           (vector_float4){m[2][0], m[2][1], m[2][2], 0},
                           (vector_float4){0,       0,       0,       1} );
}
