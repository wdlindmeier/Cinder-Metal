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

VertexBufferRef VertexBuffer::create( const ci::geom::AttribSet &requestedAttribs,
                                      ci::mtl::geom::Primitive primitive )
{
    return VertexBufferRef( new VertexBuffer( requestedAttribs, primitive ) );
}

VertexBuffer::VertexBuffer( const ci::geom::AttribSet &requestedAttribs,
                            ci::mtl::geom::Primitive primitive ) :
mRequestedAttribs(requestedAttribs)
,mPrimitive(primitive)
,mVertexLength(0)
{
}

VertexBufferRef VertexBuffer::create( const ci::geom::Source & source,
                                      const ci::geom::AttribSet &requestedAttribs )
{
    return VertexBufferRef( new VertexBuffer( source, requestedAttribs) );
}

VertexBuffer::VertexBuffer( const ci::geom::Source & source,
                            const ci::geom::AttribSet &requestedAttribs ) :
mSource( source.clone() )
,mRequestedAttribs(requestedAttribs)
,mVertexLength(0)
{
    // Is there any reason to keep the source and attribs around?
    mPrimitive = geom::mtlPrimitiveTypeFromGeom( mSource->getPrimitive() );
    mVertexLength = mSource->getNumIndices();
    mSource->loadInto( this, requestedAttribs );
}

void VertexBuffer::copyAttrib( ci::geom::Attrib attr, // POSITION, TEX_COOR_0 etc
                               uint8_t dims, // Number of floats
                               size_t strideBytes, // Stride. See srcData
                               const float *srcData, // Data representing the attribute ONLY. Not interleaved w/ other attrs
                               size_t count ) // Number of values
{
    // Skip the copy if we don't care about this attr
    if( mRequestedAttribs.count( attr ) == 0 )
    {
        return;
    }

    // When is this not zero? What is the purpose?
    assert( strideBytes == 0 );
    // Are we using stride right?
    unsigned long length = (dims * sizeof(float) + strideBytes) * count;

    std::string attrName = ci::geom::attribToString( attr );
    auto buffer = MetalBuffer::create(length,
                                      srcData,
                                      attrName);
    setBufferForAttribute(buffer, attr);
}

MetalBufferRef VertexBuffer::getBufferForAttribute( const ci::geom::Attrib attr )
{
    return mAttributeBuffers[attr];
}

void VertexBuffer::setBufferForAttribute( MetalBufferRef buffer, const ci::geom::Attrib attr )
{
    assert( mRequestedAttribs.count( attr ) != 0 );
    mAttributeBuffers[attr] = buffer;
}

void VertexBuffer::copyIndices( ci::geom::Primitive primitive, const uint32_t *source,
                                size_t numIndices, uint8_t requiredBytesPerIndex )
{
    assert( mPrimitive == mtl::geom::mtlPrimitiveTypeFromGeom(primitive) );
    
    // NOTE: Is unsigned int the right data type?
    size_t idxBytesRequired = sizeof(unsigned int);
    assert(idxBytesRequired >= requiredBytesPerIndex);
    
    unsigned long length = idxBytesRequired * numIndices;
    mIndexBuffer = MetalBuffer::create(length,
                                       NULL,
                                       "Indices");
    
    // Copy each index one by one to minimize the memory required
    for ( size_t i = 0; i < numIndices; ++i )
    {
        unsigned int * bufferPointer = (unsigned int *)mIndexBuffer->contents() + i;
        // Convert the index into the type expected by Metal
        unsigned int idx = source[i];
        *bufferPointer = idx;
    }
}

uint8_t VertexBuffer::getAttribDims( ci::geom::Attrib attr ) const
{
    if ( mSource )
    {
        return mSource->getAttribDims(attr);
    }
    
    CI_LOG_E("Requesting attrib dims for a GeomBufferTarget with no source. Returning 0.");
    
    return 0;
}

void VertexBuffer::render( MetalRenderEncoderRef renderEncoder )
{
    if ( mVertexLength == 0 )
    {
        CI_LOG_E("Vertex length must be > 0");
    }
    assert( mVertexLength > 0 );
    render( renderEncoder, mVertexLength );
}

void VertexBuffer::render( MetalRenderEncoderRef renderEncoder,
                           size_t vertexLength,
                           size_t vertexStart,
                           size_t instanceCount )
{
    // IMPORTANT: Can we be sure these will stay in the correct order?
    // TODO: Find a cleaner way to define the buffer indexes.
    int idx = 0;
    if ( mIndexBuffer )
    {
        renderEncoder->setVertexBuffer(mIndexBuffer, 0, idx);
        idx++;
    }
    
    for ( auto kvp : mAttributeBuffers )
    {
        ci::geom::Attrib attr = kvp.first;
        MetalBufferRef buffer = kvp.second;
        renderEncoder->setVertexBuffer(buffer, 0, idx);
        idx++;
    }
    
    renderEncoder->draw(mPrimitive,
                        vertexStart,
                        vertexLength,
                        instanceCount);
}
