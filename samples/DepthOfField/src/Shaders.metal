//
//  Shaders.metal
//  MetalTemplate
//
//  Created by William Lindmeier on 11/26/15.
//
//

#include <metal_stdlib>
#include <simd/simd.h>

#include "SharedTypes.h"
#include "ShaderUtils.h"
#include "ShaderTypes.h"
#include "MetalConstants.h"

using namespace metal;
using namespace cinder;
using namespace cinder::mtl;

typedef struct
{
    metal::packed_float3 ciPosition;
    metal::packed_float3 ciNormal;
    metal::packed_float2 ciTexCoord0;
    metal::packed_float4 ciColor;
} VertIn;

typedef struct
{
    metal::packed_float2 ciPosition;
    metal::packed_float2 ciTexCoord0;
} RectIn;

typedef struct
{
    vector_float4 position [[position]];
    vector_float4 vertPosition;
    vector_float3 vertNormal;
    vector_float4 vertColor;
    vector_float2 texCoords;
} VertOut;

#pragma mark - Vertex

vertex VertOut background_vertex( device const VertIn* ciVerts [[ buffer(ciBufferIndexInterleavedVerts) ]],
                                  constant ciUniforms_t& ciUniforms [[ buffer(ciBufferIndexUniforms) ]],
                                  unsigned int vid [[ vertex_id ]] )
{
    VertOut out;
    VertIn p = ciVerts[vid];
    out.vertPosition = float4(p.ciPosition, 1.0);
    out.vertNormal = normalize(float3(p.ciNormal));
    out.vertColor = ciUniforms.ciColor;
    out.texCoords = p.ciTexCoord0;
    
    out.position = ciUniforms.ciProjectionMatrix * out.vertPosition;
    
    return out;
}

vertex VertOut instanced_vertex( device const VertIn* ciVerts [[ buffer(ciBufferIndexInterleavedVerts) ]],
                                 device const TeapotInstance* instances [[ buffer(ciBufferIndexInstanceData) ]],
                                 constant ciUniforms_t& ciUniforms [[ buffer(ciBufferIndexUniforms) ]],
                                 unsigned int vid [[ vertex_id ]],
                                 uint i [[ instance_id ]] )
{
    VertOut out;
    
    VertIn p = ciVerts[vid];
    
    TeapotInstance instance = instances[i];
    out.vertPosition = ciUniforms.ciViewMatrix * instance.modelMatrix * float4(p.ciPosition, 1.0);
    out.vertColor = ciUniforms.ciColor;
    matrix_float3x3 normalMatrix = mat3( ciUniforms.ciViewMatrix * instance.modelMatrix ); // assumes homogenous scaling    
    
    out.vertNormal = normalize( normalMatrix * float3(p.ciNormal) );
    out.position = ciUniforms.ciProjectionMatrix * out.vertPosition;
    out.texCoords = p.ciTexCoord0;
    
    return out;
}

vertex VertOut texture_vertex( device const RectIn* ciVerts [[ buffer(ciBufferIndexInterleavedVerts) ]],
                               constant ciUniforms_t& ciUniforms [[ buffer(ciBufferIndexUniforms) ]],
                               unsigned int vid [[ vertex_id ]] )
{
    VertOut out;
    
    RectIn p = ciVerts[vid];
    out.position = ciUniforms.ciModelViewProjection * float4(p.ciPosition, 0.f, 1.0);
    out.texCoords = p.ciTexCoord0;
    
    return out;
}

#pragma mark - Fragment

#define saturate(s) clamp( s, 0.0, 1.0 )

constant const int2 kDirectionHorizontal = int2(1, 0);
constant const int2 kDirectionVertical = int2(0, 1);

inline bool inNearField( float radiusPixels )
{
    return radiusPixels > 0.25;
}

constexpr sampler shaderSampler( coord::normalized, address::clamp_to_edge,
                                 filter::linear, mip_filter::none );

inline float2 gl_FragCoord( float2 texCoords, uint2 fboSize )
{
    return texCoords.xy * float2(fboSize.x, fboSize.y);
}

constant const int KERNEL_TAPS = 6;
constant float kern[KERNEL_TAPS + 1] = {1.00, 1.00, 0.90, 0.75, 0.60, 0.50, 0.00};

