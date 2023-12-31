#pragma once

#include "Gaia/Math/AMGVector2.h"

NAMESPACE_AMAZING_ENGINE_BEGIN

class Vector2i
{
public:
    int x = 0;
    int y = 0;

    Vector2i() = default;
    Vector2i(int x, int y)
        : x(x)
        , y(y){};

    explicit Vector2i(const Vector2f& rhs)
        : x(static_cast<int>(rhs.x))
        , y(static_cast<int>(rhs.y)){};
    explicit operator Vector2f() const { return {static_cast<float>(x), static_cast<float>(y)}; }

    Vector2i operator+(const Vector2i& rhs) const
    {
        return {x + rhs.x, y + rhs.y};
    }
    Vector2i operator-(const Vector2i& rhs) const
    {
        return {x - rhs.x, y - rhs.y};
    }
    Vector2i operator*(int s)
    {
        return {x * s, y * s};
    }

    int operator[](int i) const
    {
        return (&x)[i];
    }
    int& operator[](int i)
    {
        return (&x)[i];
    }

    bool operator==(const Vector2i& v) const { return x == v.x && y == v.y; }
    bool operator!=(const Vector2i& v) const { return x != v.x || y != v.y; }
};

NAMESPACE_AMAZING_ENGINE_END
