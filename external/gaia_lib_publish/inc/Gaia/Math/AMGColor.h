/**
 * @file AMGColor.h
 * @author fanjiaqi (fanjiaqi.837@bytedance.com)
 * @brief Definition of basic color class.
 * @version 0.1
 * @date 2019-11-26
 * 
 * @copyright Copyright (c) 2019
 * 
 */
#ifndef COLOR_H
#define COLOR_H

#include <algorithm>
#include "Gaia/AMGPrerequisites.h"
#include "Gaia/Math/AMGFloatConversion.h"
#include "Gaia/Math/AMGVector4.h"

NAMESPACE_AMAZING_ENGINE_BEGIN
/**
 * @brief Basic color class. Values of channels are stored with float(0.0 ~ 1.0).
 * 
 */
class GAIA_LIB_EXPORT Color
{
public:
    /**
     * @brief r, g, b, a channel of color.
     * 
     */
    float r = 0.f;
    float g = 0.f;
    float b = 0.f;
    float a = 0.f;

    //	DEFINE_GET_TYPESTRING_IS_ANIMATION_CHANNEL (ColorRGBA)
    /**
     * @brief Construct a new Color object.
     * 
     */
    Color() {}

    /**
     * @brief Construct a new Color object.
     * 
     * @param inR Value of r channel.
     * @param inG Value of g channel.
     * @param inB Value of b channel.
     * @param inA Value of a channel.
     */
    Color(float inR, float inG, float inB, float inA = 1.0F)
        : r(inR)
        , g(inG)
        , b(inB)
        , a(inA)
    {
    }
    /**
     * @brief Construct a new Color object.
     * 
     * @param c Pointer of the value array.
     */
    explicit Color(const float* c)
        : r(c[0])
        , g(c[1])
        , b(c[2])
        , a(c[3])
    {
    }
    /**
     * @brief Set current channel values with 4 floats.
     * 
     * @param inR Value of r channel.
     * @param inG Value of g channel.
     * @param inB Value of b channel.
     * @param inA Value of a channel.
     */
    void Set(float inR, float inG, float inB, float inA)
    {
        r = inR;
        g = inG;
        b = inB;
        a = inA;
    }
    /**
     * @brief Set current channel values with 32-bit unsigned int.
     * 
     * @param hex Unsigned int which stores 4 channel values.
     */
    void SetHex(UInt32 hex)
    {
        Set(float(hex >> 24) / 255.0f,
            float((hex >> 16) & 255) / 255.0f,
            float((hex >> 8) & 255) / 255.0f,
            float(hex & 255) / 255.0f);
    }
    /**
     * @brief Convert current channel values to a 32-bit unsigned int and get it.
     * 
     * @return UInt32 Conversion result.
     */
    UInt32 GetHex() const
    {
        UInt32 hex = (NormalizedToByte(r) << 24) | (NormalizedToByte(g) << 16) | (NormalizedToByte(b) << 8) | NormalizedToByte(a);
        return hex;
    }
    /**
     * @brief Get the average value of r,g,b channels.
     * 
     * @return float Average value.
     */
    float AverageRGB() const { return (r + g + b) * (1.0F / 3.0F); }
    /**
     * @brief Get the gray scale of r,g,b channel. The weight of 3 channels is 0.3, 0.59 and 0.11.
     * 
     * @return float Gray Scale.
     */
    float GreyScaleValue() const { return r * 0.30f + g * 0.59f + b * 0.11f; }
    /**
     * @brief Overload operator=. Copy value from other color.
     * 
     * @param in Other color.
     * @return Color& Reference of self. *this.
     */
    Color& operator=(const Color& in)
    {
        Set(in.r, in.g, in.b, in.a);
        return *this;
    }
    /**
     * @brief Judge whether the value of current color is equal to other color.
     * 
     * @param inRGB Other color.
     * @return true The value of current color is equal to other color.
     * @return false The value of current color is not equal to other color.
     */
    bool Equals(const Color& inRGB) const
    {
        return (r == inRGB.r && g == inRGB.g && b == inRGB.b && a == inRGB.a);
    }
    /**
     * @brief Judge whether the value of current color is not equal to other color.
     * 
     * @param inRGB Other color.
     * @return true The value of current color is not equal to other color.
     * @return false The value of current color is equal to other color.
     */
    bool NotEquals(const Color& inRGB) const
    {
        return (r != inRGB.r || g != inRGB.g || b != inRGB.b || a != inRGB.a);
    }
    /**
     * @brief Convert current color to vector4.
     * 
     * @return Vector4f Result vector.
     */
    Vector4f toVec4() const
    {
        return Vector4f(r, g, b, a);
    }
    /**
     * @brief Get the pointer of value.
     * 
     * @return float* Pointer of value.
     */
    float* GetPtr() { return &r; }
    /**
     * @brief Get the pointer of value.
     * 
     * @return const float* Pointer of value.
     */
    const float* GetPtr() const { return &r; }
    /**
     * @brief Add other color to current color. Value in every channel is added.
     * 
     * @param inRGBA Other color.
     * @return Color& Reference to self. *this.
     */
    Color& operator+=(const Color& inRGBA)
    {
        r += inRGBA.r;
        g += inRGBA.g;
        b += inRGBA.b;
        a += inRGBA.a;
        return *this;
    }
    /**
     * @brief Multiply other color to current color. Value in every channel is multiplied.
     * 
     * @param inRGBA Other color.
     * @return Color& Reference to self. *this.
     */
    Color& operator*=(const Color& inRGBA)
    {
        r *= inRGBA.r;
        g *= inRGBA.g;
        b *= inRGBA.b;
        a *= inRGBA.a;
        return *this;
    }

