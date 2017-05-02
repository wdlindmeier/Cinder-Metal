//
//  Shaders.metal
//  MetalBasic
//
//  Created by William Lindmeier on 10/11/15.
//

#include <metal_stdlib>
#include <simd/simd.h>
#include "MetalConstants.h"
#include "SharedData.h"

using namespace metal;
using namespace cinder::mtl;

typedef struct
{
    float4 position [[position]];
    float pointSize [[point_size]];
    float4 color;
    float2 texCoords;
} ColorInOut;

typedef struct
{
    packed_float3 position;
    packed_float3 velocity;
} Particle;

// Convert the indices into the sortable values (0 .. large num)
float4 indexSortKeys( const int4 indices,
                     constant float* inParticleDepths);
float4 indexSortKeys( const int4 indices,
                     constant float* inParticleDepths)
{
    return float4(inParticleDepths[indices[0]],
                  inParticleDepths[indices[1]],
                  inParticleDepths[indices[2]],
                  inParticleDepths[indices[3]]);
}

int4 vecMask( int4 leftValues, int4 rightValues, bool4 mask );
int4 vecMask( int4 leftValues, int4 rightValues, bool4 mask )
{
    int4 newValues(0);
    for ( int i = 0; i < 4; ++i )
    {
        newValues[i] = mask[i] ? leftValues[i] : rightValues[i];
    }
    return newValues;
}

float4 vecMask( float4 leftValues, float4 rightValues, bool4 mask );
float4 vecMask( float4 leftValues, float4 rightValues, bool4 mask )
{
    float4 newValues(0);
    for ( int i = 0; i < 4; ++i )
    {
        newValues[i] = mask[i] ? leftValues[i] : rightValues[i];
    }
    return newValues;
}

// Creates a < mask of 4 vectors, and uses the indices as a secondary sort if the values are the same.
// This guarantees that every value will have a definitive < or > relationship, even if they're ==,
// which is necessary when using a bitonic sort, otherwise it's possible to lose particles.
// This assumes that the indices are unique.
bool4 ltMask( float4 leftValues, float4 rightValues,
              int4 leftIndices, int4 rightIndices );
bool4 ltMask( float4 leftValues, float4 rightValues,
              int4 leftIndices, int4 rightIndices )
{
    bool4 ret(false);
    
    for ( int i = 0; i < 4; ++i )
    {
        if ( leftValues[i] < rightValues[i] )
        {
            ret[i] = true;
        }
        else if ( leftValues[i] == rightValues[i] )
        {
            ret[i] = leftIndices[i] < rightIndices[i];
        }
    }
    return ret;
}

// An extremely simple sort to demonstrate the compute pipeline.
// This is not efficient.
kernel void kernel_sort(device const Particle* inPositions [[ buffer(1) ]],
                        device Particle* outPositions [[ buffer(2) ]],
                        constant myUniforms_t& uniforms [[ buffer(ciBufferIndexUniforms) ]],
                        uint2 global_thread_position [[thread_position_in_grid]],
                        uint local_index [[thread_index_in_threadgroup]],
                        uint2 groups_per_grid [[ threadgroups_per_grid ]],
                        uint2 group_thread_size [[ threads_per_threadgroup ]],
                        uint2 grid_thread_count [[ threads_per_grid ]],
                        uint2 group_position [[ threadgroup_position_in_grid ]] )
{
    uint index = global_thread_position[0];
    Particle p = inPositions[index];
    float4 viewPosition = uniforms.modelMatrix * float4(p.position, 0.0f);
    float viewZ = viewPosition[2];
    int numBefore = 0;
    for ( uint i = 0; i < uniforms.numParticles; ++i )
    {
        if ( i != index )
        {
            Particle otherP = inPositions[i];
            float4 otherViewPosition = uniforms.modelMatrix * float4(otherP.position, 0.0f);
            float otherViewZ = otherViewPosition[2];
            if ( otherViewZ > viewZ )
            {
                numBefore += 1;
            }
        }
    }
    Particle prevP = outPositions[numBefore];
    outPositions[numBefore] = p;
}

