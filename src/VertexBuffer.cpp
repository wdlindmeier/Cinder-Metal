//
//  GeomTarget.cpp
//
//  Created by William Lindmeier on 10/24/15.
//
//

#include "VertexBuffer.h"
#include "cinder/Log.h"
#include "MetalGeom.h"

using namespace cinder;
using namespace cinder::mtl;

VertexBufferRef VertexBuffer::create( uint32_t numVertices,
                                      const DataBufferRef interleavedData,
                                      const DataBufferRef bufferedIndices,
                                      const ci::mtl::geom::Primitive primitive )
{
    return VertexBufferRef( new VertexBuffer( numVertices, interleavedData, bufferedIndices, primitive ) );
}

VertexBuffer::VertexBuffer( uint32_t numVertices,
                            const DataBufferRef interleavedData,
                            const DataBufferRef bufferedIndices,
                            const ci::mtl::geom::Primitive primitive ) :
mPrimitive(primitive)
,mVertexLength(numVertices)
,mIsInterleaved(true)
,mIndexLength(0)
,mIndexBuffer(bufferedIndices)
,mInterleavedData(interleavedData)
{
    if ( mIndexBuffer )
    {
        mIndexLength = numVertices;
    }
}

VertexBufferRef VertexBuffer::create( uint32_t numVertices,
                                      const ci::mtl::geom::Primitive primitive )
{
    return VertexBufferRef( new VertexBuffer( numVertices, primitive ) );
}

VertexBuffer::VertexBuffer( uint32_t numVertices, const ci::mtl::geom::Primitive primitive ) :
mPrimitive(primitive)
,mVertexLength(numVertices)
,mIndexLength(0)
,mIsInterleaved(false)
{}

VertexBufferRef VertexBuffer::create( const ci::geom::Source & source,
                                      const std::vector<ci::geom::Attrib> & orderedAttribs,
                                      const DataBuffer::Format & format )
{
    size_t stride = 0;
    
    // If the user didn't request specific attributes, send them all in.
    std::vector<ci::geom::Attrib> loadAttribs = orderedAttribs;
    if ( loadAttribs.size() == 0 )
    {
        for ( ci::geom::Attrib a : source.getAvailableAttribs() )
        {
            loadAttribs.push_back(a);
        }
    }
    
    // First calculate the stride
    for ( const ci::geom::Attrib & attrib : loadAttribs )
    {
        uint dimensions = source.getAttribDims(attrib);
        stride += dimensions * sizeof(float);
    }
    
    ci::geom::BufferLayout geomLayout;
    size_t offset = 0;
    // Next, create a BufferLayout for all available attributes
    for ( const ci::geom::Attrib & attrib : loadAttribs )
    {
        uint dimensions = source.getAttribDims(attrib);
        geomLayout.append(attrib, dimensions, stride, offset);
        offset += dimensions * sizeof(float);
    }
    assert(offset == stride);
    
    return VertexBufferRef( new VertexBuffer( source, geomLayout, format ) );
}

VertexBufferRef VertexBuffer::create( const ci::geom::Source & source,
                                      const ci::geom::BufferLayout & layout,
                                      const DataBuffer::Format & format )
{
    return VertexBufferRef( new VertexBuffer( source, layout, format ) );
}

VertexBuffer::VertexBuffer( const ci::geom::Source & source,
                            const ci::geom::BufferLayout & layout,
                            DataBuffer::Format format ) :
mSource( source.clone() )
,mVertexLength(0)
,mIndexLength(0)
,mBufferLayout(layout)
,mIsInterleaved(true)
{
    // Is there any reason to keep the Source around?
    mPrimitive = geom::mtlPrimitiveTypeFromGeom( mSource->getPrimitive() );
    mVertexLength = mSource->getNumVertices();
    // NOTE: If there are no indices, we'll just generate them; 1 for each vert
    size_t numSourceIndices = mSource->getNumIndices();
    mIndexLength = std::max<size_t>(numSourceIndices, mVertexLength);

    // Create the data buffer for the indices
    DataBuffer::Format indexFormat = format;
    indexFormat.setLabel(format.getLabel() + ": Indices");
    mIndexBuffer = DataBuffer::create(mIndexLength * sizeof(uint32_t), NULL, indexFormat);
    
    // Create the buffer for the interleaved vert data
    size_t numVertData = mSource->getNumVertices();
    size_t bufferLength = mBufferLayout.calcRequiredStorage( numVertData );

    DataBuffer::Format interleavedFormat = format;
    interleavedFormat.setLabel(format.getLabel() + ": Interleaved");
    mInterleavedData = DataBuffer::create(bufferLength, nullptr, interleavedFormat);

    // Construct the requested attribs
    ci::geom::AttribSet requestedAttribs;
    for( const auto &attribInfo : layout.getAttribs() )
    {
        requestedAttribs.insert(attribInfo.getAttrib());
    }
    
    mSource->loadInto( this, requestedAttribs );
    
    mInterleavedData->didModifyRange(0, bufferLength);
    
    if ( numSourceIndices <= 0 )
    {
        createDefaultIndices();
    }
}

DataBufferRef VertexBuffer::getBufferForAttribute( const ci::geom::Attrib attr )
{
    return mAttributeBuffers[attr];
}

void VertexBuffer::setBufferForAttribute( DataBufferRef buffer,
                                          const ci::geom::Attrib attr,
                                          int shaderBufferIndex )
{
    mAttributeBuffers[attr] = buffer;
    
    if ( shaderBufferIndex != -1 )
    {
        setAttributeBufferIndex(attr, shaderBufferIndex);
    }
    else if ( mAttributeBufferIndices.count(attr) == 0 )
    {
        // If we don't have an index, use the default
        setAttributeBufferIndex(attr, geom::defaultBufferIndexForAttribute(attr));
    }
}