    /**
     * @brief Overload operator==. Compare value of current color with other color.
     * 
     * @param inRGB Other color.
     * @return true The value of current color equals to other color.
     * @return false The value of current color does not equal to other color.
     */
    bool operator==(const Color& inRGB) const
    {
        return Equals(inRGB);
    }

    /**
     * @brief Overload operator==. Compare value of current color with other color.
     * 
     * @param inRGB Other color.
     * @return true The value of current color does not equal to other color.
     * @return false The value of current color equals to other color.
     */
    bool operator!=(const Color& inRGB) const
    {
        return NotEquals(inRGB);
    }
};
/**
 * @brief Overload operator+. Add the values of two colors.
 * 
 * @param inC0 Left input color.
 * @param inC1 Right input color.
 * @return Color Result color.
 */
inline Color operator+(const Color& inC0, const Color& inC1)
{
    return Color(inC0.r + inC1.r, inC0.g + inC1.g, inC0.b + inC1.b, inC0.a + inC1.a);
}
/**
 * @brief Overload operator*. Multiply the values of two colors.
 * 
 * @param inC0 Left input color.
 * @param inC1 Right input color.
 * @return Color Result color.
 */
inline Color operator*(const Color& inC0, const Color& inC1)
{
    return Color(inC0.r * inC1.r, inC0.g * inC1.g, inC0.b * inC1.b, inC0.a * inC1.a);
}
/**
 * @brief Overload operator*. Multiply a float with a color.
 * 
 * @param inScale Input float.
 * @param inC0 Input color.
 * @return Color Result color.
 */
inline Color operator*(float inScale, const Color& inC0)
{
    return Color(inC0.r * inScale, inC0.g * inScale, inC0.b * inScale, inC0.a * inScale);
}
/**
 * @brief Overload operator*. Multiply a float with a color.
 * 
 * @param inC0 Input color.
 * @param inScale Input float.
 * @return Color Result color.
 */
inline Color operator*(const Color& inC0, float inScale)
{
    return Color(inC0.r * inScale, inC0.g * inScale, inC0.b * inScale, inC0.a * inScale);
}
/**
 * @brief Linear interpolation between c0 and c1 using t to weight between them
 * 
 * @param c0 Input color0.
 * @param c1 Input color1.
 * @param t Interpolation weight.
 * @return Color Result color.
 */
inline Color Lerp(const Color& c0, const Color& c1, float t)
{
    return (1.0f - t) * c0 + t * c1;
}
/**
 * @brief Basic color class. Values of channels are stored with UInt8.
 * 
 */
