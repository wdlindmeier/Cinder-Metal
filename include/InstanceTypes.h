//
//  InstanceTypes.h
//  CascadeTimeline
//
//  Created by William Lindmeier on 2/27/16.
//
//

#ifndef InstanceTypes_h
#define InstanceTypes_h

#include <simd/simd.h>

//namespace cinder { namespace mtl {
    
    // TODO: Can we make these dynamically?
    typedef struct
    {
        metal::packed_float3 ciPosition;
        metal::packed_float3 ciNormal;
        metal::packed_float2 ciTexCoord0;
    } GeomVertex;

    typedef struct
    {
        metal::packed_float3 ciPosition;
        metal::packed_float3 ciNormal;
        metal::packed_float4 ciColor;
    } ColoredVertex;

    typedef struct
    {
        metal::packed_float3 ciPosition;
    } WireVertex;

    typedef struct
    {
        metal::packed_float2 ciPosition;
        metal::packed_float2 ciTexCoord0;
    } RectVertex;

    typedef struct Instance
    {
        float scale = 1.f;
        vector_float4 color = {1,1,1,1};
        vector_float3 position = {0,0,0};
        bool isTextured = false;
        int textureSlice = 0;
        vector_float4 texCoordRect = {0.f,0.f,1.f,1.f};
        // Storage for a few other bits and bobs
        float floats[5] = {0.f,0.f,0.f,0.f,0.f};
        int ints[5] = {0,0,0,0,0};
        matrix_float4x4 modelMatrix = {
            (vector_float4){1,0,0,0},
            (vector_float4){0,1,0,0},
            (vector_float4){0,0,1,0},
            (vector_float4){0,0,0,1}
        }; // Identity
    } Instance;
    
//}

#endif /* InstanceTypes_h */