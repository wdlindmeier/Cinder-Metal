//
//  Shader.cpp
//
//  Created by William Lindmeier on 4/18/16.
//
//

#include "Shader.h"
#include "RendererMetalImpl.h"
#include "cinder/Log.h"
#include "MetalMacros.h"

using namespace std;

namespace cinder { namespace mtl {
    
#pragma mark - ShaderDef
    
    ShaderDef::ShaderDef()
    :
    mTextureMapping( false )
    //,mTextureMappingRectangle( false )
    ,mColor( false )
    ,mLambert( false )
    ,mPoints( false )
    ,mTextureArray( false )
    ,mBillboard( false )
    ,mRing(false)
    ,mAlphaBlending(false)
    ,mUniformBasedPosAndTexCoord( false )
    {
        mTextureSwizzleMask[0] = RED;
        mTextureSwizzleMask[1] = GREEN;
        mTextureSwizzleMask[2] = BLUE;
        mTextureSwizzleMask[3] = ALPHA;
    }
    
    ShaderDef& ShaderDef::texture()
    {
        mTextureMapping = true;
        return *this;
    }
    
    ShaderDef& ShaderDef::textureSwizzleMask( SwizzleComponent zero, SwizzleComponent one,
                                              SwizzleComponent two, SwizzleComponent three )
    {
        mTextureSwizzleMask[0] = zero;
        mTextureSwizzleMask[1] = one;
        mTextureSwizzleMask[2] = two;
        mTextureSwizzleMask[3] = three;
        return *this;
    }
    
    ShaderDef& ShaderDef::uniformBasedPosAndTexCoord()
    {
        mUniformBasedPosAndTexCoord = true;
        return *this;
    }
    
    ShaderDef& ShaderDef::color()
    {
        mColor = true;
        return *this;
    }
    
    ShaderDef& ShaderDef::lambert()
    {
        mLambert = true;
        return *this;
    }
    
    ShaderDef& ShaderDef::points()
    {
        mPoints = true;
        return *this;
    }

    ShaderDef& ShaderDef::textureArray()
    {
        mTextureMapping = true;
        mTextureArray = true;
        return *this;
    }

    ShaderDef& ShaderDef::billboard()
    {
        mBillboard = true;
        return *this;
    }
    
    ShaderDef& ShaderDef::ring()
    {
        mRing = true;
        return *this;
    }
    
    ShaderDef& ShaderDef::alphaBlending( BlendMode blendMode )
    {
        mAlphaBlending = true;
        mBlendMode = blendMode;
        return *this;
    }

    bool ShaderDef::isTextureSwizzleDefault() const
    {
        return mTextureSwizzleMask[0] == RED &&
        mTextureSwizzleMask[1] == GREEN &&
        mTextureSwizzleMask[2] == BLUE &&
        mTextureSwizzleMask[3] == ALPHA;
    }

    // this only works with RGBA values
    std::string ShaderDef::getTextureSwizzleString() const
    {
        string result;
        for( int i = 0; i < 4; ++i )
        {
            if( mTextureSwizzleMask[i] == RED )
            result += "r";
            else if( mTextureSwizzleMask[i] == GREEN )
            result += "g";
            else if( mTextureSwizzleMask[i] == BLUE )
            result += "b";
            else
            result += "a";
        }

        return result;
    }
    
    bool ShaderDef::operator<( const ShaderDef &rhs ) const
    {
        if( rhs.mTextureMapping != mTextureMapping )
        {
            return rhs.mTextureMapping;
        }

        if( rhs.mUniformBasedPosAndTexCoord != mUniformBasedPosAndTexCoord )
        {
            return rhs.mUniformBasedPosAndTexCoord;
        }
        
        if( rhs.mColor != mColor )
        {
            return rhs.mColor;
        }
        else if( rhs.mTextureSwizzleMask[0] != mTextureSwizzleMask[0] )
        return mTextureSwizzleMask[0] < rhs.mTextureSwizzleMask[0];
        else if( rhs.mTextureSwizzleMask[1] != mTextureSwizzleMask[1] )
        return mTextureSwizzleMask[1] < rhs.mTextureSwizzleMask[1];	
        else if( rhs.mTextureSwizzleMask[2] != mTextureSwizzleMask[2] )
        return mTextureSwizzleMask[2] < rhs.mTextureSwizzleMask[2];	
        else if( rhs.mTextureSwizzleMask[3] != mTextureSwizzleMask[3] )
        return mTextureSwizzleMask[3] < rhs.mTextureSwizzleMask[3];	

        if( rhs.mLambert != mLambert )
        {
            return rhs.mLambert;
        }
        
        if ( rhs.mBillboard != mBillboard )
        {
            return rhs.mBillboard;
        }
        
        if ( rhs.mTextureArray != mTextureArray )
        {
            return rhs.mTextureArray;
        }
        
        if ( rhs.mPoints != mPoints )
        {
            return rhs.mPoints;
        }
        
        if ( rhs.mRing != mRing )
        {
            return rhs.mRing;
        }
        
        if ( rhs.mAlphaBlending != mAlphaBlending )
        {
            return rhs.mAlphaBlending;
        }

        if ( rhs.mBlendMode != mBlendMode )
        {
            return rhs.mBlendMode;
        }

        return false;
    }
    
#pragma mark Shader Builder
    
#define STRINGIFY(s) str(s)
#define str(...) #__VA_ARGS__
    
