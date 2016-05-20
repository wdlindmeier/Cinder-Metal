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
//
//typedef struct
//{
//    // Must be in the same order as the attributes were requested
//    // in VertexBuffer::create
//    packed_float4 ciPosition;
//    packed_float3 ciNormal;
//    packed_float2 ciTexCoord0;
//} VertexIn;
//
//typedef struct
//{
//    float4 position [[position]];
//    float4 normal;
//    float2 texCoords;
//} ColorInOut;
//
//vertex ColorInOut batch_vertex( device const VertexIn* ciVerts [[ buffer(ciBufferIndexInterleavedVerts) ]],
//                                constant ciUniforms_t& ciUniforms [[ buffer(ciBufferIndexUniforms) ]],
//                                unsigned int vid [[ vertex_id ]] )
//{
//    VertexIn vert = ciVerts[vid];
//    ColorInOut out;
//
//    out.position = ciUniforms.ciModelViewProjection * float4(vert.ciPosition);
//    out.texCoords = float2(vert.ciTexCoord0);
//    out.normal = normalize(ciUniforms.ciNormalMatrix4x4 * float4(vert.ciNormal, 0.0));
//    
//    return out;
//}
//


typedef struct
{
    metal::packed_float4 ciPosition;
    metal::packed_float3 ciNormal; // << this is the issue
    metal::packed_float2 ciTexCoord0;
} ciVertexIn_t;

typedef struct
{
    float4 position [[position]];
    float4 color;
    float2 texCoords;
    int texIndex;
} ciVertexOut_t;

vertex ciVertexOut_t batch_vertex( device const ciVertexIn_t* ciVerts [[ buffer(ciBufferIndexInterleavedVerts) ]],
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
    float texWidth = instances[i].texCoordRect[2] - instances[i].texCoordRect[0];
    float texHeight = instances[i].texCoordRect[3] - instances[i].texCoordRect[1];
    float2 texCoord(v.ciTexCoord0);
    float2 instanceTexCoord(instances[i].texCoordRect[0] + texCoord.x * texWidth,
                            instances[i].texCoordRect[1] + texCoord.y * texHeight);
    out.texCoords = instanceTexCoord;
    out.texIndex = instances[i].textureSlice;
    return out;
}


constexpr sampler shaderSampler( coord::normalized, // normalized (0-1) or coord::pixel (0-width,height)
                                 address::repeat, // repeat, clamp_to_zero, clamp_to_edge,
                                 filter::linear, // nearest or linear
                                 mip_filter::linear ); // nearest or linear or none

// Fragment shader function
fragment float4 cube_fragment( ciVertexOut_t in [[ stage_in ]],
                               texture2d<float> textureCube [[ texture(ciTextureIndex0) ]] )
{
    
    // TMP
//    float4 normal = -in.normal;
    float diffuse = 1.0;//max( dot( normal, float4( 0, 0, -1, 1 ) ), 0.f );
    // NOTE: "texture.jpg" is a single channel image, so we'll just grab the red.
    float4 texColor = textureCube.sample(shaderSampler, in.texCoords);
    return float4(float3(texColor.r * diffuse), 1.f);
}
