//
//  Draw.cpp
//  MetalDrawing
//
//  Created by William Lindmeier on 2/27/16.
//
//

#include "Draw.h"

using namespace ci;
using namespace ci::mtl;
using namespace std;

namespace cinder { namespace mtl {
 
#pragma mark - Generic Pipelines

// TODO: REPLACE these with a shader builder

ci::mtl::RenderPipelineStateRef sPipelineRing;
ci::mtl::RenderPipelineStateRef getStockPipelineRing()
{
    if ( !sPipelineRing )
    {
        sPipelineRing = ci::mtl::RenderPipelineState::create("ci_ring_vertex", "ci_color_fragment",
                                                             mtl::RenderPipelineState::Format()
                                                             .blendingEnabled()
                                                             );
    }
    return sPipelineRing;
}

mtl::RenderPipelineStateRef sPipelineBillboardRing;
mtl::RenderPipelineStateRef getStockPipelineBillboardRing()
{
    if ( !sPipelineBillboardRing )
    {
        sPipelineBillboardRing = mtl::RenderPipelineState::create("ci_billboard_ring_vertex", "ci_color_fragment",
                                                                  mtl::RenderPipelineState::Format()
                                                                  .blendingEnabled()
                                                                  );
    }
    return sPipelineBillboardRing;
}

mtl::RenderPipelineStateRef sPipelineWire;
mtl::RenderPipelineStateRef getStockPipelineWire()
{
    if ( !sPipelineWire )
    {
        sPipelineWire = mtl::RenderPipelineState::create("ci_wire_vertex", "ci_color_fragment",
                                                         mtl::RenderPipelineState::Format()
                                                         .blendingEnabled()
                                                         );
    }
    return sPipelineWire;
}

mtl::RenderPipelineStateRef sPipelineTexturedRect;
mtl::RenderPipelineStateRef getStockPipelineTexturedRect()
{
    if ( !sPipelineTexturedRect )
    {
        sPipelineTexturedRect = mtl::RenderPipelineState::create("ci_rect_vertex", "ci_texture_fragment",
                                                                 mtl::RenderPipelineState::Format()
                                                                 .blendingEnabled()
                                                                 );
    }
    return sPipelineTexturedRect;
}

mtl::RenderPipelineStateRef sPipelineMultiTexturedRect;
mtl::RenderPipelineStateRef getStockPipelineMultiTexturedRect()
{
    if ( !sPipelineMultiTexturedRect )
    {
        sPipelineMultiTexturedRect = mtl::RenderPipelineState::create("ci_rect_vertex", "ci_texture_array_fragment",
                                                                      mtl::RenderPipelineState::Format()
                                                                      .blendingEnabled()
                                                                      );
    }
    return sPipelineMultiTexturedRect;
}

mtl::RenderPipelineStateRef sPipelineBillboardTexture;
mtl::RenderPipelineStateRef getStockPipelineBillboardTexture()
{
    if ( !sPipelineBillboardTexture )
    {
        sPipelineBillboardTexture = mtl::RenderPipelineState::create("ci_billboard_rect_vertex", "ci_texture_fragment",
                                                                     mtl::RenderPipelineState::Format()
                                                                     .blendingEnabled()
                                                                     );
    }
    return sPipelineBillboardTexture;
}
        
mtl::RenderPipelineStateRef sPipelineBillboardMultiTexture;
mtl::RenderPipelineStateRef getStockPipelineBillboardMultiTexture()
{
    if ( !sPipelineBillboardMultiTexture )
    {
        sPipelineBillboardMultiTexture = mtl::RenderPipelineState::create("ci_billboard_rect_vertex", "ci_texture_array_fragment",
                                                                          mtl::RenderPipelineState::Format()
                                                                          .blendingEnabled()
                                                                          );
    }
    return sPipelineBillboardMultiTexture;
}

mtl::RenderPipelineStateRef sPipelineSolidRect;
mtl::RenderPipelineStateRef getStockPipelineSolidRect()
{
    if ( !sPipelineSolidRect )
    {
        sPipelineSolidRect = mtl::RenderPipelineState::create("ci_rect_vertex", "ci_color_fragment",
                                                              mtl::RenderPipelineState::Format()
                                                              .blendingEnabled()
                                                              );
    }
    return sPipelineSolidRect;
}

mtl::RenderPipelineStateRef sPipelineGeom;
mtl::RenderPipelineStateRef getStockPipelineGeom()
{
    if ( !sPipelineGeom )
    {
        sPipelineGeom = mtl::RenderPipelineState::create("ci_geom_vertex", "ci_color_fragment",
                                                         mtl::RenderPipelineState::Format()
                                                         .blendingEnabled()
                                                         );
    }
    return sPipelineGeom;
}

mtl::RenderPipelineStateRef sPipelineColoredGeom;
mtl::RenderPipelineStateRef getStockPipelineColoredGeom()
{
    if ( !sPipelineColoredGeom )
    {
        sPipelineColoredGeom = mtl::RenderPipelineState::create("ci_colored_vertex", "ci_color_fragment",
                                                                mtl::RenderPipelineState::Format()
                                                                .blendingEnabled()
                                                                );
    }
    return sPipelineColoredGeom;
}

mtl::BatchRef sBatchWireCube;
mtl::BatchRef getStockBatchWireCube()
{
    if ( !sBatchWireCube )
    {
        sBatchWireCube = mtl::Batch::create( ci::geom::WireCube().size(ci::vec3(1.f)), getStockPipelineWire() );
    }
    return sBatchWireCube;
}

mtl::BatchRef sBatchWireCircle;
mtl::BatchRef getStockBatchWireCircle()
{
    if ( !sBatchWireCircle )
    {
        sBatchWireCircle = mtl::Batch::create( ci::geom::WireCircle().subdivisions(360).radius(1),
                                               getStockPipelineWire() );
    }
    return sBatchWireCircle;
}

mtl::BatchRef sBatchWireRect;
mtl::BatchRef getStockBatchWireRect()
{
    if ( !sBatchWireRect )
    {
        // NOTE; ci::geom::WireRect doesn't exist for some reason
        vector<WireVertex> rectVerts = {
            { vec3(-0.5f,-0.5f,0.f) },
            { vec3(0.5f,-0.5f,0.f) },
            { vec3(0.5f,0.5f,0.f) },
            { vec3(-0.5f,0.5f,0.f) },
            { vec3(-0.5f,-0.5f,0.f) }
        };
        vector<unsigned int> indices = {{0,1,2,3,4}};
        auto rectBuffer = mtl::VertexBuffer::create(rectVerts.size(),
                                                    mtl::DataBuffer::create(rectVerts, mtl::DataBuffer::Format().label("RectVerts")),
                                                    mtl::DataBuffer::create(indices),
                                                    mtl::geom::LINE_STRIP);
        sBatchWireRect = mtl::Batch::create( rectBuffer, getStockPipelineWire() );
    }
    return sBatchWireRect;
}

mtl::BatchRef sBatchTexturedRectCentered;
mtl::BatchRef sBatchTexturedRectUL;
mtl::BatchRef getStockBatchTexturedRect( bool isCentered )
{
    if ( isCentered )
    {
        if ( !sBatchTexturedRectCentered )
        {
            sBatchTexturedRectCentered = mtl::Batch::create( ci::geom::Rect(Rectf(-0.5,-0.5,0.5,0.5)), getStockPipelineTexturedRect() );
        }
        return sBatchTexturedRectCentered;
    }
    // Else
    if ( !sBatchTexturedRectUL )
    {
        sBatchTexturedRectUL = mtl::Batch::create( ci::geom::Rect(Rectf(0,0,1,1)), getStockPipelineTexturedRect() );
    }
    return sBatchTexturedRectUL;
}

mtl::BatchRef sBatchMultiTexturedRectCentered;
mtl::BatchRef sBatchMultiTexturedRectUL;
mtl::BatchRef getStockBatchMultiTexturedRect( bool isCentered )
{
    if ( isCentered )
    {
        if ( !sBatchMultiTexturedRectCentered )
        {
            sBatchMultiTexturedRectCentered = mtl::Batch::create( ci::geom::Rect(Rectf(-0.5,-0.5,0.5,0.5)), getStockPipelineMultiTexturedRect() );
        }
        return sBatchMultiTexturedRectCentered;
    }
    // Else
    if ( !sBatchMultiTexturedRectUL )
    {
        sBatchMultiTexturedRectUL = mtl::Batch::create( ci::geom::Rect(Rectf(0,0,1,1)), getStockPipelineMultiTexturedRect() );
    }
    return sBatchMultiTexturedRectUL;
}

mtl::BatchRef sBatchBillboard;
mtl::BatchRef getStockBatchBillboard()
{
    if ( !sBatchBillboard )
    {
        sBatchBillboard = mtl::Batch::create( ci::geom::Rect(Rectf(-0.5,-0.5,0.5,0.5)), getStockPipelineBillboardTexture() );
    }
    return sBatchBillboard;
}
    
mtl::BatchRef sBatchMultiBillboard;
mtl::BatchRef getStockBatchMultiBillboard()
{
    if ( !sBatchMultiBillboard )
    {
        sBatchMultiBillboard = mtl::Batch::create( ci::geom::Rect(Rectf(-0.5,-0.5,0.5,0.5)), getStockPipelineBillboardMultiTexture() );
    }
    return sBatchMultiBillboard;
}

mtl::BatchRef sBatchSolidRect;
mtl::BatchRef getStockBatchSolidRect()
{
    if ( !sBatchSolidRect )
    {
        sBatchSolidRect = mtl::Batch::create(ci::geom::Rect(Rectf(-0.5,-0.5,0.5,0.5)), getStockPipelineSolidRect());
    }
    return sBatchSolidRect;
}

mtl::BatchRef sBatchSphere;
mtl::BatchRef getStockBatchSphere()
{
    if ( !sBatchSphere )
    {
        sBatchSphere = mtl::Batch::create( ci::geom::Sphere().radius(0.5).subdivisions(36), getStockPipelineGeom() );
    }
    return sBatchSphere;
}

mtl::BatchRef sBatchCube;
mtl::BatchRef getStockBatchCube()
{
    if ( !sBatchCube )
    {
        sBatchCube = mtl::Batch::create( ci::geom::Cube().size(ci::vec3(1.f)), getStockPipelineGeom() );
    }
    return sBatchCube;
}

mtl::VertexBufferRef sRingBuffer;
mtl::VertexBufferRef getRingBuffer()
{
    if ( !sRingBuffer )
    {
        // Create a "ring"
        vector<GeomVertex> circVerts;
        vector<unsigned int> indices;
        for ( int i = 0; i < 37; ++i )
        {
            indices.push_back(i*2);
            indices.push_back(i*2+1);
            
            float rads = ci::toRadians(float(min(361, i*10)));
            float x = cos(rads);
            float y = sin(rads);
            
            GeomVertex inner;
            inner.ciPosition = vec3(x,y,0);
            circVerts.push_back(inner);
            
            GeomVertex outer;
            outer.ciPosition = vec3(x,y,0);
            circVerts.push_back(outer);
        }
        
        sRingBuffer = mtl::VertexBuffer::create(circVerts.size(),
                                                mtl::DataBuffer::create(circVerts, mtl::DataBuffer::Format().label("CircleVerts")),
                                                mtl::DataBuffer::create(indices),
                                                mtl::geom::TRIANGLE_STRIP);
    }
    return sRingBuffer;
}

// NOTE: Batch ring can be used as a circle by passing in an innerRadius of 0
mtl::BatchRef sBatchRing;
mtl::BatchRef getStockBatchRing()
{
    if ( !sBatchRing )
    {
        sBatchRing = mtl::Batch::create( getRingBuffer(), getStockPipelineRing() );
    }
    return sBatchRing;
}

mtl::BatchRef sBatchBillboardRing;
mtl::BatchRef getStockBatchBillboardRing()
{
    if ( !sBatchBillboardRing )
    {
        sBatchBillboardRing = mtl::Batch::create( getRingBuffer(), getStockPipelineBillboardRing() );
    }
    return sBatchBillboardRing;
}

}};