    std::string	PipelineBuilder::generateMetalLibrary( const ShaderDef &shader )
    {
        string library = ""
        "#include <metal_stdlib>\n"
        "#include <simd/simd.h>\n"
         // These user includes will be pre-processed by RenderPipelineState
        "#include \"ShaderTypes.h\"\n"
        "#include \"MetalConstants.h\"\n";
        if ( shader.mBillboard )
        {
            library += "#include \"ShaderUtils.h\"\n";
        }
        library += "\n"
        "using namespace metal;\n"
        "using namespace cinder;\n"
        "using namespace cinder::mtl;\n"
        "\n"
        "typedef struct\n"
        "{\n"
        "    metal::packed_float4 ciPosition;\n";
        if ( shader.mLambert )
        {
            library += "    metal::packed_float3 ciNormal;\n";
        }
        if ( shader.mColor )
        {
            library += "    metal::packed_float4 ciColor;\n";
        }
        if ( shader.mTextureMapping )
        {
            library += "    metal::packed_float2 ciTexCoord0;\n";
        }
        library +=
        "} ciVertexIn_t;\n"
        "\n"
        "typedef struct\n"
        "{\n"
        "    float4 position [[position]];\n";
        if ( shader.mPoints )
        {
            library += "    float pointSize [[point_size]];\n";
        }
        if ( shader.mLambert )
        {
            library += "    float4 normal;\n";
        }

        library += "    float4 color;\n";
        
        if ( shader.mTextureMapping )
        {
            library +=
            "    float2 texCoords;\n"
            "    int texIndex;\n";
        }
        library +=
        "} ciVertexOut_t;\n"
        "\n";
        
        library += PipelineBuilder::generateVertexShader(shader);
        library += "";
        library +=  PipelineBuilder::generateFragmentShader(shader);
        return library;
    }

    std::string	PipelineBuilder::generateVertexShader( const ShaderDef &shader )
    {
        std::string s;
        
        s +=
        "vertex ciVertexOut_t ci_generated_vert( device const ciVertexIn_t* ciVerts [[ buffer(ciBufferIndexInterleavedVerts) ]],\n"
        "                                        device const Instance* instances [[ buffer(ciBufferIndexInstanceData) ]],\n"
        "                                        constant ciUniforms_t& ciUniforms [[ buffer(ciBufferIndexUniforms) ]],\n";
        if ( shader.mRing )
        {
            s += "                                        constant float *innerRadius [[ buffer(ciBufferIndexCustom0) ]],\n";
        }
        
        s +=
        "                                        unsigned int vid [[ vertex_id ]],\n"
        "                                        uint i [[ instance_id ]] )\n"
        "{\n"
        "   ciVertexOut_t out;\n";
        
        s +=
        "   ciVertexIn_t v = ciVerts[vid];\n"
        "   matrix_float4x4 modelMat = ciUniforms.ciModelMatrix * instances[i].modelMatrix;\n";

        if ( shader.mBillboard )
        {
            // Billboard the texture.
            // NOTE: This only really works if the instance geometry is flat in the first place.
            s += "   modelMat = modelMat * rotationMatrix(ciUniforms.ciModelViewInverse);\n";
        }
        s += "   matrix_float4x4 mvpMat = ciUniforms.ciViewProjection * modelMat;\n";
        s += "   float4 pos = float4(v.ciPosition[0], v.ciPosition[1], v.ciPosition[2], 1.0f);\n";
        
        if ( shader.mUniformBasedPosAndTexCoord )
        {
            s += "   pos = float4( ciUniforms.ciPositionOffset, 0 ) + float4( ciUniforms.ciPositionScale, 1 ) * pos;\n";
        }
        
        if ( shader.mRing )
        {
            s +=
            "   int segment = vid / 2;\n" // NOTE: % 2 doesn't work on Radeon GPUs
            "   if ( (vid / 2.0f) == segment )\n"
            "   {\n"
            "       pos = float4(pos.rgb * innerRadius[0],1.0);\n"
            "   }\n";
        }

        s += "   out.position = mvpMat * pos;\n";
        s += "   out.color = instances[i].color * ciUniforms.ciColor;\n";
        
        if ( shader.mColor )
        {
            s += "   out.color *= v.ciColor;\n";
        }
        
        if( shader.mTextureMapping )
        {
            s +=
            "   float texWidth = instances[i].texCoordRect[2] - instances[i].texCoordRect[0];\n"
            "   float texHeight = instances[i].texCoordRect[3] - instances[i].texCoordRect[1];\n"
            "   float2 texCoord(v.ciTexCoord0);\n"
            "   float2 instanceTexCoord(instances[i].texCoordRect[0] + texCoord.x * texWidth,\n"
            "                           instances[i].texCoordRect[1] + texCoord.y * texHeight);\n";

            if( shader.mUniformBasedPosAndTexCoord )
            {
                s += "   out.texCoords = ciUniforms.ciTexCoordOffset + ciUniforms.ciTexCoordScale * instanceTexCoord;\n";
            }
            else
            {
                s += "   out.texCoords = instanceTexCoord;\n";
            }
            
            if ( shader.mTextureArray )
            {
                 s += "   out.texIndex = instances[i].textureSlice;\n";
            }
        }
        
        if( shader.mLambert )
        {
            s += "   out.normal = ciUniforms.ciNormalMatrix4x4 * float4(v.ciNormal, 0.0);\n";
        }
        
        if( shader.mPoints )
        {
            s += "   out.pointSize = instances[i].scale;\n";
        }
        
        if( shader.mTextureMapping )
        {
            s += "   out.texIndex = instances[i].textureSlice;\n";
        }
        
        s +=
            "   return out;\n"
            "}\n\n";
        
        return s;
    }
    
