//
//  MetalEnums.h
//
//  Created by William Lindmeier on 12/9/15.
//
//

#pragma once

namespace cinder { namespace mtl {
    
    #define ResourceCPUCacheModeShift 0
    #define ResourceCPUCacheModeMask  (0xfUL << ResourceCPUCacheModeShift)
    #define ResourceStorageModeShift  4
    #define ResourceStorageModeMask   (0xfUL << ResourceStorageModeShift)
    
    typedef enum
    {
        PurgeableStateKeepCurrent = 1,
        PurgeableStateNonVolatile = 2,
        PurgeableStateVolatile = 3,
        PurgeableStateEmpty = 4,
    } PurgeableState;
    
    typedef enum
    {
        CPUCacheModeDefaultCache = 0,
        CPUCacheModeWriteCombined = 1,
    } CPUCacheMode;
    
    typedef enum StorageMode
    {
        StorageModeShared  = 0,
        StorageModeManaged = 1,
        StorageModePrivate = 2,
    } StorageMode;
    
    typedef enum
    {
        ResourceCPUCacheModeDefaultCache = CPUCacheModeDefaultCache  << ResourceCPUCacheModeShift,
        ResourceCPUCacheModeWriteCombined = CPUCacheModeWriteCombined << ResourceCPUCacheModeShift,
        ResourceStorageModeShared  = StorageModeShared  << ResourceStorageModeShift,
        ResourceStorageModeManaged   = StorageModeManaged << ResourceStorageModeShift,
        ResourceStorageModePrivate  = StorageModePrivate << ResourceStorageModeShift,
    } ResourceOptions;
        
    typedef enum
    {
        CompareFunctionNever = 0,
        CompareFunctionLess = 1,
        CompareFunctionEqual = 2,
        CompareFunctionLessEqual = 3,
        CompareFunctionGreater = 4,
        CompareFunctionNotEqual = 5,
        CompareFunctionGreaterEqual = 6,
        CompareFunctionAlways = 7,
    } CompareFunction;
    
    typedef enum
    {
        StencilOperationKeep = 0,
        StencilOperationZero = 1,
        StencilOperationReplace = 2,
        StencilOperationIncrementClamp = 3,
        StencilOperationDecrementClamp = 4,
        StencilOperationInvert = 5,
        StencilOperationIncrementWrap = 6,
        StencilOperationDecrementWrap = 7,
    } StencilOperation;
    
