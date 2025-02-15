/**
 * @file AMGRandom.h
 * @author fanjiaqi (fanjiaqi.837@bytedance.com)
 * @brief Random functions.
 * @version 0.1
 * @date 2019-12-04
 * 
 * @copyright Copyright (c) 2019
 * 
 */
#ifndef RANDOM_H
#define RANDOM_H

#include "Gaia/Math/Random/amg_rand.h"
#include "Gaia/Math/AMGVector2.h"
#include "Gaia/Math/AMGQuaternion.h"
#include "Gaia/Math/AMGFloatConversion.h"

NAMESPACE_AMAZING_ENGINE_BEGIN

/**
 * @brief Generate a random float number between min and max.
 * 
 * @param r Random generator.
 * @param min The low range of random number.
 * @param max The high range of random number.
 * @return float The random number generated.
 */
inline float RangedRandom(Rand& r, float min, float max)
{
    float t = r.GetFloat();
    t = min * t + (1.0F - t) * max;
    return t;
}

/**
 * @brief Generate a random float number between 0.1 and 1.0.
 * 
 * @param r Random generator.
 * @return float The random number generated.
 */
inline float Random01(Rand& r)
{
    return r.GetFloat();
}

/**
 * @brief Generate a random int number between min and max.
 * 
 * @param r Random generator.
 * @param min The low range of random number.
 * @param max The high range of random number.
 * @return int The random number generated.
 */
inline int RangedRandom(Rand& r, int min, int max)
{
    int dif;
    if (min < max)
    {
        dif = max - min;
        int t = r.Get() % dif;
        t += min;
        return t;
    }
    else if (min > max)
    {
        dif = min - max;
        int t = r.Get() % dif;
        t = min - t;
        return t;
    }
    else
    {
        return min;
    }
}

/**
 * @brief Generate a random unit vector3.
 * 
 * @param rand Ramdon generator.
 * @return Vector3f The random vector3 generated.
 */
inline Vector3f RandomUnitVector(Rand& rand)
{
    float z = RangedRandom(rand, -1.0f, 1.0f);
    float a = RangedRandom(rand, 0.0f, 2.0F * kPI);

    float r = sqrt(1.0f - z * z);

    float x = r * cos(a);
    float y = r * sin(a);

    return Vector3f(x, y, z);
}

/**
 * @brief Generate a random unit vector2.
 * 
 * @param rand Random generator.
 * @return Vector2f The random vector2 generated.
 */
inline Vector2f RandomUnitVector2(Rand& rand)
{
    float a = RangedRandom(rand, 0.0f, 2.0F * kPI);

    float x = cos(a);
    float y = sin(a);

    return Vector2f(x, y);
}

/**
 * @brief Generate a random quaternion.
 * 
 * @param rand Random generator.
 * @return Quaternionf The random quaternion generated.
 */
inline Quaternionf RandomQuaternion(Rand& rand)
{
    Quaternionf q;
    q.x = RangedRandom(rand, -1.0f, 1.0f);
    q.y = RangedRandom(rand, -1.0f, 1.0f);
    q.z = RangedRandom(rand, -1.0f, 1.0f);
    q.w = RangedRandom(rand, -1.0f, 1.0f);
    q = NormalizeSafe(q);
    if (Dot(q, Quaternionf::identity()) < 0.0f)
        return -q;
    else
        return q;
}

/**
 * @brief Generate a random quaternion with uniform distribution.
 * 
 * @param rand Random generator.
 * @return Quaternionf The random quaternion generated.
 */
inline Quaternionf RandomQuaternionUniformDistribution(Rand& rand)
{
    const float two_pi = 2.0F * kPI;

    // Employs Hopf fibration to uniformly distribute quaternions
    float u1 = RangedRandom(rand, 0.0f, 1.0f);
    float theta = RangedRandom(rand, 0.0f, two_pi);
    float rho = RangedRandom(rand, 0.0f, two_pi);

    float i = sqrt(1.0f - u1);
    float j = sqrt(u1);

    // We do not need to normalize the generated quaternion, because the probability density corresponds to the Haar measure.
    // This means that a random rotation is obtained by picking a point at random on S^3, and forming the unit quaternion.
    Quaternionf q(i * sin(theta), i * cos(theta), j * sin(rho), j * cos(rho));

    if (Dot(q, Quaternionf::identity()) < 0.0f)
        return -q;
    else
        return q;
}

