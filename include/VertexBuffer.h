//
//  GeomTarget.hpp
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

namespace cinder { namespace mtl {
    
    typedef std::shared_ptr<class VertexBuffer> VertexBufferRef;
    
    class VertexBuffer : public ci::geom::Target
    {
        
    public:

        // Create a VertexBuffer with interleaved data. Optionally pass in indices if the data is indexed.
        static VertexBufferRef create( uint32_t numVertices,
                                       const DataBufferRef interleavedData,
                                       const DataBufferRef bufferedIndices = DataBufferRef(),
                                       const ci::mtl::geom::Primitive primitive = ci::mtl::geom::TRIANGLE );

        static VertexBufferRef create( uint32_t numVertices,
                                       const ci::mtl::geom::Primitive primitive = ci::mtl::geom::TRIANGLE );

        static VertexBufferRef create( const ci::geom::Source & source,
                                       const std::vector<ci::geom::Attrib> & orderedAttribs = {{}},
                                       const DataBuffer::Format & format = DataBuffer::Format()
                                                                           .label("Verts") );

        // The DataBuffer::Format will be used to create the index and interleaved data buffers.
        static VertexBufferRef create( const ci::geom::Source & source,
                                       const ci::geom::BufferLayout & layout,
                                       const DataBuffer::Format & format = DataBuffer::Format()
                                                                            .label("Verts") );
        virtual ~VertexBuffer(){}
        
        ci::mtl::geom::Primitive getPrimitive(){ return mPrimitive; };
        void setPrimitive( const ci::mtl::geom::Primitive primitive ){ mPrimitive = primitive; };
        
        // Set shaderBufferIndex to something > -1 if you wish to update / assign the shader index for this attribute
        void setBufferForAttribute( DataBufferRef buffer,
                                    const ci::geom::Attrib attr,
                                    int shaderBufferIndex = -1 );
        DataBufferRef getBufferForAttribute( const ci::geom::Attrib attr );
        
        void setInterleavedBuffer( DataBufferRef buffer ){ mInterleavedData = buffer; };
        DataBufferRef getInterleavedBuffer(){ return mInterleavedData; };

        void setIndexBuffer( DataBufferRef buffer ){ mIndexBuffer = buffer; };
        DataBufferRef getIndexBuffer(){ return mIndexBuffer; };

        // Override the default shader indices.
        // The default geom::Attr shader indices are defined in MetalConstants.h
        void setAttributeBufferIndex( const ci::geom::Attrib attr, unsigned long shaderBufferIndex );
        // Returns -1 if the attr doesnt have an index
        unsigned long getAttributeBufferIndex( const ci::geom::Attrib attr );

//        void setIndicesBufferIndex( unsigned long shaderBufferIndex ){ mBufferIndexIndices = shaderBufferIndex; };
//        unsigned long getIndicesBufferIndex(){ return mBufferIndexIndices; };

        template<typename T>
        void update( ci::geom::Attrib attr, std::vector<T> vectorData )
        {
            getBufferForAttribute(attr)->update(vectorData);
        }
        
        bool getIsInterleaved(){ return mIsInterleaved; };
        
        size_t getNumVertices(){ return mVertexLength; };
        size_t getNumIndices(){ return mIndexLength; };
        
        void draw( RenderEncoder & renderEncoder );
        void drawInstanced( RenderEncoder & renderEncoder, size_t instanceCount );
        void draw( RenderEncoder & renderEncoder, size_t vertexLength,
                   size_t vertexStart = 0, size_t instanceCount = 1 );
        
    protected:
        
        VertexBuffer( uint32_t numVertices,
                      const DataBufferRef interleavedData,
                      const DataBufferRef bufferedIndices,
                      const ci::mtl::geom::Primitive primitive);

        VertexBuffer( const ci::geom::Source & source,
                      const ci::geom::BufferLayout & layout,
                      DataBuffer::Format format );
        
        VertexBuffer( uint32_t numVertices,
                      const ci::mtl::geom::Primitive primitive );

        // geom::Target subclass
        void copyAttrib( ci::geom::Attrib attr, uint8_t dims, size_t strideBytes, const float *srcData, size_t count );
        void copyIndices( ci::geom::Primitive primitive, const uint32_t *source, size_t numIndices, uint8_t requiredBytesPerIndex );
        uint8_t getAttribDims( ci::geom::Attrib attr ) const;

        void createDefaultIndices();
        
        ci::mtl::geom::Primitive mPrimitive;
        std::map<ci::geom::Attrib, DataBufferRef> mAttributeBuffers;
        
        std::map<ci::geom::Attrib, unsigned long> mAttributeBufferIndices;
        ci::geom::SourceRef mSource;
        size_t mVertexLength;
        size_t mIndexLength;
        
//        unsigned long mBufferIndexIndices = ciBufferIndexIndices; // default
        
        ci::geom::BufferLayout mBufferLayout;
        DataBufferRef mInterleavedData;
        DataBufferRef mIndexBuffer;
        bool mIsInterleaved;
        
    };
}}