class GAIA_LIB_EXPORT ColorRGBA32
{
public:
    /**
     * @brief r, g, b, a channel of color.
     * 
     */
    UInt8 r, g, b, a;

    //	DEFINE_GET_TYPESTRING_IS_ANIMATION_CHANNEL (ColorRGBA)
    /**
     * @brief Construct a new colorRGBA32 object.
     * 
     */
    ColorRGBA32() {}
    /**
     * @brief Construct a new colorRGBA32 object.
     * 
     * @param inR Value of r channel.
     * @param inG Value of g channel.
     * @param inB Value of b channel.
     * @param inA Value of a channel.
     */
    ColorRGBA32(UInt8 inR, UInt8 inG, UInt8 inB, UInt8 inA)
    {
        r = inR;
        g = inG;
        b = inB;
        a = inA;
    }
    /**
     * @brief Construct a new colorRGBA32 object.
     * 
     * @param c UInt32 which stores value of 4 channels.
     */
    ColorRGBA32(UInt32 c) { *(UInt32*)this = c; }
    /**
     * @brief Set the value of current colorRGBA32.
     * 
     * @param inR Value of r channel.
     * @param inG Value of g channel.
     * @param inB Value of b channel.
     * @param inA Value of a channel.
     */
    void Set(UInt8 inR, UInt8 inG, UInt8 inB, UInt8 inA)
    {
        r = inR;
        g = inG;
        b = inB;
        a = inA;
    }
    /**
     * @brief Overload operator=. Copy value from other colorRGBA32.
     * 
     * @param c Other colorRGBA32.
     * @return ColorRGBA32 Reference of self. *this.
     */
    ColorRGBA32 operator=(const ColorRGBA32& c)
    {
        *(UInt32*)this = *((UInt32*)&c);
        return *this;
    }
    /**
     * @brief Construct a new ColorRGBA32 object.
     * 
     * @param c Other color.
     */
    ColorRGBA32(const Color& c) { Set(c); }
    /**
     * @brief Overload operator Color. Convert current colorRGBA32 into color.
     * 
     * @return Color Conversion result.
     */
    operator Color() const
    {
        return Color(ByteToNormalized(r), ByteToNormalized(g), ByteToNormalized(b), ByteToNormalized(a));
    }
    /**
     * @brief Convert value of current colorRGBA32 into UInt32.
     * 
     * @return UInt32 Conversion result.
     */
    UInt32 AsUInt32() const { return *(UInt32*)this; }
    /**
     * @brief Overload operator=. Copy value from other color.
     * 
     * @param c Other color.
     */
    void operator=(const Color& c)
    {
        Set(c);
    }
    /**
     * @brief Convert value of current colorRGBA32 into UInt32.
     * 
     * @return UInt32 Conversion result.
     */
    UInt32 GetUInt32() { return *(UInt32*)this; }
    /**
     * @brief Set value of current colorRGBA32 with a color instance.
     * 
     * @param c Input color.
     */
    void Set(const Color& c)
    {
        r = NormalizedToByte(c.r);
        g = NormalizedToByte(c.g);
        b = NormalizedToByte(c.b);
        a = NormalizedToByte(c.a);
    }

