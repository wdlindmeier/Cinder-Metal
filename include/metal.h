//
//  metal.h
//  Cinder-Metal
//
//  Created by William Lindmeier on 10/13/15.
//
//

#pragma once

#include "cinder/Cinder.h"
#include "MetalConstants.h"
#include "MetalEnums.h"
#include "RendererMetal.h"
#include "RenderPipelineState.h"
#include "CommandBuffer.h"
#include "DataBuffer.h"
#include "RenderPassDescriptor.h"
#include "RenderEncoder.h"
#include "ComputeEncoder.h"
#include "BlitEncoder.h"
#include "MetalGeom.h"
#include "UniformBlock.hpp"
#include "TextureBuffer.h"
#include "MetalHelpers.hpp"
#include "Scope.h"

#if defined( __OBJC__ )
#if !__has_feature(objc_arc)
#error Cinder::Metal requires that ARC is enabled. This can be set in the project "build settings."
#endif
#endif