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
#include "Pipeline.h"
#include "CommandBuffer.h"
#include "DataBuffer.h"
#include "RenderFormat.h"
//#include "ComputeFormat.h"
//#include "BlitFormat.h"
#include "RenderEncoder.h"
#include "ComputeEncoder.h"
#include "BlitEncoder.h"
#include "MetalGeom.h"
#include "TextureBuffer.h"

#if defined( __OBJC__ )
#if !__has_feature(objc_arc)
#error Cinder::Metal requires that ARC is enabled. This can be set in the project "build settings."
#endif
#endif


