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
            
            // NOTE: The order that the attribs are passed in is the order that they
            // should appear in the shader.
            static GeomBufferTargetRef create( const ci::geom::Source & source,
                                               const ci::geom::AttribSet & requestedAttribs );
            virtual ~GeomBufferTarget(){}
            
            ci::mtl::geom::Primitive getPrimitive(){ return mPrimitive; };

            void render( MetalRenderEncoderRef renderEncoder );
            
            // geom::Target subclass
            void copyAttrib( ci::geom::Attrib attr, uint8_t dims, size_t strideBytes, const float *srcData, size_t count );
            void copyIndices( ci::geom::Primitive primitive, const uint32_t *source, size_t numIndices, uint8_t requiredBytesPerIndex );
            uint8_t getAttribDims( ci::geom::Attrib attr ) const;
            
        protected:
            
            GeomBufferTarget( const ci::geom::Source & source, const ci::geom::AttribSet &requestedAttribs );

            ci::mtl::geom::Primitive mPrimitive;
            std::map< ci::geom::Attrib, MetalBufferRef > mAttributeBuffers;
            MetalBufferRef mIndexBuffer;
            ci::geom::SourceRef mSource;
            
        };
    }
}
