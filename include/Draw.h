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
    
#pragma mark - Generic Pipelines
    
    // TODO: REPLACE these with a shader builder
    ci::mtl::RenderPipelineStateRef getStockPipelineRing();
    ci::mtl::RenderPipelineStateRef getStockPipelineBillboardRing();
    ci::mtl::RenderPipelineStateRef getStockPipelineWire();
    ci::mtl::RenderPipelineStateRef getStockPipelineTexturedRect();
    ci::mtl::RenderPipelineStateRef getStockPipelineMultiTexturedRect();
    ci::mtl::RenderPipelineStateRef getStockPipelineBillboardTexture();
    ci::mtl::RenderPipelineStateRef getStockPipelineBillboardMultiTexture();
    ci::mtl::RenderPipelineStateRef getStockPipelineSolidRect();
    ci::mtl::RenderPipelineStateRef getStockPipelineGeom();
    ci::mtl::RenderPipelineStateRef getStockPipelineColoredGeom();

    ci::mtl::BatchRef getStockBatchWireCube();
    ci::mtl::BatchRef getStockBatchWireCircle();
    ci::mtl::BatchRef getStockBatchWireRect();
    ci::mtl::BatchRef getStockBatchTexturedRect( bool isCentered = true );
    ci::mtl::BatchRef getStockBatchMultiTexturedRect( bool isCentered = true );
    ci::mtl::BatchRef getStockBatchBillboard();
    ci::mtl::BatchRef getStockBatchMultiBillboard();
    ci::mtl::BatchRef getStockBatchSolidRect();
    ci::mtl::BatchRef getStockBatchSphere();
    ci::mtl::BatchRef getStockBatchCube();
    ci::mtl::BatchRef getStockBatchRing();
    ci::mtl::BatchRef getStockBatchBillboardRing();
    
    ci::mtl::VertexBufferRef getRingBuffer();
}}
