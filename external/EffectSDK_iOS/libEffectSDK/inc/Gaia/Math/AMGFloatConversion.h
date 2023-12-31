/**
 * @file AMGColorSpaceConversion.h
 * @author fanjiaqi (fanjiaqi.837@bytedance.com)
 * @brief Float conversion functions.
 * @version 0.1
 * @date 2019-12-03
 * 
 * @copyright Copyright (c) 2019
 * 
 */

#ifndef FLOATCONVERSION_H
#define FLOATCONVERSION_H

#include <algorithm>
#include <cmath>
#include <limits>
#include <math.h>
#include "Gaia/AMGPrerequisites.h"

#if defined(__APPLE__)
#include <MacTypes.h>
#else
/**
 * @brief Alias of uint8_t
 * 
 */
typedef uint8_t UInt8;
/**
 * @brief Alias of uint16_t
 * 
 */
typedef uint16_t UInt16;
/**
 * @brief Alias of uint32_t
 * 
 */
typedef uint32_t UInt32;
/**
 * @brief Alias of uint64_t
 * 
 */
typedef uint64_t UInt64;
/**
 * @brief Alias of int8_t
 * 
 */
typedef int8_t Int8;
/**
 * @brief Alias of int16_t
 * 
 */
typedef int16_t SInt16;
/**
 * @brief Alias of int32_t
 * 
 */
typedef int32_t SInt32;
/**
 * @brief Alias of int64_t
 * 
 */
typedef int64_t SInt64;
#endif
/**
 * @brief Alias of float
 * 
 */
typedef float Real;

#ifndef kPI
#define kPI 3.14159265358979323846264338327950288419716939937510F
#endif

NAMESPACE_AMAZING_ENGINE_BEGIN
/**
 * @brief The biggest float of all that are smaller than 1.
 * 
 */
const float kBiggestFloatSmallerThanOne = 0.99999994f;
/**
 * @brief The biggest double of all that are smaller than 1.
 * 
 */
const double kBiggestDoubleSmallerThanOne = 0.99999999999999989;

/**
 * @brief Get the minimal value of two floats.
 * 
 * @param a Input float a.
 * @param b Input float b.
 * @return float The minimal value of two floats.
 */
inline float FloatMin(float a, float b)
{
    return std::min(a, b);
}

/**
 * @brief Get the maximal value of two floats.
 * 
 * @param a Input float a.
 * @param b Input float b.
 * @return float The maximal valur of two floats.
 */
inline float FloatMax(float a, float b)
{
    return std::max(a, b);
}

/**
 * @brief Get the absolute value of input float.
 * 
 * @param v Input float.
 * @return float The absolute value of input float.
 */
inline float Abs(float v)
{
    return v < 0.0F ? -v : v;
}

/**
 * @brief Get the absolute value of input double.
 * 
 * @param v Input double.
 * @return double The absolute value of input double.
 */
inline double Abs(double v)
{
    return v < 0.0 ? -v : v;
}

/**
 * @brief Get the absolute value of input int.
 * 
 * @param v Input int.
 * @return int The absolute value of input int.
 */
inline int Abs(int v)
{
    return v < 0 ? -v : v;
}

// Floor, ceil and round functions.
//
// When changing or implementing these functions, make sure the tests in MathTest.cpp
// still pass.
//
// Floor: rounds to the largest integer smaller than or equal to the input parameter.
// Ceil: rounds to the smallest integer larger than or equal to the input parameter.
// Round: rounds to the nearest integer. Ties (0.5) are rounded up to the smallest integer
// larger than or equal to the input parameter.
// Chop/truncate: use a normal integer cast.
//
// Windows:
// Casts are as fast as a straight fistp on an SSE equipped CPU. This is by far the most common
// scenario and will result in the best code for most users. fistp will use the rounding mode set
// in the control register (round to nearest by default), and needs fiddling to work properly.
// This actually makes code that attempt to use fistp slower than a cast.
// Unless we want round to nearest, in which case fistp should be the best choice, right? But
// it is not. The default rounding mode is round to nearest, but in case of a tie (0.5), round to
// nearest even is used. Thus 0.5 is rounded down to 0, 1.5 is rounded up to 2.
// Conclusion - fistp is useless without stupid fiddling around that actually makes is slower than
// an SSE cast.
//
// OS X Intel:
// Needs investigating
//
// iPhone:
// Needs investigating
//
// Android:
// Needs investigating

