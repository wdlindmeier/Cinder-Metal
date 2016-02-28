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
    
void draw( ci::mtl::VertexBufferRef vertBuffer,
           ci::mtl::RenderPipelineStateRef pipeline,
           ci::mtl::RenderEncoder & renderEncoder )
{
    setDefaultShaderVars(renderEncoder, pipeline);
    renderEncoder.setPipelineState(pipeline);
    vertBuffer->draw(renderEncoder);
}

#pragma mark - Instancing Draw Calls

static ci::mtl::DataBufferRef sInstanceBuffer;

void setInstanceData( ci::mtl::DataBufferRef & instanceBuffer, ci::mtl::RenderEncoder & renderEncoder )
{
    renderEncoder.setVertexBufferAtIndex(instanceBuffer, ci::mtl::ciBufferIndexInstanceData);
}

void setIdentityInstance( ci::mtl::RenderEncoder & renderEncoder )
{
    if ( !sInstanceBuffer )
    {
        // Cache the vanilla buffer.
        Instance i;
        i.modelMatrix = toMtl(mat4(1)); // identity
        i.color = toMtl(vec4(1,1,1,1)); // white
        i.position = toMtl(vec3(0.f));
        std::vector<Instance> is = {i};
        sInstanceBuffer = ci::mtl::DataBuffer::create(is);
    }
    setInstanceData(sInstanceBuffer, renderEncoder);
}

void drawOne( ci::mtl::BatchRef batch, ci::mtl::RenderEncoder & renderEncoder )
{
    setIdentityInstance( renderEncoder );
    batch->drawInstanced(renderEncoder, 1);
}

void drawOne( ci::mtl::BatchRef batch, ci::mtl::RenderEncoder & renderEncoder, const Instance & i)
{
    std::vector<Instance> is = {i};
    ci::mtl::DataBufferRef iBuffer = ci::mtl::DataBuffer::create(is);
    setInstanceData(iBuffer, renderEncoder);
    batch->drawInstanced(renderEncoder, 1);
}

#pragma mark - Generic Pipelines

// TODO: REPLACE these with a shader builder

ci::mtl::RenderPipelineStateRef sPipelineRing;
static ci::mtl::RenderPipelineStateRef getStockPipelineRing()
{
    if ( !sPipelineRing )
    {
        sPipelineRing = ci::mtl::RenderPipelineState::create("ring_vertex", "color_fragment",
                                                             mtl::RenderPipelineState::Format()
                                                             .blendingEnabled()
                                                             );
    }
    return sPipelineRing;
}

mtl::RenderPipelineStateRef sPipelineBillboardRing;
static mtl::RenderPipelineStateRef getStockPipelineBillboardRing()
{
    if ( !sPipelineBillboardRing )
    {
        sPipelineBillboardRing = mtl::RenderPipelineState::create("billboard_ring_vertex", "color_fragment",
                                                                  mtl::RenderPipelineState::Format()
                                                                  .blendingEnabled()
                                                                  );
    }
    return sPipelineBillboardRing;
}

mtl::RenderPipelineStateRef sPipelineWire;
static mtl::RenderPipelineStateRef getStockPipelineWire()
{
    if ( !sPipelineWire )
    {
        sPipelineWire = mtl::RenderPipelineState::create("wire_vertex", "color_fragment",
                                                         mtl::RenderPipelineState::Format()
                                                         .blendingEnabled()
                                                         );
    }
    return sPipelineWire;
}

mtl::RenderPipelineStateRef sPipelineTexturedRect;
static mtl::RenderPipelineStateRef getStockPipelineTexturedRect()
{
    if ( !sPipelineTexturedRect )
    {
        sPipelineTexturedRect = mtl::RenderPipelineState::create("rect_vertex", "texture_fragment",
                                                                 mtl::RenderPipelineState::Format()
                                                                 .blendingEnabled()
                                                                 );
    }
    return sPipelineTexturedRect;
}

