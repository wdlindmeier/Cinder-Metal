//
//  InstanceShaders.metal
//  CascadeTimeline
//
//  Created by William Lindmeier on 2/27/16.
//
//

//  A collection of useful shaders that use the instance pattern

#include <metal_stdlib>
#include <simd/simd.h>

#include "InstanceTypes.h"
#include "ShaderUtils.h"
#include "MetalConstants.h"

using namespace metal;
using namespace cinder;
using namespace cinder::mtl;

using namespace metal;

vertex VertOut geom_vertex(device const GeomVertex* ciVerts [[ buffer(ciBufferIndexInterleavedVerts) ]],
                           device const uint* ciIndices [[ buffer(ciBufferIndexIndicies) ]],
                           device const Instance* instances [[ buffer(ciBufferIndexInstanceData) ]],
                           constant ciUniforms_t& ciUniforms [[ buffer(ciBufferIndexUniforms) ]],
                           unsigned int vid [[ vertex_id ]],
                           uint i [[ instance_id ]] )
{
    VertOut out;
    
    unsigned int vertIndex = ciIndices[vid];
    GeomVertex p = ciVerts[vertIndex];

    matrix_float4x4 modelMat = ciUniforms.ciModelMatrix * instances[i].modelMatrix;
    matrix_float4x4 mat = ciUniforms.ciViewProjection * modelMat;
    out.position = mat * float4(p.ciPosition, 1.0f);
    out.color = instances[i].color * ciUniforms.ciColor;
    out.texIndex = instances[i].textureSlice;
    
    return out;
}

vertex VertOut colored_vertex(device const ColoredVertex* ciVerts [[ buffer(ciBufferIndexInterleavedVerts) ]],
                              device const uint* ciIndices [[ buffer(ciBufferIndexIndicies) ]],
                              device const Instance* instances [[ buffer(ciBufferIndexInstanceData) ]],
                              constant ciUniforms_t& ciUniforms [[ buffer(ciBufferIndexUniforms) ]],
                              unsigned int vid [[ vertex_id ]],
                              uint i [[ instance_id ]] )
{
    VertOut out;
    
    unsigned int vertIndex = ciIndices[vid];
    ColoredVertex p = ciVerts[vertIndex];
    
    matrix_float4x4 modelMat = ciUniforms.ciModelMatrix * instances[i].modelMatrix;
    matrix_float4x4 mat = ciUniforms.ciViewProjection * modelMat;
    out.position = mat * float4(p.ciPosition, 1.0f);
    out.color = instances[i].color * ciUniforms.ciColor * p.ciColor;
    out.texIndex = instances[i].textureSlice;
    
    return out;
}

vertex VertOut billboard_rect_vertex(device const RectVertex* ciVerts [[ buffer(ciBufferIndexInterleavedVerts) ]],
                                     device const uint* ciIndices [[ buffer(ciBufferIndexIndicies) ]],
                                     device const Instance* instances [[ buffer(ciBufferIndexInstanceData) ]],
                                     constant ciUniforms_t& ciUniforms [[ buffer(ciBufferIndexUniforms) ]],
                                     unsigned int vid [[ vertex_id ]],
                                     uint i [[ instance_id ]] )
{
    VertOut out;
    
    unsigned int vertIndex = ciIndices[vid];
    RectVertex p = ciVerts[vertIndex];
    
    matrix_float4x4 modelMat = ciUniforms.ciModelMatrix * instances[i].modelMatrix;
    // Billboard the texture
    modelMat = modelMat * rotationMatrix(ciUniforms.ciViewMatrixInverse);
    
    matrix_float4x4 mat = ciUniforms.ciViewProjection * modelMat;
    out.position = mat * float4(p.ciPosition, 0.f, 1.0f);
    
    out.color = instances[i].color * ciUniforms.ciColor;
    
    float texWidth = instances[i].texCoordRect[2] - instances[i].texCoordRect[0];
    float texHeight = instances[i].texCoordRect[3] - instances[i].texCoordRect[1];
    float2 texCoord(p.ciTexCoord0);
    float2 instanceTexCoord(instances[i].texCoordRect[0] + texCoord.x * texWidth,
                            instances[i].texCoordRect[1] + texCoord.y * texHeight);
    out.texCoords = instanceTexCoord;
    out.texIndex = instances[i].textureSlice;
    
    return out;
}

vertex VertOut ring_vertex( device const GeomVertex* ciVerts [[ buffer(ciBufferIndexInterleavedVerts) ]],
                            device const uint* ciIndices [[ buffer(ciBufferIndexIndicies) ]],
                            device const Instance* instances [[ buffer(ciBufferIndexInstanceData) ]],
                            constant ciUniforms_t& ciUniforms [[ buffer(ciBufferIndexUniforms) ]],
                            constant float *innerRadius [[ buffer(ciBufferIndexCustom0) ]],
                            unsigned int vid [[ vertex_id ]],
                            uint i [[ instance_id ]] )
{
    VertOut out;
    
    unsigned int vertIndex = ciIndices[vid];
    GeomVertex p = ciVerts[vertIndex];

    matrix_float4x4 modelMat = ciUniforms.ciModelMatrix * instances[i].modelMatrix;
    matrix_float4x4 mat = ciUniforms.ciViewProjection * modelMat;
    
    float4 position = float4(p.ciPosition, 1.0f);
    
    // :-/ AMD RADEON R9! % 2 doesn't work
    int slice = vid / 2;
    if ( (vid / 2.0f) == slice )
    {
        position = float4(position.rgb * innerRadius[0], 1.0);
    }
    out.position = mat * position;
    
    out.color = instances[i].color * ciUniforms.ciColor;
    out.texIndex = instances[i].textureSlice;
    
    return out;
}

