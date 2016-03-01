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
#include "InstanceTypes.h"
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

vertex VertOut cube_vertex( device const CubeVertex* ciVerts [[ buffer(ciBufferIndexInterleavedVerts) ]],
                            device const uint* ciIndices [[ buffer(ciBufferIndexIndicies) ]],
                            constant ciUniforms_t& ciUniforms [[ buffer(ciBufferIndexUniforms) ]],
                            unsigned int vid [[ vertex_id ]] )
{
    VertOut out;
    
    unsigned int vertIndex = ciIndices[vid];
    CubeVertex p = ciVerts[vertIndex];
    out.position = ciUniforms.ciModelViewProjection * float4(p.ciPosition, 1.0f);
    out.color = p.ciColor;
    out.texCoords = p.ciTexCoord0;
    return out;
}

constexpr sampler shaderSampler( coord::normalized, // normalized (0-1) or coord::pixel (0-width,height)
                                 address::repeat, // repeat, clamp_to_zero, clamp_to_edge,
                                 filter::linear, // nearest or linear
                                 mip_filter::linear ); // nearest or linear or none

fragment float4 rgb_texture_fragment( VertOut in [[ stage_in ]],
                                      texture2d<float> texture [[ texture(ciTextureIndex0) ]] )
{
    return texture.sample(shaderSampler, in.texCoords);
}

fragment float4 gray_texture_fragment( VertOut in [[ stage_in ]],
                                       texture2d<float> texture [[ texture(ciTextureIndex0) ]] )
{
    float4 c = texture.sample(shaderSampler, in.texCoords);
    return float4(c.r, c.r, c.r, c.a);
}