mtl::RenderPipelineStateRef sPipelineBillboardTexture;
static mtl::RenderPipelineStateRef getStockPipelineBillboardTexture()
{
    if ( !sPipelineBillboardTexture )
    {
        sPipelineBillboardTexture = mtl::RenderPipelineState::create("billboard_rect_vertex", "texture_fragment",
                                                                     mtl::RenderPipelineState::Format()
                                                                     .blendingEnabled()
                                                                     );
    }
    return sPipelineBillboardTexture;
}

mtl::RenderPipelineStateRef sPipelineSolidRect;
static mtl::RenderPipelineStateRef getStockPipelineSolidRect()
{
    if ( !sPipelineSolidRect )
    {
        sPipelineSolidRect = mtl::RenderPipelineState::create("rect_vertex", "color_fragment",
                                                              mtl::RenderPipelineState::Format()
                                                              .blendingEnabled()
                                                              );
    }
    return sPipelineSolidRect;
}

mtl::RenderPipelineStateRef sPipelineGeom;
static mtl::RenderPipelineStateRef getStockPipelineGeom()
{
    if ( !sPipelineGeom )
    {
        sPipelineGeom = mtl::RenderPipelineState::create("geom_vertex", "color_fragment",
                                                         mtl::RenderPipelineState::Format()
                                                         .blendingEnabled()
                                                         );
    }
    return sPipelineGeom;
}

