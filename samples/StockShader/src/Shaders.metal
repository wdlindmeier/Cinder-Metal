//
//  Shaders.metal
//  MetalTemplate
//
//  Created by William Lindmeier on 11/26/15.
//
//

//#include <metal_stdlib>
//#include <simd/simd.h>
//
//#include "SharedTypes.h"
//#include "ShaderUtils.h"
//#include "MetalConstants.h"
//#include "InstanceTypes.h"
//
//using namespace metal;
//using namespace cinder;
//using namespace cinder::mtl;

#include <metal_stdlib>
#include <simd/simd.h>
#include "/Users/bill/Tools/cinder_master/blocks/Cinder-Metal/include/InstanceTypes.h"
#include "ShaderUtils.h"
#include "MetalConstants.h"
using namespace metal;
using namespace cinder;
using namespace cinder::mtl;

vertex ciVertOut_t _generated_vert(device const ciVertex_t* ciVerts [[ buffer(ciBufferIndexInterleavedVerts) ]],
                                     device const uint* ciIndices [[ buffer(ciBufferIndexIndicies) ]],
                                     device const Instance* instances [[ buffer(ciBufferIndexInstanceData) ]],
                                     constant ciUniforms_t& ciUniforms [[ buffer(ciBufferIndexUniforms) ]],
                                     unsigned int vid [[ vertex_id ]],
                                     uint i [[ instance_id ]] )
{
    ciVertOut_t out;
    unsigned int vertIndex = ciIndices[vid];
    ciVertex_t v = ciVerts[vertIndex];
    matrix_float4x4 modelMat = ciUniforms.ciModelMatrix * instances[i].modelMatrix;
    matrix_float4x4 mat = ciUniforms.ciViewProjection * modelMat;
    float4 pos = float4(v.ciPosition, 1.0f);
    out.position = mat * pos;
    out.color = instances[i].color * ciUniforms.ciColor * v.ciColor;
    float texWidth = instances[i].texCoordRect[2] - instances[i].texCoordRect[0];
    float texHeight = instances[i].texCoordRect[3] - instances[i].texCoordRect[1];
    float2 texCoord(v.ciTexCoord0);
    float2 instanceTexCoord(instances[i].texCoordRect[0] + texCoord.x * texWidth,
                            instances[i].texCoordRect[1] + texCoord.y * texHeight);
    out.texCoords = instanceTexCoord;
    out.normal = ciUniforms.ciNormalMatrix * float3(v.ciNormal);
    out.pointSize = instances[i].scale;
    out.texIndex = instances[i].textureSlice;
    return out;
}

fragment float4 _generated_frag( ciVertOut_t in [[ stage_in ]] )
{
    float4 oColor = in.color;
    return oColor;
}

