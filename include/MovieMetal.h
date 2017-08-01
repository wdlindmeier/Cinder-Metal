//
//  MovieMetal.h
//  VideoMetalTexture
//
//  Created by William Lindmeier on 7/11/17.
//

#pragma once

#include "cinder/Cinder.h"

// TODO: Update with OS X support
#ifdef CINDER_COCOA_TOUCH

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
        void seekToTime(double secondsOffset);
        double getDuration();
        void setRate(float rate);
        float getRate();
        
        TextureBufferRef & getTextureLuma();
        TextureBufferRef & getTextureChroma();
        
    protected:
        
        MovieMetal( const ci::fs::path & movieURL );
        MovieMetalImpl *mVideoDelegate;
    };
    
}}

#endif