mtl::RenderPipelineStateRef sPipelineColoredGeom;
static mtl::RenderPipelineStateRef getStockPipelineColoredGeom()
{
    if ( !sPipelineColoredGeom )
    {
        sPipelineColoredGeom = mtl::RenderPipelineState::create("colored_vertex", "color_fragment",
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

mtl::BatchRef sBatchTexturedRect;
mtl::BatchRef getStockBatchTexturedRect()
{
    if ( !sBatchTexturedRect )
    {
        sBatchTexturedRect = mtl::Batch::create( ci::geom::Rect(Rectf(-0.5,-0.5,0.5,0.5)), getStockPipelineTexturedRect() );
    }
    return sBatchTexturedRect;
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
        for ( int i = 0; i < 361; ++i )
        {
            indices.push_back(i*2);
            indices.push_back(i*2+1);
            
            float rads = ci::toRadians(float(i));
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

#pragma mark - Drawing Convenience Functions

void drawStrokedCircle( ci::vec3 position, float radius, mtl::RenderEncoder & renderEncoder )
{
    mtl::ScopedModelMatrix matModel;
    mtl::translate(position);
    mtl::scale(vec3(radius));
    mtl::drawOne(mtl::getStockBatchWireCircle(), renderEncoder);
}

void drawSolidCircle( ci::vec3 position, float radius, mtl::RenderEncoder & renderEncoder )
{
    mtl::ScopedModelMatrix matModel;
    mtl::translate(position);
    mtl::scale(vec3(radius));
    const float circleInnerRadius = 0.f;
    renderEncoder.setVertexBytesAtIndex(&circleInnerRadius, sizeof(float), ciBufferIndexCustom0);
    mtl::drawOne(mtl::getStockBatchRing(), renderEncoder);
}

void drawRing( ci::vec3 position, float outerRadius, float innerRadius, mtl::RenderEncoder & renderEncoder )
{
    mtl::ScopedModelMatrix matModel;
    mtl::translate(position);
    mtl::scale(vec3(outerRadius));
    const float circleInnerRadius = innerRadius / outerRadius;
    renderEncoder.setVertexBytesAtIndex(&circleInnerRadius, sizeof(float), ciBufferIndexCustom0);
    mtl::drawOne(mtl::getStockBatchRing(), renderEncoder);
}

void drawStrokedRect( ci::Rectf rect, mtl::RenderEncoder & renderEncoder )
{
    mtl::ScopedModelMatrix matModel;
    mtl::translate(ci::vec3(rect.getCenter(), 0));
    mtl::scale(vec3(rect.getWidth(), rect.getHeight(), 1));
    mtl::drawOne(mtl::getStockBatchWireRect(), renderEncoder);
}

void drawSolidRect( ci::Rectf rect, mtl::RenderEncoder & renderEncoder )
{
    mtl::ScopedModelMatrix matModel;
    mtl::translate(ci::vec3(rect.getCenter(), 0));
    mtl::scale(vec3(rect.getWidth(), rect.getHeight(), 1));
    mtl::drawOne(mtl::getStockBatchSolidRect(), renderEncoder);
}

void drawCube( ci::vec3 position, ci::vec3 size, mtl::RenderEncoder & renderEncoder )
{
    mtl::ScopedModelMatrix matModel;
    mtl::translate(position);
    mtl::scale(size);
    mtl::drawOne(mtl::getStockBatchCube(), renderEncoder);
}

void drawSphere( ci::vec3 position, float radius, mtl::RenderEncoder & renderEncoder )
{
    mtl::ScopedModelMatrix matModel;
    mtl::translate(position);
    mtl::scale(vec3(radius * 2.f)); // NOTE: default sphere radius is 0.5
    mtl::drawOne(mtl::getStockBatchSphere(), renderEncoder);
}

void drawLines( std::vector<ci::vec3> lines, bool isLineStrip, mtl::RenderEncoder & renderEncoder )
{
    vector<unsigned int> indices;
    for ( int i = 0; i < lines.size(); ++i )
    {
        indices.push_back(i);
    }
    auto lineBuffer = mtl::VertexBuffer::create(lines.size(),
                                                mtl::DataBuffer::create(lines, mtl::DataBuffer::Format().label("LineVerts")),
                                                mtl::DataBuffer::create(indices),
                                                isLineStrip ? mtl::geom::LINE_STRIP : mtl::geom::LINE);
    setIdentityInstance( renderEncoder );
    mtl::draw(lineBuffer, mtl::getStockPipelineWire(), renderEncoder);
}

void drawLine( ci::vec3 from, ci::vec3 to, mtl::RenderEncoder & renderEncoder )
{
    drawLines({{from, to}}, false, renderEncoder);
}

static mtl::VertexBufferRef sColoredCubeBuffer;
void drawColoredCube( ci::vec3 position, ci::vec3 size, mtl::RenderEncoder & renderEncoder )
{
    if ( !sColoredCubeBuffer )
    {
        sColoredCubeBuffer = mtl::VertexBuffer::create( ci::geom::Cube()
                                                       .size(vec3(1.f))
                                                       .colors(Color(1,0,0),Color(0,1,0),Color(0,0,1),
                                                               Color(1,1,0),Color(0,1,1),Color(1,0,1)),
                                                       {{ ci::geom::POSITION, ci::geom::NORMAL, ci::geom::COLOR }});
    }
    mtl::ScopedModelMatrix matModel;
    mtl::translate(position);
    mtl::scale(size);
    setIdentityInstance( renderEncoder );
    mtl::draw(sColoredCubeBuffer, mtl::getStockPipelineColoredGeom(), renderEncoder);
}

// Draw a texture
void draw( mtl::TextureBufferRef & texture, ci::Rectf rect, mtl::RenderEncoder & renderEncoder )
{
    renderEncoder.setTexture(texture);
    mtl::ScopedModelMatrix matModel;
    if ( rect.getWidth() != 0 && rect.getHeight() != 0 )
    {
        mtl::translate(ci::vec3(rect.getCenter(), 0));
        mtl::scale(vec3(rect.getWidth(), rect.getHeight(), 1));
    }
    else
    {
        mtl::scale(vec3(texture->getWidth(), texture->getHeight(), 1));
    }
    mtl::drawOne(mtl::getStockBatchTexturedRect(), renderEncoder);
}

}};