    typedef enum
    {
        PixelFormatInvalid = 0,
        
        /* Normal 8 bit formats */
        
        PixelFormatA8Unorm      = 1,
        
        PixelFormatR8Unorm      = 10,
        PixelFormatR8Unorm_sRGB = 11,
        
        PixelFormatR8Snorm      = 12,
        PixelFormatR8Uint       = 13,
        PixelFormatR8Sint       = 14,
        
        /* Normal 16 bit formats */
        
        PixelFormatR16Unorm     = 20,
        PixelFormatR16Snorm     = 22,
        PixelFormatR16Uint      = 23,
        PixelFormatR16Sint      = 24,
        PixelFormatR16Float     = 25,
        
        PixelFormatRG8Unorm                            = 30,
        PixelFormatRG8Unorm_sRGB                       = 31,
        PixelFormatRG8Snorm                            = 32,
        PixelFormatRG8Uint                             = 33,
        PixelFormatRG8Sint                             = 34,
        
        /* Packed 16 bit formats */
        
        PixelFormatB5G6R5Unorm  = 40,
        PixelFormatA1BGR5Unorm  = 41,
        PixelFormatABGR4Unorm   = 42,
        PixelFormatBGR5A1Unorm  = 43,
        
        /* Normal 32 bit formats */
        
        PixelFormatR32Uint  = 53,
        PixelFormatR32Sint  = 54,
        PixelFormatR32Float = 55,
        
        PixelFormatRG16Unorm  = 60,
        PixelFormatRG16Snorm  = 62,
        PixelFormatRG16Uint   = 63,
        PixelFormatRG16Sint   = 64,
        PixelFormatRG16Float  = 65,
        
        PixelFormatRGBA8Unorm      = 70,
        PixelFormatRGBA8Unorm_sRGB = 71,
        PixelFormatRGBA8Snorm      = 72,
        PixelFormatRGBA8Uint       = 73,
        PixelFormatRGBA8Sint       = 74,
        
        PixelFormatBGRA8Unorm      = 80,
        PixelFormatBGRA8Unorm_sRGB = 81,
        
        /* Packed 32 bit formats */
        
        PixelFormatRGB10A2Unorm = 90,
        PixelFormatRGB10A2Uint  = 91,
        PixelFormatRG11B10Float = 92,
        PixelFormatRGB9E5Float = 93,
        
        /* Normal 64 bit formats */
        
        PixelFormatRG32Uint  = 103,
        PixelFormatRG32Sint  = 104,
        PixelFormatRG32Float = 105,
        PixelFormatRGBA16Unorm  = 110,
        PixelFormatRGBA16Snorm  = 112,
        PixelFormatRGBA16Uint   = 113,
        PixelFormatRGBA16Sint   = 114,
        PixelFormatRGBA16Float  = 115,
        
        /* Normal 128 bit formats */
        
        PixelFormatRGBA32Uint  = 123,
        PixelFormatRGBA32Sint  = 124,
        PixelFormatRGBA32Float = 125,
        
        /* Compressed formats. */
        
        /* S3TC/DXT */
        PixelFormatBC1_RGBA              = 130,
        PixelFormatBC1_RGBA_sRGB         = 131,
        PixelFormatBC2_RGBA              = 132,
        PixelFormatBC2_RGBA_sRGB         = 133,
        PixelFormatBC3_RGBA              = 134,
        PixelFormatBC3_RGBA_sRGB         = 135,
        
        /* RGTC */
        PixelFormatBC4_RUnorm            = 140,
        PixelFormatBC4_RSnorm            = 141,
        PixelFormatBC5_RGUnorm           = 142,
        PixelFormatBC5_RGSnorm           = 143,
        
        /* BPTC */
        PixelFormatBC6H_RGBFloat         = 150,
        PixelFormatBC6H_RGBUfloat        = 151,
        PixelFormatBC7_RGBAUnorm         = 152,
        PixelFormatBC7_RGBAUnorm_sRGB    = 153,
        
        /* PVRTC */
        PixelFormatPVRTC_RGB_2BPP        = 160,
        PixelFormatPVRTC_RGB_2BPP_sRGB   = 161,
        PixelFormatPVRTC_RGB_4BPP        = 162,
        PixelFormatPVRTC_RGB_4BPP_sRGB   = 163,
        PixelFormatPVRTC_RGBA_2BPP       = 164,
        PixelFormatPVRTC_RGBA_2BPP_sRGB  = 165,
        PixelFormatPVRTC_RGBA_4BPP       = 166,
        PixelFormatPVRTC_RGBA_4BPP_sRGB  = 167,
        
        /* ETC2 */
        PixelFormatEAC_R11Unorm          = 170,
        PixelFormatEAC_R11Snorm          = 172,
        PixelFormatEAC_RG11Unorm         = 174,
        PixelFormatEAC_RG11Snorm         = 176,
        PixelFormatEAC_RGBA8             = 178,
        PixelFormatEAC_RGBA8_sRGB        = 179,
        
        PixelFormatETC2_RGB8             = 180,
        PixelFormatETC2_RGB8_sRGB        = 181,
        PixelFormatETC2_RGB8A1           = 182,
        PixelFormatETC2_RGB8A1_sRGB      = 183,
        
        /* ASTC */
        PixelFormatASTC_4x4_sRGB         = 186,
        PixelFormatASTC_5x4_sRGB         = 187,
        PixelFormatASTC_5x5_sRGB         = 188,
        PixelFormatASTC_6x5_sRGB         = 189,
        PixelFormatASTC_6x6_sRGB         = 190,
        PixelFormatASTC_8x5_sRGB         = 192,
        PixelFormatASTC_8x6_sRGB         = 193,
        PixelFormatASTC_8x8_sRGB         = 194,
        PixelFormatASTC_10x5_sRGB        = 195,
        PixelFormatASTC_10x6_sRGB        = 196,
        PixelFormatASTC_10x8_sRGB        = 197,
        PixelFormatASTC_10x10_sRGB       = 198,
        PixelFormatASTC_12x10_sRGB       = 199,
        PixelFormatASTC_12x12_sRGB       = 200,
        
        PixelFormatASTC_4x4_LDR          = 204,
        PixelFormatASTC_5x4_LDR          = 205,
        PixelFormatASTC_5x5_LDR          = 206,
        PixelFormatASTC_6x5_LDR          = 207,
        PixelFormatASTC_6x6_LDR          = 208,
        PixelFormatASTC_8x5_LDR          = 210,
        PixelFormatASTC_8x6_LDR          = 211,
        PixelFormatASTC_8x8_LDR          = 212,
        PixelFormatASTC_10x5_LDR         = 213,
        PixelFormatASTC_10x6_LDR         = 214,
        PixelFormatASTC_10x8_LDR         = 215,
        PixelFormatASTC_10x10_LDR        = 216,
        PixelFormatASTC_12x10_LDR        = 217,
        PixelFormatASTC_12x12_LDR        = 218,
        PixelFormatGBGR422               = 240,
        PixelFormatBGRG422               = 241,
        PixelFormatDepth32Float          = 252,
        PixelFormatStencil8              = 253,
        PixelFormatDepth24Unorm_Stencil8 = 255,
        PixelFormatDepth32Float_Stencil8 = 260,
    } PixelFormat;
    
