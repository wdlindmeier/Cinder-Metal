//
//  MetalHelpers.hpp
//
//  Created by William Lindmeier on 11/4/15.
//
//

#pragma once

#include <simd/simd.h>
#include "glm/glm.hpp"

namespace cinder {

    // Conversions to simd types
    
    template <typename T, typename U >
    const U static inline convert( const T & t )
    {
        U tmp;
        memcpy(&tmp, &t, sizeof(U));
        U ret = tmp;
        return ret;
    }
    
    const matrix_float4x4 static inline toMtl( const glm::mat4 & mat )
    {
        return convert<glm::mat4, matrix_float4x4>(mat);
    }

    const glm::mat4 static inline fromMtl( const matrix_float4x4 & mat )
    {
        return convert<matrix_float4x4, glm::mat4>(mat);
    }

    const matrix_float3x3 static inline toMtl( const glm::mat3 & mat )
    {
        return convert<glm::mat3, matrix_float3x3>(mat);
    }

    const glm::mat3 static inline fromMtl( const matrix_float3x3 & mat )
    {
        return convert<matrix_float3x3, glm::mat3>(mat);
    }

    const vector_float4 static inline toMtl( const glm::vec4 & vec )
    {
        return convert<glm::vec4, vector_float4>(vec);
    }

    const vector_uint4 static inline toMtl( const glm::uvec4 & vec )
    {
        return convert<glm::uvec4, vector_uint4>(vec);
    }

    const vector_int4 static inline toMtl( const glm::ivec4 & vec )
    {
        return convert<glm::ivec4, vector_int4>(vec);
    }

    const glm::vec4 static inline fromMtl( const vector_float4 & vec )
    {
        return convert<vector_float4, glm::vec4>(vec);
    }

    const glm::uvec4 static inline fromMtl( const vector_uint4 & vec )
    {
        return convert<vector_uint4, glm::uvec4>(vec);
    }

    const glm::ivec4 static inline fromMtl( const vector_int4 & vec )
    {
        return convert<vector_int4, glm::ivec4>(vec);
    }

    const vector_uint3 static inline toMtl( const glm::uvec3 & vec )
    {
        return convert<glm::uvec3, vector_uint3>(vec);
    }

    const vector_int3 static inline toMtl( const glm::ivec3 & vec )
    {
        return convert<glm::ivec3, vector_int3>(vec);
    }

    const vector_float3 static inline toMtl( const glm::vec3 & vec )
    {
        return convert<glm::vec3, vector_float3>(vec);
    }

    const glm::vec3 static inline fromMtl( const vector_float3 & vec )
    {
        return convert<vector_float3, glm::vec3>(vec);
    }

    const glm::ivec3 static inline fromMtl( const vector_int3 & vec )
    {
        return convert<vector_int3, glm::ivec3>(vec);
    }

    const glm::uvec3 static inline fromMtl( const vector_uint3 & vec )
    {
        return convert<vector_uint3, glm::uvec3>(vec);
    }

    const vector_int2 static inline toMtl( const glm::ivec2 & vec )
    {
        return convert<glm::ivec2, vector_int2>(vec);
    }

    const vector_uint2 static inline toMtl( const glm::uvec2 & vec )
    {
        return convert<glm::uvec2, vector_uint2>(vec);
    }

    const vector_float2 static inline toMtl( const glm::vec2 & vec )
    {
        return convert<glm::vec2, vector_float2>(vec);
    }

    const glm::vec2 static inline fromMtl( const vector_float2 & vec )
    {
        return convert<vector_float2, glm::vec2>(vec);
    }

    const glm::uvec2 static inline fromMtl( const vector_uint2 & vec )
    {
        return convert<vector_uint2, glm::uvec2>(vec);
    }

    const glm::ivec2 static inline fromMtl( const vector_int2 & vec )
    {
        return convert<vector_int2, glm::ivec2>(vec);
    }
    
    const vector_float4 static inline toMtl( const ci::ColorAf & color )
    {
        return {color.r,color.g,color.b,color.a};
    }
    
    const vector_float3 static inline toMtl( const ci::Color & color )
    {
        return {color.r,color.g,color.b};
    }

}

namespace metal
{
    // Map metal shader types to glm types so we can use shared structs between shaders and the app
    typedef ci::vec4 packed_float4;
    typedef ci::vec3 packed_float3;
    typedef ci::vec2 packed_float2;
}

// For buffers in the constant address space, the offset must be aligned to 256 bytes in OS X.
// In iOS, the offset must be aligned to the maximum of either the data type consumed by the vertex
// shader function, or 4 bytes. A 16-byte alignment is always safe in iOS if you do not need to
// worry about the data type.

// mtlConstantBufferSize takes a number
#if defined( CINDER_COCOA_TOUCH )
#define mtlConstantBufferSize(num) size_t(16 * ceil(num / 16.0f))
#else
#define mtlConstantBufferSize(num) size_t(256 * ceil(num / 256.0f))
#endif

// mtlConstantSizeOf takes a type
#if defined( CINDER_COCOA_TOUCH )
#define mtlConstantSizeOf(T) mtlConstantBufferSize(sizeof(T))
#else
#define mtlConstantSizeOf(T) mtlConstantBufferSize(sizeof(T))
#endif
