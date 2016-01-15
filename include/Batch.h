//
//  Batch.hpp
//  Batch
//
//  Created by William Lindmeier on 1/10/16.
//
//

#pragma once

#include "cinder/Cinder.h"
#include "cinder/GeomIo.h"
#include "MetalGeom.h"
#include "DataBuffer.h"
#include "RenderEncoder.h"
#include "VertexBuffer.h"
#include "apple/RenderPipelineState.h"

namespace cinder { namespace mtl {
    
//    enum UniformSemantic {
//        UNIFORM_MODEL_MATRIX,
//        UNIFORM_MODEL_MATRIX_INVERSE,
//        UNIFORM_MODEL_MATRIX_INVERSE_TRANSPOSE,
//        UNIFORM_VIEW_MATRIX,
//        UNIFORM_VIEW_MATRIX_INVERSE,
//        UNIFORM_MODEL_VIEW,
//        UNIFORM_MODEL_VIEW_INVERSE,
//        UNIFORM_MODEL_VIEW_INVERSE_TRANSPOSE,
//        UNIFORM_MODEL_VIEW_PROJECTION,
//        UNIFORM_MODEL_VIEW_PROJECTION_INVERSE,
//        UNIFORM_PROJECTION_MATRIX,
//        UNIFORM_PROJECTION_MATRIX_INVERSE,
//        UNIFORM_VIEW_PROJECTION,
//        UNIFORM_NORMAL_MATRIX,
//        UNIFORM_VIEWPORT_MATRIX,
//        UNIFORM_WINDOW_SIZE,
//        UNIFORM_ELAPSED_SECONDS,
//        UNIFORM_USER_DEFINED
//    };

    typedef std::shared_ptr<class Batch> BatchRef;
    
    class Batch
    {
        public:
            //! Maps a geom::Attrib to a named attribute in the GlslProg
            typedef std::map<ci::geom::Attrib,std::string> AttributeMapping;
        
            //mtl::RenderPipelineState
            //! Builds a Batch from a VboMesh and a GlslProg. Attributes defined in \a attributeMapping override the default mapping between AttributeSemantics and GlslProg attribute names
        // TODO
            static BatchRef		create( const VertexBufferRef & vertexBuffer, //const VboMeshRef &vboMesh,
                                        const RenderPipelineStateRef & renderPipeline, // aaconst gl::GlslProgRef &glsl,
                                        const AttributeMapping &attributeMapping = AttributeMapping() )
            {
                return BatchRef(new Batch(vertexBuffer, renderPipeline, attributeMapping));
            }
        
            //! Builds a Batch from a geom::Source and a GlslProg. Attributes defined in \a attributeMapping override the default mapping
        
            static BatchRef		create( const ci::geom::Source &source,
                                        //const gl::GlslProgRef &glsl,
                                        const RenderPipelineStateRef & renderPipeline,
                                        const AttributeMapping &attributeMapping = AttributeMapping() )
            {
                return BatchRef(new Batch(source, renderPipeline, attributeMapping));
            }
            
            //! Draws the Batch. Optionally specify a \a first vertex/element and a \a count. Otherwise the entire geometry will be drawn.
            //void			draw( GLint first = 0, GLsizei count = -1 );
            void draw( RenderEncoder & renderEncoder );
            void drawInstanced( RenderEncoder & renderEncoder, size_t instanceCount );
            void draw( RenderEncoder & renderEncoder,
                       size_t vertexStart,
                       size_t vertexLength,
                       size_t instanceCount = 1 );

//#if defined( CINDER_GL_HAS_DRAW_INSTANCED )
//            void			drawInstanced( GLsizei instanceCount );
//#endif
            // TODO: What's the eqiv. to "bind"? Maybe there doesn't need to be
            // void			bind();
            
            //! Returns OpenGL primitive type (GL_TRIANGLES, GL_TRIANGLE_STRIP, etc)
            // GLenum			getPrimitive() const { return mVboMesh->getGlPrimitive(); }
            ci::mtl::geom::Primitive getPrimitive(){ return mVertexBuffer->getPrimitive(); };
        
            //! Returns the total number of vertices in the associated geometry
            //size_t			getNumVertices() const { return mVboMesh->getNumVertices(); }
            size_t			getNumVertices() const { return mVertexBuffer->getNumVertices(); }
        
            //! Returns the number of element indices in the associated geometry; 0 for non-indexed geometry
            //size_t			getNumIndices() const { return mVboMesh->getNumIndices(); }
            size_t			getNumIndices() const { return mVertexBuffer->getNumIndices(); }
        
            //! Returns the data type for indices; GL_UNSIGNED_INT or GL_UNSIGNED_SHORT
            // GLenum			getIndexDataType() const { return mVboMesh->getIndexDataType(); }
        
            //! Returns the shader associated with the Batch
            // const GlslProgRef&	getGlslProg() const	{ return mGlsl; }
            const RenderPipelineStateRef& getPipeline() const { return mRenderPipeline; }
        
            //! Replaces the shader associated with the Batch. Issues a warning if not all attributes were able to match.
            //void			replaceGlslProg( const GlslProgRef& glsl );
            void			replacePipeline( const RenderPipelineStateRef& pipeline );
        
            //! Returns the VAO mapping the Batch's geometry to its shader
            //const VaoRef	getVao() const { return mVao; }
        
            //! Returns the VboMesh associated with the Batch
            // VboMeshRef		getVboMesh() const { return mVboMesh; }
            VertexBufferRef getVertexBuffer() const { return mVertexBuffer; };
        
            //! Replaces the VboMesh associated with the Batch. Issues a warning if not all attributes were able to match.
            //void			replaceVboMesh( const VboMeshRef &vboMesh );
            void			replaceVertexBuffer( const VertexBufferRef &vertexBuffer );
            
            //! Changes the GL context the Batch is associated with
            //void			reassignContext( Context *context );
            
        protected:
        
            // TODO:
            //Batch( const VboMeshRef &vboMesh, const gl::GlslProgRef &glsl, const AttributeMapping &attributeMapping );
            Batch( const VertexBufferRef & vertexBuffer,
                   const RenderPipelineStateRef & pipeline,
                   const AttributeMapping &attributeMapping );
        
            //Batch( const geom::Source &source, const gl::GlslProgRef &glsl, const AttributeMapping &attributeMapping );
            Batch( const ci::geom::Source &source,
                   const RenderPipelineStateRef &pipeline,
                   const AttributeMapping &attributeMapping );
            
            //void	init( const geom::Source &source, const gl::GlslProgRef &glsl );
            void	initBufferLayout( const AttributeMapping &attributeMapping = AttributeMapping() );
            
            //VboMeshRef				mVboMesh;
        VertexBufferRef         mVertexBuffer;
            //VaoRef					mVao;
        ci::geom::BufferLayout      mBufferLayout;
            //GlslProgRef				mGlsl;
        RenderPipelineStateRef  mRenderPipeline;
            AttributeMapping		mAttribMapping;
        std::vector<ci::geom::Attrib> mOrderedAttribs;
        
            //friend class BatchGeomTarget;
        };
}}