    /**
     * @brief Overload operator[]. Get value of channel with index(0~3).
     * 
     * @param i Input index.
     * @return UInt8& Value of target channel.
     */
    UInt8& operator[](long i) { return GetPtr()[i]; }
    /**
     * @brief Overload operator[]. Get value of channel with index(0~3).
     * 
     * @param i Input index.
     * @return const UInt8& Value of target channel.
     */
    const UInt8& operator[](long i) const { return GetPtr()[i]; }
    /**
     * @brief Overload operator==. Compare value of current colorRGBA32 with other colorRGBA32.
     * 
     * @param inRGB Other colorRGBA32.
     * @return true The value of current colorRGBA32 equals to other colorRGBA32.
     * @return false The value of current colorRGBA32 does not equal to other colorRGBA32.
     */
    bool operator==(const ColorRGBA32& inRGB) const
    {
        return (r == inRGB.r && g == inRGB.g && b == inRGB.b && a == inRGB.a) ? true : false;
    }
    /**
     * @brief Overload operator==. Compare value of current colorRGBA32 with other colorRGBA32.
     * 
     * @param inRGB Other colorRGBA32.
     * @return true The value of current colorRGBA32 does not equal to other colorRGBA32.
     * @return false The value of current colorRGBA32 equals to other colorRGBA32.
     */
    bool operator!=(const ColorRGBA32& inRGB) const
    {
        return (r != inRGB.r || g != inRGB.g || b != inRGB.b || a != inRGB.a) ? true : false;
    }
    /**
     * @brief Get the pointer of value.
     * 
     * @return UInt8* Pointer of value.
     */
    UInt8* GetPtr() { return &r; }
    /**
     * @brief Get the pointer of value.
     * 
     * @return const UInt8* Pointer of value.
     */
    const UInt8* GetPtr() const { return &r; }
    /**
     * @brief Pack values of 4 chanel into a colorRGBA32, and get the value of colorRGBA32 as a float.
     * 
     * @param _r Value of r channel.
     * @param _g Value of g channel.
     * @param _b Value of b channel.
     * @param _a Value of a channel.
     * @return float The 4 bits of float are value of channel r,g,b,a.
     */
    static float packToFloat(float _r, float _g, float _b, float _a) { return *(float*)(ColorRGBA32(_r * 255, _g * 255, _b * 255, _a * 255).GetPtr()); }
    /**
     * @brief Overload operator*. Multiply current colorRGBA32 with an int.
     * 
     * @param scale Input int.
     * @return ColorRGBA32 Result colorRGBA32. Temp value.
     */
    inline ColorRGBA32 operator*(int scale) const
    {
        //AssertIf (scale < 0 || scale > 255);
        scale += 1;
        const UInt32& u = reinterpret_cast<const UInt32&>(*this);
        UInt32 lsb = (((u & 0x00ff00ff) * scale) >> 8) & 0x00ff00ff;
        UInt32 msb = (((u & 0xff00ff00) >> 8) * scale) & 0xff00ff00;
        lsb |= msb;
        return ColorRGBA32(lsb);
    }
    /**
     * @brief Overload operator*=. Multiply current colorRGBA32 with other colorRGBA32. Every channel will be multiplied.
     * 
     * @param inC1 Other colorRGBA32.
     */
    inline void operator*=(const ColorRGBA32& inC1)
    {
#if 0
		r = (r * inC1.r) / 255;
		g = (g * inC1.g) / 255;
		b = (b * inC1.b) / 255;
		a = (a * inC1.a) / 255;
#else // This is much faster, but doesn't guarantee 100% matching result (basically color values van vary 1/255 but not at ends, check out unit test in cpp file).
        UInt32& u = reinterpret_cast<UInt32&>(*this);
        const UInt32& v = reinterpret_cast<const UInt32&>(inC1);
        UInt32 result = (((u & 0x000000ff) * ((v & 0x000000ff) + 1)) >> 8) & 0x000000ff;
        result |= (((u & 0x0000ff00) >> 8) * (((v & 0x0000ff00) >> 8) + 1)) & 0x0000ff00;
        result |= (((u & 0x00ff0000) * (((v & 0x00ff0000) >> 16) + 1)) >> 8) & 0x00ff0000;
        result |= (((u & 0xff000000) >> 8) * (((v & 0xff000000) >> 24) + 1)) & 0xff000000;
        u = result;
#endif
    }
    /**
     * @brief Swizzle current rgba channel into bgra.
     * 
     * @return ColorRGBA32 Swizzled colorRGBA32.
     */
    inline ColorRGBA32 SwizzleToBGRA() const { return ColorRGBA32(b, g, r, a); }
    /**
     * @brief Swizzle current rgba channel into bgr, and alpha channel is setted to 255.
     * 
     * @return ColorRGBA32 Swizzled colorRGBA32.
     */
    inline ColorRGBA32 SwizzleToBGR() const { return ColorRGBA32(b, g, r, 255); }
    /**
     * @brief Swizzle current rgba channel into argb.
     * 
     * @return ColorRGBA32 Swizzled colorRGBA32.
     */
    inline ColorRGBA32 SwizzleToARGB() const { return ColorRGBA32(a, r, g, b); }
    /**
     * @brief Swizzle current rgba channel into bgra.
     * 
     * @return ColorRGBA32 Swizzled colorRGBA32.
     */
    inline ColorRGBA32 UnswizzleBGRA() const { return ColorRGBA32(b, g, r, a); }
    /**
     * @brief Swizzle current rgba channel into argb.
     * 
     * @return ColorRGBA32 Swizzled colorRGBA32.
     */
    inline ColorRGBA32 UnswizzleARGB() const { return ColorRGBA32(g, b, a, r); }
};