/**
 * @brief Rounds f downward, returning the largest integral value that is not greater than f.
 * 
 * @param f Value to round down.
 * @return int The value of x rounded downward.
 */
inline int FloorfToInt(float f)
{
    aeAssert(!(f < INT_MIN || f > INT_MAX));
    return f >= 0 ? (int)f : (int)(f - kBiggestFloatSmallerThanOne);
}

/**
 * @brief Rounds f downward, returning the largest integral value that is not greater than f.
 * 
 * @param f Value to round down which must be positive.
 * @return UInt32 The value of x rounded downward.
 */
inline UInt32 FloorfToIntPos(float f)
{
    aeAssert(!(f < 0 || f > UINT_MAX));
    return (UInt32)f;
}

/**
 * @brief Rounds f downward, returning the largest integral value that is not greater than f.
 * 
 * @param f Value to round down.
 * @return float The value of x rounded downward (as a floating-point value).
 */
inline float Floorf(float f)
{
    // Use std::floor().
    // We are interested in reliable functions that do not lose precision.
    // Casting to int and back to float would not be helpful.
    return floor(f);
}

/**
 * @brief Rounds f downward, returning the largest integral value that is not greater than f.
 * 
 * @param f Value to round down.
 * @return double The value of x rounded downward (as a double floating-point value).
 */
inline double Floord(double f)
{
    // Use std::floor().
    // We are interested in reliable functions that do not lose precision.
    // Casting to int and back to float would not be helpful.
    return floor(f);
}

/**
 * @brief Rounds f upward, returning the smallest integral value that is not less than f.
 * 
 * @param f Value to round up.
 * @return int The smallest integral value that is not less than f.
 */
inline int CeilfToInt(float f)
{
    aeAssert(!(f < INT_MIN || f > INT_MAX));
    return f >= 0 ? (int)(f + kBiggestFloatSmallerThanOne) : (int)(f);
}

/**
 * @brief Rounds f upward, returning the smallest integral value that is not less than f.
 * 
 * @param f Value to round up which must be positive.
 * @return UInt32 The smallest integral value that is not less than f.
 */
inline UInt32 CeilfToIntPos(float f)
{
    aeAssert(!(f < 0 || f > UINT_MAX));
    return (UInt32)(f + kBiggestFloatSmallerThanOne);
}

/**
 * @brief Rounds f upward, returning the smallest integral value that is not less than f.
 * 
 * @param f Value to round up.
 * @return int The smallest integral value that is not less than f (as a floating-point value)..
 */
inline float Ceilf(float f)
{
    // Use std::ceil().
    // We are interested in reliable functions that do not lose precision.
    // Casting to int and back to float would not be helpful.
    return ceil(f);
}

/**
 * @brief Rounds f upward, returning the smallest integral value that is not less than f.
 * 
 * @param f Value to round up.
 * @return int The smallest integral value that is not less than f (as a double floating-point value)..
 */
inline double Ceild(double f)
{
    // Use std::ceil().
    // We are interested in reliable functions that do not lose precision.
    // Casting to int and back to float would not be helpful.
    return ceil(f);
}

/**
 * @brief Returns the integral value that is nearest to f.
 * 
 * @param f Value to round.
 * @return int The value of f rounded to the nearest integral.
 */
inline int RoundfToInt(float f)
{
    return FloorfToInt(f + 0.5F);
}

/**
 * @brief Returns the integral value that is nearest to f.
 * 
 * @param f Value to round which must be positive.
 * @return int The value of f rounded to the nearest integral.
 */
inline UInt32 RoundfToIntPos(float f)
{
    return FloorfToIntPos(f + 0.5F);
}

/**
 * @brief Returns the integral value that is nearest to f.
 * 
 * @param f Value to round.
 * @return int The value of f rounded to the nearest integral (as a floating-point value).
 */
inline float Roundf(float f)
{
    return Floorf(f + 0.5F);
}

/**
 * @brief Returns the integral value that is nearest to f.
 * 
 * @param f Value to round.
 * @return double The value of f rounded to the nearest integral (as a double floating-point value).
 */
inline double Roundf(double f)
{
    return Floord(f + 0.5);
}

/**
 * @brief Fast conversion of float [0...1] to 0 ... 65535
 * 
 * @param f Value to converse.
 * @return int The conversion result of f.
 */
