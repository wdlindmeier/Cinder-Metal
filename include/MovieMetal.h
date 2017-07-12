//
//  MovieMetal.h
//  VideoMetalTexture
//
//  Created by William Lindmeier on 7/11/17.
//

#pragma once

#include "cinder/Cinder.h"
#include "metal.h"
#include <memory>

@class MovieMetalImpl;

namespace cinder { namespace mtl {
    
    typedef std::shared_ptr<class MovieMetal> MovieMetalRef;
    
    class MovieMetal
    {
        
    public:
        
        static MovieMetalRef create( const ci::fs::path & movieURL )
        {
            return MovieMetalRef(new MovieMetal(movieURL));
        }
        
        void play();
        void pause();
        
        TextureBufferRef & textureLuma();
        TextureBufferRef & textureChroma();
        
    protected:
        
        MovieMetal( const ci::fs::path & movieURL );
        MovieMetalImpl *mVideoDelegate;
    };
    
}}

