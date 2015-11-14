//
//  SharedData.h
//  ParticleSorting
//
//  Created by William Lindmeier on 11/13/15.
//
//

#pragma once

#include "MetalConstants.h"

#define kParticleDimension 32

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