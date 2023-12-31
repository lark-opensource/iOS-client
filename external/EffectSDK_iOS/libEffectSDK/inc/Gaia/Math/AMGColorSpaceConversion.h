/**
 * @file AMGColorSpaceConversion.h
 * @author fanjiaqi (fanjiaqi.837@bytedance.com)
 * @brief Convert functions for color space.
 * @version 0.1
 * @date 2019-12-03
 * 
 * @copyright Copyright (c) 2019
 * 
 */

#pragma once

#include "Gaia/Math/AMGColor.h"

NAMESPACE_AMAZING_ENGINE_BEGIN
/**
 * @brief Enum for the types of different color space. 
 * 
 */
enum ColorSpace
{
    kUninitializedColorSpace = -1,
    kGammaColorSpace = 0,
    kLinearColorSpace,
    kMaxColorSpace
};
/**
 * @brief Get current ctive color space type.
 * 
 * @return Current color space type. 
 */
ColorSpace GAIA_LIB_EXPORT GetActiveColorSpace();

// http://www.opengl.org/registry/specs/EXT/framebuffer_sRGB.txt
// http://www.opengl.org/registry/specs/EXT/texture_sRGB_decode.txt
// {  cs / 12.92,                 cs <= 0.04045 }
// {  ((cs + 0.055)/1.055)^2.4,   cs >  0.04045 }

/**
 * @brief Convert float value from Gamma space to Linear space.
 * 
 * @param value Input float value in Gamma space.
 * @return float Result float value in Linear space.
 */
inline float GammaToLinearSpace(float value)
{
    if (value <= 0.04045F)
        return value / 12.92F;
    else if (value < 1.0F)
        return pow((value + 0.055F) / 1.055F, 2.4F);
    else
        return pow(value, 2.4F);
}

// http://www.opengl.org/registry/specs/EXT/framebuffer_sRGB.txt
// http://www.opengl.org/registry/specs/EXT/texture_sRGB_decode.txt
// {  0.0,                          0         <= cl
// {  12.92 * c,                    0         <  cl < 0.0031308
// {  1.055 * cl^0.41666 - 0.055,   0.0031308 <= cl < 1
// {  1.0,                                       cl >= 1  <- This has been adjusted since we want to maintain HDR colors
/**
 * @brief Convert float value from Linear space to gamma space.
 * 
 * @param value Input float value in Linear space.
 * @return float Result float value in Gamma space.
 */
inline float LinearToGammaSpace(float value)
{
    if (value <= 0.0F)
        return 0.0F;
    else if (value <= 0.0031308F)
        return 12.92F * value;
    else if (value <= 1.0F)
        return 1.055F * powf(value, 0.41666F) - 0.055F;
    else
        return powf(value, 0.41666F);
}

/**
 * @brief Convert value from Gamma space to Linear space approximately with higher performance.
 * 
 * @param val Input float value in Gamma space.
 * @return float Result float value in Linear space.
 */
inline float GammaToLinearSpaceXenon(float val)
{
    float ret;
    if (val < 0)
        ret = 0;
    else if (val < 0.25f)
        ret = 0.25f * val;
    else if (val < 0.375f)
        ret = (1.0f / 16.0f) + 0.5f * (val - 0.25f);
    else if (val < 0.75f)
        ret = 0.125f + 1.0f * (val - 0.375f);
    else if (val < 1.0f)
        ret = 0.5f + 2.0f * (val - 0.75f);
    else
        ret = 1.0f;
    return ret;
}

/**
 * @brief Convert value from Linear space to Gamma space approximately with higher performance.
 * 
 * @param val Input float value in Linear space.
 * @return float Result float value in Gamma space.
 */
inline float LinearToGammaSpaceXenon(float val)
{
    float ret;
    if (val < 0)
        ret = 0;
    else if (val < (1.0f / 16.0f))
        ret = 4.0f * val;
    else if (val < (1.0f / 8.0f))
        ret = (1.0f / 4.0f) + 2.0f * (val - (1.0f / 16.0f));
    else if (val < 0.5f)
        ret = 0.375f + 1.0f * (val - 0.125f);
    else if (val < 1.0f)
        ret = 0.75f + 0.5f * (val - 0.50f);
    else
        ret = 1.0f;

    return ret;
}

/**
 * @brief Convert color from Gamma space to Linear space.
 * 
 * @param value Input color in Gamma space.
 * @return Color Result color in Linear space.
 */
inline Color GammaToLinearSpace(const Color& value)
{
    return Color(GammaToLinearSpace(value.r), GammaToLinearSpace(value.g), GammaToLinearSpace(value.b), value.a);
}

/**
 * @brief Convert color from Linear space to Gamma space.
 * 
 * @param value Input color in Linear space.
 * @return Color Result color in Gamma space.
 */
inline Color LinearToGammaSpace(const Color& value)
{
    return Color(LinearToGammaSpace(value.r), LinearToGammaSpace(value.g), LinearToGammaSpace(value.b), value.a);
}

/**
 * @brief Convert color from Gamma space to Linear space approximately with higher performance.
 * 
 * @param value Input color in Gamma space.
 * @return Color Result color in Linear space.
 */
inline Color GammaToLinearSpaceXenon(const Color& value)
{
    return Color(GammaToLinearSpaceXenon(value.r), GammaToLinearSpaceXenon(value.g), GammaToLinearSpaceXenon(value.b), value.a);
}

/**
 * @brief Convert color from Linear space to Gamma space approximately with higher performance.
 * 
 * @param value Input color in Linear space.
 * @return Color Result color in Gamma space.
 */
inline Color LinearToGammaSpaceXenon(const Color& value)
{
    return Color(LinearToGammaSpaceXenon(value.r), LinearToGammaSpaceXenon(value.g), LinearToGammaSpaceXenon(value.b), value.a);
}

/**
 * @brief Convert float value from Gamma space to current active space.
 * 
 * @param value Input float in Gamma space.
 * @return float Result float in current active space.
 */
inline float GammaToActiveColorSpace(float value)
{
    if (GetActiveColorSpace() == kLinearColorSpace)
        return GammaToLinearSpace(value);
    else
        return value;
}

/**
 * @brief Convert color from Gamma space to current active space.
 * 
 * @param value Input color in Gamma space.
 * @return Color Result color in current active space.
 */
inline Color GammaToActiveColorSpace(const Color& value)
{
    if (GetActiveColorSpace() == kLinearColorSpace)
        return GammaToLinearSpace(value);
    else
        return value;
}

/**
 * @brief Convert color from current active color space to Gamma space.
 * 
 * @param value Input color in current active space.
 * @return Color Result color in Gamma space.
 */
inline Color ActiveToGammaColorSpace(const Color& value)
{
    if (GetActiveColorSpace() == kLinearColorSpace)
        return LinearToGammaSpace(value);
    else
        return value;
}

NAMESPACE_AMAZING_ENGINE_END
