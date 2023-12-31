#pragma once

#include "Gaia/Math/AMGVector3.h"

NAMESPACE_AMAZING_ENGINE_BEGIN

class Vector3i
{
public:
    int x = 0;
    int y = 0;
    int z = 0;

    Vector3i() = default;
    Vector3i(int x, int y, int z)
        : x(x)
        , y(y)
        , z(z){};

    explicit Vector3i(const Vector3f& rhs)
        : x(static_cast<int>(rhs.x))
        , y(static_cast<int>(rhs.y))
        , z(static_cast<int>(rhs.z)){};
    explicit operator Vector3f() const { return {static_cast<float>(x), static_cast<float>(y), static_cast<float>(z)}; }

    Vector3i operator+(const Vector3i& rhs) const
    {
        return {x + rhs.x, y + rhs.y, z + rhs.z};
    }
    Vector3i operator-(const Vector3i& rhs) const
    {
        return {x - rhs.x, y - rhs.y, z - rhs.z};
    }
    Vector3i operator*(int s)
    {
        return {x * s, y * s, z * s};
    }

    int operator[](int i) const
    {
        return (&x)[i];
    }
    int& operator[](int i)
    {
        return (&x)[i];
    }

    bool operator==(const Vector3i& v) const { return x == v.x && y == v.y && z == v.z; }
    bool operator!=(const Vector3i& v) const { return x != v.x || y != v.y || z != v.z; }
};

NAMESPACE_AMAZING_ENGINE_END
