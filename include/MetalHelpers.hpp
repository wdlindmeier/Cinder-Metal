//
//  MetalHelpers.hpp
//  MetalCube
//
//  Created by William Lindmeier on 11/4/15.
//
//

#pragma once

#include <simd/simd.h>
#include "glm/glm.hpp"

#define FORMAT_OPTION(NAME, CAP_NAME, TYPE) \
    protected: \
        TYPE m##CAP_NAME; \
    public: \
        Format& NAME( TYPE NAME ) { set##CAP_NAME( NAME ); return *this; }; \
        void set##CAP_NAME( TYPE NAME ) { m##CAP_NAME = NAME; }; \
        TYPE get##CAP_NAME() { return m##CAP_NAME; }; \

// Conversions to simd types

matrix_float4x4 static inline toMtl( glm::mat4 mat )
{
    return *(matrix_float4x4 *)&mat;
}

glm::mat4 static inline fromMtl( matrix_float4x4 mat )
{
    return *(glm::mat4 *)&mat;
}

matrix_float3x3 static inline toMtl( glm::mat3 mat )
{
    return *(matrix_float3x3 *)&mat;
}

glm::mat3 static inline fromMtl( matrix_float3x3 mat )
{
    return *(glm::mat3 *)&mat;
}

vector_float4 static inline toMtl( glm::vec4 vec )
{
    return *(vector_float4 *)&vec;
}

vector_uint4 static inline toMtl( glm::uvec4 vec )
{
    return *(vector_uint4 *)&vec;
}

vector_int4 static inline toMtl( glm::ivec4 vec )
{
    return *(vector_int4 *)&vec;
}

glm::vec4 static inline fromMtl( vector_float4 vec )
{
    return *(glm::vec4 *)&vec;
}

glm::uvec4 static inline fromMtl( vector_uint4 vec )
{
    return *(glm::uvec4 *)&vec;
}

glm::ivec4 static inline fromMtl( vector_int4 vec )
{
    return *(glm::ivec4 *)&vec;
}

vector_uint3 static inline toMtl( glm::uvec3 vec )
{
    return *(vector_uint3 *)&vec;
}

vector_int3 static inline toMtl( glm::ivec3 vec )
{
    return *(vector_int3 *)&vec;
}

vector_float3 static inline toMtl( glm::vec3 vec )
{
    return *(vector_float3 *)&vec;
}

glm::vec3 static inline fromMtl( vector_float3 vec )
{
    return *(glm::vec3 *)&vec;
}

glm::ivec3 static inline fromMtl( vector_int3 vec )
{
    return *(glm::ivec3 *)&vec;
}

glm::uvec3 static inline fromMtl( vector_uint3 vec )
{
    return *(glm::uvec3 *)&vec;
}

vector_int2 static inline toMtl( glm::ivec2 vec )
{
    return *(vector_int2 *)&vec;
}

vector_uint2 static inline toMtl( glm::uvec2 vec )
{
    return *(vector_uint2 *)&vec;
}

vector_float2 static inline toMtl( glm::vec2 vec )
{
    return *(vector_float2 *)&vec;
}

glm::vec2 static inline fromMtl( vector_float2 vec )
{
    return *(glm::vec2 *)&vec;
}

glm::uvec2 static inline fromMtl( vector_uint2 vec )
{
    return *(glm::uvec2 *)&vec;
}

glm::ivec2 static inline fromMtl( vector_int2 vec )
{
    return *(glm::ivec2 *)&vec;
}