vertex VertOut billboard_ring_vertex( device const GeomVertex* ciVerts [[ buffer(ciBufferIndexInterleavedVerts) ]],
                                      device const uint* ciIndices [[ buffer(ciBufferIndexIndicies) ]],
                                      device const Instance* instances [[ buffer(ciBufferIndexInstanceData) ]],
                                      constant ciUniforms_t& ciUniforms [[ buffer(ciBufferIndexUniforms) ]],
                                      constant float *innerRadius [[ buffer(ciBufferIndexCustom0) ]],
                                      unsigned int vid [[ vertex_id ]],
                                      uint i [[ instance_id ]] )
{
    VertOut out;
    
    unsigned int vertIndex = ciIndices[vid];
    GeomVertex p = ciVerts[vertIndex];
    
    matrix_float4x4 modelMat = ciUniforms.ciModelMatrix * instances[i].modelMatrix;
    // Billboard the circle
    modelMat = modelMat * rotationMatrix(ciUniforms.ciViewMatrixInverse);
    matrix_float4x4 mat = ciUniforms.ciViewProjection * modelMat;
    
    float4 position = float4(p.ciPosition, 1.0f);
    
    // :-/ RADEON! % 2 doesn't work
    int slice = vid / 2;
    if ( (vid / 2.0f) == slice )
    {
        position = float4(position.rgb * innerRadius[0],1.0);
    }
    out.position = mat * position;
    
    out.color = instances[i].color * ciUniforms.ciColor;
    out.texIndex = instances[i].textureSlice;
    
    return out;
}

vertex VertOut wire_vertex(device const WireVertex* ciVerts [[ buffer(ciBufferIndexInterleavedVerts) ]],
                           device const uint* ciIndices [[ buffer(ciBufferIndexIndicies) ]],
                           constant ciUniforms_t& ciUniforms [[ buffer(ciBufferIndexUniforms) ]],
                           device const Instance* instances [[ buffer(ciBufferIndexInstanceData) ]],
                           unsigned int vid [[ vertex_id ]],
                           uint i [[ instance_id ]] )
{
    VertOut out;
    
    unsigned int vertIndex = ciIndices[vid];
    WireVertex p = ciVerts[vertIndex];

    matrix_float4x4 modelMat = ciUniforms.ciModelMatrix * instances[i].modelMatrix;
    matrix_float4x4 mat = ciUniforms.ciViewProjection * modelMat;
    out.position = mat * float4(p.ciPosition, 1.0f);
    
    out.color = instances[i].color * ciUniforms.ciColor;
    out.texIndex = instances[i].textureSlice;
    
    return out;
}

vertex VertOut rect_vertex(device const RectVertex* ciVerts [[ buffer(ciBufferIndexInterleavedVerts) ]],
                           device const uint* ciIndices [[ buffer(ciBufferIndexIndicies) ]],
                           constant ciUniforms_t& ciUniforms [[ buffer(ciBufferIndexUniforms) ]],
                           device const Instance* instances [[ buffer(ciBufferIndexInstanceData) ]],
                           unsigned int vid [[ vertex_id ]],
                           uint i [[ instance_id ]] )
{
    VertOut out;
    
    unsigned int vertIndex = ciIndices[vid];
    RectVertex p = ciVerts[vertIndex];
    //    out.position = ciUniforms.ciModelViewProjection * float4(p.ciPosition, 0.f, 1.0f);
    matrix_float4x4 modelMat = ciUniforms.ciModelMatrix * instances[i].modelMatrix;
    matrix_float4x4 mat = ciUniforms.ciViewProjection * modelMat;
    out.position = mat * float4(p.ciPosition, 0.f, 1.0f);
    
    out.color = instances[i].color * ciUniforms.ciColor;
    //    out.texCoords = p.ciTexCoord0;
    float texWidth = instances[i].texCoordRect[2] - instances[i].texCoordRect[0];
    float texHeight = instances[i].texCoordRect[3] - instances[i].texCoordRect[1];
    float2 texCoord(p.ciTexCoord0);
    float2 instanceTexCoord(instances[i].texCoordRect[0] + texCoord.x * texWidth,
                            instances[i].texCoordRect[1] + texCoord.y * texHeight);
    out.texCoords = instanceTexCoord;//p.ciTexCoord0;
    out.texIndex = instances[i].textureSlice;
    
    return out;
}

fragment float4 color_fragment( VertOut in [[stage_in]] )
{
    return in.color;
}

constexpr sampler shaderSampler( coord::normalized, // normalized (0-1) or coord::pixel (0-width,height)
                                address::repeat, // repeat, clamp_to_zero, clamp_to_edge,
                                filter::linear, // nearest or linear
                                mip_filter::linear ); // nearest or linear or none

fragment float4 texture_fragment( VertOut in [[ stage_in ]],
                                 texture2d<float> texture [[ texture(ciTextureIndex0) ]] )
{
    float4 texColor = texture.sample(shaderSampler, in.texCoords);
    return texColor * in.color;
}

fragment float4 texture_array_fragment( VertOut in [[ stage_in ]],
                                        texture2d_array<float> texture [[ texture(ciTextureIndex0) ]] )
{
    float4 texColor = texture.sample(shaderSampler, in.texCoords, in.texIndex);
    return texColor * in.color;
}
