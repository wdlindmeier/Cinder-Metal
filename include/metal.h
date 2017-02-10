//
//  metal.h
//  Cinder-Metal
//
//  Created by William Lindmeier on 10/13/15.
//
//

#pragma once

#include "cinder/Cinder.h"

#include "apple/MetalEnums.h"
#include "apple/RenderPipelineState.h"
#include "apple/CommandBuffer.h"
#include "apple/DataBuffer.h"
#include "apple/RenderPassDescriptor.h"
#include "apple/RenderEncoder.h"
#include "apple/ComputeEncoder.h"
#include "apple/BlitEncoder.h"
#include "apple/Argument.h"

#include "MetalConstants.h"
#include "ShaderTypes.h"
#include "RendererMetal.h"
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
