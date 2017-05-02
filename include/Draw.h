//
//  Draw.h
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
#include "ShaderTypes.h"

namespace cinder { namespace mtl {
    
#pragma mark - Generic Batches
    
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
    ci::mtl::BatchRef getStockBatchColoredCube();
    ci::mtl::BatchRef getStockBatchPlane();
    // NOTE: Ring can be a circle by passing in an inner radius of 0
    ci::mtl::BatchRef getStockBatchRing();
    ci::mtl::BatchRef getStockBatchBillboardRing();
    
    ci::mtl::VertexBufferRef getRingBuffer();
}}