    typedef enum
    {
        PrimitiveTypePoint = 0,
        PrimitiveTypeLine = 1,
        PrimitiveTypeLineStrip = 2,
        PrimitiveTypeTriangle = 3,
        PrimitiveTypeTriangleStrip = 4,
    } PrimitiveType;
    
    typedef enum
    {
        IndexTypeUInt16 = 0,
        IndexTypeUInt32 = 1,
    } IndexType;
    
    typedef enum
    {
        VisibilityResultModeDisabled = 0,
        VisibilityResultModeBoolean = 1,
        VisibilityResultModeCounting = 2,
    } VisibilityResultMode;
    
    typedef enum
    {
        CullModeNone = 0,
        CullModeFront = 1,
        CullModeBack = 2,
    } CullMode;
    
    typedef enum
    {
        WindingClockwise = 0,
        WindingCounterClockwise = 1,
    } Winding;
    
    typedef enum
    {
        DepthClipModeClip = 0,
        DepthClipModeClamp = 1,
    } DepthClipMode;
    
    typedef enum
    {
        TriangleFillModeFill = 0,
        TriangleFillModeLines = 1,
    } TriangleFillMode;
    
    typedef enum
    {
        LoadActionDontCare = 0,
        LoadActionLoad = 1,
        LoadActionClear = 2,
    } LoadAction;
    
    typedef enum
    {
        StoreActionDontCare = 0,
        StoreActionStore = 1,
        StoreActionMultisampleResolve = 2,
    } StoreAction;
    
    typedef enum
    {
        BlendFactorZero = 0,
        BlendFactorOne = 1,
        BlendFactorSourceColor = 2,
        BlendFactorOneMinusSourceColor = 3,
        BlendFactorSourceAlpha = 4,
        BlendFactorOneMinusSourceAlpha = 5,
        BlendFactorDestinationColor = 6,
        BlendFactorOneMinusDestinationColor = 7,
        BlendFactorDestinationAlpha = 8,
        BlendFactorOneMinusDestinationAlpha = 9,
        BlendFactorSourceAlphaSaturated = 10,
        BlendFactorBlendColor = 11,
        BlendFactorOneMinusBlendColor = 12,
        BlendFactorBlendAlpha = 13,
        BlendFactorOneMinusBlendAlpha = 14,
    } BlendFactor;
    
    typedef enum
    {
        BlendOperationAdd = 0,
        BlendOperationSubtract = 1,
        BlendOperationReverseSubtract = 2,
        BlendOperationMin = 3,
        BlendOperationMax = 4,
    } BlendOperation;
    
    typedef enum
    {
        ColorWriteMaskNone  = 0,
        ColorWriteMaskRed   = 0x1 << 3,
        ColorWriteMaskGreen = 0x1 << 2,
        ColorWriteMaskBlue  = 0x1 << 1,
        ColorWriteMaskAlpha = 0x1 << 0,
        ColorWriteMaskAll   = 0xf
    } ColorWriteMask;
    
    typedef enum
    {
        PrimitiveTopologyClassUnspecified = 0,
        PrimitiveTopologyClassPoint = 1,
        PrimitiveTopologyClassLine = 2,
        PrimitiveTopologyClassTriangle = 3,
    } PrimitiveTopologyClass;
    
    typedef enum
    {
        SamplerMinMagFilterNearest = 0,
        SamplerMinMagFilterLinear = 1,
    } SamplerMinMagFilter;
    
