#include "MetalGeom.h"
#include "cinder/Cinder.h"
#include "cinder/Log.h"
#include <Metal/Metal.h>

//using namespace cinder;
//using namespace cinder::mtl;
//using namespace cinder::mtl::geom;
//

namespace cinder { namespace mtl { namespace geom {

    int nativeMTLPrimativeTypeFromGL( ci::geom::Primitive primitive )
    {
        switch ( primitive )
        {
            case ci::geom::LINES:
                return MTLPrimitiveTypeLine;
            case ci::geom::LINE_STRIP:
                return MTLPrimitiveTypeLineStrip;
            case ci::geom::TRIANGLES:
                return MTLPrimitiveTypeTriangle;
            case ci::geom::TRIANGLE_STRIP:
                return MTLPrimitiveTypeTriangleStrip;
            case ci::geom::TRIANGLE_FAN:
                printf( "ERROR: Metal does not have a TRIANGLE_FAN primitive type %i", primitive );
                assert( false );
                break;
            case ci::geom::NUM_PRIMITIVES:
                break;
        }
        CI_LOG_E( "Unknown primitive type" << primitive );
        assert( false );
        return MTLPrimitiveTypeTriangle;
    }

    Primitive mtlPrimitiveTypeFromGeom( ci::geom::Primitive primitive )
    {
        switch ( primitive )
        {
            case ci::geom::LINES:
                return LINE;
            case ci::geom::LINE_STRIP:
                return LINE_STRIP;
            case ci::geom::TRIANGLES:
                return TRIANGLE;
            case ci::geom::TRIANGLE_STRIP:
                return TRIANGLE_STRIP;
            case ci::geom::TRIANGLE_FAN:
                printf( "ERROR: Metal does not have a TRIANGLE_FAN primitive type %i", primitive );
                assert( false );
                break;
            case ci::geom::NUM_PRIMITIVES:
                break;
        }
        CI_LOG_E( "Unknown primitive type" << primitive );
        assert( false );
        return TRIANGLE;
    }

    int nativeMTLPrimitiveType( ci::mtl::geom::Primitive primitive )
    {
        switch ( primitive )
        {
            case POINT:
                return MTLPrimitiveTypePoint;
            case LINE:
                return MTLPrimitiveTypeLine;
            case LINE_STRIP:
                return MTLPrimitiveTypeLineStrip;
            case TRIANGLE:
                return MTLPrimitiveTypeTriangle;
            case TRIANGLE_STRIP:
                return MTLPrimitiveTypeTriangleStrip;
            case NUM_PRIMITIVES:
                break;
        }
        CI_LOG_E( "Unknown primitive type " << primitive );
        assert( false );
        return MTLPrimitiveTypeTriangle;
    }
    
}}}