struct BlurFragmentOut
{
    float4 blurResult [[ color(0) ]];
    float4 nearResult [[ color(1) ]];
};

fragment BlurFragmentOut blur_vert_fragment( VertOut in [[ stage_in ]],
                                             texture2d<float> uBlurSource [[ texture(ciTextureIndex0) ]],
                                             texture2d<float> uNearSource [[ texture(ciTextureIndex1) ]],
                                             constant int   &uMaxCoCRadiusPixels [[ buffer(ciBufferIndexCustom0) ]],
                                             constant int   &uNearBlurRadiusPixels [[ buffer(ciBufferIndexCustom1) ]],
                                             constant uint2 &uFBOSize [[ buffer(ciBufferIndexCustom3) ]] )
{
    int2 direction = kDirectionVertical;
    
    BlurFragmentOut out;

    // Accumulate the blurry image color
    out.blurResult.rgb  = float3( 0.0 );
    float blurWeightSum = 0.0;
    
    // Accumulate the near-field color and coverage
    out.nearResult = float4( 0.0 );
    float nearWeightSum = 0.0;
    
    // Location of the central filter tap (i.e., "this" pixel's location)
    // Account for the scaling down to 25% of original dimensions during blur
    int2 A = int2( gl_FragCoord(in.texCoords, uFBOSize).xy * float2( direction * 3 + int2( 1 ) ) );
    
    float packedA = uBlurSource.read(uint2(A)).a;//texelFetch( uBlurSource, A, 0 ).a;
    float r_A = ( packedA * 2.0 - 1.0 ) * uMaxCoCRadiusPixels;
    
    // Map r_A << 0 to 0, r_A >> 0 to 1
    float nearFieldness_A = saturate( r_A * 4.0 );
    
    for( int delta = -uMaxCoCRadiusPixels; delta <= uMaxCoCRadiusPixels; ++delta )
    {
        // Tap location near A
        int2   B = A + ( direction * delta );
        
        // Packed values
        float4 blurInput = uBlurSource.read(uint2(clamp( B, int2( 0 ),
                                                        int2(uBlurSource.get_width(0), uBlurSource.get_height(0)) -
                                                        int2( 1 ) ) ));
        
        // Signed kernel radius at this tap, in pixels
        float r_B = ( blurInput.a * 2.0 - 1.0 ) * float( uMaxCoCRadiusPixels );
        
        /////////////////////////////////////////////////////////////////////////////////////////////
        // Compute blurry buffer
        
        float weight = 0.0;
        
        float wNormal  =
        // Only consider mid- or background pixels (allows inpainting of the near-field)
        float(! inNearField(r_B)) *
        
        // Only blur B over A if B is closer to the viewer (allow 0.5 pixels of slop, and smooth the transition)
        // This term avoids "glowy" background objects but leads to aliasing under 4x downsampling
        // saturate( abs( r_A ) - abs( r_B ) + 1.5 ) *
        
        // Stretch the kernel extent to the radius at pixel B.
        kern[clamp( int( float( abs( delta ) * ( KERNEL_TAPS - 1 ) ) / ( 0.001 + abs( r_B * 0.8 ) ) ), 0, KERNEL_TAPS )];
        
        weight = mix( wNormal, 1.0, nearFieldness_A );
        
        // far + mid-field output
        blurWeightSum  += weight;
        out.blurResult.rgb += blurInput.rgb * weight;
        
        ///////////////////////////////////////////////////////////////////////////////////////////////
        // Compute near-field super blurry buffer
        
        float4 nearInput;
        
        // On the vertical pass, use the already-available alpha values
        nearInput = uNearSource.read(uint2(clamp( B, int2( 0 ),
                                                 int2(uNearSource.get_width(0), uNearSource.get_height(0)) -
                                                 int2( 1 ) ) ));

        // We subsitute the following efficient expression for the more complex: weight = kernel[clamp(int(float(abs(delta) * (KERNEL_TAPS - 1)) * uInvNearBlurRadiusPixels), 0, KERNEL_TAPS)];
        weight =  float( abs( delta ) < uNearBlurRadiusPixels );
        out.nearResult += nearInput * weight;
        nearWeightSum += weight;
    }
    
    out.blurResult.a = 1.0;

    // Normalize the blur
    out.blurResult.rgb /= blurWeightSum;
    out.nearResult     /= max( nearWeightSum, 0.00001 );
    
    return out;
}

