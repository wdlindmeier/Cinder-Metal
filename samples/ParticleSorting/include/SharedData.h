//
//  SharedData.h
//  ParticleSorting
//
//  Created by William Lindmeier on 11/13/15.
//
//

#pragma once

#include "MetalConstants.h"

#define kParticleDimension 32 // 1024 particles. should be a power of 2

struct sortState_t
{
    unsigned int direction = 1;
    unsigned int stage = 0;
    unsigned int pass = 0;
};

struct myUniforms_t
{
    unsigned int numParticles = kParticleDimension * kParticleDimension;
    matrix_float4x4 projectionMatrix;
    matrix_float4x4 viewMatrix;
    matrix_float4x4 modelMatrix;
    matrix_float4x4 inverseModelMatrix;
    matrix_float4x4 modelViewMatrix;
    matrix_float4x4 modelViewProjectionMatrix;
    matrix_float4x4 normalMatrix;
    matrix_float4x4 inverseViewMatrix;
};