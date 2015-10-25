//
//  GeomTarget.cpp
//  MetalCube
//
//  Created by William Lindmeier on 10/24/15.
//
//

#include "GeomBufferTarget.h"
#include "cinder/Log.h"

using namespace cinder;
using namespace cinder::mtl;

GeomBufferTargetRef GeomBufferTarget::create( const ci::geom::Source & source,
                                              const ci::geom::AttribSet &requestedAttribs )
{
    return GeomBufferTargetRef( new GeomBufferTarget( source, requestedAttribs) );
}

GeomBufferTarget::GeomBufferTarget( const ci::geom::Source & source,
                                    const ci::geom::AttribSet &requestedAttribs ) :
mSource( source.clone() )
,mRequestedAttribs(requestedAttribs)
{
    // Is there any reason to keep the source and attribs around?
    mPrimitive = geom::mtlPrimitiveTypeFromGeom( mSource->getPrimitive() );
    mSource->loadInto( this, requestedAttribs );
}

void GeomBufferTarget::copyAttrib( ci::geom::Attrib attr, // POSITION, TEX_COOR_0 etc
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
    mAttributeBuffers[attr] = buffer;
}

void GeomBufferTarget::copyIndices( ci::geom::Primitive primitive, const uint32_t *source, size_t numIndices, uint8_t requiredBytesPerIndex )
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
    
//    // Make sure we've copied correctly
//    unsigned int *data = (unsigned int *)mIndexBuffer->contents();
//    for ( size_t i = 0; i < numIndices; ++i )
//    {
//        unsigned int d = data[i];
//        uint32_t s = source[i];
//        assert(d == s);
//    }

}

uint8_t GeomBufferTarget::getAttribDims( ci::geom::Attrib attr ) const
{
    return mSource->getAttribDims(attr);
}

void GeomBufferTarget::render( MetalRenderEncoderRef renderEncoder )
{
    // IMPORTANT: Can we be sure these will stay in the correct order?
    // TODO: Find a cleaner way to define the buffer indexes.
    int idx = 0;
    renderEncoder->setVertexBuffer(mIndexBuffer, 0, idx);
    
    idx++;
    for ( auto kvp : mAttributeBuffers )
    {
        ci::geom::Attrib attr = kvp.first;
        MetalBufferRef buffer = kvp.second;
        renderEncoder->setVertexBuffer(buffer, 0, idx);
        idx++;
    }
    
    // Just draw them all for now
    size_t numVerts = mSource->getNumIndices();
    renderEncoder->draw(mPrimitive,
                        0,
                        numVerts,
                        1);
}
