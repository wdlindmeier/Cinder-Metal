//
//  GeomTarget.hpp
//  MetalCube
//
//  Created by William Lindmeier on 10/24/15.
//
//

#pragma once

#include "cinder/Cinder.h"
#include "cinder/GeomIo.h"
#include "MetalGeom.h"
#include "MetalBuffer.h"
#include "MetalRenderEncoder.h"

namespace cinder
{
    namespace mtl
    {
        typedef std::shared_ptr<class GeomBufferTarget> GeomBufferTargetRef;
        
        // A class that pipes ci::geom Sources into metal buffers
        
        class GeomBufferTarget : public ci::geom::Target
        {
            
        public:

            // Create a container with no data.
            // Data should be passed in with setBufferForAttribute().
            static GeomBufferTargetRef create( const ci::geom::AttribSet & requestedAttribs,
                                               ci::mtl::geom::Primitive primitive = ci::mtl::geom::TRIANGLE );

            // NOTE: The order that the attribs are passed in is the order that they
            // should appear in the shader.
            static GeomBufferTargetRef create( const ci::geom::Source & source,
                                               const ci::geom::AttribSet & requestedAttribs );
            virtual ~GeomBufferTarget(){}
            
            ci::mtl::geom::Primitive getPrimitive(){ return mPrimitive; };
            void setPrimitive( const ci::mtl::geom::Primitive primitive ){ mPrimitive = primitive; };
            
            void setBufferForAttribute( MetalBufferRef buffer, const ci::geom::Attrib attr );
            
            void setVertexLength( size_t vertLength ){ mVertexLength = vertLength; };
            size_t getVertexLength(){ return mVertexLength; };

            void render( MetalRenderEncoderRef renderEncoder );
            void render( MetalRenderEncoderRef renderEncoder, size_t vertexLength, size_t vertexStart = 0, size_t instanceCount = 1 );
            
        protected:
            
            GeomBufferTarget( const ci::geom::Source & source, const ci::geom::AttribSet &requestedAttribs );
            GeomBufferTarget( const ci::geom::AttribSet &requestedAttribs, ci::mtl::geom::Primitive primitive );

            // geom::Target subclass
            // Only use internally
            void copyAttrib( ci::geom::Attrib attr, uint8_t dims, size_t strideBytes, const float *srcData, size_t count );
            void copyIndices( ci::geom::Primitive primitive, const uint32_t *source, size_t numIndices, uint8_t requiredBytesPerIndex );
            uint8_t getAttribDims( ci::geom::Attrib attr ) const;

            ci::mtl::geom::Primitive mPrimitive;
            std::map< ci::geom::Attrib, MetalBufferRef > mAttributeBuffers;
            ci::geom::AttribSet mRequestedAttribs;
            MetalBufferRef mIndexBuffer;
            ci::geom::SourceRef mSource;
            size_t mVertexLength;
            
        };
    }
}
