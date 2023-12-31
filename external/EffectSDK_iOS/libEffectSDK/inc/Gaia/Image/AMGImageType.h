/**
 * @file AMGThreadLocal.h
 * @author Benny LIU (benny.liu@bytedance.com)
 * @brief Definition of base enum about image.
 * @version 0.1
 * @date 2019-01-14
 * 
 * @copyright Copyright (c) 2019
 * 
 */

#ifndef ImageType_h
#define ImageType_h

#include "Gaia/AMGPrerequisites.h"

NAMESPACE_AMAZING_ENGINE_BEGIN
/**
 * @brief Enum of image pixel format.
 * 
 */
enum class GAIA_LIB_EXPORT AMGPixelFormat
{
    Invalid = 0,
    A8Unorm,
    L8Unorm,
    LA8Unorm,
    GR4Unorm,
    ABGR4Unorm,
    ARGB4Unorm,
    RGBA4Unorm,
    BGRA4Unorm,
    B5G6R5Unorm,
    R5G6B5Unorm,
    A1BGR5Unorm,
    A1RGB5Unorm,
    RGB5A1Unorm,
    BGR5A1Unorm,

    R8Unorm,
    R8Snorm,
    R8Uscaleld,
    R8Sscaled,
    R8Uint,
    R8Sint,
    R8_sRGB,
    RG8Unorm,
    RG8Snorm,
    RG8Uscaled,
    RG8Sscaled,
    RG8Uint,
    RG8Sint,
    RG8_sRGB,

    RGB8Unorm,
    RGB8Snorm,
    RGB8Uscaled,
    RGB8Sscaled,
    RGB8Uint,
    RGB8Sint,
    RGB8_sRGB,
    BGR8Unorm,
    BGR8Snorm,
    BGR8Uscaled,
    BGR8Sscaled,
    BGR8Uint,
    BGR8Sint,
    BGR8_sRGB,

    RGBA8Unorm,
    RGBA8Snorm,
    RGBA8Uscaled,
    RGBA8Sscaled,
    RGBA8Uint,
    RGBA8Sint,
    RGBA8_sRGB,
    BGRA8Unorm,
    BGRA8Snorm,
    BGRA8Uscaled,
    BGRA8Sscaled,
    BGRA8Uint,
    BGRA8Sint,
    BGRA8_sRGB,
    ABGR8Unorm,
    ABGR8Snorm,
    ABGR8Uscaled,
    ABGR8Sscaled,
    ABGR8Uint,
    ABGR8Sint,
    ABGR8_sRGB,

    BGR10A2Unorm,
    BGR10A2Snorm,
    BGR10A2Uscaled,
    BGR10A2Sscaled,
    BGR10A2Uint,
    BGR10A2Sint,
    RGB10A2Unorm,
    RGB10A2Snorm,
    RGB10A2Uscaled,
    RGB10A2Sscaled,
    RGB10A2Uint,
    RGB10A2Sint,

    R16Unorm,
    R16Snorm,
    R16Uscaleld,
    R16Sscaled,
    R16Uint,
    R16Sint,
    R16Sfloat,
    RG16Unorm,
    RG16Snorm,
    RG16Uscaled,
    RG16Sscaled,
    RG16Uint,
    RG16Sint,
    RG16Sfloat,
    RGB16Unorm,
    RGB16Snorm,
    RGB16Uscaled,
    RGB16Sscaled,
    RGB16Uint,
    RGB16Sint,
    RGB16Sfloat,
    RGBA16Unorm,
    RGBA16Snorm,
    RGBA16Uscaled,
    RGBA16Sscaled,
    RGBA16Uint,
    RGBA16Sint,
    RGBA16Sfloat,

    R32Uint,
    R32Sint,
    R32Sfloat,
    RG32Uint,
    RG32Sint,
    RG32Sfloat,
    RGB32Uint,
    RGB32Sint,
    RGB32Sfloat,
    RGBA32Uint,
    RGBA32Sint,
    RGBA32Sfloat,

