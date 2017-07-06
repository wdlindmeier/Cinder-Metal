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
using namespace cinder;
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

vertex ColorInOut simple_vertex( device const VertexIn* ciVerts [[ buffer(ciBufferIndexInterleavedVerts) ]],
                                 constant ciUniforms_t& ciUniforms [[ buffer(ciBufferIndexUniforms) ]],
                                 unsigned int vid [[ vertex_id ]] )
{
    VertexIn vert = ciVerts[vid];
    float4 localPosition(vert.ciPosition[0], vert.ciPosition[1], 0, 1);
    ColorInOut out;
    out.position = ciUniforms.ciModelViewProjection * localPosition;
    out.texCoords = vert.ciTexCoord0;
    return out;
}

fragment float4 camera_fragment(ColorInOut in [[stage_in]],
                                texture2d<float, access::sample> capturedImageTextureY [[ texture(ciTextureIndex0) ]],
                                texture2d<float, access::sample> capturedImageTextureCbCr [[ texture(ciTextureIndex1) ]]) {
    
    constexpr sampler colorSampler(mip_filter::linear,
                                   mag_filter::linear,
                                   min_filter::linear);
    
    const float4x4 ycbcrToRGBTransform = float4x4(
                                                  float4(+1.0000f, +1.0000f, +1.0000f, +0.0000f),
                                                  float4(+0.0000f, -0.3441f, +1.7720f, +0.0000f),
                                                  float4(+1.4020f, -0.7141f, +0.0000f, +0.0000f),
                                                  float4(-0.7010f, +0.5291f, -0.8860f, +1.0000f)
                                                  );
    
    // Sample Y and CbCr textures to get the YCbCr color at the given texture coordinate
    float4 ycbcr = float4(capturedImageTextureY.sample(colorSampler, in.texCoords).r,
                          capturedImageTextureCbCr.sample(colorSampler, in.texCoords).rg, 1.0);
    
    // Return converted RGB color
    return ycbcrToRGBTransform * ycbcr;
}
