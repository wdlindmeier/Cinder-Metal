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

using namespace metal;
using namespace cinder::mtl;

typedef struct
{
    // Must be in the same order as the attributes were requested
    // in VertexBuffer::create
    packed_float4 ciPosition;
    packed_float3 ciNormal;
    packed_float2 ciTexCoord0;
} VertexIn;

typedef struct
{
    float4 position [[position]];
    float4 normal;
    float2 texCoords;
} ColorInOut;

vertex ColorInOut batch_vertex( device const VertexIn* ciVerts [[ buffer(ciBufferIndexInterleavedVerts) ]],
                                constant ciUniforms_t& ciUniforms [[ buffer(ciBufferIndexUniforms) ]],
                                unsigned int vid [[ vertex_id ]] )
{
    VertexIn vert = ciVerts[vid];
    ColorInOut out;

    out.position = ciUniforms.ciModelViewProjection * float4(vert.ciPosition);
    out.texCoords = float2(vert.ciTexCoord0);
    out.normal = normalize(ciUniforms.ciNormalMatrix4x4 * float4(vert.ciNormal, 0.0));
    
    return out;
}

constexpr sampler shaderSampler( coord::normalized, // normalized (0-1) or coord::pixel (0-width,height)
                                 address::repeat, // repeat, clamp_to_zero, clamp_to_edge,
                                 filter::linear, // nearest or linear
                                 mip_filter::linear ); // nearest or linear or none

// Fragment shader function
fragment float4 cube_fragment( ColorInOut in [[ stage_in ]],
                               texture2d<float> textureCube [[ texture(ciTextureIndex0) ]] )
{
    
    float4 normal = -in.normal;
    float diffuse = max( dot( normal, float4( 0, 0, -1, 1 ) ), 0.f );
    // NOTE: "texture.jpg" is a single channel image, so we'll just grab the red.
    float4 texColor = textureCube.sample(shaderSampler, in.texCoords);
    return float4(float3(texColor.r * diffuse), 1.f);
}
