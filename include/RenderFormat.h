//
//  MetalRenderPass.hpp
//  MetalCube
//
//  Created by William Lindmeier on 10/13/15.
//
//

#pragma once

#include "cinder/Cinder.h"
#include "MetalHelpers.hpp"

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
            mShouldClear(true)
            ,mClearColor(0.f,0.f,0.f,1.f)
            ,mClearDepth(1.f)
            {};
            
            FORMAT_OPTION(shouldClear, ShouldClear, bool)
            FORMAT_OPTION(clearColor, ClearColor, ci::ColorAf)
            FORMAT_OPTION(clearDepth, ClearDepth, float)
        };
        
        static RenderFormatRef create( Format format = Format() );
        ~RenderFormat(){};
        
        void * getNative(); // MTLRenderPassDescriptor *
        
    protected:

        void prepareForTexture( void * texture ); // <MTLTexture>
        
        void setShouldClear( bool shouldClear );
        void setClearColor( const ColorAf clearColor );
        void setClearDepth( float clearDepth );

        RenderFormat( Format format );
        RenderFormatImpl *mImpl;
        
    };
    
} }