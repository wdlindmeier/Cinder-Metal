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

using namespace metal;
using namespace cinder::mtl;

typedef struct
{
    // Must be in the same order as the attributes were requested
    // in VertexBuffer::create
    packed_float3 position;
    packed_float3 normal;
    packed_float2 texCoord0;
} VertexIn;

typedef struct
{
    float4 position [[position]];
    float4 normal;
    float2 texCoords;
} ColorInOut;

// Vertex shader function
vertex ColorInOut cube_vertex( device const VertexIn* vertexArray [[ buffer(ciBufferIndexInterleavedVerts) ]],
                               device const uint* indices [[ buffer(ciBufferIndexIndicies) ]],
                               constant ciUniforms_t& uniforms [[ buffer(ciBufferIndexUniforms) ]],
                               unsigned int vid [[ vertex_id ]] )
{
    // NOTE: We're using index accessing rather than a MTLVertexDescriptor approach so we can
    // use BufferLayouts to change the data layout on a per-model basis, rather than on a
    // per-pipeline basis.
    uint vertIndex = indices[vid];
    VertexIn vert = vertexArray[vertIndex];
    ColorInOut out;
    
    out.position = uniforms.ciModelViewProjectionMatrix * float4(vert.position, 1.0);
    out.texCoords = float2(vert.texCoord0);
    out.normal = normalize(uniforms.ciNormalMatrix * float4(vert.normal, 0.0));
    
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
