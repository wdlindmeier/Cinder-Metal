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
#include "ShaderUtils.h"

using namespace metal;
using namespace cinder;
using namespace cinder::mtl;

typedef struct
{
    metal::packed_float3 ciPosition;
    metal::packed_float3 ciNormal;
    metal::packed_float2 ciTexCoord0;
    metal::packed_float4 ciColor;
} CubeVertex;

using namespace metal;

vertex ciVertOut_t cube_vertex( device const CubeVertex* ciVerts [[ buffer(ciBufferIndexInterleavedVerts) ]],
                                constant ciUniforms_t& ciUniforms [[ buffer(ciBufferIndexUniforms) ]],
                                unsigned int vid [[ vertex_id ]] )
{
    ciVertOut_t out;
    
    CubeVertex p = ciVerts[vid];
    out.position = ciUniforms.ciModelViewProjection * float4(p.ciPosition, 1.0);
    out.color = p.ciColor;
    out.texCoords = p.ciTexCoord0;
    return out;
}

constexpr sampler shaderSampler( coord::normalized, // normalized (0-1) or coord::pixel (0-width,height)
                                 address::repeat, // repeat, clamp_to_zero, clamp_to_edge,
                                 filter::linear, // nearest or linear
                                 mip_filter::linear ); // nearest or linear or none

fragment float4 rgb_texture_fragment( ciVertOut_t in [[ stage_in ]],
                                      texture2d<float> texture [[ texture(ciTextureIndex0) ]] )
{
    return texture.sample(shaderSampler, in.texCoords);
}

fragment float4 color_fragment( ciVertOut_t in [[ stage_in ]] )
{
    return in.color;
}
