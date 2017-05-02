//
//  Draw.cpp
//
//  Created by William Lindmeier on 2/27/16.
//
//

#include "Draw.h"
#include "Shader.h"

using namespace ci;
using namespace ci::mtl;
using namespace std;

namespace cinder { namespace mtl {
 
#pragma mark - Generic Pipelines

std::map<std::string, mtl::BatchRef> sCachedBatches;

mtl::BatchRef getStockBatchWireCube()
{
    if ( !sCachedBatches.count("BatchWireCube") )
    {
        sCachedBatches["BatchWireCube"] = mtl::Batch::create( ci::geom::WireCube().size(ci::vec3(1.f)),
                                                              getStockPipeline(mtl::ShaderDef()) );
    }
    return sCachedBatches.at("BatchWireCube");
}

mtl::BatchRef getStockBatchWireCircle()
{
    if ( !sCachedBatches.count("BatchWireCircle") )
    {
        sCachedBatches["BatchWireCircle"] = mtl::Batch::create( ci::geom::WireCircle().subdivisions(360).radius(1),
                                                                getStockPipeline(mtl::ShaderDef()) );
    }
    return sCachedBatches.at("BatchWireCircle");
}

mtl::BatchRef getStockBatchWireRect()
{
    if ( !sCachedBatches.count("BatchWireRect") )
    {
        // NOTE; ci::geom::WireRect doesn't exist for some reason
        vector<vec4> rectVerts = {
            { vec4(-0.5f,-0.5f,0.f,1.f) },
            { vec4( 0.5f,-0.5f,0.f,1.f) },
            { vec4( 0.5f, 0.5f,0.f,1.f) },
            { vec4(-0.5f, 0.5f,0.f,1.f) },
            { vec4(-0.5f,-0.5f,0.f,1.f) }
        };
        vector<unsigned int> indices = {{0,1,2,3,4}};
        auto rectBuffer = mtl::VertexBuffer::create(rectVerts.size(),
                                                    mtl::DataBuffer::create(rectVerts, mtl::DataBuffer::Format().label("RectVerts")),
                                                    mtl::DataBuffer::create(indices),
                                                    mtl::geom::LINE_STRIP);
        sCachedBatches["BatchWireRect"] = mtl::Batch::create( rectBuffer, getStockPipeline(mtl::ShaderDef()) );
    }
    return sCachedBatches.at("BatchWireRect");
}

mtl::BatchRef getStockBatchTexturedRect( bool isCentered )
{
    if ( isCentered )
    {
        if ( !sCachedBatches.count("BatchTexturedRectCentered") )
        {
            sCachedBatches["BatchTexturedRectCentered"] = mtl::Batch::create( ci::geom::Rect(Rectf(-0.5,-0.5,0.5,0.5)),
                                                                              getStockPipeline(mtl::ShaderDef().texture()) );
            
        }
        return sCachedBatches.at("BatchTexturedRectCentered");
    }
    // Else
    if ( !sCachedBatches.count("BatchTexturedRectUL") )
    {
        sCachedBatches["BatchTexturedRectUL"] = mtl::Batch::create( ci::geom::Rect(Rectf(0,0,1,1)),
                                                                    getStockPipeline(mtl::ShaderDef().texture()) );
    }
    return sCachedBatches.at("BatchTexturedRectUL");
}

mtl::BatchRef getStockBatchMultiTexturedRect( bool isCentered )
{
    if ( isCentered )
    {
        if ( !sCachedBatches.count("BatchMultiTexturedRectCentered") )
        {
            sCachedBatches["BatchMultiTexturedRectCentered"] = mtl::Batch::create( ci::geom::Rect(Rectf(-0.5,-0.5,0.5,0.5)),
                                                                                   getStockPipeline(mtl::ShaderDef().textureArray()) );
        }
        return sCachedBatches.at("BatchMultiTexturedRectCentered");
    }
    // Else
    if ( !sCachedBatches.count("BatchMultiTexturedRectUL") )
    {
        sCachedBatches["BatchMultiTexturedRectUL"] = mtl::Batch::create( ci::geom::Rect(Rectf(0,0,1,1)),
                                                                         getStockPipeline(mtl::ShaderDef().textureArray()) );
    }
    return sCachedBatches.at("BatchMultiTexturedRectUL");
}

mtl::BatchRef getStockBatchBillboard()
{
    if ( !sCachedBatches.count("BatchBillboard") )
    {
        sCachedBatches["BatchBillboard"] = mtl::Batch::create( ci::geom::Rect(Rectf(-0.5,-0.5,0.5,0.5)),
                                                               getStockPipeline(mtl::ShaderDef().texture().billboard()) );
    }
    return sCachedBatches.at("BatchBillboard");
}
    
mtl::BatchRef getStockBatchMultiBillboard()
{
    if ( !sCachedBatches.count("BatchMultiBillboard") )
    {
        sCachedBatches["BatchMultiBillboard"] = mtl::Batch::create( ci::geom::Rect(Rectf(-0.5,-0.5,0.5,0.5)),
                                                                    getStockPipeline(mtl::ShaderDef().textureArray().billboard()) );
    }
    return sCachedBatches.at("BatchMultiBillboard");
}

mtl::BatchRef getStockBatchSolidRect()
{
    if ( !sCachedBatches.count("BatchSolidRect") )
    {
        sCachedBatches["BatchSolidRect"] = mtl::Batch::create( ci::geom::Rect(Rectf(-0.5,-0.5,0.5,0.5)),
                                                               getStockPipeline(mtl::ShaderDef()) );
    }
    return sCachedBatches.at("BatchSolidRect");
}

mtl::BatchRef getStockBatchSphere()
{
    if ( !sCachedBatches.count("BatchSphere") )
    {
        sCachedBatches["BatchSphere"] = mtl::Batch::create( ci::geom::Sphere().radius(0.5).subdivisions(36),
                                                            getStockPipeline(mtl::ShaderDef()) );
    }
    return sCachedBatches.at("BatchSphere");
}

mtl::BatchRef getStockBatchCube()
{
    if ( !sCachedBatches.count("BatchCube") )
    {
        sCachedBatches["BatchCube"] = mtl::Batch::create( ci::geom::Cube().size(ci::vec3(1.f)),
                                                          getStockPipeline(mtl::ShaderDef()) );
    }
    return sCachedBatches.at("BatchCube");
}
        
mtl::BatchRef getStockBatchColoredCube()
{
    if ( !sCachedBatches.count("BatchColoredCube") )
    {
        ci::geom::BufferLayout cubeLayout;
        size_t sizeOfVert = sizeof(float) * 8;
        cubeLayout.append(ci::geom::Attrib::POSITION, 4, sizeOfVert, 0);
        cubeLayout.append(ci::geom::Attrib::COLOR, 4, sizeOfVert, sizeof(float) * 4);
        mtl::VertexBufferRef vertBuffer = mtl::VertexBuffer::create( ci::geom::Cube()
                                                                    .size(vec3(1.f))
                                                                    .colors(Color(1,0,0),Color(0,1,0),Color(0,0,1),
                                                                            Color(1,1,0),Color(0,1,1),Color(1,0,1)),
                                                                    cubeLayout);
        sCachedBatches["BatchColoredCube"] = mtl::Batch::create( vertBuffer,
                                                                 getStockPipeline(mtl::ShaderDef().color()) );
   
    }
    return sCachedBatches.at("BatchColoredCube");
}

mtl::VertexBufferRef sRingBuffer;
mtl::VertexBufferRef getRingBuffer()
{
    if ( !sRingBuffer )
    {
        // Create a "ring"
        vector<vec4> circVerts;
        vector<unsigned int> indices;
        for ( int i = 0; i < 37; ++i )
        {
            indices.push_back(i*2);
            indices.push_back(i*2+1);
            
            float rads = ci::toRadians(float(min(361, i*10)));
            float x = cos(rads);
            float y = sin(rads);
            
            circVerts.push_back(vec4(x,y,0,1));
            circVerts.push_back(vec4(x,y,0,1));
        }
        
        sRingBuffer = mtl::VertexBuffer::create(circVerts.size(),
                                                mtl::DataBuffer::create(circVerts, mtl::DataBuffer::Format().label("Circle Verts")),
                                                mtl::DataBuffer::create(indices, mtl::DataBuffer::Format().label("Circle Indices")),
                                                mtl::geom::TRIANGLE_STRIP);
    }
    return sRingBuffer;
}

// NOTE: Batch ring can be used as a circle by passing in an innerRadius of 0
mtl::BatchRef getStockBatchRing()
{
    if ( !sCachedBatches.count("BatchRing") )
    {
        sCachedBatches["BatchRing"] = mtl::Batch::create( getRingBuffer(),
                                                          getStockPipeline(mtl::ShaderDef().ring()) );
    }
    return sCachedBatches.at("BatchRing");
}
mtl::BatchRef getStockBatchBillboardRing()
{
    if ( !sCachedBatches.count("BatchBillboardRing") )
    {
        sCachedBatches["BatchBillboardRing"] = mtl::Batch::create( getRingBuffer(),
                                                                   getStockPipeline(mtl::ShaderDef().ring().billboard()) );
    }
    return sCachedBatches.at("BatchBillboardRing");
}

}};