    R64Uint,
    R64Sint,
    R64Sfloat,
    RG64Uint,
    RG64Sint,
    RG64Sfloat,
    RGB64Uint,
    RGB64Sint,
    RGB64Sfloat,
    RGBA64Uint,
    RGBA64Sint,
    RGBA64Sfloat,

    RG11B10Ufloat,
    RGB9E5Ufloat,

    D16Unorm,
    D24X8Unorm,
    D32Sfloat,
    S8Uint,
    D16UnormS8Uint,
    D24UnormS8Uint,
    D32SfloatS8Uint,

    BC1_RGBUnorm,
    BC1_RGB_sRGB,
    BC1_RGBAUnorm,
    BC1_RGBA_sRGB,
    BC2_RGBAUnorm,
    BC2_RGBA_sRGB,
    BC3_RGBAUnorm,
    BC3_RGBA_sRGB,
    BC4_RUnorm,
    BC4_RSnorm,
    BC5_RGUnorm,
    BC5_RGSnorm,
    BC6H_RGBUfloat,
    BC6H_RGBSfloat,
    BC7_RGBAUnorm,
    BC7_RGBAUnorm_sRGB,

    ETC1_RGB8Unorm,
    ETC2_RGB8Unorm,
    ETC2_RGB8_sRGB,
    ETC2_RGB8A1Unorm,
    ETC2_RGB8A1_sRGB,
    ETC2_RGBA8Unorm,
    ETC2_RGBA8_sRGB,
    EAC_R11Unorm,
    EAC_R11Snorm,
    EAC_RG11Unorm,
    EAC_RG11Snorm,

    ASTC_4x4_LDR,
    ASTC_4x4_sRGB,
    ASTC_5x4_LDR,
    ASTC_5x4_sRGB,
    ASTC_5x5_LDR,
    ASTC_5x5_sRGB,
    ASTC_6x5_LDR,
    ASTC_6x5_sRGB,
    ASTC_6x6_LDR,
    ASTC_6x6_sRGB,
    ASTC_8x5_LDR,
    ASTC_8x5_sRGB,
    ASTC_8x6_LDR,
    ASTC_8x6_sRGB,
    ASTC_8x8_LDR,
    ASTC_8x8_sRGB,
    ASTC_10x5_LDR,
    ASTC_10x5_sRGB,
    ASTC_10x6_LDR,
    ASTC_10x6_sRGB,
    ASTC_10x8_LDR,
    ASTC_10x8_sRGB,
    ASTC_10x10_LDR,
    ASTC_10x10_sRGB,
    ASTC_12x10_LDR,
    ASTC_12x10_sRGB,
    ASTC_12x12_LDR,
    ASTC_12x12_sRGB,

    PVRTC1_RGB_2BPP,
    PVRTC1_RGB_4BPP,
    PVRTC1_RGBA_2BPP,
    PVRTC1_RGBA_4BPP,
    PVRTC2_RGBA_2BPP,
    PVRTC2_RGBA_4BPP,
    PVRTC1_RGB_2BPP_sRGB,
    PVRTC1_RGB_4BPP_sRGB,
    PVRTC1_RGBA_2BPP_sRGB,
    PVRTC1_RGBA_4BPP_sRGB,
    PVRTC2_RGBA_2BPP_sRGB,
    PVRTC2_RGBA_4BPP_sRGB,

