//
//  MetalRenderPass.hpp
//  MetalCube
//
//  Created by William Lindmeier on 10/13/15.
//
//

#pragma once

#include "cinder/Cinder.h"

#if defined( __OBJC__ )
@class RenderFormatImpl;
#else
class RenderFormatImpl;
#endif

namespace cinder { namespace mtl {
    
    typedef std::shared_ptr<class RenderFormat> RenderFormatRef;
    
    class RenderFormat
    {
        
        friend class CommandBuffer;
        
    public:
        
        struct Format
        {
            Format() :
            mShouldClear(true), mClearColor(0.f,0.f,0.f,1.f), mClearDepth(1.f)
            {};
            
            Format& shouldClear( bool shouldClear ) { setShouldClear( shouldClear ); return *this; }
            Format& clearColor( ci::ColorAf clearColor ) { setClearColor( clearColor ); return *this; }
            Format& clearDepth( float clearDepth ) { setClearDepth( clearDepth ); return *this; }

            void setShouldClear( bool clear ) { mShouldClear = clear; }
            void setClearColor( ci::ColorAf color ) { mClearColor = color; }
            void setClearDepth( float depth ) { mClearDepth = depth; }
            
            bool getShouldClear() { return mShouldClear; }
            ci::ColorAf getClearColor() { return mClearColor; }
            float getClearDepth() { return mClearDepth; }
            
        protected:
            
            bool mShouldClear;
            ci::ColorAf mClearColor;
            float mClearDepth;
        };
        
        static RenderFormatRef create( Format format = Format() );
        ~RenderFormat(){};

        void setShouldClear( bool shouldClear );
        void setClearColor( const ColorAf clearColor );
        void setClearDepth( float clearDepth );

    protected:

        RenderFormat( Format format );
        RenderFormatImpl *mImpl;
        
    };
    
} }