//
//  MetalGeom.h
//
//  Created by William Lindmeier on 10/17/15.
//
//

#pragma once

#include "cinder/GeomIo.h"

namespace cinder { namespace mtl {
        
    namespace geom {
        
        // NOTE: Metal uses "Line" and "Triangle", not the pluralized verions found in GL
        enum Primitive { POINT, LINE, LINE_STRIP, TRIANGLE, TRIANGLE_STRIP, NUM_PRIMITIVES };
        
        // Converts ci::geom::Primitive into (ObjC) MTLPrimitiveType
        // Returns MTLPrimitiveType (must be cast)
        extern int nativeMTLPrimativeTypeFromGeom( const ci::geom::Primitive geomPrimitive );
        
        // Converts ci::mtl::geom::Primitive into (ObjC) MTLPrimitiveType
        // Returns MTLPrimitiveType (must be cast)
        extern int nativeMTLPrimitiveType( const ci::mtl::geom::Primitive primitive );
        
        // Converts ci::geom::Primitive into a mtl::geom::Primitive
        extern Primitive mtlPrimitiveTypeFromGeom( const ci::geom::Primitive primitive );
        
        // Returns the shader index associated with a given attribute
        extern int defaultBufferIndexForAttribute( const ci::geom::Attrib attr );
                
    }
}}
