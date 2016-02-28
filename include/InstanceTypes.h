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

    typedef struct
    {
        float scale;
        vector_float4 color;
        vector_float3 position;
        bool isTextured;
        vector_float4 texCoordRect = {0.f,0.f,1.f,1.f};
        float floats[10] = {0.f,0.f,0.f,0.f,0.f,0.f,0.f,0.f,0.f,0.f};
        int ints[10] = {0,0,0,0,0,0,0,0,0,0};
        matrix_float4x4 modelMatrix;
    } Instance;
    
//}

#endif /* InstanceTypes_h */