fragment BlurFragmentOut blur_horiz_fragment( VertOut in [[ stage_in ]],
                                              texture2d<float> uBlurSource [[ texture(ciTextureIndex0) ]],
                                              constant int   &uMaxCoCRadiusPixels [[ buffer(ciBufferIndexCustom0) ]],
                                              constant int   &uNearBlurRadiusPixels [[ buffer(ciBufferIndexCustom1) ]],
                                              constant float &uInvNearBlurRadiusPixels [[ buffer(ciBufferIndexCustom2) ]],
                                              constant uint2 &uFBOSize [[ buffer(ciBufferIndexCustom3) ]] )
{
    int2 direction = kDirectionHorizontal;

    BlurFragmentOut out;

    // Accumulate the blurry image color
    out.blurResult.rgb  = float3( 0.0 );
    float blurWeightSum = 0.0;
    
    // Accumulate the near-field color and coverage
    out.nearResult = float4( 0.0 );
    float nearWeightSum = 0.0;

    // Location of the central filter tap (i.e., "this" pixel's location)
    // Account for the scaling down to 25% of original dimensions during blur
    int2 A = int2( gl_FragCoord(in.texCoords, uFBOSize).xy * float2( direction * 3 + int2( 1 ) ) );
    
    float packedA = uBlurSource.read(uint2(A)).a;//texelFetch( uBlurSource, A, 0 ).a;
    float r_A = ( packedA * 2.0 - 1.0 ) * uMaxCoCRadiusPixels;
    
    // Map r_A << 0 to 0, r_A >> 0 to 1
    float nearFieldness_A = saturate( r_A * 4.0 );
    
    for( int delta = -uMaxCoCRadiusPixels; delta <= uMaxCoCRadiusPixels; ++delta )
    {
        // Tap location near A
        int2   B = A + ( direction * delta );
        
        // Packed values
        float4 blurInput = uBlurSource.read(uint2(clamp( B, int2( 0 ),
                                                  int2(uBlurSource.get_width(0), uBlurSource.get_height(0)) -
                                                  int2( 1 ) ) ));
        
        // Signed kernel radius at this tap, in pixels
        float r_B = ( blurInput.a * 2.0 - 1.0 ) * float( uMaxCoCRadiusPixels );
        
        /////////////////////////////////////////////////////////////////////////////////////////////
        // Compute blurry buffer
        
        float weight = 0.0;
        
        float wNormal  =
        // Only consider mid- or background pixels (allows inpainting of the near-field)
        float(! inNearField(r_B)) *
        
        // Only blur B over A if B is closer to the viewer (allow 0.5 pixels of slop, and smooth the transition)
        // This term avoids "glowy" background objects but leads to aliasing under 4x downsampling
        // saturate( abs( r_A ) - abs( r_B ) + 1.5 ) *
        
        // Stretch the kernel extent to the radius at pixel B.
        kern[clamp( int( float( abs( delta ) * ( KERNEL_TAPS - 1 ) ) / ( 0.001 + abs( r_B * 0.8 ) ) ), 0, KERNEL_TAPS )];
        
        weight = mix( wNormal, 1.0, nearFieldness_A );
        
        // far + mid-field output
        blurWeightSum  += weight;
        out.blurResult.rgb += blurInput.rgb * weight;
        
        ///////////////////////////////////////////////////////////////////////////////////////////////
        // Compute near-field super blurry buffer
        
        float4 nearInput;
        
        // On the horizontal pass, extract coverage from the near field radius
        // Note that the near field gets a box-blur instead of a kernel
        // blur; we found that the quality improvement was not worth the
        // performance impact of performing the kernel computation here as well.
        
        // Curve the contribution based on the radius.  We tuned this particular
        // curve to blow out the near field while still providing a reasonable
        // transition into the focus field.
        nearInput.a = float( abs( delta ) <= r_B ) * saturate( r_B * uInvNearBlurRadiusPixels * 4.0 );
        
        // Optionally increase edge fade contrast in the near field
        nearInput.a *= nearInput.a; nearInput.a *= nearInput.a;
        
        // Compute premultiplied-alpha color
        nearInput.rgb = blurInput.rgb * nearInput.a;
        
        // We subsitute the following efficient expression for the more complex: weight = kernel[clamp(int(float(abs(delta) * (KERNEL_TAPS - 1)) * uInvNearBlurRadiusPixels), 0, KERNEL_TAPS)];
        weight =  float( abs( delta ) < uNearBlurRadiusPixels );
        out.nearResult += nearInput * weight;
        nearWeightSum += weight;
    }
    
    // Retain the packed radius on the horiz pass.  On the second pass it is not needed.
    out.blurResult.a = packedA;

    // Normalize the blur
    out.blurResult.rgb /= blurWeightSum;
    out.nearResult     /= max( nearWeightSum, 0.00001 );

    return out;
}

