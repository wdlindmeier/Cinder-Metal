//
//  metal.h
//  MetalCube
//
//  Created by William Lindmeier on 10/13/15.
//
//

#pragma once

#include "cinder/Cinder.h"
#include "RendererMetal.h"
#include "MetalPipeline.h"
#include "MetalCommandBuffer.h"
#include "MetalBuffer.h"
#include "MetalRenderFormat.h"
#include "MetalComputeFormat.h"
#include "MetalBlitFormat.h"
#include "MetalRenderEncoder.h"
#include "MetalComputeEncoder.h"
#include "MetalBlitEncoder.h"
#include "MetalGeom.h"

#if defined( __OBJC__ )
#if !__has_feature(objc_arc)
#error Cinder::Metal requires that ARC is enabled. This can be set in the project "build settings."
#endif
#endif


