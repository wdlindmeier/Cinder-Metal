//
//  GeomTarget.cpp
//  MetalCube
//
//  Created by William Lindmeier on 10/24/15.
//
//

#include "VertexBuffer.h"
#include "cinder/Log.h"

using namespace cinder;
using namespace cinder::mtl;

VertexBufferRef VertexBuffer::create( const std::map<ci::geom::Attrib, int> & requestedAttribs,
                                      ci::mtl::geom::Primitive primitive )
{
    return VertexBufferRef( new VertexBuffer( requestedAttribs, primitive ) );
}

VertexBuffer::VertexBuffer( const std::map<ci::geom::Attrib, int> & requestedAttribs,
                            ci::mtl::geom::Primitive primitive ) :
mRequestedAttribs(requestedAttribs)
,mPrimitive(primitive)
,mVertexLength(0)
{
}

VertexBufferRef VertexBuffer::create( const ci::geom::Source & source,
                                      const std::map<ci::geom::Attrib, int> & requestedAttribs )
{
    return VertexBufferRef( new VertexBuffer( source, requestedAttribs ) );
}

VertexBuffer::VertexBuffer( const ci::geom::Source & source,
                            const std::map<ci::geom::Attrib, int> & requestedAttribs ) :
mSource( source.clone() )
,mRequestedAttribs(requestedAttribs)
,mVertexLength(0)
{
    // Is there any reason to keep the source and attribs around?
    mPrimitive = geom::mtlPrimitiveTypeFromGeom( mSource->getPrimitive() );
    mVertexLength = mSource->getNumIndices();
    if ( mVertexLength == 0 )
    {
        mVertexLength = mSource->getNumVertices();
    }
    else
    {
        // Make sure we've got a shader index for the vert indices.
        assert( requestedAttribs.count(ci::geom::INDEX) > 0 );
    }
    
    ci::geom::AttribSet attribSet;
    for ( auto kvp : requestedAttribs )
    {
        attribSet.insert( kvp.first );
    }
    
    mSource->loadInto( this, attribSet );
}

DataBufferRef VertexBuffer::getBufferForAttribute( const ci::geom::Attrib attr )
{
    return mAttributeBuffers[attr];
}

void VertexBuffer::setBufferForAttribute( DataBufferRef buffer, const ci::geom::Attrib attr, int shaderBufferIndex )
{
    mAttributeBuffers[attr] = buffer;
    
    if ( shaderBufferIndex != -1 )
    {
        mRequestedAttribs[attr] = shaderBufferIndex;
    }
    else
    {
        // Make sure we've got an index for this attribute
        assert( mRequestedAttribs.count(attr) > 0 );
    }
}

void VertexBuffer::copyAttrib( ci::geom::Attrib attr, // POSITION, TEX_COOR_0 etc
                              uint8_t dims, // Number of floats
                              size_t strideBytes, // Stride. See srcData
                              const float *srcData, // Data representing the attribute ONLY. Not interleaved w/ other attrs
                              size_t count ) // Number of values
{
    // Skip the copy if we don't care about this attr
    if ( mRequestedAttribs.find( attr ) == mRequestedAttribs.end() )
    {
        CI_LOG_I("Skipping attr " << attr << ". Not found in requested attributes: " << mRequestedAttribs[attr] );
        return;
    }
    
    // When is this not zero? What is the purpose?
    assert( strideBytes == 0 );
    
    // Are we using stride right?
    unsigned long length = (dims * sizeof(float) + strideBytes) * count;
    
    std::string attrName = ci::geom::attribToString( attr );
    auto buffer = DataBuffer::create(length,
                                     srcData,
                                     attrName);
    setBufferForAttribute(buffer, attr);
}


void VertexBuffer::copyIndices( ci::geom::Primitive primitive, const uint32_t *source,
                                size_t numIndices, uint8_t requiredBytesPerIndex )
{
    assert( mPrimitive == mtl::geom::mtlPrimitiveTypeFromGeom(primitive) );
    if ( numIndices > 0 )
    {
        assert( mRequestedAttribs.count(ci::geom::INDEX) > 0 );
    }
    
    // NOTE: Is unsigned int the right data type?
    size_t idxBytesRequired = sizeof(unsigned int);
    assert(idxBytesRequired >= requiredBytesPerIndex);
    
    unsigned long length = idxBytesRequired * numIndices;
    DataBufferRef indexBuffer = DataBuffer::create(length,
                                                   NULL,
                                                   "Indices");
    
    // Copy each index one by one to minimize the memory required
    for ( size_t i = 0; i < numIndices; ++i )
    {
        unsigned int * bufferPointer = (unsigned int *)indexBuffer->contents() + i;
        // Convert the index into the type expected by Metal
        unsigned int idx = source[i];
        *bufferPointer = idx;
    }
    setBufferForAttribute( indexBuffer, ci::geom::INDEX );
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

void VertexBuffer::render( RenderEncoderRef renderEncoder )
{
    if ( mVertexLength == 0 )
    {
        CI_LOG_E("Vertex length must be > 0");
    }
    assert( mVertexLength > 0 );
    render( renderEncoder, mVertexLength );
}

void VertexBuffer::render( RenderEncoderRef renderEncoder,
                           size_t vertexLength,
                           size_t vertexStart,
                           size_t instanceCount )
{
    for ( auto kvp : mRequestedAttribs )
    {
        ci::geom::Attrib attr = kvp.first;
        DataBufferRef buffer = mAttributeBuffers[attr];
        assert( !!buffer );
        renderEncoder->setBufferAtIndex( buffer, kvp.second );
    }
    
    renderEncoder->draw(mPrimitive,
                        vertexStart,
                        vertexLength,
                        instanceCount);
}
