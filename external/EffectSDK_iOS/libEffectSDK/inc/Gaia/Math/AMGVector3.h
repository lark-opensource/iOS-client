/**
 * @file AMGVector3.h
 * @author wangze.happy
 * @brief 三维浮点向量
 * @version 10.16.0
 * @date 2019-10-12
 * 
 * @copyright Copyright (c) 2019
 * 
 */
#ifndef VECTOR3_H
#define VECTOR3_H

#include <algorithm>
#include "Gaia/AMGPrerequisites.h"
#include "Gaia/Math/AMGFloatConversion.h"

NAMESPACE_AMAZING_ENGINE_BEGIN

class GAIA_LIB_EXPORT Vector3f
{
public:
    /// x, y, z分量值
    float x = 0.f;
    float y = 0.f;
    float z = 0.f;

    /**
     * @brief 构造3维浮点向量
     * 
     */
    Vector3f()
        : x(0.f)
        , y(0.f)
        , z(0.f)
    {
    }
    /**
     * @brief 构造3维浮点向量
     * 
     * @param inX x分量
     * @param inY y分量
     * @param inZ z分量
     */
    constexpr Vector3f(float inX, float inY, float inZ)
        : x(inX)
        , y(inY)
        , z(inZ)
    {
    }
    /**
     * @brief 由一维浮点数组构造3维浮点向量
     * 
     * @param array 浮点数组指针, 所指向的一维级数至少需要包含3个元素
     */
    explicit Vector3f(const float* array)
    {
        x = array[0];
        y = array[1];
        z = array[2];
    }
    /**
     * @brief 设置向量各分量的值
     * 
     * @param inX x分量
     * @param inY y分量
     * @param inZ z分量
     */
    void Set(float inX, float inY, float inZ)
    {
        x = inX;
        y = inY;
        z = inZ;
    }
    /**
     * @brief 由一维浮点数组设置向量
     * 
     * @param array 浮点数组指针, 所指向的一维数组至少需要包含3个元素
     */
    void Set(const float* array)
    {
        x = array[0];
        y = array[1];
        z = array[2];
    }

    /**
     * @brief 获取成员变量首地址指针
     * 
     * @return 返回成员变量首地址指针
     */
    float* GetPtr() { return &x; }
    /**
     * @brief 获取成员变量首地址指针
     * 
     * @return 返回成员变量首地址指针
     */
    const float* GetPtr() const { return &x; }
    /**
     * @brief 获取向量分量的值
     * 
     * @param i 分量索引
     * @return 分量的值 
     */
    float get(int i)
    {
        if (i == 0)
            return x;
        if (i == 1)
            return y;
        if (i == 2)
            return z;
        return 0;
    }
    /// 数组下标运算符
    float& operator[](int i)
    {
        aeAssert(!(i < 0 || i > 2));
        return (&x)[i];
    }
    /// 数组下标运算符
    const float& operator[](int i) const
    {
        aeAssert(!(i < 0 || i > 2));
        return (&x)[i];
    }

    /// 关系运算符
    bool operator==(const Vector3f& v) const { return x == v.x && y == v.y && z == v.z; }
    /// 关系运算符
    bool operator!=(const Vector3f& v) const { return x != v.x || y != v.y || z != v.z; }

    /// 算术运算符
    Vector3f& operator+=(const Vector3f& inV)
    {
        x += inV.x;
        y += inV.y;
        z += inV.z;
        return *this;
    }
    /// 算术运算符
    Vector3f& operator-=(const Vector3f& inV)
    {
        x -= inV.x;
        y -= inV.y;
        z -= inV.z;
        return *this;
    }
    /// 算术运算符, 标量乘
    Vector3f& operator*=(float s)
    {
        x *= s;
        y *= s;
        z *= s;
        return *this;
    }
    /// 算术运算符, 标量除
    Vector3f& operator/=(float s);

    /// 算术运算符
    Vector3f operator-() const { return Vector3f(-x, -y, -z); }

    /**
     * @brief 逐分量乘
     * 
     * @param inV 输入向量
     * @return 返回结果向量
     */
    Vector3f& Scale(const Vector3f& inV)
    {
        x *= inV.x;
        y *= inV.y;
        z *= inV.z;
        return *this;
    }

    static float epsilon();
    static float infinity();
    static Vector3f infinityVec();
    static Vector3f zero();
    static Vector3f one();
    static Vector3f xAxis();
    static Vector3f yAxis();
    static Vector3f zAxis();
};

/**
 * @brief 计算两个向量逐分量乘的向量
 * 
 * @param lhs 输入向量
 * @param rhs 输入向量
 * @return 返回逐分量乘的向量 
 */
inline Vector3f Scale(const Vector3f& lhs, const Vector3f& rhs)
{
    return Vector3f(lhs.x * rhs.x, lhs.y * rhs.y, lhs.z * rhs.z);
}

