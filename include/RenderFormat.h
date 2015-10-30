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
        
        static RenderFormatRef create();
        ~RenderFormat(){};

        void setShouldClear( bool shouldClear );
        void setClearColor( const ColorAf clearColor );
        void setClearDepth( float clearDepth );

    protected:

        RenderFormat();
        RenderFormatImpl *mImpl;
        
    };
    
} }