    GBGR8_422_Unorm,
    BGRG8_422_Unorm,
    G8_B8_R8_3PLANE_420_Unorm,
    G8_BR8_2PLANE_420_Unorm,
    G8_B8_R8_3PLANE_422_Unorm,
    G8_BR8_2PLANE_422_UNnorm,
    G8_B8_R8_3PLANE_444_Unorm,
    // Only For GL
    RGB16Sfloat_GL_FLOAT = 255,
    RGBA16Sfloat_GL_FLOAT,
};
constexpr inline bool isCompressionFormat(const AMGPixelFormat& pixelFormat)
{
    switch (pixelFormat)
    {
        default:
            return false;
        case AMGPixelFormat::BC1_RGBUnorm:
        case AMGPixelFormat::BC1_RGB_sRGB:
        case AMGPixelFormat::BC1_RGBAUnorm:
        case AMGPixelFormat::BC1_RGBA_sRGB:
        case AMGPixelFormat::BC2_RGBAUnorm:
        case AMGPixelFormat::BC2_RGBA_sRGB:
        case AMGPixelFormat::BC3_RGBAUnorm:
        case AMGPixelFormat::BC3_RGBA_sRGB:
        case AMGPixelFormat::BC4_RUnorm:
        case AMGPixelFormat::BC4_RSnorm:
        case AMGPixelFormat::BC5_RGUnorm:
        case AMGPixelFormat::BC5_RGSnorm:
        case AMGPixelFormat::BC6H_RGBUfloat:
        case AMGPixelFormat::BC6H_RGBSfloat:
        case AMGPixelFormat::BC7_RGBAUnorm:
        case AMGPixelFormat::BC7_RGBAUnorm_sRGB:
        case AMGPixelFormat::ETC1_RGB8Unorm:
        case AMGPixelFormat::ETC2_RGB8Unorm:
        case AMGPixelFormat::ETC2_RGB8_sRGB:
        case AMGPixelFormat::ETC2_RGB8A1Unorm:
        case AMGPixelFormat::ETC2_RGB8A1_sRGB:
        case AMGPixelFormat::ETC2_RGBA8Unorm:
        case AMGPixelFormat::ETC2_RGBA8_sRGB:
        case AMGPixelFormat::EAC_R11Unorm:
        case AMGPixelFormat::EAC_R11Snorm:
        case AMGPixelFormat::EAC_RG11Unorm:
        case AMGPixelFormat::EAC_RG11Snorm:
        case AMGPixelFormat::ASTC_4x4_LDR:
        case AMGPixelFormat::ASTC_4x4_sRGB:
        case AMGPixelFormat::ASTC_5x4_LDR:
        case AMGPixelFormat::ASTC_5x4_sRGB:
        case AMGPixelFormat::ASTC_5x5_LDR:
        case AMGPixelFormat::ASTC_5x5_sRGB:
        case AMGPixelFormat::ASTC_6x5_LDR:
        case AMGPixelFormat::ASTC_6x5_sRGB:
        case AMGPixelFormat::ASTC_6x6_LDR:
        case AMGPixelFormat::ASTC_6x6_sRGB:
        case AMGPixelFormat::ASTC_8x5_LDR:
        case AMGPixelFormat::ASTC_8x5_sRGB:
        case AMGPixelFormat::ASTC_8x6_LDR:
        case AMGPixelFormat::ASTC_8x6_sRGB:
        case AMGPixelFormat::ASTC_8x8_LDR:
        case AMGPixelFormat::ASTC_8x8_sRGB:
        case AMGPixelFormat::ASTC_10x5_LDR:
        case AMGPixelFormat::ASTC_10x5_sRGB:
        case AMGPixelFormat::ASTC_10x6_LDR:
        case AMGPixelFormat::ASTC_10x6_sRGB:
        case AMGPixelFormat::ASTC_10x8_LDR:
        case AMGPixelFormat::ASTC_10x8_sRGB:
        case AMGPixelFormat::ASTC_10x10_LDR:
        case AMGPixelFormat::ASTC_10x10_sRGB:
        case AMGPixelFormat::ASTC_12x10_LDR:
        case AMGPixelFormat::ASTC_12x10_sRGB:
        case AMGPixelFormat::ASTC_12x12_LDR:
        case AMGPixelFormat::ASTC_12x12_sRGB:
        case AMGPixelFormat::PVRTC1_RGB_2BPP:
        case AMGPixelFormat::PVRTC1_RGB_4BPP:
        case AMGPixelFormat::PVRTC1_RGBA_2BPP:
        case AMGPixelFormat::PVRTC1_RGBA_4BPP:
        case AMGPixelFormat::PVRTC2_RGBA_2BPP:
        case AMGPixelFormat::PVRTC2_RGBA_4BPP:
        case AMGPixelFormat::PVRTC1_RGB_2BPP_sRGB:
        case AMGPixelFormat::PVRTC1_RGB_4BPP_sRGB:
        case AMGPixelFormat::PVRTC1_RGBA_2BPP_sRGB:
        case AMGPixelFormat::PVRTC1_RGBA_4BPP_sRGB:
        case AMGPixelFormat::PVRTC2_RGBA_2BPP_sRGB:
        case AMGPixelFormat::PVRTC2_RGBA_4BPP_sRGB:
            return true;
    }
}
constexpr inline bool isDepthFormat(const AMGPixelFormat& pixelFormat)
{
    switch (pixelFormat)
    {
        default:
            return false;
        case AMGPixelFormat::D16Unorm:
        case AMGPixelFormat::D24X8Unorm:
        case AMGPixelFormat::D32Sfloat:
            return true;
    }
}
constexpr inline bool isDepthStencilFormat(const AMGPixelFormat& pixelFormat)
{
    switch (pixelFormat)
    {
        default:
            return false;
        case AMGPixelFormat::D16UnormS8Uint:
        case AMGPixelFormat::D24UnormS8Uint:
        case AMGPixelFormat::D32SfloatS8Uint:
            return true;
    }
}
/**
 * @brief Enum of image data type.
 * 
 */
