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
        ShaderDef&		alphaBlending();
        ShaderDef&		texture();
        ShaderDef&		lambert();
        ShaderDef&		points();
        ShaderDef&		textureArray();
        bool            getColor() const { return mColor; };
        bool            getAlphaBlending() const { return mAlphaBlending; };
        bool            getTexture() const { return mTextureMapping; };
        bool            getLambert() const { return mLambert; };
        bool            getPoints() const { return mPoints; };
        bool            getTextureArray() const { return mTextureArray; };
        
        // Display
        ShaderDef&		billboard();
        ShaderDef&		uniformBasedPosAndTexCoord();
        bool            getBillboard() const { return mBillboard; };
        bool            getUniformBasedPosAndTexCoord() const { return mUniformBasedPosAndTexCoord; };
        
        // Geom
        ShaderDef&      ring();
        
        bool			isTextureSwizzleDefault() const;
        std::string		getTextureSwizzleString() const;
        
        bool operator<( const ShaderDef &rhs ) const;
        
        protected:
        
        bool					mTextureMapping;
        std::array<int,4>		mTextureSwizzleMask;
        bool					mUniformBasedPosAndTexCoord;
        
        bool					mColor;
        bool                    mAlphaBlending;
        bool					mLambert;
        bool                    mPoints;
        bool					mTextureArray;
        bool                    mBillboard;
        bool                    mRing;
        
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