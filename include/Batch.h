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
    
    typedef std::shared_ptr<class Batch> BatchRef;
    
    class Batch
    {
        public:
        
            //! Maps a geom::Attrib to a named attribute in the Pipeline
            typedef std::map<ci::geom::Attrib,std::string> AttributeMapping;
        
            //! Builds a Batch from a VboMesh and a Pipeline. Attributes defined in \a attributeMapping override the default mapping between AttributeSemantics and Pipeline attribute names
            static BatchRef		create( const VertexBufferRef & vertexBuffer,
                                        const RenderPipelineStateRef & renderPipeline,
                                        const AttributeMapping &attributeMapping = AttributeMapping() )
            {
                return BatchRef(new Batch(vertexBuffer, renderPipeline, attributeMapping));
            }
        
            //! Builds a Batch from a geom::Source and a Pipeline. Attributes defined in \a attributeMapping override the default mapping
            static BatchRef		create( const ci::geom::Source &source,
                                        const RenderPipelineStateRef & renderPipeline,
                                        const AttributeMapping &attributeMapping = AttributeMapping() )
            {
                return BatchRef(new Batch(source, renderPipeline, attributeMapping));
            }
            
            void draw( RenderEncoder & renderEncoder );
            void drawInstanced( RenderEncoder & renderEncoder, size_t instanceCount );
            void draw( RenderEncoder & renderEncoder,
                       size_t vertexStart,
                       size_t vertexLength,
                       size_t instanceCount = 1 );

            // Does bind apply to Metal?
            // void			bind();
            
            //! Returns OpenGL primitive type (GL_TRIANGLES, GL_TRIANGLE_STRIP, etc)
            ci::mtl::geom::Primitive getPrimitive(){ return mVertexBuffer->getPrimitive(); };
        
            //! Returns the total number of vertices in the associated geometry
            size_t			getNumVertices() const { return mVertexBuffer->getNumVertices(); }
        
            //! Returns the number of element indices in the associated geometry; 0 for non-indexed geometry
            size_t			getNumIndices() const { return mVertexBuffer->getNumIndices(); }
        
            //! Returns the data type for indices; GL_UNSIGNED_INT or GL_UNSIGNED_SHORT
            // GLenum			getIndexDataType() const { return mVboMesh->getIndexDataType(); }
        
            //! Returns the shader pipeline associated with the Batch
            const RenderPipelineStateRef& getPipeline() const { return mRenderPipeline; }
        
            //! Replaces the shader pipeline associated with the Batch.
            void			replacePipeline( const RenderPipelineStateRef& pipeline );
        
            //const VaoRef	getVao() const { return mVao; }
        
            //! Returns the VertexBuffer associated with the Batch
            VertexBufferRef getVertexBuffer() const { return mVertexBuffer; };
        
            //! Replaces the VertexBuffer associated with the Batch.
            void			replaceVertexBuffer( const VertexBufferRef &vertexBuffer );
            
            //! Changes the Metal context the Batch is associated with
            //void			reassignContext( Context *context );
            
        protected:
        
            Batch( const VertexBufferRef & vertexBuffer,
                   const RenderPipelineStateRef & pipeline,
                   const AttributeMapping &attributeMapping );
        
            Batch( const ci::geom::Source &source,
                   const RenderPipelineStateRef &pipeline,
                   const AttributeMapping &attributeMapping );
            
            void	initBufferLayout( const AttributeMapping &attributeMapping = AttributeMapping() );
        
            void    checkBufferLayout();
        
            VertexBufferRef         mVertexBuffer;
            RenderPipelineStateRef  mRenderPipeline;
            AttributeMapping		mAttribMapping;
        
            std::vector<ci::geom::Attrib> mInterleavedAttribs;
            std::map<ci::geom::Attrib, unsigned long> mAttribBufferIndices;

    };
}}