enum class GAIA_LIB_EXPORT AMGDataType
{
    Invalid = 0,
    U8norm,
    S8norm,
    U8,
    S8,
    U16norm,
    S16norm,
    U16,
    S16,
    //    U32norm,
    //    S32norm,
    U32,
    S32,
    //    U64,
    //    S64,
    //    X32,
    F16,
    F32,
    //    F64,
};
/**
 * @brief Enum of image type.
 * 
 */
enum class GAIA_LIB_EXPORT ImageType
{
    RENDERBUFFER,
    RENDERBUFFER_MS,
    TEXTURE_1D,
    TEXTURE_2D,
    TEXTURE_3D,
    TEXTURE_CUBE,
    TEXTURE_BUFFER,
    TEXTURE_2D_MS,
    TEXTURE_1D_ARRAY,
    TEXTURE_2D_ARRAY,
    TEXTURE_CUBE_ARRAY,
    TEXTURE_2D_MS_ARRAY,
    TEXTURE_EXTERNAL,
#if AMAZING_PLATFORM == AMAZING_MACOS
    TEXTURE_RECTANGLE,
#endif
    ImageTypeCount,
    RENDERBUFFER_MS_ATTACH,
    INVALID,
};

inline int getPixelFormatSize(const AMGPixelFormat format)
{
    switch (format)
    {
        default:
            return 0;
        case AMGPixelFormat::A8Unorm:
        case AMGPixelFormat::L8Unorm:
        case AMGPixelFormat::GR4Unorm:
            return 1;
        case AMGPixelFormat::LA8Unorm:
        case AMGPixelFormat::ABGR4Unorm:
        case AMGPixelFormat::ARGB4Unorm:
        case AMGPixelFormat::RGBA4Unorm:
        case AMGPixelFormat::BGRA4Unorm:
        case AMGPixelFormat::B5G6R5Unorm:
        case AMGPixelFormat::R5G6B5Unorm:
        case AMGPixelFormat::A1BGR5Unorm:
        case AMGPixelFormat::A1RGB5Unorm:
        case AMGPixelFormat::RGB5A1Unorm:
        case AMGPixelFormat::BGR5A1Unorm:
            return 2;
        case AMGPixelFormat::R8Unorm:
        case AMGPixelFormat::R8Snorm:
        case AMGPixelFormat::R8Uscaleld:
        case AMGPixelFormat::R8Sscaled:
        case AMGPixelFormat::R8Uint:
        case AMGPixelFormat::R8Sint:
        case AMGPixelFormat::R8_sRGB:
            return 1;
        case AMGPixelFormat::RG8Unorm:
        case AMGPixelFormat::RG8Snorm:
        case AMGPixelFormat::RG8Uscaled:
        case AMGPixelFormat::RG8Sscaled:
        case AMGPixelFormat::RG8Uint:
        case AMGPixelFormat::RG8Sint:
        case AMGPixelFormat::RG8_sRGB:
            return 2;
        case AMGPixelFormat::RGB8Unorm:
        case AMGPixelFormat::RGB8Snorm:
        case AMGPixelFormat::RGB8Uscaled:
        case AMGPixelFormat::RGB8Sscaled:
        case AMGPixelFormat::RGB8Uint:
        case AMGPixelFormat::RGB8Sint:
        case AMGPixelFormat::RGB8_sRGB:
        case AMGPixelFormat::BGR8Unorm:
        case AMGPixelFormat::BGR8Snorm:
        case AMGPixelFormat::BGR8Uscaled:
        case AMGPixelFormat::BGR8Sscaled:
        case AMGPixelFormat::BGR8Uint:
        case AMGPixelFormat::BGR8Sint:
        case AMGPixelFormat::BGR8_sRGB:
            return 3;
        case AMGPixelFormat::RGBA8Unorm:
        case AMGPixelFormat::RGBA8Snorm:
        case AMGPixelFormat::RGBA8Uscaled:
        case AMGPixelFormat::RGBA8Sscaled:
        case AMGPixelFormat::RGBA8Uint:
        case AMGPixelFormat::RGBA8Sint:
        case AMGPixelFormat::RGBA8_sRGB:
        case AMGPixelFormat::BGRA8Unorm:
        case AMGPixelFormat::BGRA8Snorm:
        case AMGPixelFormat::BGRA8Uscaled:
        case AMGPixelFormat::BGRA8Sscaled:
        case AMGPixelFormat::BGRA8Uint:
        case AMGPixelFormat::BGRA8Sint:
        case AMGPixelFormat::BGRA8_sRGB:
        case AMGPixelFormat::ABGR8Unorm:
        case AMGPixelFormat::ABGR8Snorm:
        case AMGPixelFormat::ABGR8Uscaled:
        case AMGPixelFormat::ABGR8Sscaled:
        case AMGPixelFormat::ABGR8Uint:
        case AMGPixelFormat::ABGR8Sint:
        case AMGPixelFormat::ABGR8_sRGB:
            return 4;
        case AMGPixelFormat::BGR10A2Unorm:
        case AMGPixelFormat::BGR10A2Snorm:
        case AMGPixelFormat::BGR10A2Uscaled:
        case AMGPixelFormat::BGR10A2Sscaled:
        case AMGPixelFormat::BGR10A2Uint:
        case AMGPixelFormat::BGR10A2Sint:
        case AMGPixelFormat::RGB10A2Unorm:
        case AMGPixelFormat::RGB10A2Snorm:
        case AMGPixelFormat::RGB10A2Uscaled:
        case AMGPixelFormat::RGB10A2Sscaled:
        case AMGPixelFormat::RGB10A2Uint:
        case AMGPixelFormat::RGB10A2Sint:
            return 4;
        case AMGPixelFormat::R16Unorm:
        case AMGPixelFormat::R16Snorm:
        case AMGPixelFormat::R16Uscaleld:
        case AMGPixelFormat::R16Sscaled:
        case AMGPixelFormat::R16Uint:
        case AMGPixelFormat::R16Sint:
        case AMGPixelFormat::R16Sfloat:
            return 2;
        case AMGPixelFormat::RG16Unorm:
        case AMGPixelFormat::RG16Snorm:
        case AMGPixelFormat::RG16Uscaled:
        case AMGPixelFormat::RG16Sscaled:
        case AMGPixelFormat::RG16Uint:
        case AMGPixelFormat::RG16Sint:
        case AMGPixelFormat::RG16Sfloat:
            return 4;
        case AMGPixelFormat::RGB16Unorm:
        case AMGPixelFormat::RGB16Snorm:
        case AMGPixelFormat::RGB16Uscaled:
        case AMGPixelFormat::RGB16Sscaled:
        case AMGPixelFormat::RGB16Uint:
        case AMGPixelFormat::RGB16Sint:
        case AMGPixelFormat::RGB16Sfloat:
            return 6;
        case AMGPixelFormat::RGBA16Unorm:
        case AMGPixelFormat::RGBA16Snorm:
        case AMGPixelFormat::RGBA16Uscaled:
        case AMGPixelFormat::RGBA16Sscaled:
        case AMGPixelFormat::RGBA16Uint:
        case AMGPixelFormat::RGBA16Sint:
        case AMGPixelFormat::RGBA16Sfloat:
            return 8;
        case AMGPixelFormat::R32Uint:
        case AMGPixelFormat::R32Sint:
        case AMGPixelFormat::R32Sfloat:
            return 4;
        case AMGPixelFormat::RG32Uint:
        case AMGPixelFormat::RG32Sint:
        case AMGPixelFormat::RG32Sfloat:
            return 8;
        case AMGPixelFormat::RGB32Uint:
        case AMGPixelFormat::RGB32Sint:
        case AMGPixelFormat::RGB32Sfloat:
            return 12;
        case AMGPixelFormat::RGBA32Uint:
        case AMGPixelFormat::RGBA32Sint:
        case AMGPixelFormat::RGBA32Sfloat:
            return 16;
        case AMGPixelFormat::R64Uint:
        case AMGPixelFormat::R64Sint:
        case AMGPixelFormat::R64Sfloat:
            return 8;
        case AMGPixelFormat::RG64Uint:
        case AMGPixelFormat::RG64Sint:
        case AMGPixelFormat::RG64Sfloat:
            return 16;
        case AMGPixelFormat::RGB64Uint:
        case AMGPixelFormat::RGB64Sint:
        case AMGPixelFormat::RGB64Sfloat:
            return 24;
        case AMGPixelFormat::RGBA64Uint:
        case AMGPixelFormat::RGBA64Sint:
        case AMGPixelFormat::RGBA64Sfloat:
            return 32;
        case AMGPixelFormat::RG11B10Ufloat:
        case AMGPixelFormat::RGB9E5Ufloat:
            return 4;
        case AMGPixelFormat::D16Unorm:
            return 2;
        case AMGPixelFormat::D24X8Unorm:
        case AMGPixelFormat::D32Sfloat:
            return 4;
        case AMGPixelFormat::S8Uint:
            return 1;
        case AMGPixelFormat::D16UnormS8Uint:
        case AMGPixelFormat::D24UnormS8Uint:
            return 4;
        case AMGPixelFormat::D32SfloatS8Uint:
            return 8;
    }
}

inline int getDataTypeSize(const AMGDataType type)
{
    switch (type)
    {
        default:
            return 0;
        case AMGDataType::U8norm:
        case AMGDataType::S8norm:
        case AMGDataType::U8:
        case AMGDataType::S8:
            return 1;
        case AMGDataType::U16norm:
        case AMGDataType::S16norm:
        case AMGDataType::U16:
        case AMGDataType::S16:
        case AMGDataType::F16:
            return 2;
        case AMGDataType::U32:
        case AMGDataType::S32:
        case AMGDataType::F32:
            return 4;
    }
}
NAMESPACE_AMAZING_ENGINE_END

#endif
