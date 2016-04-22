//
//  Shader.h
//  StockShader
//
//  Created by William Lindmeier on 4/18/16.
//
//

#pragma once

#include "cinder/Cinder.h"
#include "TextureBuffer.h"
#include "RenderPipelineState.h"
#include "metal.h"

namespace cinder { namespace mtl {
    
    class ShaderDef
    {
        public:
        ShaderDef();
        
        // Attribs
        ShaderDef&		color();
        ShaderDef&		texture(); // const TextureBufferRef &tex = TextureBufferRef() );
        ShaderDef&		lambert();
        ShaderDef&		points();
        ShaderDef&		textureArray();
        
        // Display
        ShaderDef&		billboard();
        ShaderDef&		uniformBasedPosAndTexCoord();
        
        // Geom
        ShaderDef&      ring();
        
    //    bool			isTextureSwizzleDefault() const;
    //    std::string		getTextureSwizzleString() const;
        
        bool operator<( const ShaderDef &rhs ) const;
        
        protected:
        
        bool					mTextureMapping;
    //    bool					mTextureMappingRectangle;
    //    std::array<int,4>		mTextureSwizzleMask;
        bool					mUniformBasedPosAndTexCoord;
        
        bool					mColor;
        bool					mLambert;
        bool                    mPoints;
        bool					mTextureArray;
        bool                    mBillboard;
        bool                    mRing;
        
    //    friend class EnvironmentCore;
    //    friend class EnvironmentEs;
        friend class PipelineBuilder;
    };
    
    class PipelineBuilder
    {
    public:
        static ci::mtl::RenderPipelineStateRef buildPipeline( const ShaderDef &shader,
                                                              ci::mtl::RenderPipelineState::Format format =
                                                              ci::mtl::RenderPipelineState::Format() );
        static std::string	generateFragmentShader( const ShaderDef &shader );
        static std::string	generateVertexShader( const ShaderDef &shader );
        static std::string	generateMetalLibrary( const ShaderDef &shader );
    };

}}