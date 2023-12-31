/**
 * @file AMGVector2.h
 * @author wangze.happy
 * @brief 二维浮点向量
 * @version 10.16.0
 * @date 2019-10-12
 * 
 * @copyright Copyright (c) 2019
 * 
 */
#ifndef VECTOR2_H
#define VECTOR2_H

#include <algorithm>
#include <cmath>
#include "Gaia/AMGPrerequisites.h"
#include "Gaia/Math/AMGFloatConversion.h"

NAMESPACE_AMAZING_ENGINE_BEGIN

/**
 * @brief 二维浮点向量类
 * 
 */
class GAIA_LIB_EXPORT Vector2f
{
public:
    /// x, y分量值
    float x = 0.f;
    float y = 0.f;

    /**
     * @brief 构造2维浮点向量
     * 
     */
    Vector2f()
        : x(0.f)
        , y(0.f)
    {
    }
    /**
     * @brief 构造2维浮点向量
     * 
     * @param inX x分量
     * @param inY y分量
     */
    constexpr Vector2f(float inX, float inY)
        : x(inX)
        , y(inY)
    {
    }
    /**
     * @brief 由一维浮点数组构造3维浮点向量
     * 
     * @param p 浮点数组指针, 所指向的一维级数至少需要包含2个元素
     */
    explicit Vector2f(const float* p)
    {
        x = p[0];
        y = p[1];
    }