constant float2 kCocReadScaleBias = float2(2.0, -1.0);

// Boost the coverage of the near field by this factor.  Should always be >= 1
//
// Make this larger if near-field objects seem too transparent
//
// Make this smaller if an obvious line is visible between the near-field blur and the mid-field sharp region
// when looking at a textured ground plane.
constant float kCoverageBoost = 1.5;

fragment float4 composite_fragment( VertOut in [[ stage_in ]],
                                   texture2d<float> uInputSource [[ texture(ciTextureIndex0) ]],
                                   texture2d<float> uBlurSource [[ texture(ciTextureIndex1)]],
                                   texture2d<float> uNearSource [[ texture(ciTextureIndex2)]],
                                   constant float2 &uInputSourceInvSize [[ buffer(ciBufferIndexCustom0)]],
                                   constant float2 &uOffset [[ buffer(ciBufferIndexCustom1)]],
                                   constant float  &uFarRadiusRescale [[ buffer(ciBufferIndexCustom2)]],
                                   constant uint2 &uFBOSize [[ buffer(ciBufferIndexCustom3) ]]
                                   )
{
    float4 result;
    
    const int		uDebugOption = 0;
    
    float2 fragCoord = gl_FragCoord(in.texCoords, uFBOSize);// * 0.5;
    
    int2 A      = int2( fragCoord.xy - uOffset );
    
    float4 pack    = uInputSource.read(uint2(A));
    float3 sharp   = pack.rgb;
    float3 blurred = uBlurSource.sample( shaderSampler, fragCoord.xy * uInputSourceInvSize ).rgb;
    float4 near    = uNearSource.sample( shaderSampler, fragCoord.xy * uInputSourceInvSize );
    
    // Signed, normalized radius of the circle of confusion.
    // |normRadius| == 1.0 corresponds to camera->maxCircleOfConfusionRadiusPixels()
    float normRadius = pack.a * kCocReadScaleBias.x + kCocReadScaleBias.y;
    
    // Fix the far field scaling factor so that it remains independent of the
    // near field settings
    normRadius *= ( normRadius < 0.0 ) ? uFarRadiusRescale : 1.0;
    
    // Boost the blur factor
    // normRadius = clamp( normRadius * 2.0, -1.0, 1.0 );
    
    // Decrease sharp image's contribution rapidly in the near field
    // (which has positive normRadius)
    if ( normRadius > 0.1 )
    {
        normRadius = min( normRadius * 1.5, 1.0 );
    }
    
    if (kCoverageBoost != 1.0) {
        float a = saturate( kCoverageBoost * near.a );
        near.rgb = near.rgb * ( a / max( near.a, 0.001 ) );
        near.a = a;
    }
    
    // Two mixs, the second of which has a premultiplied alpha
    result.rgb = mix( sharp, blurred, abs( normRadius ) ) * ( 1.0 - near.a ) + near.rgb;
    
    /////////////////////////////////////////////////////////////////////////////////
    // Debugging options:
    const int SHOW_COC          = 1;
    const int SHOW_REGION       = 2;
    const int SHOW_NEAR         = 3;
    const int SHOW_BLURRY       = 4;
    const int SHOW_INPUT        = 5;
    const int SHOW_MID_AND_FAR  = 6;
    const int SHOW_SIGNED_COC   = 7;
    
    switch (uDebugOption) {
        case SHOW_COC:
            // Go back to the true radius, before it was enlarged by post-processing
            result.rgb = float3( abs( pack.a * kCocReadScaleBias.x + kCocReadScaleBias.y ) );
            break;
            
        case SHOW_SIGNED_COC:
        {
            // Go back to the true radius, before it was enlarged by post-processing
            float r = pack.a * kCocReadScaleBias.x + kCocReadScaleBias.y;
            if (r < 0) {
                result.rgb = float3( 0.0, 0.14, 0.8 ) * abs(r);
            } else {
                result.rgb = float3( 1.0, 1.0, 0.15 ) * abs(r);
            }
        }
            break;
            
        case SHOW_REGION:
            if ( pack.a < 0.49 )
            {
                // Far field: Dark blue
                result.rgb = float3( 0.0, 0.07, 0.4 ) * ( dot( sharp, float3( 1.0 / 3.0 ) ) * 0.7 + 0.3 );
            } else if ( pack.a <= 0.51 ) {
                // Mifield: Gray
                result.rgb = float3( 0.4 ) * ( dot( sharp, float3( 1.0 / 3.0 ) ) * 0.7 + 0.3 );
            } else {
                result.rgb = float3( 1.0, 1.0, 0.15 ) * ( dot( sharp, float3( 1.0 / 3.0 ) ) * 0.7 + 0.3 );
            }
            break;
            
        case SHOW_BLURRY:
            result.rgb = blurred;
            break;
            
        case SHOW_NEAR:
            result.rgb = near.rgb;
            break;
            
        case SHOW_INPUT:
            result.rgb = sharp;
            break;
            
        case SHOW_MID_AND_FAR:
            // Just mix based on this pixel's blurriness. Works well in the background, less well in the foreground
            result.rgb = mix( sharp, blurred, abs( normRadius ) );
            break;
        default:
            break;
    }

    return result;
}

