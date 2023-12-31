/**
 * @file AMGPerlinNoise.h
 * @author fanjiaqi (fanjiqi.837@bytedance.com)
 * @brief Perlin noise generator.
 * @version 0.1
 * @date 2019-12-10
 * 
 * @copyright Copyright (c) 2019
 * 
 */
#pragma once
#include "Gaia/AMGPrerequisites.h"
#include "Gaia/Math/AMGVector2.h"
#include "Gaia/Math/AMGVector3.h"

NAMESPACE_AMAZING_ENGINE_BEGIN

/**
 * @brief Union of Perlin noise functions.
 * 
 */
struct GAIA_LIB_EXPORT PerlinNoise
{
    /**
     * @brief Generate 2D Perlin noise.
     * 
     * @param src The value of sample point.
     * @param elapsed The offset of X-coordinate of src.
     * @return Real Generated perlin noise.
     */
    static Real Perlin2D(const Vector2f& src, Real elapsed = 0.f);

    /**
     * @brief Generate two 2D Perlin noise as vector. 
     * 
     * @param src The value of sample point.
     * @param elapsed The offset vector of X-coordinate of src.
     * @return Vector2f Generated perlin noise vector.
     */
    static Vector2f Perlin2DVector(const Vector2f& src, Vector2f elapsed = Vector2f(0.0f, 0.0f));

    /**
     * @brief Generate 3D Perlin noise.
     * 
     * @param src The value of sample point.
     * @param elapsed The offset of X-coordinate of src.
     * @return Real Generated perlin noise.
     */
    static Real Perlin3D(const Vector3f& src, Real elapsed = 0.f);

    /**
     * @brief Generate three 3D Perlin noise as vector. 
     * 
     * @param src The value of sample point.
     * @param elapsed The offset vector of X-coordinate of src.
     * @return Vector2f Generated perlin noise vector.
     */
    static Vector3f Perlin3DVector(const Vector3f& src, Vector3f elapsed = Vector3f(0.0f, 0.0f, 0.0f));

    /**
     * @brief Gernerate fractal 3D Perlin noise.
     * 
     * @param src The value of sample point.
     * @param octaves No used.
     * @param persistance Value of persistence.
     * @param elapsed The offset of X-coordinate of src.
     * @return Real Generated perlin noise.
     */
    static Real FractalPerlin3D(const Vector3f& src, int octaves, Real persistance, Real elapsed = 0.f);

    /**
     * @brief Genertate fractal 3D Perlin noise vector.
     * 
     * @param src The value of sample point.
     * @param octaves No used.
     * @param persistance Value of persistence.
     * @param elapsed The offset vector of X-coordinate of src.
     * @return Vector3f Generated perlin noise vector.
     */
    static Vector3f FractalPerlin3DVector(const Vector3f& src, int octaves, Real persistance, Vector3f elapsed = Vector3f(0.0f, 0.0f, 0.0f));
};

NAMESPACE_AMAZING_ENGINE_END
