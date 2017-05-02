//
//  Pipeline.hpp
//
//  Created by William Lindmeier on 10/13/15.
//
//

#pragma once

#include "cinder/Cinder.h"
#include "cinder/GeomIo.h"
#include "MetalHelpers.hpp"
#include "MetalEnums.h"
#include "Argument.h"

namespace cinder { namespace mtl {
    
    typedef std::shared_ptr<class RenderPipelineState> RenderPipelineStateRef;
    
    class RenderPipelineState
    {
        
    public:
        
        struct Format
        {
            Format() :
            mSampleCount(1)
            ,mNumColorAttachments(1)
            ,mBlendingEnabled(false)
            ,mColorBlendOperation(BlendOperationAdd)
            ,mAlphaBlendOperation(BlendOperationAdd)
            ,mSrcColorBlendFactor(BlendFactorSourceAlpha)
            ,mSrcAlphaBlendFactor(BlendFactorSourceAlpha)
            ,mDstColorBlendFactor(BlendFactorOneMinusSourceAlpha)
            ,mDstAlphaBlendFactor(BlendFactorOneMinusSourceAlpha)
            ,mLabel("Default Pipeline")
            ,mColorPixelFormat(PixelFormatBGRA8Unorm)
            ,mDepthPixelFormat(PixelFormatDepth32Float)
            ,mStencilPixelFormat(PixelFormatInvalid)
            ,mPreprocessSource(true)
            {}

        public:

            Format& sampleCount( int sampleCount ) { setSampleCount( sampleCount ); return *this; };
            void setSampleCount( int sampleCount ) { mSampleCount = sampleCount; };
            int getSampleCount() const { return mSampleCount; };

            Format& blendingEnabled( bool blendingEnabled = true ) { setBlendingEnabled( blendingEnabled ); return *this; };
            void setBlendingEnabled( bool blendingEnabled ) { mBlendingEnabled = blendingEnabled; };
            bool getBlendingEnabled() const { return mBlendingEnabled; };

            Format& colorBlendOperation( BlendOperation colorBlendOperation ) { setColorBlendOperation( colorBlendOperation ); return *this; };
            void setColorBlendOperation( BlendOperation colorBlendOperation ) { mColorBlendOperation = colorBlendOperation; };
            BlendOperation getColorBlendOperation() const { return mColorBlendOperation; };

            Format& alphaBlendOperation( BlendOperation alphaBlendOperation ) { setAlphaBlendOperation( alphaBlendOperation ); return *this; };
            void setAlphaBlendOperation( BlendOperation alphaBlendOperation ) { mAlphaBlendOperation = alphaBlendOperation; };
            BlendOperation getAlphaBlendOperation() const { return mAlphaBlendOperation; };

            Format& srcColorBlendFactor( BlendFactor srcColorBlendFactor ) { setSrcColorBlendFactor( srcColorBlendFactor ); return *this; };
            void setSrcColorBlendFactor( BlendFactor srcColorBlendFactor ) { mSrcColorBlendFactor = srcColorBlendFactor; };
            BlendFactor getSrcColorBlendFactor() const { return mSrcColorBlendFactor; };

            Format& srcAlphaBlendFactor( BlendFactor srcAlphaBlendFactor ) { setSrcAlphaBlendFactor( srcAlphaBlendFactor ); return *this; };
            void setSrcAlphaBlendFactor( BlendFactor srcAlphaBlendFactor ) { mSrcAlphaBlendFactor = srcAlphaBlendFactor; };
            BlendFactor getSrcAlphaBlendFactor() const { return mSrcAlphaBlendFactor; };

            Format& dstColorBlendFactor( BlendFactor dstColorBlendFactor ) { setDstColorBlendFactor( dstColorBlendFactor ); return *this; };
            void setDstColorBlendFactor( BlendFactor dstColorBlendFactor ) { mDstColorBlendFactor = dstColorBlendFactor; };
            BlendFactor getDstColorBlendFactor() const { return mDstColorBlendFactor; };

            Format& dstAlphaBlendFactor( BlendFactor dstAlphaBlendFactor ) { setDstAlphaBlendFactor( dstAlphaBlendFactor ); return *this; };
            void setDstAlphaBlendFactor( BlendFactor dstAlphaBlendFactor ) { mDstAlphaBlendFactor = dstAlphaBlendFactor; };
            BlendFactor getDstAlphaBlendFactor() const { return mDstAlphaBlendFactor; };

