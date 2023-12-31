/**
 * @file AMGPolynomials.h
 * @author fanjiaqi (fanjiaqi.837@bytedance.com)
 * @brief Base function for polynomials.
 * @version 0.1
 * @date 2019-11-26
 * 
 * @copyright Copyright (c) 2019
 * 
 */
#ifndef POLYNOMIALS_H
#define POLYNOMIALS_H

NAMESPACE_AMAZING_ENGINE_BEGIN

/**
 * @brief Returns the highest root for the cubic x^3 + px^2 + qx + r.
 * 
 * @param p p parameter of current polynomials.
 * @param q q parameter of current polynomials. 
 * @param r r parameter of current polynomials.
 * @return double The highest root of current polynomials.
 */
inline double CubicPolynomialRoot(const double p, const double q, const double r)
{
    double rcp3 = 1.0 / 3.0;
    double half = 0.5;
    double po3 = p * rcp3;
    double po3_2 = po3 * po3;
    double po3_3 = po3_2 * po3;
    double b = po3_3 - po3 * q * half + r * half;
    double a = -po3_2 + q * rcp3;
    double a3 = a * a * a;
    double det = a3 + b * b;

    if (det >= 0)
    {
        double r0 = sqrt(det) - b;
        r0 = r0 > 0 ? pow(r0, rcp3) : -pow(-r0, rcp3);

        return -po3 - a / r0 + r0;
    }

    double abs = sqrt(-a3);
    double arg = acos(-b / abs);
    abs = pow(abs, rcp3);
    abs = abs - a / abs;
    arg = -po3 + abs * cos(arg * rcp3);
    return arg;
}

/**
 * @brief Calculates all real roots of polynomial ax^2 + bx + c and returns the number.
 * 
 * @param a a parameter of current polynomials.
 * @param b b parameter of current polynomials.
 * @param c c parameter of current polynomials.
 * @param r0 The variable to store the first root of current polynomials if it has.
 * @param r1 The variable to store the second root of current polynomials if it has.
 * @return int The number of roots of current polynomials.
 */
inline int QuadraticPolynomialRootsGeneric(const float a, const float b, const float c, float& r0, float& r1)
{
    const float eps = 0.00001f;
    if (Abs(a) < eps)
    {
        if (Abs(b) > eps)
        {
            r0 = -c / b;
            return 1;
        }
        else
            return 0;
    }

    float disc = b * b - 4 * a * c;
    if (disc < 0.0f)
        return 0;

    const float halfRcpA = 0.5f / a;
    const float sqrtDisc = sqrt(disc);
    r0 = (sqrtDisc - b) * halfRcpA;
    r1 = (-sqrtDisc - b) * halfRcpA;
    return 2;
}

/**
 * @brief Calculates all the roots for the cubic ax^3 + bx^2 + cx + d and return the number.
 * 
 * @param roots The array to store the roots of current polynomials.
 * @param a a paramter of current polynomials.
 * @param b b paramter of current polynomials.
 * @param c c paramter of current polynomials.
 * @param d d paramter of current polynomials.
 * @return int The number of roots of current polynomials.
 */
inline int CubicPolynomialRootsGeneric(float* roots, const double a, const double b, const double c, const double d)
{
    int numRoots = 0;
    if (Abs(a) >= 0.0001f)
    {
        const double p = b / a;
        const double q = c / a;
        const double r = d / a;
        roots[0] = CubicPolynomialRoot(p, q, r);
        numRoots++;

        double la = a;
        double lb = b + a * roots[0];
        double lc = c + b * roots[0] + a * roots[0] * roots[0];
        numRoots += QuadraticPolynomialRootsGeneric(la, lb, lc, roots[1], roots[2]);
    }
    else
    {
        numRoots += QuadraticPolynomialRootsGeneric(b, c, d, roots[0], roots[1]);
    }

    return numRoots;
}

/**
 * @brief Specialized version of QuadraticPolynomialRootsGeneric that returns the largest root
 * 
 * @param a a parameter of current polynomials.
 * @param b b parameter of current polynomials.
 * @param c c parameter of current polynomials.
 * @return float The largest root of current polynomials.
 */
inline float QuadraticPolynomialRoot(const float a, const float b, const float c)
{
    float r0, r1;
    QuadraticPolynomialRootsGeneric(a, b, c, r0, r1);
    return r0;
}

NAMESPACE_AMAZING_ENGINE_END

#endif
