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
@class MetalRenderFormatImpl;
#else
class MetalRenderFormatImpl;
#endif

namespace cinder { namespace mtl {
    
    typedef std::shared_ptr<class MetalRenderFormat> MetalRenderFormatRef;
    
    class MetalRenderFormat
    {
        
        friend class MetalCommandBuffer;
        
    public:
        
        static MetalRenderFormatRef create();
        ~MetalRenderFormat(){};

        void setShouldClear( bool shouldClear );
        void setClearColor( const ColorAf clearColor );
        void setClearDepth( float clearDepth );

        // Hmmm...
        // Can this work w/ smart pointers?
//        MetalRenderFormat & shouldClear( bool shouldClear );
//        MetalRenderFormat & clearColor( const ColorAf clearColor );
//        MetalRenderFormat & clearDepth( float clearDepth );
        // TODO: Add "has depth" accessor
        
    protected:

        MetalRenderFormat();
        MetalRenderFormatImpl *mImpl;
        
    };
    
} }