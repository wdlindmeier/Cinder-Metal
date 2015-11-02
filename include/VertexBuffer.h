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
#include "DataBuffer.h"
#include "RenderEncoder.h"

namespace cinder
{
    namespace geom
    {
        // Append "INDEX" onto the attrib list so we can assign a buffer and shader index to it like an Attrib
        static Attrib INDEX = USER_DEFINED;
    }
    
    namespace mtl
    {
        typedef std::shared_ptr<class VertexBuffer> VertexBufferRef;
        
        class VertexBuffer : public ci::geom::Target
        {
            
        public:

            static VertexBufferRef create( const std::map<ci::geom::Attrib, int> & requestedAttribsWithShaderIndex = {{}},
                                           ci::mtl::geom::Primitive primitive = ci::mtl::geom::TRIANGLE );

            static VertexBufferRef create( const ci::geom::Source & source,
                                           const std::map<ci::geom::Attrib, int> & requestedAttribsWithShaderIndex = {{}} );
            virtual ~VertexBuffer(){}
            
            ci::mtl::geom::Primitive getPrimitive(){ return mPrimitive; };
            void setPrimitive( const ci::mtl::geom::Primitive primitive ){ mPrimitive = primitive; };
            
            // Set shaderBufferIndex to something > -1 if you wish to update / assign the shader index for this attribute
            void setBufferForAttribute( DataBufferRef buffer, const ci::geom::Attrib attr,
                                        int shaderBufferIndex = -1 );
            DataBufferRef getBufferForAttribute( const ci::geom::Attrib attr );
            
            template<typename T>
            void update( ci::geom::Attrib attr, std::vector<T> vectorData )
            {
                getBufferForAttribute(attr)->update(vectorData);
            }
            
            void setVertexLength( size_t vertLength ){ mVertexLength = vertLength; };
            size_t getVertexLength(){ return mVertexLength; };

            void render( RenderEncoderRef renderEncoder );
            void render( RenderEncoderRef renderEncoder, size_t vertexLength,
                         size_t vertexStart = 0, size_t instanceCount = 1 );
            
        protected:
            
            VertexBuffer( const ci::geom::Source & source,
                          const std::map<ci::geom::Attrib, int> & requestedAttribsWithShaderIndex );
            VertexBuffer( const std::map<ci::geom::Attrib, int> & requestedAttribsWithShaderIndex,
                          ci::mtl::geom::Primitive primitive );

            // geom::Target subclass
            // Only use internally
            void copyAttrib( ci::geom::Attrib attr, uint8_t dims, size_t strideBytes, const float *srcData, size_t count );
            void copyIndices( ci::geom::Primitive primitive, const uint32_t *source, size_t numIndices, uint8_t requiredBytesPerIndex );
            uint8_t getAttribDims( ci::geom::Attrib attr ) const;

            ci::mtl::geom::Primitive mPrimitive;
            std::map< ci::geom::Attrib, DataBufferRef > mAttributeBuffers;
            
            std::map<ci::geom::Attrib, int> mRequestedAttribs;
            //DataBufferRef mIndexBuffer;
            ci::geom::SourceRef mSource;
            size_t mVertexLength;
            
        };
    }
}
