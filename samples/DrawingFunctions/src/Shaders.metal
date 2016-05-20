//
//  Shaders.metal
//  MetalTemplate
//
//  Created by William Lindmeier on 11/26/15.
//
//

#include <metal_stdlib>
#include <simd/simd.h>
#include "MetalConstants.h"
#include "ShaderTypes.h"
#include "SharedTypes.h"

using namespace metal;
using namespace cinder::mtl;

typedef struct
{
    metal::packed_float3 ciPosition;
    metal::packed_float4 ciColor;
} ciVertexIn_t;

typedef struct
{
    float4 position [[position]];
    float4 color;
} ciVertexOut_t;

vertex ciVertexOut_t generated_vert( device const ciVertexIn_t* ciVerts [[ buffer(ciBufferIndexInterleavedVerts) ]],
                                     device const Instance* instances [[ buffer(ciBufferIndexInstanceData) ]],
                                     constant ciUniforms_t& ciUniforms [[ buffer(ciBufferIndexUniforms) ]],
                                     unsigned int vid [[ vertex_id ]],
                                     uint i [[ instance_id ]] )
{
    ciVertexOut_t out;
    ciVertexIn_t v = ciVerts[vid];
    matrix_float4x4 modelMat = ciUniforms.ciModelMatrix * instances[i].modelMatrix;
    matrix_float4x4 mvpMat = ciUniforms.ciViewProjection * modelMat;
    float4 pos = float4(v.ciPosition[0], v.ciPosition[1], v.ciPosition[2], 1.0f);
    out.position = mvpMat * pos;
    out.color = instances[i].color * ciUniforms.ciColor;
    out.color *= v.ciColor;
    return out;
}

fragment float4 generated_frag( ciVertexOut_t in [[ stage_in ]] )
{
    float4 oColor = in.color;
    return oColor;
}
