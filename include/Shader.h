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
        
        ShaderDef&		color();
        ShaderDef&		texture();
        ShaderDef&		texture( const TextureBufferRef &tex = TextureBufferRef() );
        ShaderDef&		texture( int target );
        ShaderDef&		lambert();
        ShaderDef&		pointSize();
        ShaderDef&		uniformBasedPosAndTexCoord();
        
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
        bool                    mPointSize;
        
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