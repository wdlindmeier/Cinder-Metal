//
//  Shaders.metal
//  MetalBasic
//
//  Created by William Lindmeier on 10/11/15.
//  Copyright (c) 2015 wdlindmeier. All rights reserved.
//

#include <metal_stdlib>
#include <simd/simd.h>
#include "BufferConstants.h"

using namespace metal;

// Variables in constant address space
constant float3 light_position = float3(0.0, 1.0, -1.0);
constant float4 ambient_color  = float4(0.18, 0.24, 0.8, 1.0);
constant float4 diffuse_color  = float4(0.4, 0.4, 1.0, 1.0);

typedef struct
{
    matrix_float4x4 modelview_projection_matrix;
    matrix_float4x4 normal_matrix;
} uniforms_t;

typedef struct
{
    packed_float3 position;
    packed_float3 normal;
} vertex_t;

typedef struct {
    float4 position [[position]];
    float4 color;
    float2 texCoords;
//    bool sampleTexture;
} ColorInOut;

// Vertex shader function
vertex ColorInOut lighting_vertex_interleaved(device vertex_t* vertex_array [[ buffer(BUFFER_INDEX_VERTS) ]],
                                              constant uniforms_t& uniforms [[ buffer(BUFFER_INDEX_UNIFORMS) ]],
                                              unsigned int vid [[ vertex_id ]])
{
    ColorInOut out;
    
    float4 in_position = float4(float3(vertex_array[vid].position), 1.0);
    out.position = uniforms.modelview_projection_matrix * in_position;
    
    float3 normal = vertex_array[vid].normal;
    float4 eye_normal = normalize(uniforms.normal_matrix * float4(normal, 0.0));
    float n_dot_l = dot(eye_normal.rgb, normalize(light_position));
    n_dot_l = fmax(0.0, n_dot_l);
    
    //out.color = half4(ambient_color + diffuse_color * n_dot_l);
    out.color = ambient_color + diffuse_color * n_dot_l;
//    out.sampleTexture = false;
    
    return out;
}

// Vertex shader function using geom::Source data layout
vertex ColorInOut lighting_vertex_geom(device unsigned int* indices [[ buffer(BUFFER_INDEX_GEOM_INDICES) ]],
                                       device packed_float3* verts [[ buffer(BUFFER_INDEX_GEOM_VERTS) ]],
                                       device packed_float3* normals [[ buffer(BUFFER_INDEX_GEOM_NORMALS) ]],
                                       device packed_float2* texCoords [[ buffer(BUFFER_INDEX_GEOM_TEX_COORDS) ]],
                                       constant uniforms_t& uniforms [[ buffer(BUFFER_INDEX_GEOM_UNIFORMS) ]],
                                       unsigned int vid [[ vertex_id ]])
{
    ColorInOut out;
    
    unsigned int vertIndex = indices[vid];
    
    float4 in_position = float4(verts[vertIndex], 1.0);
    out.position = uniforms.modelview_projection_matrix * in_position;
    
    float3 normal = normals[vertIndex];
    float4 eye_normal = normalize(uniforms.normal_matrix * float4(normal, 0.0));
    float n_dot_l = dot(eye_normal.rgb, normalize(light_position));
    n_dot_l = fmax(0.0, n_dot_l);
    
    out.color = float4(float4(1.0) * n_dot_l);
    out.texCoords = texCoords[vertIndex];
//    out.sampleTexture = true;
    
    return out;
}

// Vertex shader function using attrib buffers
vertex ColorInOut lighting_vertex_attrib_buffers(device packed_float3* positions [[ buffer(BUFFER_INDEX_ATTRIB_POSITIONS) ]],
                                                 device packed_float3* normals [[ buffer(BUFFER_INDEX_ATTRIB_NORMALS) ]],
                                                 constant uniforms_t& uniforms [[ buffer(BUFFER_INDEX_ATTRIB_UNIFORMS) ]],
                                                 unsigned int vid [[ vertex_id ]])
{
    ColorInOut out;
    
    float4 in_position = float4(positions[vid], 1.0);
    out.position = uniforms.modelview_projection_matrix * in_position;
    
    float3 normal = normals[vid];
    float4 eye_normal = normalize(uniforms.normal_matrix * float4(normal, 0.0));
    float n_dot_l = dot(eye_normal.rgb, normalize(light_position));
    n_dot_l = fmax(0.0, n_dot_l);
    
    out.color = ambient_color + diffuse_color * n_dot_l;
//    out.sampleTexture = false;
    
    return out;
}

// NOTE: samplers defined in the shader don't appear to have an anisotropy param
constexpr sampler shaderSampler(coord::normalized, // normalized (0-1) or coord::pixel (0-width,height)
                                address::repeat, // repeat, clamp_to_zero, clamp_to_edge,
                                filter::linear, // nearest or linear
                                mip_filter::linear ); // nearest or linear or none

// Fragment shader function
fragment float4 lighting_texture_fragment( ColorInOut in [[stage_in]],
                                          texture2d<float> textureCube [[ texture(TEXTURE_INDEX_CUBE) ]],// )
                                          sampler objcSampler [[sampler(0)]] )
{
    float4 texColor = textureCube.sample(objcSampler, in.texCoords);
    //float4 texColor = textureCube.sample(shaderSampler, in.texCoords);
    return float4(texColor.rgb * in.color.rgb, texColor.a);
}

fragment float4 lighting_fragment( ColorInOut in [[stage_in]] )
{
    return in.color;
}


