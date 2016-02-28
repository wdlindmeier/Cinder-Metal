//
//  Draw.h
//  MetalBasic
//
//  Created by William Lindmeier on 2/23/16.
//
//

#pragma once

#include "cinder/Cinder.h"
#include "VertexBuffer.h"
#include "RenderPipelineState.h"
#include "Context.h"
#include "cinder/app/App.h"
#include "cinder/CameraUi.h"
#include "cinder/GeomIo.h"
#include "metal.h"
#include "Batch.h"
#include "InstanceTypes.h"

namespace cinder { namespace mtl {
    
    // Draw a VertexBuffer w/out a batch
    void draw( ci::mtl::VertexBufferRef vertBuffer, ci::mtl::RenderPipelineStateRef pipeline, ci::mtl::RenderEncoder & renderEncoder );
    
#pragma mark - Instancing Draw Calls

    void drawOne( ci::mtl::BatchRef batch, ci::mtl::RenderEncoder & renderEncoder );
    void drawOne( ci::mtl::BatchRef batch, ci::mtl::RenderEncoder & renderEncoder, const Instance & i);
    
#pragma mark - Generic Pipelines
    
    // TODO: REPLACE these with a shader builder
    static ci::mtl::RenderPipelineStateRef getStockPipelineRing();
    static ci::mtl::RenderPipelineStateRef getStockPipelineBillboardRing();
    static ci::mtl::RenderPipelineStateRef getStockPipelineWire();
    static ci::mtl::RenderPipelineStateRef getStockPipelineTexturedRect();
    static ci::mtl::RenderPipelineStateRef getStockPipelineBillboardTexture();
    static ci::mtl::RenderPipelineStateRef getStockPipelineSolidRect();
    static ci::mtl::RenderPipelineStateRef getStockPipelineGeom();
    static ci::mtl::RenderPipelineStateRef getStockPipelineColoredGeom();

    ci::mtl::BatchRef getStockBatchWireCube();
    ci::mtl::BatchRef getStockBatchWireCircle();
    ci::mtl::BatchRef getStockBatchWireRect();
    ci::mtl::BatchRef getStockBatchTexturedRect();
    ci::mtl::BatchRef getStockBatchBillboard();
    ci::mtl::BatchRef getStockBatchSolidRect();
    ci::mtl::BatchRef getStockBatchSphere();
    ci::mtl::BatchRef getStockBatchCube();
    ci::mtl::BatchRef getStockBatchRing();
    ci::mtl::BatchRef getStockBatchBillboardRing();

#pragma mark - Drawing Convenience Functions
    
    void drawStrokedCircle( ci::vec3 position, float radius,
                            ci::mtl::RenderEncoder & renderEncoder = *mtl::context()->getCurrentRenderEncoder() );
    void drawSolidCircle( ci::vec3 position, float radius,
                         ci::mtl::RenderEncoder & renderEncoder = *mtl::context()->getCurrentRenderEncoder() );
    void drawRing( ci::vec3 position, float outerRadius, float innerRadius,
                  ci::mtl::RenderEncoder & renderEncoder = *mtl::context()->getCurrentRenderEncoder() );
    void drawStrokedRect( ci::Rectf rect,
                          ci::mtl::RenderEncoder & renderEncoder = *mtl::context()->getCurrentRenderEncoder() );
    void drawSolidRect( ci::Rectf rect,
                        ci::mtl::RenderEncoder & renderEncoder = *mtl::context()->getCurrentRenderEncoder() );
    void drawCube( ci::vec3 position, ci::vec3 size,
                   ci::mtl::RenderEncoder & renderEncoder = *mtl::context()->getCurrentRenderEncoder() );
    void drawSphere( ci::vec3 position, float radius,
                     ci::mtl::RenderEncoder & renderEncoder = *mtl::context()->getCurrentRenderEncoder() );
    // NOTE: This is not designed to be fast—just convenient
    void drawLines( std::vector<ci::vec3> lines,
                    bool isLineStrip = false,
                    ci::mtl::RenderEncoder & renderEncoder = *mtl::context()->getCurrentRenderEncoder() );
    // NOTE: This is not designed to be fast—just convenient
    void drawLine( ci::vec3 from, ci::vec3 to,
                   ci::mtl::RenderEncoder & renderEncoder = *mtl::context()->getCurrentRenderEncoder() );
    void drawColoredCube( ci::vec3 position, ci::vec3 size,
                          ci::mtl::RenderEncoder & renderEncoder = *mtl::context()->getCurrentRenderEncoder() );
    void draw( ci::mtl::TextureBufferRef & texture, ci::Rectf rect = ci::Rectf(0,0,0,0),
               ci::mtl::RenderEncoder & renderEncoder = *mtl::context()->getCurrentRenderEncoder());
    
}}
