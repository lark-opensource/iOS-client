/**
 * @file AMGVector4.h
 * @author wangze.happy
 * @brief 四维浮点向量
 * @version 10.16.0
 * @date 2019-10-11
 * 
 * @copyright Copyright (c) 2019
 * 
 */
#pragma once

#include "Gaia/Math/AMGVector3.h"

NAMESPACE_AMAZING_ENGINE_BEGIN

/**
 * @brief 四维浮点向量类
 * 
 */
class GAIA_LIB_EXPORT Vector4f
{
public:
    /**
     * @brief 构造4维浮点向量
     * 
     */
    Vector4f()
        : x(0.f)
        , y(0.f)
        , z(0.f)
        , w(0.f)
    {
    }
    /**
     * @brief 构造4维浮点向量
     * 
     * @param inX x分量
     * @param inY y分量
     * @param inZ z分量
     * @param inW w分量
     */
    constexpr Vector4f(float inX, float inY, float inZ, float inW)
        : x(inX)
        , y(inY)
        , z(inZ)
        , w(inW)
    {
    }
    /**
     * @brief 由3维浮点向量及w分量构造4维浮点向量
     * 
     * @param v 3维浮点向量
     * @param inW w分量
     */
    explicit Vector4f(const Vector3f& v, float inW = 0.0)
        : x(v.x)
        , y(v.y)
        , z(v.z)
        , w(inW)
    {
    }
    /**
     * @brief 由一维浮点数组构造4维浮点向量
     * 
     * @param v 浮点数组指针, 所指向的一维级数至少需要包含4个元素
     */
    explicit Vector4f(const float* v)
        : x(v[0])
        , y(v[1])
        , z(v[2])
        , w(v[3])
    {
    }

    /**
     * @brief 设置向量各分量的值
     * 
     * @param inX x分量
     * @param inY y分量
     * @param inZ z分量
     * @param inW w分量
     */
    void Set(float inX, float inY, float inZ, float inW)
    {
        x = inX;
        y = inY;
        z = inZ;
        w = inW;
    }
    /**
     * @brief 由一维浮点数组设置向量
     * 
     * @param array 浮点数组指针, 所指向的一维数组至少需要包含4个元素
     */
    void Set(const float* array)
    {
        x = array[0];
        y = array[1];
        z = array[2];
        w = array[3];
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
        aeAssert(!(i < 0 || i > 3));
        return (&x)[i];
    }
    /// 数组下标运算符
    const float& operator[](int i) const
    {
        aeAssert(!(i < 0 || i > 3));
        return (&x)[i];
    }

    /// 关系运算符
    bool operator==(const Vector4f& v) const { return x == v.x && y == v.y && z == v.z && w == v.w; }
    /// 关系运算符
    bool operator!=(const Vector4f& v) const { return x != v.x || y != v.y || z != v.z || w != v.w; }
    /// 关系运算符
    bool operator==(const float v[4]) const { return x == v[0] && y == v[1] && z == v[2] && w == v[3]; }
    /// 关系运算符
    bool operator!=(const float v[4]) const { return x != v[0] || y != v[1] || z != v[2] || w != v[3]; }

    /// 算术运算符
    Vector4f operator-() const { return Vector4f(-x, -y, -z, -w); }
    /// 算术运算符
    Vector4f& operator/=(float s);

    /// N/A
    template <class TransferFunction>
    void Transfer(TransferFunction& transfer);

    float x = 0.f; ///< x分量值
    float y = 0.f; ///< y分量值
    float z = 0.f; ///< z分量值
    float w = 0.f; ///< w分量值
};

/// 算术运算符
inline Vector4f operator*(const Vector4f& lhs, const Vector4f& rhs)
{
    return Vector4f(lhs.x * rhs.x, lhs.y * rhs.y, lhs.z * rhs.z, lhs.w * rhs.w);
}
/// 算术运算符
inline Vector4f operator*(const Vector4f& inV, const float s)
{
    return Vector4f(inV.x * s, inV.y * s, inV.z * s, inV.w * s);
}
/// 算术运算符
inline Vector4f operator+(const Vector4f& lhs, const Vector4f& rhs)
{
    return Vector4f(lhs.x + rhs.x, lhs.y + rhs.y, lhs.z + rhs.z, lhs.w + rhs.w);
}
/// 算术运算符
inline Vector4f operator-(const Vector4f& lhs, const Vector4f& rhs)
{
    return Vector4f(lhs.x - rhs.x, lhs.y - rhs.y, lhs.z - rhs.z, lhs.w - rhs.w);
}
/// 点乘
inline float Dot(const Vector4f& lhs, const Vector4f& rhs)
{
    return lhs.x * rhs.x + lhs.y * rhs.y + lhs.z * rhs.z + lhs.w * rhs.w;
}
/// 线性插值
inline Vector4f Lerp(const Vector4f& from, const Vector4f& to, float t)
{
    return to * t + from * (1.0F - t);
}

/// 算术运算符
inline Vector4f operator/(const Vector4f& inV, const float s)
{
    Vector4f temp(inV);
    temp /= s;
    return temp;
}

/// 算术运算符
inline Vector4f& Vector4f::operator/=(float s)
{
    aeAssert(!(CompareApproximately(s, 0.0F)));
    x /= s;
    y /= s;
    z /= s;
    w /= s;
    return *this;
}

/// 计算输入向量inV的模长的平方
inline float SqrMagnitude(const Vector4f& inV)
{
    return Dot(inV, inV);
}
/// 计算输入向量inV的模长
inline float Magnitude(const Vector4f& inV)
{
    return SqrtImpl(Dot(inV, inV));
}

/// 判断inV0与inV1是否近似相等
bool GAIA_LIB_EXPORT CompareApproximately(const Vector4f& inV0, const Vector4f& inV1, float inMaxDist = 1e-6);

/// 判断inV0与inV1是否近似相等
inline bool CompareApproximately(const Vector4f& inV0, const Vector4f& inV1, float inMaxDist)
{
    return Magnitude(inV1 - inV0) < inMaxDist * inMaxDist;
}
NAMESPACE_AMAZING_ENGINE_END