#if GFX_OPENGLESxx_ONLY
/**
 * @brief Swizzle colorRGBA32 according to current platform.
 * 
 * @param col Input col.
 * @return ColorRGBA32 Swizzled colorRGBA32.
 */
inline ColorRGBA32 SwizzleColorForPlatform(const ColorRGBA32& col)
{
    return col;
}
/**
 * @brief Unswizzle colorRGBA32 according to current platform.
 * 
 * @param col Input col.
 * @return ColorRGBA32 Unswizzled colorRGBA32.
 */
inline ColorRGBA32 UnswizzleColorForPlatform(const ColorRGBA32& col)
{
    return col;
}
#else
/**
 * @brief Swizzle colorRGBA32 according to current platform.
 * 
 * @param col Input col.
 * @return ColorRGBA32 Swizzled colorRGBA32.
 */
inline ColorRGBA32 SwizzleColorForPlatform(const ColorRGBA32& col)
{
    return col.SwizzleToBGRA();
}
/**
 * @brief Unswizzle colorRGBA32 according to current platform.
 * 
 * @param col Input col.
 * @return ColorRGBA32 Unswizzled colorRGBA32.
 */
inline ColorRGBA32 UnswizzleColorForPlatform(const ColorRGBA32& col)
{
    return col.UnswizzleBGRA();
}
#endif
/**
 * @brief Functor which can convert colorRGBA32 into UInt32.
 * 
 */
struct GAIA_LIB_EXPORT OpColorRGBA32ToUInt32
{
    typedef UInt32 result_type;
    /**
     * @brief Overload operator(). Convert colorRGBA32 into UInt32
     * 
     * @param arg Input colorRGBA32.
     * @return UInt32 Converted result.
     */
    UInt32 operator()(ColorRGBA32 const& arg) const { return arg.AsUInt32(); }
};
/**
 * @brief Overload operator+. Multiply values of two colorRGBA32.
 * 
 * @param inC0 Left input colorRGBA32
 * @param inC1 Right input colorRGBA32.
 * @return ColorRGBA32 Result colorRGBA32.
 */
inline ColorRGBA32 operator+(const ColorRGBA32& inC0, const ColorRGBA32& inC1)
{
    return ColorRGBA32(std::min<int>(inC0.r + inC1.r, 255),
                       std::min<int>(inC0.g + inC1.g, 255),
                       std::min<int>(inC0.b + inC1.b, 255),
                       std::min<int>(inC0.a + inC1.a, 255));
}
/**
 * @brief Overload operator*. Multiply values of two colorRGBA32.
 * 
 * @param inC0 Left input colorRGBA32.
 * @param inC1 Right input colorRGBA32.
 * @return ColorRGBA32 Result colorRGBA32.
 */