kernel void calculate_particle_depths( constant myUniforms_t& uniforms [[ buffer(ciBufferIndexUniforms) ]],
                                       device float * particleDepths [[ buffer(1) ]],
                                       device const Particle * particles [[ buffer(2) ]],
                                       uint2 global_thread_position [[thread_position_in_grid]],
                                       uint local_index [[thread_index_in_threadgroup]],
                                       uint2 groups_per_grid [[ threadgroups_per_grid ]],
                                       uint2 group_thread_size [[ threads_per_threadgroup ]],
                                       uint2 grid_thread_count [[ threads_per_grid ]],
                                       uint2 group_position [[ threadgroup_position_in_grid ]] )
{
    uint i = global_thread_position[0];
    Particle p = particles[i];
    float4 position = uniforms.modelMatrix * float4(p.position, 0.0f);
    particleDepths[i] = position.z;
}

// A bitonic sort of indices based on value (e.g. depth of particle)
// Based on https://software.intel.com/en-us/articles/bitonic-sorting

kernel void bitonic_sort_by_value( constant myUniforms_t& uniforms [[ buffer(ciBufferIndexUniforms) ]],
                                   device int4 * particleIndices [[ buffer(1) ]],
                                   constant float * particleDepths [[ buffer(2) ]],
                                   constant sortState_t& sortState [[ buffer(3) ]],
                                   uint2 global_thread_position [[thread_position_in_grid]],
                                   uint local_index [[thread_index_in_threadgroup]],
                                   uint2 groups_per_grid [[ threadgroups_per_grid ]],
                                   uint2 group_thread_size [[ threads_per_threadgroup ]],
                                   uint2 grid_thread_count [[ threads_per_grid ]],
                                   uint2 group_position [[ threadgroup_position_in_grid ]] )
{
    uint stage = sortState.stage;
    uint passOfStage = sortState.pass;
    int dir = sortState.direction;
    uint i = global_thread_position[0];
    
    int4 srcLeft, srcRight;
    float4 valuesLeft, valuesRight;
    bool4 mask;
    bool4 imask10 = (bool4)(0, 0, 1, 1);
    bool4 imask11 = (bool4)(0, 1, 0, 1);
    
    if( stage > 0 )
    {
        // upper level pass, exchange between two fours
        if( passOfStage > 0 )
        {
            uint r = 1 << (passOfStage - 1);
            uint lmask = r - 1;
            uint left = ((i>>(passOfStage-1)) << passOfStage) + (i & lmask);
            uint right = left + r;
            
            srcLeft = particleIndices[left];
            srcRight = particleIndices[right];
            
            valuesLeft = indexSortKeys( srcLeft, particleDepths );
            valuesRight = indexSortKeys( srcRight, particleDepths );

            mask = ltMask(valuesLeft, valuesRight, srcLeft, srcRight);
            
            int4 imin = vecMask(srcLeft, srcRight, mask);
            
            int4 imax = vecMask(srcLeft, srcRight, ~mask);

            if( ( (i>>(stage-1)) & 1) ^ dir )
            {
                particleIndices[left]  = imax;
                particleIndices[right] = imin;
            }
            else
            {
                particleIndices[right] = imax;
                particleIndices[left]  = imin;
            }
        }
        
        // last pass, sort inside one four
        else
        {
            srcLeft = particleIndices[i];
            valuesLeft = indexSortKeys( srcLeft, particleDepths );
            srcRight = srcLeft.zwxy;
            valuesRight = valuesLeft.zwxy;
            
            mask = ltMask(valuesLeft, valuesRight, srcLeft, srcRight) ^ imask10;
            
            if ( ( (i >> stage) & 1) ^ dir )
            {
                srcLeft = vecMask(srcLeft, srcRight, ~mask);
                valuesLeft = vecMask(valuesLeft, valuesRight, ~mask);
                srcRight = srcLeft.yxwz;
                valuesRight = valuesLeft.yxwz;

                mask = ltMask(valuesLeft, valuesRight, srcLeft, srcRight) ^ imask11;

                particleIndices[i] = vecMask(srcLeft, srcRight, ~mask);
            }
            else
            {
                srcLeft = vecMask(srcLeft, srcRight, mask);
                valuesLeft = vecMask(valuesLeft, valuesRight, mask);
                srcRight = srcLeft.yxwz;
                valuesRight = valuesLeft.yxwz;
                mask = ltMask(valuesLeft, valuesRight, srcLeft, srcRight) ^ imask11;

                particleIndices[i] = vecMask(srcLeft, srcRight, mask);
            }
        }
    }
    else    // first stage, sort inside one four
    {
        bool4 imask0 = (bool4)(0, 1, 1,  0);
        
        srcLeft = particleIndices[i];
        srcRight = srcLeft.yxwz;
        valuesLeft = indexSortKeys( srcLeft, particleDepths );
        valuesRight = valuesLeft.yxwz;
        
        mask = ltMask(valuesLeft, valuesRight, srcLeft, srcRight) ^ imask0;
        
        if ( dir )
        {
            srcLeft = vecMask(srcLeft, srcRight, mask);
            valuesLeft = vecMask(valuesLeft, valuesRight, mask);
        }
        else
        {
            srcLeft = vecMask(srcLeft, srcRight, ~mask);
            valuesLeft = vecMask(valuesLeft, valuesRight, ~mask);
        }
        
        srcRight = srcLeft.zwxy;
        valuesRight = valuesLeft.zwxy;
        
        mask = ltMask(valuesLeft, valuesRight, srcLeft, srcRight) ^ imask10;
        
        if( (i & 1) ^ dir )
        {
            srcLeft = vecMask(srcLeft, srcRight, mask);
            valuesLeft = vecMask(valuesLeft, valuesRight, mask);

            srcRight = srcLeft.yxwz;
            valuesRight = valuesLeft.yxwz;

            mask = ltMask(valuesLeft, valuesRight, srcLeft, srcRight) ^ imask11;

            particleIndices[i] = vecMask(srcLeft, srcRight, mask);
        }
        else
        {
            srcLeft = vecMask(srcLeft, srcRight, ~mask);
            valuesLeft = vecMask(valuesLeft, valuesRight, ~mask);
            srcRight = srcLeft.yxwz;
            valuesRight = valuesLeft.yxwz;

            mask = ltMask(valuesLeft, valuesRight, srcLeft, srcRight) ^ imask11;

            particleIndices[i] = vecMask(srcLeft, srcRight, ~mask);
        }
    }
}