/// 算术运算符, 逐分量加法
inline Vector3f operator+(const Vector3f& lhs, const Vector3f& rhs)
{
    return Vector3f(lhs.x + rhs.x, lhs.y + rhs.y, lhs.z + rhs.z);
}
/// 算术运算符, 逐分量减法
inline Vector3f operator-(const Vector3f& lhs, const Vector3f& rhs)
{
    return Vector3f(lhs.x - rhs.x, lhs.y - rhs.y, lhs.z - rhs.z);
}
/// 向量叉乘
inline Vector3f Cross(const Vector3f& lhs, const Vector3f& rhs);
/// 向量点乘
inline float Dot(const Vector3f& lhs, const Vector3f& rhs)
{
    return lhs.x * rhs.x + lhs.y * rhs.y + lhs.z * rhs.z;
}

/// 算术运算符, 逐分量乘法
inline Vector3f operator*(const Vector3f& lhs, const Vector3f& rhs)
{
    return Vector3f(lhs.x * rhs.x, lhs.y * rhs.y, lhs.z * rhs.z);
}
/// 算术运算符, 标量乘法
inline Vector3f operator*(const Vector3f& inV, const float s)
{
    return Vector3f(inV.x * s, inV.y * s, inV.z * s);
}
/// 算术运算符, 标量乘法
inline Vector3f operator*(const float s, const Vector3f& inV)
{
    return Vector3f(inV.x * s, inV.y * s, inV.z * s);
}
/// 算术运算符, 标量除法
inline Vector3f operator/(const Vector3f& inV, const float s)
{
    Vector3f temp(inV);
    temp /= s;
    return temp;
}

/**
 * @brief 逐分量求输入向量inVec的倒数向量
 * 
 * @param inVec 输入向量
 * @return 返回inVec的倒数向量
 */
inline Vector3f Inverse(const Vector3f& inVec)
{
    return Vector3f(1.0F / inVec.x, 1.0F / inVec.y, 1.0F / inVec.z);
}

/// 计算输入向量inV的模长的平方
inline float SqrMagnitude(const Vector3f& inV)
{
    return Dot(inV, inV);
}
/// 计算输入向量inV的模长
inline float Magnitude(const Vector3f& inV)
{
    return SqrtImpl(Dot(inV, inV));
}

/// 计算inV的归一化向量, 如果该向量无法被归一化, 则assert
inline Vector3f Normalize(const Vector3f& inV)
{
    return inV / Magnitude(inV);
}
/// Normalizes a vector, returns default vector if it can't be normalized
inline Vector3f NormalizeSafe(const Vector3f& inV, const Vector3f& defaultV = Vector3f::zero());

/**
 * @brief 计算反射方向向量
 * 
 * @param inDirection 输入方向向量
 * @param inNormal 法向量
 * @return 返回反向方向向量
 */
inline Vector3f ReflectVector(const Vector3f& inDirection, const Vector3f& inNormal)
{
    return -2.0F * Dot(inNormal, inDirection) * inNormal + inDirection;
}

/// 计算线性插值
inline Vector3f Lerp(const Vector3f& from, const Vector3f& to, float t)
{
    return to * t + from * (1.0F - t);
}

/// Returns a vector with the smaller of every component from v0 and v1
inline Vector3f min(const Vector3f& lhs, const Vector3f& rhs)
{
    return Vector3f(FloatMin(lhs.x, rhs.x), FloatMin(lhs.y, rhs.y), FloatMin(lhs.z, rhs.z));
}
/// Returns a vector with the larger  of every component from v0 and v1
inline Vector3f max(const Vector3f& lhs, const Vector3f& rhs)
{
    return Vector3f(FloatMax(lhs.x, rhs.x), FloatMax(lhs.y, rhs.y), FloatMax(lhs.z, rhs.z));
}

/// Project one vector onto another.
inline Vector3f Project(const Vector3f& v1, const Vector3f& v2)
{
    return v2 * Dot(v1, v2) / Dot(v2, v2);
}

/// Returns the abs of every component of the vector
inline Vector3f Abs(const Vector3f& v)
{
    return Vector3f(Abs(v.x), Abs(v.y), Abs(v.z));
}

/// 判断inV0与inV1是否近似相等
bool GAIA_LIB_EXPORT CompareApproximately(const Vector3f& inV0, const Vector3f& inV1, float inMaxDist = Vector3f::epsilon());
/// Orthonormalizes the three vectors, assuming that a orthonormal basis can be formed
void GAIA_LIB_EXPORT OrthoNormalizeFast(Vector3f* inU, Vector3f* inV, Vector3f* inW);
/// Orthonormalizes the three vectors, returns false if no orthonormal basis could be formed.
void GAIA_LIB_EXPORT OrthoNormalize(Vector3f* inU, Vector3f* inV, Vector3f* inW);
/// Orthonormalizes the two vectors. inV is taken as a hint and will try to be as close as possible to inV.
void GAIA_LIB_EXPORT OrthoNormalize(Vector3f* inU, Vector3f* inV);

/// Calculates a vector that is orthonormal to n. Assumes that n is normalized
Vector3f GAIA_LIB_EXPORT OrthoNormalVectorFast(const Vector3f& n);

/**
 * @brief Rotates lhs towards rhs by no more than max Angle
 * Moves the magnitude of lhs towards rhs by no more than maxMagnitude
 */