            Format& preprocessSource( bool preprocessSource ) { setPreprocessSource( preprocessSource ); return *this; };
            void setPreprocessSource( bool preprocessSource ) { mPreprocessSource = preprocessSource; };
            bool getPreprocessSource() const { return mPreprocessSource; };
            
            Format& label( std::string label ) { setLabel( label ); return *this; };
            void setLabel( std::string label ) { mLabel = label; };
            std::string getLabel() const { return mLabel; };

            Format& colorPixelFormat( PixelFormat pixelFormat ) { setColorPixelFormat( pixelFormat ); return *this; };
            void setColorPixelFormat( PixelFormat pixelFormat ) { mColorPixelFormat = pixelFormat; };
            PixelFormat getColorPixelFormat() const { return mColorPixelFormat; };

            Format& depthPixelFormat( PixelFormat pixelFormat ) { setDepthPixelFormat( pixelFormat ); return *this; };
            void setDepthPixelFormat( PixelFormat pixelFormat ) { mDepthPixelFormat = pixelFormat; };
            PixelFormat getDepthPixelFormat() const { return mDepthPixelFormat; };

            Format& stencilPixelFormat( PixelFormat pixelFormat ) { setStencilPixelFormat( pixelFormat ); return *this; };
            void setStencilPixelFormat( PixelFormat pixelFormat ) { mStencilPixelFormat = pixelFormat; };
            PixelFormat getStencilPixelFormat() const { return mStencilPixelFormat; };

            Format& numColorAttachments( int numAttachments ) { setNumColorAttachments( numAttachments ); return *this; };
            void setNumColorAttachments( int numAttachments ) { mNumColorAttachments = numAttachments; };
            int getNumColorAttachments() const { return mNumColorAttachments; };

        protected:
            
            int mNumColorAttachments;
            int mSampleCount;
            bool mBlendingEnabled;
            BlendOperation mColorBlendOperation;
            BlendOperation mAlphaBlendOperation;
            BlendFactor mSrcColorBlendFactor;
            BlendFactor mSrcAlphaBlendFactor;
            BlendFactor mDstColorBlendFactor;
            BlendFactor mDstAlphaBlendFactor;
            std::string mLabel;
            PixelFormat mColorPixelFormat;
            PixelFormat mDepthPixelFormat;
            PixelFormat mStencilPixelFormat;
            bool mPreprocessSource;
            
        };
        
        static RenderPipelineStateRef create( const std::string & vertShaderName,
                                              const std::string & fragShaderName,
                                              const Format & format = Format(),
                                              void * mtlLibrary = nullptr ) // native <MTLLibrary>
        {
            return RenderPipelineStateRef( new RenderPipelineState(vertShaderName,
                                                                   fragShaderName,
                                                                   format,
                                                                   mtlLibrary) );
        }
        
        static RenderPipelineStateRef create( void * mtlRenderPipelineStateRef, void *mtlRenderPipelineReflection )
        {
            return RenderPipelineStateRef( new RenderPipelineState(mtlRenderPipelineStateRef, mtlRenderPipelineReflection) );
        }
        
        static RenderPipelineStateRef create( const std::string & librarySource,
                                              const std::string & vertName,
                                              const std::string & fragName,
                                              const mtl::RenderPipelineState::Format & format = mtl::RenderPipelineState::Format() );
        
        virtual ~RenderPipelineState();
        
        void * getNative(){ return mImpl; }
        void sampleLog();
        
        //const std::vector<ci::geom::Attribute>&	getActiveAttributes() const { return mAttributes; }
        const std::vector<ci::mtl::Argument> & getFragmentArguments();
        const std::vector<ci::mtl::Argument> & getVertexArguments();

    protected:
        
        RenderPipelineState( const std::string & vertShaderName,
                             const std::string & fragShaderName,
                             Format format,
                             void * mtlLibrary );
        
        RenderPipelineState( void * mtlRenderPipelineStateRef, void * mtlRenderPipelineReflection );
        
        void * mImpl = NULL;  // <MTLRenderPipelineState>
        void * mReflection = NULL; // <MTLRenderPipelineReflection>
        Format mFormat;
        
        std::vector<ci::mtl::Argument> mVertexArguments;
        std::vector<ci::mtl::Argument> mFragmentArguments;
    };
    
} }