inline int NormalizedToWord(float f)
{
    f = FloatMax(f, 0.0F);
    f = FloatMin(f, 1.0F);
    return RoundfToIntPos(f * 65535.0f);
}

/**
 * @brief Fast conversion of float [0...1] to 0 ... 65535
 * 
 * @param p Value to converse.
 * @return int The conversion result of f.
 */
inline float WordToNormalized(int p)
{
    aeAssert(!(p < 0 || p > 65535));
    return (float)p / 65535.0F;
}

/**
 * @brief Fast conversion of float [0...1] to 0 ... 255
 * 
 * @param f Value to converse.
 * @return int The conversion result of f.
 */
inline int NormalizedToByte(float f)
{
    f = FloatMax(f, 0.0F);
    f = FloatMin(f, 1.0F);
    return RoundfToIntPos(f * 255.0f);
}

/**
 * @brief Fast conversion of float [0...1] to 0 ... 255
 * 
 * @param p Value to converse.
 * @return int The conversion result of f.
 */
inline float ByteToNormalized(int p)
{
    aeAssert(!(p < 0 || p > 255));
    return (float)p / 255.0F;
}

/**
 * @brief Returns float remainder for t / length.
 * 
 * @param t Value of dividend.
 * @param length Value of divisor.
 * @return float The float remainder of t /length.
 */
inline float Repeat(float t, float length)
{
    return t - Floorf(t / length) * length;
}

/**
 * @brief Returns double floating-pointer remainder for t / length.
 * 
 * @param t Value of dividend.
 * @param length Value of divisor.
 * @return double The double floating-pointer remainder of t /length.
 */
inline double RepeatD(double t, double length)
{
    return t - floor(t / length) * length;
}

/**
 * @brief Returns relative angle from current to target on the interval (-pi, pi].
 * 
 * @param current Current angle.
 * @param target Target angle.
 * @return float Relative angle on the interval (-pi, pi].
 */
inline float DeltaAngleRad(float current, float target)
{
    float delta = Repeat((target - current), 2 * kPI);
    if (delta > kPI)
        delta -= 2 * kPI;
    return delta;
}

/**
 * @brief Compare if the distance between f0 and f1 is smaller than epsilon.
 * 
 * @param f0 Input float1.
 * @param f1 Input float2.
 * @param epsilon Equation error.
 * @return true The distance between f0 and f1 is smaller than epsilon.
 * @return false The distance between f0 and f1 is not smaller than epsilon.
 */
inline bool CompareApproximately(float f0, float f1, float epsilon = 0.000001F)
{
    float dist = (f0 - f1);
    dist = Abs(dist);
    return dist < epsilon;
}

/**
 * @brief Returns x with its sign changed to y's.
 * 
 * @param x Input value.
 * @param y Input value to get sign.
 * @return float Value of x with its sign changed to y's.
 */
inline float CopySignf(float x, float y)
{
    union
    {
        float f;
        UInt32 i;
    } u, u0, u1;
    u0.f = x;
    u1.f = y;
    UInt32 a = u0.i;
    UInt32 b = u1.i;
    SInt32 mask = 1 << 31;
    UInt32 sign = b & mask;
    a &= ~mask;
    a |= sign;

    u.i = a;
    return u.f;
}

/**
 * @brief Get the sign of A.
 * 
 * @param A Input float to get sign.
 * @return int Return 0x80000000 if A is negative and else return 0.
 */
inline int CompareFloatRobustSignUtility(float A)
{
    // The sign bit of a number is the high bit.
    union
    {
        float f;
        int i;
    } u;
    u.f = A;
    return (u.i) & 0x80000000;
}

/**
 * @brief Compare two floats with bits.
 * 
 * @param f0 Input float1.
 * @param f1 Input float2.
 * @param maxUlps The max distance between two inputs which representate as int.
 * @return true The max distance between two inputs which representate as int is smaller than maxUlps.
 * @return false The max distance between two inputs which representate as int is not smaller than maxUlps
 */