vertex ColorInOut vertex_particles( device const Particle * particles [[ buffer(ciBufferIndexInterleavedVerts) ]],
                                    device const int4 * indices [[ buffer(ciBufferIndexIndices) ]],
                                    constant myUniforms_t& uniforms [[ buffer(ciBufferIndexUniforms) ]],
                                    unsigned int vid [[ vertex_id ]] )
{
    ColorInOut out;
    
    int sortedIndex = indices[vid / 4][vid % 4];
    Particle p = particles[sortedIndex];
    
    float4 in_position = float4(p.position, 1.0f);
    out.position = uniforms.modelViewProjectionMatrix * in_position;
    
    out.pointSize = 20.f;
    
    float4 viewPosition = uniforms.modelMatrix * in_position;
    float scalarZ = (1.0 + viewPosition[2]) / 2.f;
    if ( p.velocity[1] == 1 )
    {
        out.color = float4(1.0,0,0,1.0);
    }
    else
    {
        out.color = float4(1.0-scalarZ,
                           1.0-scalarZ,
                           1.0-scalarZ,
                           0.5f);
    }
    
    return out;
}

// NOTE: samplers defined in the shader don't appear to have an anisotropy param
constexpr sampler shaderSampler(coord::normalized, // normalized (0-1) or coord::pixel (0-width,height)
                                address::repeat, // repeat, clamp_to_zero, clamp_to_edge,
                                filter::linear, // nearest or linear
                                mip_filter::linear ); // nearest or linear or none

fragment float4 fragment_point_texture( ColorInOut in [[stage_in]],
                                        texture2d<float> textureParticle [[ texture(ciTextureIndex0) ]],
                                        float2 pointTexCoord [[ point_coord ]] )
{
    float4 texColor = textureParticle.sample(shaderSampler, pointTexCoord);
    float4 inColor = in.color;
    inColor[3] *= texColor[3];
    return inColor;
}


