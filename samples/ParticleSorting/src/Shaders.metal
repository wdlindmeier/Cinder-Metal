//
//  Shaders.metal
//  MetalBasic
//
//  Created by William Lindmeier on 10/11/15.
//  Copyright (c) 2015 wdlindmeier. All rights reserved.
//

#include <metal_stdlib>
#include <simd/simd.h>
#include "MetalConstants.h"

using namespace metal;

// Variables in constant address space
constant float3 light_position = float3(0.0, 1.0, -1.0);
constant float4 ambient_color  = float4(0.18, 0.24, 0.8, 1.0);
constant float4 diffuse_color  = float4(0.4, 0.4, 1.0, 1.0);

typedef struct
{
    packed_float3 position;
    packed_float3 normal;
} vertex_t;

typedef struct {
    float4 position [[position]];
    float pointSize [[point_size]];
    float4 color;
    float2 texCoords;
} ColorInOut;

typedef struct {
    packed_float3 position;
    packed_float3 velocity;
} Particle;

// A simple sort pass on every particle
kernel void kernel_sort(const device Particle* inPositions [[ buffer(1) ]],
                        device int *outIndices [[ buffer(2) ]],
                        constant ciUniforms_t& uniforms [[ buffer(0) ]],
                        uint2 gid [[thread_position_in_grid]]) // global id is x,y
{
    int index = (gid[1] * 32) + gid[0];

    Particle p = inPositions[index];
    float4 viewPosition = uniforms.modelMatrix * float4(p.position, 0.0f);
    float viewZ = viewPosition[2];
    int numAfter = 0;
    for ( int i = 0; i < 1024; ++i )
    {
        if ( i != index )
        {
            Particle otherP = inPositions[i];
            float4 otherViewPosition = uniforms.modelMatrix * float4(otherP.position, 0.0f);
            float otherViewZ = otherViewPosition[2];
            if ( otherViewZ > viewZ )
            {
                numAfter += 1;
            }
        }
    }

    outIndices[numAfter] = index;
}

vertex ColorInOut vertex_particles(device Particle * particles [[ buffer(ciBufferIndexInterleavedVerts) ]],
                                   constant ciUniforms_t& uniforms [[ buffer(ciBufferIndexUniforms) ]],
                                   device int *sortedIndices [[ buffer(ciBufferIndexIndicies) ]],
                                   unsigned int vid [[ vertex_id ]] )
{
    ColorInOut out;
    
    int sortedIndex = sortedIndices[vid];
    float scalarSort = float(vid) / 1024.f;
    
    Particle p = particles[sortedIndex];
    
    float4 in_position = float4(p.position * 2.f, 1.0f);
    out.position = uniforms.modelViewProjectionMatrix * in_position;
    
    // Make the rear particles smaller 
    out.pointSize = 20.f + (scalarSort * 20.f);//40.f;
    float4 viewPosition = uniforms.modelMatrix * float4(p.position, 1.0f);
    float scalarZ = (1.0 + viewPosition[2]) / 2.f;
    out.color = float4(scalarZ,
                       1.f-scalarZ,
                       0.f,
                       0.5f);
    
    return out;
}

vertex ColorInOut vertex_lighting_geom(device unsigned int* indices [[ buffer(ciBufferIndexIndicies) ]],
                                       device packed_float3* positions [[ buffer(ciBufferIndexPositions) ]],
                                       device packed_float3* normals [[ buffer(ciBufferIndexNormals) ]],
                                       constant ciUniforms_t& uniforms [[ buffer(ciBufferIndexUniforms) ]],
                                       unsigned int vid [[ vertex_id ]])
{
    ColorInOut out;
    
    unsigned int vertIndex = indices[vid];
    
    float4 in_position = float4(positions[vertIndex] - float3(0.0,0.5,0.0), // center the teapot
                                1.0);
    out.position = uniforms.modelViewProjectionMatrix * in_position;
    
    float3 normal = normals[vertIndex];
    float4 eye_normal = normalize(uniforms.normalMatrix * float4(normal, 0.0));
    float n_dot_l = dot(eye_normal.rgb, normalize(light_position));
    n_dot_l = fmax(0.0, n_dot_l);
    
    out.color = ambient_color + diffuse_color * n_dot_l;
    
    return out;
}

fragment float4 fragment_color( ColorInOut in [[stage_in]] )
{
    return in.color;
}