    /**
     * @brief 设置向量各分量的值
     * 
     * @param inX x分量
     * @param inY y分量
     */
    void Set(float inX, float inY)
    {
        x = inX;
        y = inY;
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
    /// 数组下标运算符
    float& operator[](int i)
    {
        aeAssert(!(i < 0 || i > 1));
        return (&x)[i];
    }
    /// 数组下标运算符
    const float& operator[](int i) const
    {
        aeAssert(!(i < 0 || i > 1));
        return (&x)[i];
    }

    /// 算术运算符
    Vector2f& operator+=(const Vector2f& inV)
    {
        x += inV.x;
        y += inV.y;
        return *this;
    }
    /// 算术运算符
    Vector2f& operator-=(const Vector2f& inV)
    {
        x -= inV.x;
        y -= inV.y;
        return *this;
    }
    /// 算术运算符
    Vector2f& operator*=(const float s)
    {
        x *= s;
        y *= s;
        return *this;
    }
    /// 算术运算符
    Vector2f& operator*=(const Vector2f& inV)
    {
        x *= inV.x;
        y *= inV.y;
        return *this;
    }
    /// 算术运算符
    Vector2f& operator/=(const float s)
    {
        aeAssert(!(CompareApproximately(s, 0.0F)));
        x /= s;
        y /= s;
        return *this;
    }
    /// 关系运算符
    bool operator==(const Vector2f& v) const { return x == v.x && y == v.y; }
    /// 关系运算符
    bool operator!=(const Vector2f& v) const { return x != v.x || y != v.y; }

    /// 算术运算符
    Vector2f operator-() const { return Vector2f(-x, -y); }

    /**
     * @brief 逐分量乘
     * 
     * @param inV 输入向量
     * @return 返回结果向量
     */
    Vector2f& Scale(const Vector2f& inV)
    {
        x *= inV.x;
        y *= inV.y;
        return *this;
    }

    static const float epsilon;        ///< 容差量
    static const float infinity;       ///< 无穷大
    static const Vector2f infinityVec; ///< 各分量均为无穷大的向量
    static const Vector2f zero();      ///< 各分量均为0的向量
    static const Vector2f one();       ///< 各分量均为1的向量
    static const Vector2f xAxis;       ///< x方向单位向量
    static const Vector2f yAxis;       ///< y方向单位向量
};

/**
 * @brief 计算两个向量逐分量乘的向量
 * 
 * @param lhs 输入向量
 * @param rhs 输入向量
 * @return 返回逐分量乘的向量 
 */
inline Vector2f Scale(const Vector2f& lhs, const Vector2f& rhs)
{
    return Vector2f(lhs.x * rhs.x, lhs.y * rhs.y);
}

/// 算术运算符, 逐分量加法
inline Vector2f operator+(const Vector2f& lhs, const Vector2f& rhs)
{
    return Vector2f(lhs.x + rhs.x, lhs.y + rhs.y);
}
/// 算术运算符, 逐分量减法
inline Vector2f operator-(const Vector2f& lhs, const Vector2f& rhs)
{
    return Vector2f(lhs.x - rhs.x, lhs.y - rhs.y);
}
/// 算术运算符, 逐分量乘法
inline Vector2f operator*(const Vector2f& lhs, const Vector2f& rhs)
{
    return Vector2f(lhs.x * rhs.x, lhs.y * rhs.y);
}

/// 向量点乘
inline float Dot(const Vector2f& lhs, const Vector2f& rhs)
{
    return lhs.x * rhs.x + lhs.y * rhs.y;
}

/// 计算输入向量inV的模长的平方
inline float SqrMagnitude(const Vector2f& inV)
{
    return Dot(inV, inV);
}
/// 计算输入向量inV的模长
inline float Magnitude(const Vector2f& inV)
{
    return SqrtImpl(Dot(inV, inV));
}

/**
 * @brief 计算lhs与rhs的夹角
 * 
 * @return 返回夹角（弧度） 
 */
inline float Angle(const Vector2f& lhs, const Vector2f& rhs)
{
    return acos(std::min(1.0f, std::max(-1.0f, Dot(lhs, rhs) / (Magnitude(lhs) * Magnitude(rhs)))));
}

/// 算术运算符, 标量乘法
inline Vector2f operator*(const Vector2f& inV, float s)
{
    return Vector2f(inV.x * s, inV.y * s);
}
/// 算术运算符, 标量乘法
inline Vector2f operator*(const float s, const Vector2f& inV)
{
    return Vector2f(inV.x * s, inV.y * s);
}
/// 算术运算符, 标量除法
inline Vector2f operator/(const Vector2f& inV, float s)
{
    Vector2f temp(inV);
    temp /= s;
    return temp;
}
/**
 * @brief 逐分量求输入向量inVec的倒数向量
 * 
 * @param inVec 输入向量
 * @return 返回inVec的倒数向量
 */
inline Vector2f Inverse(const Vector2f& inVec)
{
    return Vector2f(1.0F / inVec.x, 1.0F / inVec.y);
}

/// 计算inV的归一化向量, 如果该向量无法被归一化, 则assert
inline Vector2f Normalize(const Vector2f& inV)
{
    return inV / Magnitude(inV);
}
/// Normalizes a vector, returns default vector if it can't be normalized
inline Vector2f NormalizeSafe(const Vector2f& inV, const Vector2f& defaultV = Vector2f::zero());

/// 计算线性插值
inline Vector2f Lerp(const Vector2f& from, const Vector2f& to, float t)
{
    return to * t + from * (1.0f - t);
}

/// Returns a vector with the smaller of every component from v0 and v1
inline Vector2f min(const Vector2f& lhs, const Vector2f& rhs)
{
    return Vector2f(std::min(lhs.x, rhs.x), std::min(lhs.y, rhs.y));
}
/// Returns a vector with the larger  of every component from v0 and v1
inline Vector2f max(const Vector2f& lhs, const Vector2f& rhs)
{
    return Vector2f(std::max(lhs.x, rhs.x), std::max(lhs.y, rhs.y));
}

/// 判断inV0与inV1是否近似相等
bool GAIA_LIB_EXPORT CompareApproximately(const Vector2f& inV0, const Vector2f& inV1, float inMaxDist = Vector2f::epsilon);

/// 判断inV0与inV1是否近似相等
inline bool CompareApproximately(const Vector2f& inV0, const Vector2f& inV1, float inMaxDist)
{
    return SqrMagnitude(inV1 - inV0) < inMaxDist * inMaxDist;
}

/**
 * @brief 判断vec是否是归一化向量
 * 
 * @param vec 待判断的向量
 * @param epsilon 容差
 * @return true vec是归一化向量
 * @return false vec不是归一化向量
 */
inline bool IsNormalized(const Vector2f& vec, float epsilon = Vector2f::epsilon)
{
    return CompareApproximately(SqrMagnitude(vec), 1.0F, epsilon);
}

/// Returns the abs of every component of the vector
inline Vector2f Abs(const Vector2f& v)
{
    return Vector2f(Abs(v.x), Abs(v.y));
}

/// 判断是否存在NaN 或者 +/- 无穷大分量
inline bool IsFinite(const Vector2f& f)
{
    return IsFinite(f.x) & IsFinite(f.y);
}

/// 快速归一化
inline Vector2f NormalizeFast(const Vector2f& inV)
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

/// Normalizes a vector, returns default vector if it can't be normalized
inline Vector2f NormalizeSafe(const Vector2f& inV, const Vector2f& defaultV)
{
    float mag = Magnitude(inV);
    if (mag > Vector2f::epsilon)
        return inV / Magnitude(inV);
    else
        return defaultV;
}

/// 计算p1与p2的距离
inline double Distance(const Vector2f& p1, const Vector2f& p2)
{
    Vector2f v = p1 - p2;

    return sqrt(v.x * v.x + v.y * v.y);
}

NAMESPACE_AMAZING_ENGINE_END

#endif