unsigned long VertexBuffer::getAttributeBufferIndex( const ci::geom::Attrib attr )
{
    if ( mAttributeBufferIndices.count(attr) != 0 )
    {
        return mAttributeBufferIndices[attr];
    }
    return -1;
}

void VertexBuffer::setAttributeBufferIndex( const ci::geom::Attrib attr, unsigned long shaderBufferIndex )
{
    mAttributeBufferIndices[attr] = shaderBufferIndex;
}

void VertexBuffer::copyAttrib( ci::geom::Attrib attr, // POSITION, TEX_COORD_0 etc
                               uint8_t dims, // Number of floats
                               size_t strideBytes, // Stride. See srcData
                               const float *srcData, // Data representing the attribute ONLY. Not interleaved w/ other attrs
                               size_t count ) // Number of values
{
    // Skip the copy if we don't care about this attr
    if ( !mBufferLayout.hasAttrib(attr) )
    {
        CI_LOG_I("Skipping attr " << attr << ". Not found in requested attributes." );
        return;
    }
    
    ci::geom::AttribInfo attrInfo = mBufferLayout.getAttribInfo(attr);
    
    uint8_t *dstData = nullptr;
    uint8_t dstDims;
    size_t dstStride, dstDataSize;
    dstDims = attrInfo.getDims();
    dstStride = attrInfo.getStride();

    if ( dstDims == 0 )
    {
        CI_LOG_F("FATAL: The geometry source doesn't have data for attr " << attr << ". This probably means your shader is asking for it.");
        assert( false );
    }

    uint8_t *bufferPointer = (uint8_t*)mInterleavedData->contents();
    dstData = bufferPointer + attrInfo.getOffset();
    dstDataSize = mInterleavedData->getLength();
    
    CI_ASSERT( dstData );

    // verify we have room for this data
    auto testDstStride = dstStride ? dstStride : ( dstDims * sizeof(float) );
    if( dstDataSize < count * testDstStride )
    {
        CI_LOG_E( "copyAttrib() called with inadequate attrib data storage allocated" );
        assert( false );
    }
    
    ci::geom::copyData( dims, srcData, count, dstDims, dstStride, reinterpret_cast<float*>( dstData ) );
}


void VertexBuffer::copyIndices( ci::geom::Primitive primitive, const uint32_t *source,
                                size_t numIndices, uint8_t requiredBytesPerIndex )
{
    assert( mPrimitive == mtl::geom::mtlPrimitiveTypeFromGeom(primitive) );
    std::vector<uint32_t> indices;
    for ( size_t i = 0; i < numIndices; ++i )
    {
        // Convert the index into the type expected by Metal
        uint32_t idx = source[i];
        indices.push_back(idx);
    }
    mIndexBuffer->update(indices);
}

void VertexBuffer::createDefaultIndices()
{
    assert(mIndexLength == mVertexLength);
    std::vector<uint32_t> indices;
    for ( uint32_t i = 0; i < mVertexLength; ++i )
    {
        indices.push_back(i);
    }
    mIndexBuffer->update(indices);
}

uint8_t VertexBuffer::getAttribDims( ci::geom::Attrib attr ) const
{
    if ( mSource )
    {
        return mSource->getAttribDims(attr);
    }
    
    CI_LOG_E("Requesting attrib dims for a VertexBuffer with no source. Returning 0.");
    
    return 0;
}

void VertexBuffer::draw( RenderEncoder & renderEncoder )
{
    drawInstanced(renderEncoder, 1);
}

void VertexBuffer::drawInstanced( RenderEncoder & renderEncoder, size_t instanceCount )
{
    if ( instanceCount <= 0 )
    {
        return;
    }
    
    if ( mIndexLength > 0 )
    {
        draw( renderEncoder, mIndexLength, 0, instanceCount );
    }
    else
    {
        if ( mVertexLength == 0 )
        {
            CI_LOG_E("Vertex length must be > 0 for non-indexed VertexBuffer");
        }
        assert( mVertexLength > 0 );
        draw( renderEncoder, mVertexLength, 0, instanceCount );
    }
}

void VertexBuffer::draw( RenderEncoder & renderEncoder,
                         size_t vertexLength,
                         size_t vertexStart,
                         size_t instanceCount )
{
    for ( auto kvp : mAttributeBufferIndices )
    {
        ci::geom::Attrib attr = kvp.first;
        DataBufferRef buffer = mAttributeBuffers[attr];
        assert( !!buffer );
        renderEncoder.setVertexBufferAtIndex( buffer, kvp.second );
    }

    if ( mIsInterleaved )
    {
        // NOTE: We're not using drawIndexed because Metal requires that we define
        // a MTLVertexDescriptor as part of the pipeline, which is less flexible
        // that using a known data layout with index access. This also lets us
        // use BufferLayouts, which follows the Cinder convention.
        renderEncoder.setVertexBufferAtIndex( mInterleavedData, ciBufferIndexInterleavedVerts );
    }

    if ( mIndexBuffer )
    {
        size_t indexBufferOffset = vertexStart * sizeof(u_int32_t);
        renderEncoder.drawIndexed( mPrimitive,
                                   mIndexBuffer,
                                   vertexLength,
                                   instanceCount,
                                   indexBufferOffset);

    }
    else
    {
        renderEncoder.draw( mPrimitive,
                            vertexLength,
                            vertexStart,
                            instanceCount );
    }
}
