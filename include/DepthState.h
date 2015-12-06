//
//  DepthState.hpp
//  MetalCube
//
//  Created by William Lindmeier on 11/7/15.
//
//

#pragma once

#include "cinder/Cinder.h"
#include "MetalHelpers.hpp"

namespace cinder { namespace mtl {
    
    typedef std::shared_ptr<class DepthState> DepthStateRef;
    
    class DepthState
    {
        
    public:
        
        struct Format
        {
            Format() :
            mDepthCompareFunction(-1) // defaults to MTLCompareFunctionLessEqual
            ,mDepthWriteEnabled(false)
            ,mFrontFaceStencil(nullptr)
            ,mBackFaceStencil(nullptr)
            ,mLabel("Default Depth State")
            {}

            FORMAT_OPTION(depthCompareFunction, DepthCompareFunction, int) // MTLCompareFunction
            FORMAT_OPTION(depthWriteEnabled, DepthWriteEnabled, bool)
            // TODO: Maybe the back/front stencil descriptors don't belong in the format...
            FORMAT_OPTION(frontFaceStencil, FrontFaceStencil, void *) // MTLStencilDescriptor
            FORMAT_OPTION(backFaceStencil, BackFaceStencil, void *) // MTLStencilDescriptor
            FORMAT_OPTION(label, Label, std::string)
        };
        
        static DepthStateRef create( const Format & format = Format() )
        {
            return DepthStateRef( new DepthState(format) );
        }
        virtual ~DepthState();
        
        void * getNative(){ return mImpl; }
        
    protected:
        
        DepthState( Format format );
        
        void * mImpl = NULL; // <MTLDepthStencilState>
        Format mFormat;
        
    };
    
} }