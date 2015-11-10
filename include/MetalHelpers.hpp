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

glm::vec4 static inline fromMtl( vector_float4 vec )
{
    return *(glm::vec4 *)&vec;
}

vector_float3 static inline toMtl( glm::vec3 vec )
{
    return *(vector_float3 *)&vec;
}

glm::vec3 static inline fromMtl( vector_float3 vec )
{
    return *(glm::vec3 *)&vec;
}

vector_float2 static inline toMtl( glm::vec2 vec )
{
    return *(vector_float2 *)&vec;
}

glm::vec2 static inline fromMtl( vector_float2 vec )
{
    return *(glm::vec2 *)&vec;
}