inline bool CompareFloatRobust(float f0, float f1, int maxUlps = 10)
{
    if (CompareFloatRobustSignUtility(f0) != CompareFloatRobustSignUtility(f1))
        return f0 == f1;

    union
    {
        float f;
        int i;
    } u0, u1;
    u0.f = f0;
    u1.f = f1;
    int aInt = u0.i;
    // Make aInt lexicographically ordered as a twos-complement int
    if (aInt < 0)
        aInt = 0x80000000 - aInt;
    // Make bInt lexicographically ordered as a twos-complement int
    int bInt = u1.i;
    if (bInt < 0)
        bInt = 0x80000000 - bInt;

    // Now we can compare aInt and bInt to find out how far apart A and B
    // are.
    int intDiff = Abs(aInt - bInt);
    if (intDiff <= maxUlps)
        return true;
    return false;
}

/**
 * @brief Returns the t^2.
 * 
 * @tparam T The input type.
 * @param t Input value.
 * @return T Value of t^2.
 */
template <class T>
T Sqr(const T& t)
{
    return t * t;
}

#define kDeg2Rad (2.0F * kPI / 360.0F)
#define kRad2Deg (1.F / kDeg2Rad)

/**
 * @brief Transfer degree to radian.
 * 
 * @param deg Input degree.
 * @return float Radian corresponding to angle.
 */
inline float Deg2Rad(float deg)
{
    // TODO : should be deg * kDeg2Rad, but can't be changed,
    // because it changes the order of operations and that affects a replay in some RegressionTests
    return deg / 360.0F * 2.0F * kPI;
}

/**
 * @brief Transfer radian to degree.
 * 
 * @param rad Input radian.
 * @return float Degree corresponding to radian.
 */
inline float Rad2Deg(float rad)
{
    // TODO : should be rad * kRad2Deg, but can't be changed,
    // because it changes the order of operations and that affects a replay in some RegressionTests
    return rad / 2.0F / kPI * 360.0F;
}

/**
 * @brief Linear interpolation between from and to.
 * 
 * @param from Linear interpolation start point from.
 * @param to Linear interpolation end point to.
 * @param t Interpolation coefficient
 * @return float 
 */
inline float Lerp(float from, float to, float t)
{
    return to * t + from * (1.0F - t);
}

/**
 * @brief Returns whether x is a NaN (Not-A-Number) value. 
 * The NaN values are used to identify undefined or non-representable values for floating-point elements, such as the square root of negative numbers or the result of 0/0.
 * @param value A floating-point value.
 * @return true Value is a NaN.
 * @return false Value is not a NaN.
 */
inline bool IsNAN(float value)
{
#if defined __APPLE_CC__
    return value != value;
#elif _MSC_VER
    return _isnan(value) != 0;
#else
    return std::isnan(value);
#endif
}

/**
 * @brief Returns whether x is a NaN (Not-A-Number) value. 
 *  The NaN values are used to identify undefined or non-representable values for floating-point elements, such as the square root of negative numbers or the result of 0/0.
 * @param value A double floating-point value.
 * @return true Value is a NaN.
 * @return false Value is not a NaN.
 */
inline bool IsNAN(double value)
{
#if defined __APPLE_CC__
    return value != value;
#elif _MSC_VER
    return _isnan(value) != 0;
#else
    return std::isnan(value);
#endif
}

/**
 * @brief Judge if value equals to the positive infinity value of floating-point type.
 * 
 * @param value Input float.
 * @return true The input value equals to the positive infinity value of floating-point type.
 * @return false The input value does not equal to the positive infinity value of floating-point type.
 */
inline bool IsPlusInf(float value)
{
    return value == std::numeric_limits<float>::infinity();
}

/**
 * @brief Judge if value equals to the negative infinity value of floating-point type.
 * 
 * @param value Input float.
 * @return true The input value equals to the negative infinity value of floating-point type.
 * @return false he input value does not equal to the positive infinity value of floating-point type.
 */
inline bool IsMinusInf(float value)
{
    return value == -std::numeric_limits<float>::infinity();
}

/**
 * @brief Judge if value is finite.
 * 
 * @param value Input floating-point value.
 * @return true Value is not NaN and +/- infinity.
 * @return false Value is NaN or +/- infinity.
 */
inline bool IsFinite(const float& value)
{
    // Returns false if value is NaN or +/- infinity
    UInt32 intval = *reinterpret_cast<const UInt32*>(&value);
    return (intval & 0x7f800000) != 0x7f800000;
}

/**
 * @brief Judge value is finite.
 * 
 * @param value Input double floating-point value.
 * @return true Value is not NaN and +/- infinity.
 * @return false Value is NaN or +/- infinity. 
 */
