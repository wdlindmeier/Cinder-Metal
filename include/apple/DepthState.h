//
//  DepthState.hpp
//
//  Created by William Lindmeier on 11/7/15.
//
//

#pragma once

#include "cinder/Cinder.h"
#include "MetalHelpers.hpp"
#include "MetalEnums.h"

namespace cinder { namespace mtl {
    
    typedef std::shared_ptr<class DepthState> DepthStateRef;
    
    class DepthState
    {
        
    public:
        
        struct Format
        {
            Format() :
            mDepthCompareFunction(CompareFunctionLessEqual)
            ,mDepthWriteEnabled(false)
            ,mFrontFaceStencil(nullptr)
            ,mBackFaceStencil(nullptr)
            ,mLabel("Default Depth State")
            {}

        public:

            Format& depthCompareFunction( CompareFunction depthCompareFunction ) { setDepthCompareFunction( depthCompareFunction ); return *this; };
            void setDepthCompareFunction( CompareFunction depthCompareFunction ) { mDepthCompareFunction = depthCompareFunction; };
            CompareFunction getDepthCompareFunction() { return mDepthCompareFunction; };

            Format& depthWriteEnabled( bool depthWriteEnabled = true ) { setDepthWriteEnabled( depthWriteEnabled ); return *this; };
            void setDepthWriteEnabled( bool depthWriteEnabled ) { mDepthWriteEnabled = depthWriteEnabled; };
            bool getDepthWriteEnabled() const { return mDepthWriteEnabled; };

            // TODO: Maybe the back/front stencil descriptors don't belong in the format...
            Format& frontFaceStencil( void * frontFaceStencil ) { setFrontFaceStencil( frontFaceStencil ); return *this; };
            void setFrontFaceStencil( void * frontFaceStencil ) { mFrontFaceStencil = frontFaceStencil; };
            void * getFrontFaceStencil() const { return mFrontFaceStencil; };

            Format& backFaceStencil( void * backFaceStencil ) { setBackFaceStencil( backFaceStencil ); return *this; };
            void setBackFaceStencil( void * backFaceStencil ) { mBackFaceStencil = backFaceStencil; };
            void * getBackFaceStencil() const { return mBackFaceStencil; };

            Format& label( std::string label ) { setLabel( label ); return *this; };
            void setLabel( std::string label ) { mLabel = label; };
            std::string getLabel() const { return mLabel; };

        protected:
            
            CompareFunction mDepthCompareFunction;
            bool mDepthWriteEnabled;
            void * mFrontFaceStencil;
            void * mBackFaceStencil;
            std::string mLabel;
            
        };
        
        static DepthStateRef create( const Format & format = Format() )
        {
            return DepthStateRef( new DepthState(format) );
        }
        
        static DepthStateRef create( void *mtlDepthStencilState )
        {
            return DepthStateRef( new DepthState(mtlDepthStencilState) );
        }
        
        virtual ~DepthState();
        
        void * getNative(){ return mImpl; }
        
    protected:
        
        DepthState( Format format );
        DepthState( void *mtlDepthStencilState );
        
        void * mImpl = NULL; // <MTLDepthStencilState>
        Format mFormat;
        
    };
    
} }