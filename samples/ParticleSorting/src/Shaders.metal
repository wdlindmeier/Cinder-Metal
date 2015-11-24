//
//  Shaders.metal
//  MetalBasic
//
//  Created by William Lindmeier on 10/11/15.
//  Copyright (c) 2015 wdlindmeier. All rights reserved.
//

#include <metal_stdlib>
#include <simd/simd.h>
#include "MetalConstants.h"
#include "SharedData.h"

using namespace metal;

// Variables in constant address space
constant float3 light_position = float3(0.0, 1.0, -1.0);
constant float4 ambient_color  = float4(0.18, 0.24, 0.8, 1.0);
constant float4 diffuse_color  = float4(0.4, 0.4, 1.0, 1.0);

typedef struct
{
    packed_float3 position;
    packed_float3 normal;
} vertex_t;

typedef struct {
    float4 position [[position]];
    float pointSize [[point_size]];
    float4 color;
    float2 texCoords;
} ColorInOut;

typedef struct {
    packed_float3 position;
    packed_float3 velocity;
} Particle;

// An extremely simple sort to demonstrate the compute pipeline
kernel void kernel_sort(const device Particle* inPositions [[ buffer(1) ]],
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

constant float minDepth = -1.f;
constant float maxDepth = 1.f;
int keyForDepth( float depth );
int keyForDepth( float depth )
{
    // NOTE: This might have to be re-jiggered if we get into signedness issues
    return ((depth - minDepth) / (maxDepth - minDepth)) * 65535.0;
}

int4 indexSortKeys( int4 indices,
                    const device Particle* inParticles,
                    constant myUniforms_t& uniforms );
int4 indexSortKeys( int4 indices,
                    const device Particle* inParticles,
                    constant myUniforms_t& uniforms )
{
    int4 depths;//(0);
    // Convert the indices into the sortable values (0 .. large num)
    for ( int a = 0; a < 4; ++a )
    {
        int index = indices[a];
        Particle p = inParticles[index];
        float4 position = float4(p.position, 0.0f);
        depths[a] = keyForDepth(position.z);
    }
    return depths;
}

// Bitwise operators
// https://www.bignerdranch.com/blog/smooth-bitwise-operator/

int4 valueMask( int4 leftValues, int4 rightValues, bool4 mask )
{
    int4 newValues(0);
    for ( int i = 0; i < 4; ++i )
    {
        newValues[i] = mask[i] ? leftValues[i] : rightValues[i];
    }
    return newValues;
}

kernel void debug_sort( const device uint& sortStage [[ buffer(5) ]],
                        const device uint& sortPass [[ buffer(6) ]],
                        device uint * randValues [[ buffer(1) ]],
                        device debugInfo_t * debugInfo [[ buffer(4) ]],
                        constant sortState_t& sortState [[ buffer(3) ]],
                        constant myUniforms_t& uniforms [[ buffer(ciBufferIndexUniforms) ]],
                        uint2 global_thread_position [[thread_position_in_grid]],
                        uint local_index [[thread_index_in_threadgroup]],
                        uint2 groups_per_grid [[ threadgroups_per_grid ]],
                        uint2 group_thread_size [[ threads_per_threadgroup ]],
                        uint2 grid_thread_count [[ threads_per_grid ]],
                        uint2 group_position [[ threadgroup_position_in_grid ]] )
{
    uint stage = sortState.stage; // sortStage
    uint pass = sortState.pass; // sortPass
    
    debugInfo->completedStages[stage] = 1;
    debugInfo->completedPasses[pass] = 1;
    
    if ( debugInfo->previousStage[stage] == 999 )
    {
        // NOTE: We'll hit this point multiple times during the same stage,
        // so we only want to do it once.
        debugInfo->previousStage[stage] = debugInfo->lastStage;
    }
    debugInfo->previousPass[pass] = debugInfo->lastPass;
    debugInfo->lastStage = stage;
    debugInfo->lastPass = pass;
    debugInfo->numTimesAccessed += 1; // NOTE: this ends up being 1-per-dispatch
}

kernel void simple_sort( device uint * randValues [[ buffer(1) ]],
                       device debugInfo_t * debugInfo [[ buffer(4) ]],
                       constant sortState_t& sortState [[ buffer(3) ]],
                       constant myUniforms_t& uniforms [[ buffer(ciBufferIndexUniforms) ]],
                       uint2 global_thread_position [[thread_position_in_grid]],
                       uint local_index [[thread_index_in_threadgroup]],
                       uint2 groups_per_grid [[ threadgroups_per_grid ]],
                       uint2 group_thread_size [[ threads_per_threadgroup ]],
                       uint2 grid_thread_count [[ threads_per_grid ]],
                       uint2 group_position [[ threadgroup_position_in_grid ]] )
{
    uint stage = sortState.stage; // sortStage
    uint pass = sortState.pass; // sortPass
    uint passNum = sortState.passNum;
    uint threadI = global_thread_position[0];
    uint iA = threadI * 2;
//    bool isEven passNum % 2 == 0;
    iA += passNum % 2;
    uint iB = iA + 1;
    
    if ( iB >= uniforms.numParticles )
    {
        return;
    }
    
    // Compare
    uint valA = randValues[iA];
    uint valB = randValues[iB];
    
    // Swap
    if ( valA > valB )
    {
        randValues[iB] = valA;
        randValues[iA] = valB;
    }
//    else
//    {
//        randValues[iB] = valB;
//        randValues[iA] = valA;
//    }

    debugInfo->lastStage = stage;
    debugInfo->lastPass = pass;
    debugInfo->numTimesAccessed += 1; // NOTE: this ends up being 1-per-dispatch
}

kernel void simple_bitonic_sort( device int4 * randValues [[ buffer(1) ]],
                                 device debugInfo_t * debugInfo [[ buffer(4) ]],
                                 constant sortState_t& sortState [[ buffer(3) ]],
                                 constant myUniforms_t& uniforms [[ buffer(ciBufferIndexUniforms) ]],
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
    bool4 mask;
    bool4 imask10 = (bool4)(0, 0, 1, 1);
    bool4 imask11 = (bool4)(0, 1, 0, 1);
    
    srcLeft = randValues[i];
    srcRight = srcLeft.zwxy;
    
    if( stage > 0 )
    {
        // upper level pass, exchange between two fours
        if( passOfStage > 0 )
        {
            uint r = 1 << (passOfStage - 1);
            uint lmask = r - 1;
            uint left = ((i>>(passOfStage-1)) << passOfStage) + (i & lmask);
            uint right = left + r;
            
            srcLeft = randValues[left];
            srcRight = randValues[right];

            //            mask = (srcLeft < srcRight);
            mask = (srcLeft < srcRight);
            
            //            int4 imin = (leftValues & mask) | (rightValues & ~mask);
            int4 imin = valueMask(srcLeft, srcRight, ~mask);
            
            //            int4 imax = (leftValues & ~mask) | (rightValues & mask);
            int4 imax = valueMask(srcLeft, srcRight, mask);
            
            if( ( (i>>(stage-1)) & 1) ^ dir )
            {
                // theArray[left]  = imin;
                randValues[left]  = imin;
                // theArray[right] = imax;
                randValues[right] = imax;
            }
            else
            {
                // theArray[right] = imin;
                randValues[right] = imin;
                // theArray[left]  = imax;
                randValues[left]  = imax;
            }
        }
        
        // last pass, sort inside one four
        else
        {
            
            //srcLeft = theArray[i];
            srcLeft = randValues[i];
            
            //srcRight = srcLeft.zwxy;
            srcRight = srcLeft.zwxy;
            
            //mask = (srcLeft < srcRight) ^ imask10;
            mask = (srcLeft < srcRight) ^ imask10;
            
            if ( ( (i >> stage) & 1) ^ dir )
            {
                //                srcLeft = (srcLeft & ~mask) | (srcRight & mask);
                srcLeft = valueMask(srcLeft, srcRight, ~mask);
                
                //                srcRight = srcLeft.yxwz;
                srcRight = srcLeft.yxwz;
                
                //                mask = (srcLeft < srcRight) ^ imask11;
                mask = (srcLeft < srcRight) ^ imask11;
                
                //                theArray[i] = (srcLeft & ~mask) | (srcRight & mask);
                randValues[i] = valueMask(srcLeft, srcRight, ~mask);

            }
            else
            {
                //                srcLeft = (srcLeft & mask) | (srcRight & ~mask);
                srcLeft = valueMask(srcLeft, srcRight, mask);
                
                //                srcRight = srcLeft.yxwz;
                srcRight = srcLeft.yxwz;
                
                //                mask = (srcLeft < srcRight) ^ imask11;
                mask = (srcLeft < srcRight) ^ imask11;
                
                //                theArray[i] = (srcLeft & mask) | (srcRight & ~mask);
                randValues[i] = valueMask(srcLeft, srcRight, mask);
            }
        }
    }
    else    // first stage, sort inside one four
    {
        
        //int4 imask0 = (int4)(0, -1, -1,  0);
        bool4 imask0 = (bool4)(0, 1, 1,  0);
        
        srcLeft = randValues[i];
        srcRight = srcLeft.yxwz;
        
        // mask = (srcLeft < srcRight) ^ imask0;
        mask = (srcLeft < srcRight) ^ imask0;
        
        if ( dir )
        {
            //            srcLeft = (srcLeft & mask) | (srcRight & ~mask);
            srcLeft = valueMask(srcLeft, srcRight, mask);
        }
        else
        {
            //            srcLeft = (srcLeft & ~mask) | (srcRight & mask);
            srcLeft = valueMask(srcLeft, srcRight, ~mask);
        }
        
        //        srcRight = srcLeft.zwxy;
        srcRight = srcLeft.zwxy;
        
        //        mask = (srcLeft < srcRight) ^ imask10;
        mask = (srcLeft < srcRight) ^ imask10;
        
        if( (i & 1) ^ dir )
        {
            //            srcLeft = (srcLeft & mask) | (srcRight & ~mask);
            srcLeft = valueMask(srcLeft, srcRight, mask);
            
            //            srcRight = srcLeft.yxwz;
            srcRight = srcLeft.yxwz;
            
            //            mask = (srcLeft < srcRight) ^ imask11;
            mask = (srcLeft < srcRight) ^ imask11;
            
            //            theArray[i] = (srcLeft & mask) | (srcRight & ~mask);
            randValues[i] = valueMask(srcLeft, srcRight, mask);
            
        }
        else
        {
            
            //            srcLeft = (srcLeft & ~mask) | (srcRight & mask);
            srcLeft = valueMask(srcLeft, srcRight, ~mask);
            
            //            srcRight = srcLeft.yxwz;
            srcRight = srcLeft.yxwz;
            
            //            mask = (srcLeft < srcRight) ^ imask11;
            mask = (srcLeft < srcRight) ^ imask11;
            
            //          theArray[i] = (srcLeft & ~mask) | (srcRight & mask);
            randValues[i] = valueMask(srcLeft, srcRight, ~mask);
        }
    }

    
    


    
    // Write debug info
    debugInfo->completedStages[stage] = 1;
    debugInfo->completedPasses[passOfStage] = 1;
    
    if ( debugInfo->previousStage[stage] == 999 )
    {
        // NOTE: We'll hit this point multiple times during the same stage,
        // so we only want to do it once.
        debugInfo->previousStage[stage] = debugInfo->lastStage;
    }
    debugInfo->previousPass[passOfStage] = debugInfo->lastPass;
    debugInfo->lastStage = stage;
    debugInfo->lastPass = passOfStage;
    debugInfo->numTimesAccessed += 1; // NOTE: this ends up being 1-per-dispatch
}


// Bitonic sort
kernel void bitonic_sort(const device Particle* inParticles [[ buffer(1) ]],
                         device int4* sortIndices [[ buffer(2) ]],
                         device debugInfo_t * debugInfo [[ buffer(4) ]],
                         constant sortState_t& sortState [[ buffer(3) ]],
                         constant myUniforms_t& uniforms [[ buffer(ciBufferIndexUniforms) ]],
                         uint2 global_thread_position [[thread_position_in_grid]],
                         uint local_index [[thread_index_in_threadgroup]],
                         uint2 groups_per_grid [[ threadgroups_per_grid ]],
                         uint2 group_thread_size [[ threads_per_threadgroup ]],
                         uint2 grid_thread_count [[ threads_per_grid ]],
                         uint2 group_position [[ threadgroup_position_in_grid ]] )
{
    // NOTE: i is NOT the particle index, it's the int4 index, which contains 4 indices
    uint i = global_thread_position[0];

    int4 srcLeft, srcRight,
          // lame way of mapping the values to the indices
          // BILL
            leftValues, rightValues;
    bool4 mask;
    bool4 imask10 = (bool4)(0, 0, 1, 1);
    bool4 imask11 = (bool4)(0, 1,  0, 1);
    
    int stage = sortState.stage;
    int passOfStage = sortState.pass;
    int dir = sortState.direction;
    
    srcLeft = sortIndices[i];
    srcRight = srcLeft.zwxy;
    
    /*
     // TEST
     // So far so good
     sortIndices[i] = srcLeft;
     i 120: [      480,      481,      482,      483]
     i 121: [      484,      485,      486,      487]
     i 122: [      488,      489,      490,      491]
     i 123: [      492,      493,      494,      495]
     */

    /*
     // TEST
     // So far so good
     sortIndices[i] = indexSortKeys(srcLeft, inParticles, uniforms);
     i 120: [    27303,    38968,    31478,    32925]
     i 121: [     8679,    35177,    14640,    18379]
     i 122: [    27157,    63838,     8251,     5474]
     i 123: [    31185,     9335,    33721,    29560]
     */
    
    // Woo hoo!
//    480 == 27303
//    482 == 31478
//    483 == 32925
//    481 == 38968

    
    if ( uint(stage) > debugInfo->maxStage ) debugInfo->maxStage = uint(stage);
    if ( uint(stage) < debugInfo->minStage ) debugInfo->minStage = uint(stage);
    if ( uint(passOfStage) > debugInfo->maxPass ) debugInfo->maxPass = uint(passOfStage);
    if ( uint(passOfStage) < debugInfo->minPass ) debugInfo->minPass = uint(passOfStage);
//    if ( uint(stage) > debugInfo.maxStage ) debugInfo.maxStage = uint(stage);
//    if ( uint(stage) < debugInfo.minStage ) debugInfo.minStage = uint(stage);
//    if ( uint(passOfStage) > debugInfo.maxPass ) debugInfo.maxPass = uint(passOfStage);
//    if ( uint(passOfStage) < debugInfo.minPass ) debugInfo.minPass = uint(passOfStage);

//    debugInfo->maxStage = stage;
//    debugInfo->minStage = stage;
//    debugInfo->maxPass = passOfStage;
//    debugInfo->minPass = passOfStage;
    
    if( stage > 0 )
    {
        // upper level pass, exchange between two fours
        if( passOfStage > 0 )
        {
            uint r = 1 << (passOfStage - 1);
            uint lmask = r - 1;
            uint left = ((i>>(passOfStage-1)) << passOfStage) + (i & lmask);
            uint right = left + r;
            
            srcLeft = sortIndices[left];
            srcRight = sortIndices[right];
            
            leftValues = indexSortKeys(srcLeft, inParticles, uniforms);
            rightValues = indexSortKeys(srcRight, inParticles, uniforms);
            
//            mask = (srcLeft < srcRight);
            mask = (leftValues < rightValues);
            
//            int4 imin = (leftValues & mask) | (rightValues & ~mask);
            int4 imin = valueMask(srcLeft, srcRight, ~mask);
            
//            int4 imax = (leftValues & ~mask) | (rightValues & mask);
            int4 imax = valueMask(srcLeft, srcRight, mask);
            
//            debugInfo->int4s[0] = uint4(0,0,0,0);
//            debugInfo->int4s[1] = uint4(1,1,1,1);
//            debugInfo->int4s[2] = uint4(2,2,2,2);
//            debugInfo->int4s[3] = uint4(3,3,3,3);
//            debugInfo->numInt4s = 4;
            
            if ( stage > 1 )
            {
                debugInfo->int4s[0] = uint4(0,0,0,0);
                uint s = uint(stage);
                debugInfo->int4s[1] = uint4(s,s,s,s);
                uint maxS = uint(debugInfo->maxStage);
                debugInfo->int4s[2] = uint4(maxS,maxS,maxS,maxS);
                debugInfo->int4s[3] = uint4(99,99,99,99);
                debugInfo->numInt4s = 4;
            }

            if( ( (i>>(stage-1)) & 1) ^ dir )
            {
                // theArray[left]  = imin;
                sortIndices[left]  = imin;
                // theArray[right] = imax;
                sortIndices[right] = imax;
            }
            else
            {
                // theArray[right] = imin;
                sortIndices[right] = imin;
                // theArray[left]  = imax;
                sortIndices[left]  = imax;
            }
        }
        
        // last pass, sort inside one four
        else
        {
            /*
             // TEST
             // So far so good
             sortIndices[i] = int4(i,i,i,i);
             i 120: [      120,      120,      120,      120]
             i 121: [      121,      121,      121,      121]
             i 122: [      122,      122,      122,      122]
             i 123: [      123,      123,      123,      123]
             */
            
            //srcLeft = theArray[i];
            srcLeft = sortIndices[i];
            //srcRight = srcLeft.zwxy;
            srcRight = srcLeft.zwxy;

            leftValues = indexSortKeys(srcLeft, inParticles, uniforms);
            rightValues = indexSortKeys(srcRight, inParticles, uniforms);
            
            // TEST
            /*
             sortIndices[i] = originalLeftValues;
             i 120: [-2147483648,-2147483648,-2147483648,-2147483648]
             i 121: [-2147483648,-2147483648,-2147483648,-2147483648]
             i 122: [    32767,    32767,    32767,    32767]
             i 123: [    32767,    32767,    32767,    32767]
            */

            //mask = (srcLeft < srcRight) ^ imask10;
            mask = (leftValues < rightValues) ^ imask10;
            
            // TEST
            /*
            sortIndices[i] = mask;
             i 120: [        0,        0,       -2,       -2]
             i 121: [        0,        0,       -2,       -2]
             i 122: [        0,        0,       -2,       -2]
             i 123: [        0,        0,       -2,       -2]
            */

            if ( ( (i >> stage) & 1) ^ dir )
            {
//                srcLeft = (srcLeft & mask) | (srcRight & ~mask);
//                leftValues = (leftValues & mask) | (rightValues & ~mask);
                leftValues = valueMask(leftValues, rightValues, mask);
                srcLeft = valueMask(srcLeft, srcRight, mask);
                
//                srcRight = srcLeft.yxwz;
                rightValues = leftValues.yxwz;
                srcRight = srcLeft.yxwz;
                
                // TEST
                /*
                sortIndices[i] = leftValues;
                 i 120: [-2147483648,-2147483648,-2147483648,-2147483648]
                 i 121: [-2147483648,-2147483648,-2147483648,-2147483648]
                 i 122: [    32767,    32767,    32767,    32767]
                 i 123: [    32767,    32767,    32767,    32767]
                */
                
//                mask = (srcLeft < srcRight) ^ imask11;
                mask = (leftValues < rightValues) ^ imask11;
                
//                theArray[i] = (srcLeft & mask) | (srcRight & ~mask);
                sortIndices[i] = valueMask(srcLeft, srcRight, mask);
            }
            else
            {
//                srcLeft = (srcLeft & ~mask) | (srcRight & mask);
                leftValues = valueMask(leftValues, rightValues, ~mask);
                srcLeft = valueMask(leftValues, rightValues, ~mask);
                
//                srcRight = srcLeft.yxwz;
                rightValues = leftValues.yxwz;
                srcRight = srcLeft.yxwz;
                
//                mask = (srcLeft < srcRight) ^ imask11;
                mask = (leftValues < rightValues) ^ imask11;
  
//                theArray[i] = (srcLeft & ~mask) | (srcRight & mask);
                sortIndices[i] = valueMask(srcLeft, srcRight, ~mask);
            }
        }
    }
    
    // EVERYTHING below seems to work
    else    // first stage, sort inside one four
    {
        
        //int4 imask0 = (int4)(0, -1, -1,  0);
        bool4 imask0 = (bool4)(0, 1, 1,  0);

        
        srcLeft = sortIndices[i];
        srcRight = srcLeft.yxwz;
        
        leftValues = indexSortKeys(srcLeft, inParticles, uniforms);
        rightValues = indexSortKeys(srcRight, inParticles, uniforms);
        
        /*
         sortIndices[i] = leftValues;
         i 120: [    27303,    38968,    31478,    32925]
         i 121: [     8679,    35177,    14640,    18379]
         i 122: [    27157,    63838,     8251,     5474]
         i 123: [    31185,     9335,    33721,    29560]
         return;
         */
        
        /*
        // TEST
        sortIndices[i] = rightValues;
         i 120: [    38968,    27303,    32925,    31478]
         i 121: [    35177,     8679,    18379,    14640]
         i 122: [    63838,    27157,     5474,     8251]
         i 123: [     9335,    31185,    29560,    33721]
        */
        
        /*
         // TEST
        sortIndices[i] = int4(leftValues < rightValues);
        i 120: [        1,        0,        1,        0]
        i 121: [        1,        0,        1,        0]
        i 122: [        1,        0,        0,        1]
        i 123: [        0,        1,        0,        1]
        */
        
        // mask = (srcLeft < srcRight) ^ imask0;
        mask = (leftValues < rightValues) ^ imask0;
        
        /*
         // TEST
         // OK! This seems much more like it
        mask = int4((leftValues < rightValues) ^ bool4(imask0));
        sortIndices[i] = mask;
         i 120: [        1,        1,        0,        0]
         i 121: [        1,        1,        0,        0]
         i 122: [        1,        1,        1,        1]
         i 123: [        0,        0,        1,        1]
        */
        
        if ( dir )
        {
//            srcLeft = (srcLeft & mask) | (srcRight & ~mask);
            leftValues = valueMask(leftValues, rightValues, mask);
            srcLeft = valueMask(srcLeft, srcRight, mask);
        }
        else
        {
//            srcLeft = (srcLeft & ~mask) | (srcRight & mask);
            leftValues = valueMask(leftValues, rightValues, ~mask);
            srcLeft = valueMask(srcLeft, srcRight, ~mask);
        }
        
        /*
        // TEST
        // NOT OK: We're modifying the values by the mask
        sortIndices[i] = leftValues;
//        i 120: [    27303,    38968,    32925,    31478]
//        i 121: [     8679,    35177,    18379,    14640]
//        i 122: [    27157,    63838,     8251,     5474]
//        i 123: [     9335,    31185,    33721,    29560]
        */

        
//        srcRight = srcLeft.zwxy;
        rightValues = leftValues.zwxy;
        srcRight = srcLeft.zwxy;
        
//        mask = (srcLeft < srcRight) ^ imask10;
        mask = (leftValues < rightValues) ^ imask10;
        
        if( (i & 1) ^ dir )
        {
//            srcLeft = (srcLeft & mask) | (srcRight & ~mask);
            leftValues = valueMask(leftValues, rightValues, mask);
            srcLeft = valueMask(srcLeft, srcRight, mask);
            
//            srcRight = srcLeft.yxwz;
            rightValues = leftValues.yxwz;
            srcRight = srcLeft.yxwz;
            
//            mask = (srcLeft < srcRight) ^ imask11;
            mask = (leftValues < rightValues) ^ imask11;
            
//            theArray[i] = (srcLeft & mask) | (srcRight & ~mask);
            sortIndices[i] = valueMask(srcLeft, srcRight, mask);
            // YEP
//            i 120: [      480,      482,      483,      481]
//            i 121: [      485,      487,      486,      484]
//            i 122: [      491,      490,      488,      489]
//            i 123: [      494,      492,      495,      493]

        }
        else
        {

//            srcLeft = (srcLeft & ~mask) | (srcRight & mask);
            leftValues = valueMask(leftValues, rightValues, ~mask);
            srcLeft = valueMask(srcLeft, srcRight, ~mask);
            
//            srcRight = srcLeft.yxwz;
            rightValues = leftValues.yxwz;
            srcRight = srcLeft.yxwz;
            
//            mask = (srcLeft < srcRight) ^ imask11;
            mask = (leftValues < rightValues) ^ imask11;
            
//          theArray[i] = (srcLeft & ~mask) | (srcRight & mask);
            sortIndices[i] = valueMask(srcLeft, srcRight, ~mask);
        }
    }
}


vertex ColorInOut vertex_particles(const device Particle * particles [[ buffer(ciBufferIndexInterleavedVerts) ]],
                                   const device int4 * indices [[ buffer(ciBufferIndexIndicies) ]],
                                   constant myUniforms_t& uniforms [[ buffer(ciBufferIndexUniforms) ]],
                                   unsigned int vid [[ vertex_id ]] )
{
    ColorInOut out;
    
    int sortedIndex = indices[vid / 4][vid % 4];
    
    float scalarSort = 0.5; // float(sortedIndex) / uniforms.numParticles;
                            // float(vid) / uniforms.numParticles;
    
    Particle p = particles[vid];
    
    float4 in_position = float4(p.position * 2.f, 1.0f);
    out.position = uniforms.modelViewProjectionMatrix * in_position;
    
    // Make the rear particles smaller 
    out.pointSize = 20.f + (scalarSort * 40.f);
    float4 viewPosition = uniforms.modelMatrix * float4(p.position, 1.0f);
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

vertex ColorInOut vertex_lighting_geom(device unsigned int* indices [[ buffer(ciBufferIndexIndicies) ]],
                                       device packed_float3* positions [[ buffer(ciBufferIndexPositions) ]],
                                       device packed_float3* normals [[ buffer(ciBufferIndexNormals) ]],
                                       constant myUniforms_t& uniforms [[ buffer(ciBufferIndexUniforms) ]],
                                       unsigned int vid [[ vertex_id ]])
{
    ColorInOut out;
    
    unsigned int vertIndex = indices[vid];
    
    float4 in_position = float4(positions[vertIndex] - float3(0.0,0.5,0.0), // center the teapot
                                1.0);
    out.position = uniforms.modelViewProjectionMatrix * in_position;
    
    float3 normal = normals[vertIndex];
    float4 eye_normal = normalize(uniforms.normalMatrix * float4(normal, 0.0));
    float n_dot_l = dot(eye_normal.rgb, normalize(light_position));
    n_dot_l = fmax(0.0, n_dot_l);
    
    out.color = ambient_color + diffuse_color * n_dot_l;
    
    return out;
}

fragment float4 fragment_color( ColorInOut in [[stage_in]] )
{
    return in.color;
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