Vector3f GAIA_LIB_EXPORT RotateTowards(const Vector3f& lhs, const Vector3f& rhs, float maxAngle, float maxMagnitude);

// Spherically interpolates the direction of two vectors
// and interpolates the magnitude of the two vectors
Vector3f GAIA_LIB_EXPORT Slerp(const Vector3f& lhs, const Vector3f& rhs, float t);

/// Returns a Vector3 that moves lhs towards rhs by a maximum of clampedDistance
Vector3f GAIA_LIB_EXPORT MoveTowards(const Vector3f& lhs, const Vector3f& rhs, float clampedDistance);

/**
 * @brief 判断vec是否是归一化向量
 * 
 * @param vec 待判断的向量
 * @param epsilon 容差
 * @return true vec是归一化向量
 * @return false vec不是归一化向量
 */
inline bool IsNormalized(const Vector3f& vec, float epsilon = Vector3f::epsilon())
{
    return CompareApproximately(SqrMagnitude(vec), 1.0F, epsilon);
}

/// 计算lhs与rhs的叉乘向量
inline Vector3f Cross(const Vector3f& lhs, const Vector3f& rhs)
{
    return Vector3f(
        lhs.y * rhs.z - lhs.z * rhs.y,
        lhs.z * rhs.x - lhs.x * rhs.z,
        lhs.x * rhs.y - lhs.y * rhs.x);
}

/// Normalizes a vector, returns default vector if it can't be normalized
inline Vector3f NormalizeSafe(const Vector3f& inV, const Vector3f& defaultV)
{
    float mag = Magnitude(inV);
    if (mag > Vector3f::epsilon())
        return inV / Magnitude(inV);
    else
        return defaultV;
}

/// - Handles zero vector correclty
inline Vector3f NormalizeFast(const Vector3f& inV)
{
    float m = SqrMagnitude(inV);
    // GCC version of __frsqrte:
    //	static inline double __frsqrte (double x) {
    //		double y;
    //		asm ( "frsqrte %0, %1" : /*OUT*/ "=f" (y) : /*IN*/ "f" (x) );
    //		return y;
    //	}
    return inV * FastInvSqrt(m);
}

/// - low precision normalize
/// - nan for zero vector
inline Vector3f NormalizeFastest(const Vector3f& inV)
{
    float m = SqrMagnitude(inV);
    // GCC version of __frsqrte:
    //	static inline double __frsqrte (double x) {
    //		double y;
    //		asm ( "frsqrte %0, %1" : /*OUT*/ "=f" (y) : /*IN*/ "f" (x) );
    //		return y;
    //	}
    return inV * FastestInvSqrt(m);
}

/// 判断是否存在NaN 或者 +/- 无穷大分量
inline bool IsFinite(const Vector3f& f)
{
    return IsFinite(f.x) & IsFinite(f.y) & IsFinite(f.z);
}

/// 判断inV0与inV1是否近似相等
inline bool CompareApproximately(const Vector3f& inV0, const Vector3f& inV1, float inMaxDist)
{
    return SqrMagnitude(inV1 - inV0) < inMaxDist * inMaxDist;
}

/// 算术运算符
inline Vector3f& Vector3f::operator/=(float s)
{
    aeAssert(!(CompareApproximately(s, 0.0F)));
    x /= s;
    y /= s;
    z /= s;
    return *this;
}

/**
 * @brief 鲁棒性计算归一化向量
 * 
 * this may be called for vectors `a' with extremely small magnitude, for
 * example the result of a cross product on two nearly perpendicular vectors.
 * we must be robust to these small vectors. to prevent numerical error,
 * first find the component a[i] with the largest magnitude and then scale
 * all the components by 1/a[i]. then we can compute the length of `a' and
 * scale the components by 1/l. this has been verified to work with vectors
 * containing the smallest representable numbers.
 */
Vector3f GAIA_LIB_EXPORT NormalizeRobust(const Vector3f& a);
/**
 * @brief 鲁棒性计算归一化向量
 * 
 * This also returns vector's inverse original length, to avoid duplicate
 * invSqrt calculations when needed. If a is a zero vector, invOriginalLength will be 0.
 * 
 * @param a 待归一化的向量
 * @param invOriginalLength 返回原始长度的倒数
 * @return 返回归一化后的向量 
 */
Vector3f GAIA_LIB_EXPORT NormalizeRobust(const Vector3f& a, float& invOriginalLength);

/// 计算p1与p2的距离
inline double Distance(const Vector3f& p1, const Vector3f& p2)
{
    Vector3f v = p1 - p2;

    return sqrt(v.x * v.x + v.y * v.y + v.z * v.z);
}

/// 计算v的正交向量
inline Vector3f Perpendicular(const Vector3f& v)
{
    static const float fSquareZero = float(1e-06 * 1e-06);
    Vector3f perp = Cross(v, Vector3f::xAxis());
    if (SqrMagnitude(perp) < fSquareZero)
    {
        perp = Cross(perp, Vector3f::yAxis());
    }
    return Normalize(perp);
}

NAMESPACE_AMAZING_ENGINE_END

#endif