fragment float4 debug_fragment( VertOut in [[ stage_in ]],
                                constant int   &uMaxCoCRadiusPixels [[ buffer(ciBufferIndexCustom0)]], // = 5;
                                constant float &uAperture [[ buffer(ciBufferIndexCustom1)]], // = 1.0;
                                constant float &uFocalDistance [[ buffer(ciBufferIndexCustom2)]], // = 5.0;
                                constant float &uFocalLength [[ buffer(ciBufferIndexCustom3)]] ) // = 1.0;)
{
    float dist = length( in.vertPosition.xyz );
    
    float coc = uAperture * ( uFocalLength * ( uFocalDistance - dist ) ) / ( dist * ( uFocalDistance - uFocalLength ) );
    coc *= uMaxCoCRadiusPixels;
    coc = clamp( coc * 0.5 + 0.5, 0.0, 1.0 );
    
    float4 fragColor = in.vertColor;
    fragColor.a = coc;
    
    return fragColor;
}

fragment float4 scene_fragment( VertOut in [[ stage_in ]],
                                texture2d<float> uTex [[ texture(ciTextureIndex0) ]],
                                constant int   &uMaxCoCRadiusPixels [[ buffer(ciBufferIndexCustom0)]],
                                constant float &uAperture [[ buffer(ciBufferIndexCustom1)]],
                                constant float &uFocalDistance [[ buffer(ciBufferIndexCustom2)]],
                                constant float &uFocalLength [[ buffer(ciBufferIndexCustom3)]] )
{
    float3 E = normalize( in.vertPosition.xyz );
    float3 N = normalize( in.vertNormal );
    
    float3  r = reflect( E, N );
    r.z += 1.0;
    
    float m = 2.0 * sqrt( dot( r, r ) );
    float2 uv = r.xy / m + 0.5;
    
    float4 fragColor;
    fragColor.rgb = uTex.sample(shaderSampler, uv ).rgb * in.vertColor.rgb;
    
    // store the normalized circle of confusion radius in the alpha channel
    float dist = length( in.vertPosition.xyz );
    float coc = uMaxCoCRadiusPixels * uAperture * ( uFocalLength * ( uFocalDistance - dist ) ) / ( dist * ( uFocalDistance - uFocalLength ) );
    coc = clamp( coc * 0.5 + 0.5, 0.0, 1.0 );
    
    fragColor.a = coc;
    
    return fragColor;
}

fragment float4 color_fragment( VertOut in [[ stage_in ]] )
{
    return in.vertColor;
}

fragment float4 texture_fragment( VertOut in [[ stage_in ]],
                                  texture2d<float> texture [[ texture(ciTextureIndex0) ]] )
{
    return texture.sample(shaderSampler, in.texCoords);
}
