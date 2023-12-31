/**
 * @file AMGInclude.h
 * @author fanjiaqi (fanjiaqi.837@bytedance.com)
 * @brief Header file for base module
 * @version 0.1
 * @date 2019-11-25
 * 
 * @copyright Copyright (c) 2019
 * 
 */
#pragma once

#include "Gaia/AMGPrerequisites.h"
#include "Gaia/Platform/AMGPlatformDef.h"
#include "Gaia/Math/AMGFloatConversion.h"
#include "Gaia/Math/AMGVector2.h"
#include "Gaia/Math/AMGVector3.h"
#include "Gaia/Math/AMGVector4.h"
#include "Gaia/Math/AMGQuaternion.h"
#include "Gaia/Math/AMGMatrix3x3.h"
#include "Gaia/Math/AMGMatrix4x4.h"
#include "Gaia/Math/AMGRect.h"
#include "Gaia/Math/AMGColor.h"
#include "Gaia/Math/AMGColorSpaceConversion.h"
#include "Gaia/Math/AMGPolynomials.h"
#include "Gaia/Math/AMGSphericalHarmonics.h"
#include "Gaia/Math/Random/AMGRandom.h"
#include "Gaia/Math/AMGDynamicBitset.h"

const Real AMAZING_HALF_PI = 1.5707963267948966192313216916398f;
const Real AMAZING_PI = 3.1415926535897932384626433832795f;
const Real AMAZING_INV_PI = 0.31830988618379067153776752674503f;
const Real AMAZING_2PI = 6.283185307179586476925286766559f;
const Real AMAZING_INV_2PI = 0.15915494309189533576888376337251f;
const Real AMAZING_4PI = 12.566370614359172953850573533118f;
const Real AMAZING_INV_4PI = 0.07957747154594766788444188168626f;
const Real AMAZING_EPSILON = 1e-6f;
const Real AMAZING_MINEPSILON = 1e-04f;
const Real AMAZING_SinC2 = -0.16666667163372039794921875f;
const Real AMAZING_SinC4 = 8.333347737789154052734375e-3f;
const Real AMAZING_SinC6 = -1.9842604524455964565277099609375e-4f;
const Real AMAZING_SinC8 = 2.760012648650445044040679931640625e-6f;
const Real AMAZING_SinC10 = -2.50293279435709337121807038784027099609375e-8f;
const Real AMAZING_CosC2 = -0.5f;
const Real AMAZING_CosC4 = 4.166664183139801025390625e-2f;
const Real AMAZING_CosC6 = -1.388833043165504932403564453125e-3f;
const Real AMAZING_CosC8 = 2.47562347794882953166961669921875e-5f;
const Real AMAZING_CosC10 = -2.59630184018533327616751194000244140625e-7f;
const Real AMAZING_ACosC0 = 1.5707288f;
const Real AMAZING_ACosC1 = -0.2121144f;
const Real AMAZING_ACosC2 = 0.0742610f;
const Real AMAZING_ACosC3 = -0.0187293f;
const Real AMAZING_ATan2C0 = -0.013480470f;
const Real AMAZING_ATan2C1 = 0.057477314f;
const Real AMAZING_ATan2C2 = -0.121239071f;
const Real AMAZING_ATan2C3 = 0.195635925f;
const Real AMAZING_ATan2C4 = -0.332994597f;
const Real AMAZING_ATan2C5 = 0.999995630f;
const Real AMAZING_NearZero = 1.0f / Real(1 << 28);
const Real AMAZING_ExpC0 = 1.66666666666666019037e-01f;
const Real AMAZING_ExpC1 = -2.77777777770155933842e-03f;
const Real AMAZING_ExpC2 = 6.61375632143793436117e-05f;
const Real AMAZING_ExpC3 = -1.65339022054652515390e-06f;
const Real AMAZING_ExpC4 = 4.13813679705723846039e-08f;
const Real AMAZING_Sqrt2 = 1.4142135623730950488016887242097f;
const Real AMAZING_Log10 = 2.3025850929940456840179914546844f;
const Real AMAZING_Log2 = 0.6931471805599453094172321214582f;
const Real AMAZING_InvLog2 = 1.4426950408889634073599246810019f;
const Real AMAZING_E = 2.7182818284590452353602874713527f;

#define AMAZING_MAX_FLT 3.402823466e+38F
#define AMAZING_MIN_FLT 1.175494351e-38F

