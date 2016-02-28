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
    matrix_float4x4 mat = ciUniforms.ciProjectionMatrix * ciUniforms.ciViewMatrix * modelMat;
    out.position = mat * float4(p.ciPosition, 1.0f);
    out.color = instances[i].color * ciUniforms.ciColor;
    
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
    matrix_float4x4 mat = ciUniforms.ciProjectionMatrix * ciUniforms.ciViewMatrix * modelMat;
    out.position = mat * float4(p.ciPosition, 1.0f);
    out.color = instances[i].color * ciUniforms.ciColor * p.ciColor;
    
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
    
    matrix_float4x4 mat = ciUniforms.ciProjectionMatrix * ciUniforms.ciViewMatrix * modelMat;
    out.position = mat * float4(p.ciPosition, 0.f, 1.0f);
    
    out.color = instances[i].color * ciUniforms.ciColor;
    
    float texWidth = instances[i].texCoordRect[2] - instances[i].texCoordRect[0];
    float texHeight = instances[i].texCoordRect[3] - instances[i].texCoordRect[1];
    float2 texCoord(p.ciTexCoord0);
    float2 instanceTexCoord(instances[i].texCoordRect[0] + texCoord.x * texWidth,
                            instances[i].texCoordRect[1] + texCoord.y * texHeight);
    out.texCoords = instanceTexCoord;
    
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
    matrix_float4x4 mat = ciUniforms.ciProjectionMatrix * ciUniforms.ciViewMatrix * modelMat;
    
    float4 position = float4(p.ciPosition, 1.0f);
    
    // :-/ AMD RADEON R9! % 2 doesn't work
    int slice = vid / 2;
    if ( (vid / 2.0f) == slice )
    {
        position = float4(position.rgb * innerRadius[0], 1.0);
    }
    out.position = mat * position;
    
    out.color = instances[i].color * ciUniforms.ciColor;
    
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
    matrix_float4x4 mat = ciUniforms.ciProjectionMatrix * ciUniforms.ciViewMatrix * modelMat;
    
    float4 position = float4(p.ciPosition, 1.0f);
    
    // :-/ RADEON! % 2 doesn't work
    int slice = vid / 2;
    if ( (vid / 2.0f) == slice )
    {
        position = float4(position.rgb * innerRadius[0],1.0);
    }
    out.position = mat * position;
    
    out.color = instances[i].color * ciUniforms.ciColor;

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
    matrix_float4x4 mat = ciUniforms.ciProjectionMatrix * ciUniforms.ciViewMatrix * modelMat;
    out.position = mat * float4(p.ciPosition, 1.0f);
    
    out.color = instances[i].color * ciUniforms.ciColor;
    
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
    matrix_float4x4 mat = ciUniforms.ciProjectionMatrix * ciUniforms.ciViewMatrix * modelMat;
    out.position = mat * float4(p.ciPosition, 0.f, 1.0f);
    
    out.color = instances[i].color * ciUniforms.ciColor;
    //    out.texCoords = p.ciTexCoord0;
    float texWidth = instances[i].texCoordRect[2] - instances[i].texCoordRect[0];
    float texHeight = instances[i].texCoordRect[3] - instances[i].texCoordRect[1];
    float2 texCoord(p.ciTexCoord0);
    float2 instanceTexCoord(instances[i].texCoordRect[0] + texCoord.x * texWidth,
                            instances[i].texCoordRect[1] + texCoord.y * texHeight);
    out.texCoords = instanceTexCoord;//p.ciTexCoord0;
    
    
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

fragment float4 texture_fragment_indexed( VertOut in [[ stage_in ]],
                                         texture2d<float> texture0 [[ texture(100) ]],
                                         texture2d<float> texture1 [[ texture(101) ]],
                                         texture2d<float> texture2 [[ texture(102) ]],
                                         texture2d<float> texture3 [[ texture(103) ]],
                                         texture2d<float> texture4 [[ texture(104) ]],
                                         texture2d<float> texture5 [[ texture(105) ]],
                                         texture2d<float> texture6 [[ texture(106) ]],
                                         texture2d<float> texture7 [[ texture(107) ]],
                                         texture2d<float> texture8 [[ texture(108) ]],
                                         texture2d<float> texture9 [[ texture(109) ]],
                                         texture2d<float> texture10 [[ texture(110) ]],
                                         texture2d<float> texture11 [[ texture(111) ]],
                                         texture2d<float> texture12 [[ texture(112) ]],
                                         texture2d<float> texture13 [[ texture(113) ]],
                                         texture2d<float> texture14 [[ texture(114) ]],
                                         texture2d<float> texture15 [[ texture(115) ]],
                                         texture2d<float> texture16 [[ texture(116) ]],
                                         texture2d<float> texture17 [[ texture(117) ]],
                                         texture2d<float> texture18 [[ texture(118) ]],
                                         texture2d<float> texture19 [[ texture(119) ]]
                                         )
{
    float4 texColor;
    switch ( in.texIndex )
    {
        case 0:
            texColor = texture0.sample(shaderSampler, in.texCoords);
            break;
        case 1:
            texColor = texture1.sample(shaderSampler, in.texCoords);
            break;
        case 2:
            texColor = texture2.sample(shaderSampler, in.texCoords);
            break;
        case 3:
            texColor = texture3.sample(shaderSampler, in.texCoords);
            break;
        case 4:
            texColor = texture4.sample(shaderSampler, in.texCoords);
            break;
        case 5:
            texColor = texture5.sample(shaderSampler, in.texCoords);
            break;
        case 6:
            texColor = texture6.sample(shaderSampler, in.texCoords);
            break;
        case 7:
            texColor = texture7.sample(shaderSampler, in.texCoords);
            break;
        case 8:
            texColor = texture8.sample(shaderSampler, in.texCoords);
            break;
        case 9:
            texColor = texture9.sample(shaderSampler, in.texCoords);
            break;
        case 10:
            texColor = texture10.sample(shaderSampler, in.texCoords);
            break;
        case 11:
            texColor = texture11.sample(shaderSampler, in.texCoords);
            break;
        case 12:
            texColor = texture12.sample(shaderSampler, in.texCoords);
            break;
        case 13:
            texColor = texture13.sample(shaderSampler, in.texCoords);
            break;
        case 14:
            texColor = texture14.sample(shaderSampler, in.texCoords);
            break;
        case 15:
            texColor = texture15.sample(shaderSampler, in.texCoords);
            break;
        case 16:
            texColor = texture16.sample(shaderSampler, in.texCoords);
            break;
        case 17:
            texColor = texture17.sample(shaderSampler, in.texCoords);
            break;
        case 18:
            texColor = texture18.sample(shaderSampler, in.texCoords);
            break;
        case 19:
            texColor = texture19.sample(shaderSampler, in.texCoords);
            break;
            
    }
    return texColor * in.color;
}