inline ColorRGBA32 operator*(const ColorRGBA32& inC0, const ColorRGBA32& inC1)
{
#if 0
	return ColorRGBA32 ((inC0.r * inC1.r) / 255, 
		(inC0.g * inC1.g) / 255,
		(inC0.b * inC1.b) / 255,
		(inC0.a * inC1.a) / 255);
#else
    // This is much faster, but doesn't guarantee 100% matching result (basically color values van vary 1/255 but not at ends, check out unit test in cpp file).
    const UInt32& u = reinterpret_cast<const UInt32&>(inC0);
    const UInt32& v = reinterpret_cast<const UInt32&>(inC1);
    UInt32 result = (((u & 0x000000ff) * ((v & 0x000000ff) + 1)) >> 8) & 0x000000ff;
    result |= (((u & 0x0000ff00) >> 8) * (((v & 0x0000ff00) >> 8) + 1)) & 0x0000ff00;
    result |= (((u & 0x00ff0000) * (((v & 0x00ff0000) >> 16) + 1)) >> 8) & 0x00ff0000;
    result |= (((u & 0xff000000) >> 8) * (((v & 0xff000000) >> 24) + 1)) & 0xff000000;
    return ColorRGBA32(result);
#endif
}
/**
 * @brief Linear interpolation between c0 and c1 using t to weight between them.
 * 
 * @param c0 Input colorRGBA32 c0.
 * @param c1 Input colorRGBA32 c1.
 * @param scale Linear interpolation weight.
 * @return ColorRGBA32 Interpolation result.
 */
inline ColorRGBA32 Lerp(const ColorRGBA32& c0, const ColorRGBA32& c1, int scale)
{
    //AssertIf (scale < 0 || scale > 255);
    const UInt32& u0 = reinterpret_cast<const UInt32&>(c0);
    const UInt32& u1 = reinterpret_cast<const UInt32&>(c1);
    UInt32 vx = u0 & 0x00ff00ff;
    UInt32 rb = vx + ((((u1 & 0x00ff00ff) - vx) * scale) >> 8) & 0x00ff00ff;
    vx = u0 & 0xff00ff00;
    return ColorRGBA32(rb | (vx + ((((u1 >> 8) & 0x00ff00ff) - (vx >> 8)) * scale) & 0xff00ff00));
}
/**
 * @brief Convert RGB color to HSV.
 *
 * @param c Input RGB color.
 * @return Vector4f Result HSV color, h in x:[0, 360), s in y:[0, 1], v in z:[0, 1], a in w:[0, 1]
 */
inline Vector4f RGB2HSV(const ColorRGBA32& c)
{
    int r = c.r;
    int g = c.g;
    int b = c.b;
    int max = std::max(std::max(r, g), b);
    int min = std::min(std::min(r, g), b);

    float v = max / 255.0f;
    float s = max == 0 ? 0 : (max - min) / (float)max;

    float h = 0;
    if (max == min)
    {
        h = 0;
    }
    else if (max == r && g >= b)
    {
        h = (g - b) * 60.f / (max - min) + 0;
    }
    else if (max == r && g < b)
    {
        h = (g - b) * 60.f / (max - min) + 360;
    }
    else if (max == g)
    {
        h = (b - r) * 60.f / (max - min) + 120;
    }
    else if (max == b)
    {
        h = (r - g) * 60.f / (max - min) + 240;
    }

    return Vector4f(h, s, v, c.a / 255.0f);
}
/**
 * @brief Convert HSV color to RGB.
 *
 * @param c Input HSV color, h in x:[0, 360), s in y:[0, 1], v in z:[0, 1], a in w:[0, 1]
 * @return Vector4f Result RGB color.
 */
inline ColorRGBA32 HSV2RGB(const Vector4f& hsv)
{
    float h = hsv.x;
    float s = hsv.y;
    float v = hsv.z;
    float r = 0, g = 0, b = 0;
    int i = (int)fmod((h / 60.f), 6.f);
    float f = (h / 60) - i;
    float p = v * (1 - s);
    float q = v * (1 - f * s);
    float t = v * (1 - (1 - f) * s);
    switch (i)
    {
        case 0:
            r = v;
            g = t;
            b = p;
            break;
        case 1:
            r = q;
            g = v;
            b = p;
            break;
        case 2:
            r = p;
            g = v;
            b = t;
            break;
        case 3:
            r = p;
            g = q;
            b = v;
            break;
        case 4:
            r = t;
            g = p;
            b = v;
            break;
        case 5:
            r = v;
            g = p;
            b = q;
            break;
        default:
            break;
    }
    return ColorRGBA32(r * 255, g * 255, b * 255, hsv.w * 255);
}

NAMESPACE_AMAZING_ENGINE_END

#endif
