//
//  Shaders.metal
//  MetalTemplate
//
//  Created by William Lindmeier on 11/26/15.
//
//

#include <metal_stdlib>
#include <simd/simd.h>

#include "SharedTypes.h"
#include "ShaderUtils.h"
#include "MetalConstants.h"

using namespace metal;
using namespace cinder;
using namespace cinder::mtl;

// Sample Shader

// Cinder-Metal infers attribute mapping by name.
// If you use the names found in src/Batch.cpp for your custom structs,
// the Batch class will know where to put the data.
typedef struct
{
    metal::packed_float3 ciPosition;
    metal::packed_float3 ciNormal;
    metal::packed_float2 ciTexCoord0;
    metal::packed_float4 ciColor;
} MyVertex;

// Cinder-Metal will inspect your vertex function and look for parameters with pre-defined names and buffer indices.
// ciVerts: The vertex data populated by a Batch. Should use buffer index ciBufferIndexInterleavedVerts.
// ciUniforms: The uniforms passed in by the context. Should be located at ciBufferIndexUniforms.
vertex ciVertOut_t geom_vertex( device const MyVertex* ciVerts [[ buffer(ciBufferIndexInterleavedVerts) ]],
                                constant ciUniforms_t& ciUniforms [[ buffer(ciBufferIndexUniforms) ]],
                                unsigned int vid [[ vertex_id ]] )
{
    ciVertOut_t out;
    
    MyVertex vert = ciVerts[vid];
    out.position = ciUniforms.ciModelViewProjection * float4(vert.ciPosition, 1.0);
    out.color = vert.ciColor;
    out.texCoords = vert.ciTexCoord0;
    return out;
}

fragment float4 color_fragment( ciVertOut_t in [[ stage_in ]] )
{
    return in.color;
}

constexpr sampler shaderSampler( coord::normalized, // normalized (0-1) or coord::pixel (0-width,height)
                                 address::repeat, // repeat, clamp_to_zero, clamp_to_edge,
                                 filter::linear, // nearest or linear
                                 mip_filter::linear ); // nearest or linear or none

fragment float4 texture_fragment( ciVertOut_t in [[ stage_in ]],
                                  texture2d<float> texture [[ texture(ciTextureIndex0) ]] )
{
    return texture.sample(shaderSampler, in.texCoords);
}