#define VEC2_INVALID Vector2f(AMAZING_MAX_FLT, AMAZING_MAX_FLT)
#define VEC2_ZERO Vector2f(0.0f, 0.0f)
#define VEC2_ONE Vector2f(1.0f, 1.0f)

#define VEC3_INVALID Vector3f(AMAZING_MAX_FLT, AMAZING_MAX_FLT, AMAZING_MAX_FLT)
#define VEC3_ZERO Vector3f(0.0f, 0.0f, 0.0f)
#define VEC3_ONE Vector3f(1.0f, 1.0f, 1.0f)
#define VEC3_UNIT_X Vector3f(1.0f, 0.0f, 0.0f)
#define VEC3_UNIT_Y Vector3f(0.0f, 1.0f, 0.0f)
#define VEC3_UNIT_Z Vector3f(0.0f, 0.0f, 1.0f)
#define VEC3_NEGATIVE_UNIT_X Vector3f(-1.0f, 0.0f, 0.0f)
#define VEC3_NEGATIVE_UNIT_Y Vector3f(0.0f, -1.0f, 0.0f)
#define VEC3_NEGATIVE_UNIT_Z Vector3f(0.0f, 0.0f, -1.0f)
#define VEC3_UNIT_SCALE Vector3f(1.0f, 1.0f, 1.0f)

#define VEC4_INVALID Vector4f(AMAZING_MAX_FLT, AMAZING_MAX_FLT, AMAZING_MAX_FLT, AMAZING_MAX_FLT)
#define VEC4_ZERO Vector4f(0.0f, 0.0f, 0.0f, 0.0f)
#define VEC4_ONE Vector4f(1.0f, 1.0f, 1.0f, 1.0f)

#define QUAT_INVALID Quaternionf(AMAZING_MAX_FLT, AMAZING_MAX_FLT, AMAZING_MAX_FLT, AMAZING_MAX_FLT)
#define QUAT_ZERO Quaternionf(0.0f, 0.0f, 0.0f, 0.0f)
#define QUAT_IDENTITY Quaternionf(0.0f, 0.0f, 0.0f, 1.0f)

#define MAT3_INVALID Matrix3x3f(AMAZING_MAX_FLT, AMAZING_MAX_FLT, AMAZING_MAX_FLT, AMAZING_MAX_FLT, AMAZING_MAX_FLT, AMAZING_MAX_FLT, AMAZING_MAX_FLT, AMAZING_MAX_FLT, AMAZING_MAX_FLT)
#define MAT3_IDENTITY Matrix3x3f::identity()

#define MAT4_INVALID Matrix4x4f(AMAZING_MAX_FLT, AMAZING_MAX_FLT, AMAZING_MAX_FLT, AMAZING_MAX_FLT, AMAZING_MAX_FLT, AMAZING_MAX_FLT, AMAZING_MAX_FLT, AMAZING_MAX_FLT, AMAZING_MAX_FLT, AMAZING_MAX_FLT, AMAZING_MAX_FLT, AMAZING_MAX_FLT, AMAZING_MAX_FLT, AMAZING_MAX_FLT, AMAZING_MAX_FLT, AMAZING_MAX_FLT)
#define MAT4_IDENTITY Matrix4x4f::identity()

NAMESPACE_AMAZING_ENGINE_BEGIN
/**
 * @brief Overload operator*, calculate result of multiplication of a matrix and a vector.
 * 
 * @param m Input matrix.
 * @param v Input vector.
 * @return Vector3f Result vector.
 */
inline Vector3f operator*(const Matrix4x4f& m, const Vector3f& v)
{
    return m.MultiplyVector3(v);
}

/**
 * @brief Overload operator*, calculate result of multiplication of two matrix.
 * 
 * @param a Input left matrix. 
 * @param b Input right matrix.
 * @return Matrix4x4f Result matrix.
 */
inline Matrix4x4f operator*(const Matrix4x4f& a, const Matrix4x4f& b)
{
    Matrix4x4f r;
    MultiplyMatrices4x4(&a, &b, &r);
    return r;
}

/**
 * @brief Overload operator/, calculate result of division of two vectors.
 * 
 * @param a Input left vector.
 * @param b Input right vector.
 * @return Vector3f 
 */
inline Vector3f operator/(const Vector3f& a, const Vector3f& b)
{
    return Vector3f(a.x / b.x, a.y / b.y, a.z / b.z);
}

NAMESPACE_AMAZING_ENGINE_END