/**
 * @brief Generate a random vector3 which is inside a cube.
 * 
 * @param r Random generator.
 * @param extents The parameter of cube.
 * @return Vector3f The random vector3 generated.
 */
inline Vector3f RandomPointInsideCube(Rand& r, const Vector3f& extents)
{
    return Vector3f(RangedRandom(r, -extents.x, extents.x),
                    RangedRandom(r, -extents.y, extents.y),
                    RangedRandom(r, -extents.z, extents.z));
}

/**
 * @brief Generate a random vector3 which is between cube min and cube max.
 * 
 * @param r Random generator.
 * @param min The min cube.
 * @param max The max cube.
 * @return Vector3f The random vector3 generated.
 */
inline Vector3f RandomPointBetweenCubes(Rand& r, const Vector3f& min, const Vector3f& max)
{
    Vector3f v;
    int i;
    for (i = 0; i < 3; i++)
    {
        float x = r.GetFloat() * 2.0F - 1.0F;
        if (x > 0.0f)
            v[i] = min[i] + x * (max[i] - min[i]);
        else
            v[i] = -min[i] + x * (max[i] - min[i]);
    }
    return v;
}

/**
 * @brief Generate a random vector3 which is inside an unit sphere.
 * 
 * @param r Random generator.
 * @return Vector3f The random vector3 generated.
 */
inline Vector3f RandomPointInsideUnitSphere(Rand& r)
{
    Vector3f v = RandomUnitVector(r);
    v *= pow(Random01(r), 1.0F / 3.0F);
    return v;
}

/**
 * @brief Generate a random vector3 which is inside an ellipsoid.
 * 
 * @param r Random generator.
 * @param extents The parameter to describe an ellipsoid.
 * @return Vector3f The random vector3 generated.
 */
inline Vector3f RandomPointInsideEllipsoid(Rand& r, const Vector3f& extents)
{
    return Scale(RandomPointInsideUnitSphere(r), extents);
}

/**
 * @brief Generate a random vector3 which is between two spheres whose radius are minRadius and maxRadius.
 * 
 * @param r Random generator.
 * @param minRadius The radius of smaller sphere.
 * @param maxRadius The radius of larger sphere.
 * @return Vector3f The random vector3 generated.
 */
inline Vector3f RandomPointBetweenSphere(Rand& r, float minRadius, float maxRadius)
{
    Vector3f v = RandomUnitVector(r);
    // As the volume of the sphere increases (x^3) over an interval we have to increase range as well with x^(1/3)
    float range = pow(RangedRandom(r, 0.0F, 1.0F), 1.0F / 3.0F);
    return v * (minRadius + (maxRadius - minRadius) * range);
}

/**
 * @brief Generate a random vector2 which is inside an unit circle.
 * 
 * @param r Random generator.
 * @return Vector2f The random vector2 generated.
 */
inline Vector2f RandomPointInsideUnitCircle(Rand& r)
{
    Vector2f v = RandomUnitVector2(r);
    // As the volume of the sphere increases (x^3) over an interval we have to increase range as well with x^(1/3)
    v *= pow(RangedRandom(r, 0.0F, 1.0F), 1.0F / 2.0F);
    return v;
}

/**
 * @brief Generate a random vector3 which is between two ellipsoids.
 * 
 * @param r Random generator.
 * @param maxExtents The parameter of larger ellipsoid.
 * @param minRange The scale of smaller ellipsoid compared to larger ellipsoid.
 * @return Vector3f The random vector3 generated.
 */
inline Vector3f RandomPointBetweenEllipsoid(Rand& r, const Vector3f& maxExtents, float minRange)
{
    Vector3f v = Scale(RandomUnitVector(r), maxExtents);
    // As the volume of the sphere increases (x^3) over an interval we have to increase range as well with x^(1/3)
    float range = pow(RangedRandom(r, minRange, 1.0F), 1.0F / 3.0F);
    return v * range;
}

/**
 * @brief Builds a random barycentric coordinate which can be used to generate random points on a triangle.
 * 
 * @param rand Random generator.
 * @return Vector3f The barycentric coordinate generated.
 */
inline Vector3f RandomBarycentricCoord(Rand& rand)
{
    // Was told that this leads to bad distribution because of the 1.0F - s
    float u = rand.GetFloat();
    float v = rand.GetFloat();
    if (u + v > 1.0F)
    {
        u = 1.0F - u;
        v = 1.0F - v;
    }
    float w = 1.0F - u - v;
    return Vector3f(u, v, w);
}

NAMESPACE_AMAZING_ENGINE_END

#endif
