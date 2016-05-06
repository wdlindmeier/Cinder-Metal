#include "MetalGeom.h"
#include "cinder/Cinder.h"
#include "cinder/Log.h"
#include "MetalConstants.h"
#include <Metal/Metal.h>

namespace cinder { namespace mtl { namespace geom {

    int nativeMTLPrimativeTypeFromGeom( const ci::geom::Primitive primitive )
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

    Primitive mtlPrimitiveTypeFromGeom( const ci::geom::Primitive primitive )
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

    int nativeMTLPrimitiveType( const ci::mtl::geom::Primitive primitive )
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
    
    int defaultBufferIndexForAttribute( const ci::geom::Attrib attr )
    {
        switch (attr)
        {
            case ci::geom::POSITION:
                return ciBufferIndexPositions;
            case ci::geom::COLOR:
                return ciBufferIndexColors;
            case ci::geom::TEX_COORD_0:
                return ciBufferIndexTexCoords0;
            case ci::geom::TEX_COORD_1:
                return ciBufferIndexTexCoords1;
            case ci::geom::TEX_COORD_2:
                return ciBufferIndexTexCoords2;
            case ci::geom::TEX_COORD_3:
                return ciBufferIndexTexCoords3;
            case ci::geom::NORMAL:
                return ciBufferIndexNormals;
            case ci::geom::TANGENT:
                return ciBufferIndexTangents;
            case ci::geom::BITANGENT:
                return ciBufferIndexBitangents;
            case ci::geom::BONE_INDEX:
                return ciBufferIndexBoneIndices;
            case ci::geom::BONE_WEIGHT:
                return ciBufferIndexBoneWeight;
            case ci::geom::CUSTOM_0:
                return ciBufferIndexCustom0;
            case ci::geom::CUSTOM_1:
                return ciBufferIndexCustom1;
            case ci::geom::CUSTOM_2:
                return ciBufferIndexCustom2;
            case ci::geom::CUSTOM_3:
                return ciBufferIndexCustom3;
            case ci::geom::CUSTOM_4:
                return ciBufferIndexCustom4;
            case ci::geom::CUSTOM_5:
                return ciBufferIndexCustom5;
            case ci::geom::CUSTOM_6:
                return ciBufferIndexCustom6;
            case ci::geom::CUSTOM_7:
                return ciBufferIndexCustom7;
            case ci::geom::CUSTOM_8:
                return ciBufferIndexCustom8;
            case ci::geom::CUSTOM_9:
                return ciBufferIndexCustom9;
            default:
                return -1;
        }
    }
    
}}}