    std::string	PipelineBuilder::generateFragmentShader( const ShaderDef &shader )
    {
        std::string s;
        
        // Default sampler
        if( shader.mTextureMapping )
        {
            s += "constexpr sampler ci_shader_sampler( coord::normalized,\n"
                 "                                     address::repeat,\n"
                 "                                     filter::linear,\n"
                 "                                     mip_filter::linear );\n";
        }
        
        s += "fragment float4 ci_generated_frag( ciVertexOut_t in [[ stage_in ]]";
        
        if( shader.mTextureMapping )
        {
            if ( shader.mTextureArray )
            {
                s += ",\n                               texture2d_array<float> texture [[ texture(ciTextureIndex0) ]]";
            }
            else
            {
                s += ",\n                               texture2d<float> texture [[ texture(ciTextureIndex0) ]]";
            }
            
            if ( shader.mPoints )
            {
                s += ",\n                               float2 pointCoord [[point_coord]],";
            }
        }
        s += " )\n"
        "{\n"
        "   float4 oColor = in.color;\n";

        if( shader.mTextureMapping )
        {
            if ( shader.mPoints )
            {
                if ( shader.mTextureArray )
                {
                    s += "   float4 texColor = texture.sample(ci_shader_sampler, pointCoord, in.texIndex);\n";
                }
                else
                {
                    s += "   float4 texColor = texture.sample(ci_shader_sampler, pointCoord);\n";
                }
            }
            else
            {
                if ( shader.mTextureArray )
                {
                    s += "   float4 texColor = texture.sample(ci_shader_sampler, in.texCoords, in.texIndex);\n";
                }
                else
                {
                    s += "   float4 texColor = texture.sample(ci_shader_sampler, in.texCoords);\n";
                }
            }
            
            if( !shader.isTextureSwizzleDefault() )
            {
                s += "   texColor = texColor." + shader.getTextureSwizzleString() + ";\n";
            }

            s += "   oColor *= texColor;\n";
        }

        if( shader.mLambert )
        {
            s +=
            "   float3 L = float3( 0, 0, 1 );\n"
            "   float3 N = normalize( in.normal.xyz );\n"
            "   float lambert = max( 0.0, dot( N, L ) );\n"
            "   oColor *= float4( float3( lambert ), 1.0 );\n";
        }

        s +=
        "   return oColor;\n"
        "}\n\n";
        
        return s;
    }
    
    ci::mtl::RenderPipelineStateRef	PipelineBuilder::buildPipeline( const ShaderDef &shader,
                                                                    const mtl::RenderPipelineState::Format & format )
    {
        std::string librarySource = PipelineBuilder::generateMetalLibrary(shader);
        CI_LOG_V("Generated Library:\n" << librarySource);
        return RenderPipelineState::create(librarySource, "ci_generated_vert", "ci_generated_frag", format);
    }
    
} } // namespace cinder::mtl