    typedef enum 
    {
        SamplerMipFilterNotMipmapped = 0,
        SamplerMipFilterNearest = 1,
        SamplerMipFilterLinear = 2,
    } SamplerMipFilter;
    
    typedef enum
    {
        SamplerAddressModeClampToEdge = 0,
        SamplerAddressModeMirrorClampToEdge = 1,
        SamplerAddressModeRepeat = 2,
        SamplerAddressModeMirrorRepeat = 3,
        SamplerAddressModeClampToZero = 4,
    } SamplerAddressMode;
    
    typedef enum
    {
        TextureType1D = 0,
        TextureType1DArray = 1,
        TextureType2D = 2,
        TextureType2DArray = 3,
        TextureType2DMultisample = 4,
        TextureTypeCube = 5,
        TextureTypeCubeArray = 6,
        TextureType3D = 7,
    } TextureType;
    
    typedef enum
    {
        TextureUsageUnknown         = 0x0000,
        TextureUsageShaderRead      = 0x0001,
        TextureUsageShaderWrite     = 0x0002,
        TextureUsageRenderTarget    = 0x0004,
        TextureUsagePixelFormatView = 0x0010,
    } TextureUsage;
    
    typedef enum
    {
        BlitOptionNone                       = 0,
        BlitOptionDepthFromDepthStencil      = 1 << 0,
        BlitOptionStencilFromDepthStencil    = 1 << 1,
        BlitOptionRowLinearPVRTC = 1 << 2
    } BlitOption;

    typedef enum
    {
        DataTypeNone = 0,
        
        DataTypeStruct = 1,
        DataTypeArray  = 2,
        
        DataTypeFloat  = 3,
        DataTypeFloat2 = 4,
        DataTypeFloat3 = 5,
        DataTypeFloat4 = 6,
        
        DataTypeFloat2x2 = 7,
        DataTypeFloat2x3 = 8,
        DataTypeFloat2x4 = 9,
        
        DataTypeFloat3x2 = 10,
        DataTypeFloat3x3 = 11,
        DataTypeFloat3x4 = 12,
        
        DataTypeFloat4x2 = 13,
        DataTypeFloat4x3 = 14,
        DataTypeFloat4x4 = 15,
        
        DataTypeHalf  = 16,
        DataTypeHalf2 = 17,
        DataTypeHalf3 = 18,
        DataTypeHalf4 = 19,
        
        DataTypeHalf2x2 = 20,
        DataTypeHalf2x3 = 21,
        DataTypeHalf2x4 = 22,
        
        DataTypeHalf3x2 = 23,
        DataTypeHalf3x3 = 24,
        DataTypeHalf3x4 = 25,
        
        DataTypeHalf4x2 = 26,
        DataTypeHalf4x3 = 27,
        DataTypeHalf4x4 = 28,
        
        DataTypeInt  = 29,
        DataTypeInt2 = 30,
        DataTypeInt3 = 31,
        DataTypeInt4 = 32,
        
        DataTypeUInt  = 33,
        DataTypeUInt2 = 34,
        DataTypeUInt3 = 35,
        DataTypeUInt4 = 36,
        
        DataTypeShort  = 37,
        DataTypeShort2 = 38,
        DataTypeShort3 = 39,
        DataTypeShort4 = 40,
        
        DataTypeUShort = 41,
        DataTypeUShort2 = 42,
        DataTypeUShort3 = 43,
        DataTypeUShort4 = 44,
        
        DataTypeChar  = 45,
        DataTypeChar2 = 46,
        DataTypeChar3 = 47,
        DataTypeChar4 = 48,
        
        DataTypeUChar  = 49,
        DataTypeUChar2 = 50,
        DataTypeUChar3 = 51,
        DataTypeUChar4 = 52,
        
        DataTypeBool  = 53,
        DataTypeBool2 = 54,
        DataTypeBool3 = 55,
        DataTypeBool4 = 56,
        
    } DataType;
    
    typedef enum
    {
        ArgumentTypeBuffer = 0,
        ArgumentTypeThreadgroupMemory= 1,
        ArgumentTypeTexture = 2,
        ArgumentTypeSampler = 3,
    } ArgumentType;
    
    typedef enum
    {
        ArgumentAccessReadOnly   = 0,
        ArgumentAccessReadWrite  = 1,
        ArgumentAccessWriteOnly  = 2,
    } ArgumentAccess;

}}