inline bool IsFinite(const double& value)
{
    // Returns false if value is NaN or +/- infinity
    UInt64 intval = *reinterpret_cast<const UInt64*>(&value);
    return (intval & 0x7ff0000000000000LL) != 0x7ff0000000000000LL;
}

/**
 * @brief Returns the inverse square root of p.
 * 
 * @param p Value whose square root is computed. If the argument is negative, a domain error occurs.
 * @return float Inverse square root of p. If p is negative, a domain error occurs:
 */
inline float InvSqrt(float p)
{
    return 1.0F / sqrt(p);
}

/**
 * @brief Returns the square root of p.
 * 
 * @param p Value whose square root is computed. If the argument is negative, a domain error occurs.
 * @return float Square root of p. If p is negative, a domain error occurs.
 */
inline float Sqrt(float p)
{
    return sqrt(p);
}

/**
 * @brief Returns the square root of p.
 * 
 * @param value Value whose square root is computed. If the argument is negative, a domain error occurs.
 * @return float Square root of p. If x is negative, a domain error occurs.
 */
inline float FastSqrt(float value)
{
    return sqrtf(value);
}

/**
 * @brief Returns the inverse square root of p.
 * 
 * @param f Value whose square root is computed. If the argument is negative, a domain error occurs.
 * @return float Inverse square root of p. If p is negative, a domain error occurs:
 */
inline float FastInvSqrt(float f)
{
    // The Newton iteration trick used in FastestInvSqrt is a bit faster on
    // Pentium4 / Windows, but lower precision. Doing two iterations is precise enough,
    // but actually a bit slower.
    if (fabs(f) == 0.0F)
        return f;
    return 1.0F / sqrtf(f);
}

/**
 * @brief Returns the square root of p using the Newton iteration trick.
 * 
 * @param f Value whose square root is computed.
 * @return float Square root of p.
 */
inline float FastestInvSqrt(float f)
{
    union
    {
        float f;
        int i;
    } u;
    float fhalf = 0.5f * f;
    u.f = f;
    int i = u.i;
    i = 0x5f3759df - (i >> 1);
    u.i = i;
    f = u.f;
    f = f * (1.5f - fhalf * f * f);
    // f = f*(1.5f - fhalf*f*f); // uncommenting this would be two iterations
    return f;
}

/**
 * @brief Returns the square root of p.
 * 
 * @param f Value whose square root is computed.
 * @return float Square root of p. If x is negative, a domain error occurs.
 */
inline float SqrtImpl(float f)
{
    return sqrt(f);
}

/**
 * @brief Returns the sine of an angle of f radians.
 * 
 * @param f Value representing an angle expressed in radians.
 * @return float Sine of f radians.
 */
inline float Sin(float f)
{
    return sinf(f);
}

/**
 * @brief Returns f raised to the power exponent f2.
 * 
 * @param f Base value.
 * @param f2 Exponent value.
 * @return float The result of raising base to the power exponent f2.
 */
inline float Pow(float f, float f2)
{
    return powf(f, f2);
}

/**
 * @brief Returns the cosine of an angle of f radians.
 * 
 * @param f Value representing an angle expressed in radians.
 * @return float Cosine of x radians.
 */
inline float Cos(float f)
{
    return cosf(f);
}

/**
 * @brief Returns the sign of f.
 * 
 * @param f Input value to get sign.
 * @return float Return -1.0 if negative, 1.0 otherwise.
 */
inline float Sign(float f)
{
    if (f < 0.0F)
        return -1.0F;
    else
        return 1.0;
}

#if AMAZING_SUPPORTS_SSE
#include "Foundation/Math/Simd/SimdMath.h"

#define SSE_CONST4(name, val) static const ALIGN16 UInt32 name[4] = {(val), (val), (val), (val)}
#define CONST_M128I(name) *(const __m128i*)&name

/**
 * @brief Unit16 array defination for HalfToFloat.
 * 
 */
static ALIGN16 UInt16 source[] = {0, 0, 0, 0, 0, 0, 0, 0};
/**
 * @brief Float array defination for HalfToFloat.
 * 
 */
static ALIGN16 float destination[] = {0.0, 0.0, 0.0, 0.0};

/**
 * @brief Tranfer a uint16 to a float.
 * 
 * @param src Input uint16.
 * @param dest Ouput float.
 */
static void HalfToFloat(UInt16 src, float& dest)
{
    SSE_CONST4(mask_nosign, 0x7fff);
    SSE_CONST4(smallest_normal, 0x0400);
    SSE_CONST4(infinity, 0x7c00);
    SSE_CONST4(expadjust_normal, (127 - 15) << 23);
    SSE_CONST4(magic_denorm, 113 << 23);

    source[0] = src;
    __m128i in = _mm_loadu_si128(reinterpret_cast<const __m128i*>(source));
    __m128i mnosign = CONST_M128I(mask_nosign);
    __m128i eadjust = CONST_M128I(expadjust_normal);
    __m128i smallest = CONST_M128I(smallest_normal);
    __m128i infty = CONST_M128I(infinity);
    __m128i expmant = _mm_and_si128(mnosign, in);
    __m128i justsign = _mm_xor_si128(in, expmant);
    __m128i b_notinfnan = _mm_cmpgt_epi32(infty, expmant);
    __m128i b_isdenorm = _mm_cmpgt_epi32(smallest, expmant);
    __m128i shifted = _mm_slli_epi32(expmant, 13);
    __m128i adj_infnan = _mm_andnot_si128(b_notinfnan, eadjust);
    __m128i adjusted = _mm_add_epi32(eadjust, shifted);
    __m128i den1 = _mm_add_epi32(shifted, CONST_M128I(magic_denorm));
    __m128i adjusted2 = _mm_add_epi32(adjusted, adj_infnan);
    __m128 den2 = _mm_sub_ps(_mm_castsi128_ps(den1), *(const __m128*)&magic_denorm);
    __m128 adjusted3 = _mm_and_ps(den2, _mm_castsi128_ps(b_isdenorm));
    __m128 adjusted4 = _mm_andnot_ps(_mm_castsi128_ps(b_isdenorm), _mm_castsi128_ps(adjusted2));
    __m128 adjusted5 = _mm_or_ps(adjusted3, adjusted4);
    __m128i sign = _mm_slli_epi32(justsign, 16);
    __m128 out = _mm_or_ps(adjusted5, _mm_castsi128_ps(sign));
    _mm_storeu_ps(destination, out);
    dest = destination[0];
#undef SSE_CONST4
#undef CONST_M128I
}

#else

#if 0
/**
 * @brief Tranfer a uint16 to a float.
 * 
 * @param src Input uint16.
 * @param dest Ouput float.
 */
static void HalfToFloat(UInt16 src, float& dest)
{
    // Integer alias
    UInt32& bits = *reinterpret_cast<UInt32*>(&dest);

    // Based on Fabian Giesen's public domain half_to_float_fast3
    static const UInt32 magic      = {113 << 23};
    const float& magicFloat        = *reinterpret_cast<const float*>(&magic);
    static const UInt32 shiftedExp = 0x7c00 << 13; // exponent mask after shift

    // Mask out sign bit
    bits = src & 0x7fff;
    if (bits)
    {
        // Move exponent + mantissa to correct bits
        bits <<= 13;
        UInt32 exponent = bits & shiftedExp;
        if (exponent == 0)
        {
            // Handle denormal
            bits += magic;
            dest -= magicFloat;
        }
        else if (exponent == shiftedExp) // Inf/NaN
            bits += (255 - 31) << 23;
        else
            bits += (127 - 15) << 23;
    }

    // Copy sign bit
    bits |= (src & 0x8000) << 16;
}
#endif

#endif

/**
 * @brief using std acos
 * 
 */
using std::acos;

/**
 * @brief using std atan2
 * 
 */
using std::atan2;

/**
 * @brief using std cos
 * 
 */
using std::cos;

/**
 * @brief using std exp
 * 
 */
using std::exp;

/**
 * @brief using std log
 * 
 */
using std::log;

/**
 * @brief using std pow
 * 
 */
using std::pow;

/**
 * @brief using std sin
 * 
 */
using std::sin;

/**
 * @brief using std sqrt
 * 
 */
using std::sqrt;

// On non-C99 platforms log2 is not available, so approximate it.
#if AMAZING_WINDOWS || AMAZING_ANDROID
#define kNaturalLogarithm2 0.693147180559945309417
#define Log2(x) (logf(x) / kNaturalLogarithm2)
#else
#define Log2(x) log2f(x)
#endif

NAMESPACE_AMAZING_ENGINE_END

#endif
