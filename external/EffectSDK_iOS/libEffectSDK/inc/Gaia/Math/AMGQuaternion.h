/**
 * @file AMGQuaternion.h
 * @author fanjiaqi (fanjiaqi.837@bytedance.com)
 * @brief Quaternions are used to represent rotations.
 * @version 0.1
 * @date 2019-12-13
 * 
 * @copyright Copyright (c) 2019
 * 
 */
#ifndef QUATERNION_H
#define QUATERNION_H

#include "Gaia/Math/AMGMatrix3x3.h"
#include "Gaia/Math/AMGMatrix4x4.h"
#include "Gaia/Math/AMGVector3.h"
#include <algorithm>
#include <vector>

NAMESPACE_AMAZING_ENGINE_BEGIN

/**
 * @brief Quaternions are used to represent rotations.
 * 
 */
class GAIA_LIB_EXPORT Quaternionf
{
public:
    /**
     * @brief x, y, z, w component of the Quaternion. 
     * 
     */
    float x = 0.f;
    float y = 0.f;
    float z = 0.f;
    float w = 1.0f;

    /**
     * @brief Construct a new Quaternion object.
     * 
     */
    Quaternionf()
        : x(0.0f)
        , y(0.0f)
        , z(0.0f)
        , w(1.0f)
    {
    }

    /**
     * @brief Construct a new Quaternion object.
     * 
     * @param inX X component of quaternion.
     * @param inY Y component of quaternion.
     * @param inZ Z component of quaternion.
     * @param inW W component of quaternion.
     */
    Quaternionf(float inX, float inY, float inZ, float inW);

    /**
     * @brief Construct a new Quaternion object.
     * 
     * @param array A float array to store the value of x, y, z, w.
     */
    explicit Quaternionf(const float* array)
    {
        x = array[0];
        y = array[1];
        z = array[2];
        w = array[3];
    }

    /**
     * @brief Get the data address.
     * 
     * @return const float* The data address.
     */
    const float* GetPtr() const { return &x; }

    /**
     * @brief Get the data address.
     * 
     * @return float* The data address.
     */
    float* GetPtr() { return &x; }

    /**
     * @brief Overload operator[], get the reference of component with index.
     * 
     * @param i Index of component.(0 -> x, 1 ->y, 2 -> z, 3 -> w)
     * @return const float& The reference of target component.
     */
    const float& operator[](int i) const { return GetPtr()[i]; }

    /**
     * @brief Overload operator[], get the reference of component with index.
     * 
     * @param i Index of component.(0 -> x, 1 ->y, 2 -> z, 3 -> w)
     * @return float& The reference of target component.
     */
    float& operator[](int i) { return GetPtr()[i]; }

    /**
     * @brief Set x, y, z and w components of current quaternion.
     * 
     * @param inX Value of x component.
     * @param inY Value of y component.
     * @param inZ Value of z component.
     * @param inW Value of w component.
     */
    void Set(float inX, float inY, float inZ, float inW);

    /**
     * @brief Set x, y, z and w compomemts of current quaternion with other quaternion.
     * 
     * @param aQuat Other quaternion to set the value of current quaternion.
     */
    void Set(const Quaternionf& aQuat);

    /**
     * @brief Set x, y, z and w compomemts of current quaternion with input array.
     * 
     * @param array Input float array to set the value of current quaternion.
     */
    void Set(const float* array)
    {
        x = array[0];
        y = array[1];
        z = array[2];
        w = array[3];
    }

    /**
     * @brief Converts input quaternion to one with the same orientation but with a magnitude of 1.
     * 
     * @param q Input quaternion to normalize.
     * @return Quaternionf Normalized quaternion.
     */
    friend Quaternionf Normalize(const Quaternionf& q) { return q / Magnitude(q); }

    /**
     * @brief Converts input quaternion to one with the same orientation but with a magnitude of 1.
     * If the magnitude of q is 0 and then return identity quaternion.
     * @param q Input quaternion to normalize.
     * @return Quaternionf Normalized quaternion.
     */
    friend Quaternionf NormalizeSafe(const Quaternionf& q);

    /**
     * @brief Converts input quaternion to one which is conjugate quaternion of input.
     * 
     * @param q Input quaternion to conjugate.
     * @return Quaternionf Conjugate quaternion of input quaternion.
     */
    friend Quaternionf Conjugate(const Quaternionf& q);

    /**
     * @brief Returns the Inverse of input quaternion q.
     * 
     * @param q Input quaternion to inverse.
     * @return Quaternionf Inverse quaternion of input quaternion.
     */
    friend Quaternionf Inverse(const Quaternionf& q);

    /**
     * @brief Get the sqrt magnitude of input quaternion q.
     * 
     * @param q Input quaternion to calculate magnitude.
     * @return float Sqrt magnitude of input quaternion.
     */
    friend float SqrMagnitude(const Quaternionf& q);

    /**
     * @brief Get the magnitude of input quaternion q.
     * 
     * @param q Input quaternion to calculate magnitude.
     * @return float Magnitude of input quaternion.
     */
    friend float Magnitude(const Quaternionf& q);

    /**
     * @brief Overload operator==. judge whether input quaternion q equals current quaternion.
     * 
     * @param q Quaternion to compare with current quaternion.
     * @return true Q is equal to current quaternion.
     * @return false Q is not equal to current quaternion.
     */
    bool operator==(const Quaternionf& q) const { return x == q.x && y == q.y && z == q.z && w == q.w; }

    /**
     * @brief Overload operator==. judge whether input quaternion q is not equal to current quaternion.
     * 
     * @param q Quaternion to compare with current quaternion.
     * @return true Q is not equal to current quaternion.
     * @return false Q is equal to current quaternion.
     */
    bool operator!=(const Quaternionf& q) const { return x != q.x || y != q.y || z != q.z || w != q.w; }

    /**
     * @brief Overload operator +=. Add the value of components of aQuat to current quaternion.
     * 
     * @param aQuat Quaternion to add value.
     * @return Quaternionf& Reference of current quaternion, *this.
     */
    Quaternionf& operator+=(const Quaternionf& aQuat);

    /**
     * @brief Overload operator -=. Subtract value of current quaternion with aQuat.
     * 
     * @param aQuat Quaternion to subtract value.
     * @return Quaternionf& Reference of current quaternion, *this.
     */
    Quaternionf& operator-=(const Quaternionf& aQuat);

    /**
     * @brief Overload operator *=. Scale data of current quaternion with aScalar.
     * 
     * @param aScalar The scaling fator to current quaternion.
     * @return Quaternionf& Reference of current quaternion, *this.
     */
    Quaternionf& operator*=(const float aScalar);

    /**
     * @brief Overload operator*=. Combines rotations of current quaterion and aQuat and store result in current quaternion.
     * 
     * @param aQuat Input quaternion to combine rotations.
     * @return Quaternionf& Reference of current quaternion, *this.
     */
    Quaternionf& operator*=(const Quaternionf& aQuat);

    /**
     * @brief Overload operator *=. Scale data of current quaternion with 1.0 /aScalar.
     * 
     * @param aScalar The scaling factor to current quaternion.
     * @return Quaternionf& Reference of current quaternion, *this.
     */
    Quaternionf& operator/=(const float aScalar);

    /**
     * @brief Overload operator+. Add value of two quaternions lhs and rhs.
     * 
     * @param lhs Left-hand side quaternion.
     * @param rhs Right-hand side quaternion.
     * @return Quaternionf Add result quaternion.
     */
    friend Quaternionf operator+(const Quaternionf& lhs, const Quaternionf& rhs)
    {
        Quaternionf q(lhs);
        return q += rhs;
    }

    /**
     * @brief Overload operator-. Substract value of two quaternions lhs and rhs.
     * 
     * @param lhs Left-hand side quaternion.
     * @param rhs Right-hand side quaternion.
     * @return Quaternionf Substract result quaternion.
     */
    friend Quaternionf operator-(const Quaternionf& lhs, const Quaternionf& rhs)
    {
        Quaternionf t(lhs);
        return t -= rhs;
    }

    /**
     * @brief Overload operator-. Inverse all compoennts in current quaternion.
     * 
     * @return Quaternionf Quaternion which all components inverse to current quaternion.
     */
    Quaternionf operator-() const
    {
        return Quaternionf(-x, -y, -z, -w);
    }

    /**
     * @brief Overload operator*. Scale current quaternion with s.
     * 
     * @param s Scaling factor.
     * @return Quaternionf Scaled quaternion.
     */
    Quaternionf operator*(const float s) const
    {
        return Quaternionf(x * s, y * s, z * s, w * s);
    }

    /**
     * @brief Overload operator*. Scale quaternion q with s.
     * 
     * @param s Scaling factor.
     * @param q Quaternion to scale.
     * @return Quaternionf Scaled quaternion.
     */
    friend Quaternionf operator*(const float s, const Quaternionf& q)
    {
        Quaternionf t(q);
        return t *= s;
    }

    /**
     * @brief Overload operator/. Scale quaternion q with 1.0/s.
     * 
     * @param q Scaling factor.
     * @param s uaternion to scale.
     * @return Quaternionf Scaled quaternion.
     */
    friend Quaternionf operator/(const Quaternionf& q, const float s)
    {
        Quaternionf t(q);
        return t /= s;
    }

    /**
     * @brief Overload operator*. Combines rotations lhs and rhs.
     * 
     * @param lhs Left-hand side quaternion.
     * @param rhs Right-hand side quaternion.
     * @return Quaternionf Result quaternion.
     */
    inline friend Quaternionf operator*(const Quaternionf& lhs, const Quaternionf& rhs)
    {
        return Quaternionf(
            lhs.w * rhs.x + lhs.x * rhs.w + lhs.y * rhs.z - lhs.z * rhs.y,
            lhs.w * rhs.y + lhs.y * rhs.w + lhs.z * rhs.x - lhs.x * rhs.z,
            lhs.w * rhs.z + lhs.z * rhs.w + lhs.x * rhs.y - lhs.y * rhs.x,
            lhs.w * rhs.w - lhs.x * rhs.x - lhs.y * rhs.y - lhs.z * rhs.z);
    }

    /**
     * @brief Get the quaternion of identity rotation.
     * 
     * @return Quaternionf The quaternion of identity rotation
     */
    static Quaternionf identity() { return Quaternionf(0.0F, 0.0F, 0.0F, 1.0F); }
};

/**
 * @brief Judge whether two queternions q1 and q2 equal to each other.
 * 
 * @param q1 Input quaternion1 to compare value.
 * @param q2 Input quaternion2 to compare value.
 * @param epsilon The max distance between two floats which can be regarded equal to each other.
 * @return true Q1 is equal to q2.
 * @return false Q1 is not equal to q2.
 */
bool GAIA_LIB_EXPORT CompareApproximately(const Quaternionf& q1, const Quaternionf& q2, float epsilon = Vector3f::epsilon());

/**
 * @brief Interpolates between q1 and q2 by t and normalizes the result afterwards.
 * 
 * @param q1 Input quaternion1 to lerp.
 * @param q2 Input quaternion2 to lerp.
 * @param t Interlplate parameter.
 * @return Quaternionf Result quaternion of interpolation.
 */
Quaternionf GAIA_LIB_EXPORT Lerp(const Quaternionf& q1, const Quaternionf& q2, float t);

/**
 * @brief Spherically interpolates between q1 and q2 by t.
 * 
 * @param q1 Input quaternion1 to lerp.
 * @param q2 Input quaternion2 to lerp.
 * @param t Interlplate parameter.
 * @return Quaternionf Slerp Result quaternion of spherically interpolation.
 */
Quaternionf GAIA_LIB_EXPORT Slerp(const Quaternionf& q1, const Quaternionf& q2, float t);

/**
 * @brief Get the dot product between two quaternions.
 * 
 * @param q1 Input quaternion1 to dot.
 * @param q2 Input quaternion2 to dot.
 * @return float The dot product result.
 */
float GAIA_LIB_EXPORT Dot(const Quaternionf& q1, const Quaternionf& q2);

/**
 * @brief Returns the euler angle representation of the input quaternion quat.
 * 
 * @param quat Input quaternion.
 * @return Vector3f QuaternionToEuler The euler angle representation of input quaternion.
 */
Vector3f GAIA_LIB_EXPORT QuaternionToEuler(const Quaternionf& quat);

/**
 * @brief Get all equivalent euler angles of input quaternion quat.
 * 
 * @param quat Input quaternion.
 * @return std::vector<Vector3f> All equivalent euler angles.
 */
std::vector<Vector3f> GAIA_LIB_EXPORT GetEquivalentEulerAngles(const Quaternionf& quat);

/**
 * @brief Get the quaternion representation of input Euler angle.
 * 
 * @param euler Input Euler angle.
 * @return Quaternionf The quaternion representation of input Euler angle.
 */
Quaternionf GAIA_LIB_EXPORT EulerToQuaternion(const Vector3f& euler);

/**
 * @brief Converts input quaternion q to matrix m.
 * 
 * @param q Input quaternion.
 * @param m Output matrix representation of input quaternion q.
 */
void GAIA_LIB_EXPORT QuaternionToMatrix(const Quaternionf& q, Matrix3x3f& m);

/**
 * @brief Converts input matrix m to quaternion q.
 * 
 * @param m Input matrix.
 * @param q Output quaternion representation of input matrix m.
 */
void GAIA_LIB_EXPORT MatrixToQuaternion(const Matrix3x3f& m, Quaternionf& q);

/**
 * @brief Converts input matrix m to quaternion q.
 * 
 * @param m Input matrix.
 * @param q Output quaternion representation of input matrix m.
 */
void GAIA_LIB_EXPORT MatrixToQuaternion(const Matrix4x4f& m, Quaternionf& q);

/**
 * @brief Converts input quaternion q to matrix m.
 * 
 * @param q Input quaternion.
 * @param m Output matrix representation of input quaternion q.
 */
void GAIA_LIB_EXPORT QuaternionToMatrix(const Quaternionf& q, Matrix4x4f& m);

/**
 * @brief Converts a quaternion to angle-axis representation (angles in degrees).
 * 
 * @param q Input quaternion.
 * @param axis Output rotation axis.
 * @param targetAngle Output rotation angle.
 */
void GAIA_LIB_EXPORT QuaternionToAxisAngle(const Quaternionf& q, Vector3f* axis, float* targetAngle);

/**
 * @brief Converts angle-axis to quaternion represetation.
 * 
 * @param axis Input rotation axis.
 * @param angle Input rotation angle.
 * @return Quaternionf Output quaternion.
 */
Quaternionf GAIA_LIB_EXPORT AxisAngleToQuaternion(const Vector3f& axis, float angle);

/**
 * @brief Generates a Right handed Quat from a look rotation. Returns if conversion was successful.
 * 
 * @param viewVec View vector of input look rotation.
 * @param upVec Up vector of input look rotation.
 * @param res Result quaternion.
 * @return true Conversion was successful.
 * @return false Conversion was not successful.
 */
bool GAIA_LIB_EXPORT LookRotationToQuaternion(const Vector3f& viewVec, const Vector3f& upVec, Quaternionf* res);

/**
 * @brief Rotate vector rhs by input quaternion lhs.
 * 
 * @param lhs Input rotation quternion.
 * @param rhs Input rotation vector.
 * @return Vector3f Result rotation vector.
 */
inline Vector3f RotateVectorByQuat(const Quaternionf& lhs, const Vector3f& rhs)
{
    //	Matrix3x3f m;
    //	QuaternionToMatrix (lhs, &m);
    //	Vector3f restest = m.MultiplyVector3 (rhs);
    float x = lhs.x * 2.0F;
    float y = lhs.y * 2.0F;
    float z = lhs.z * 2.0F;
    float xx = lhs.x * x;
    float yy = lhs.y * y;
    float zz = lhs.z * z;
    float xy = lhs.x * y;
    float xz = lhs.x * z;
    float yz = lhs.y * z;
    float wx = lhs.w * x;
    float wy = lhs.w * y;
    float wz = lhs.w * z;

    Vector3f res;
    res.x = (1.0f - (yy + zz)) * rhs.x + (xy - wz) * rhs.y + (xz + wy) * rhs.z;
    res.y = (xy + wz) * rhs.x + (1.0f - (xx + zz)) * rhs.y + (yz - wx) * rhs.z;
    res.z = (xz - wy) * rhs.x + (yz + wx) * rhs.y + (1.0f - (xx + yy)) * rhs.z;

    //	aeAssert (CompareApproximately (restest, res));
    return res;
}

/**
 * @brief Construct a new Quaternion object.
 * 
 * @param inX X component of quaternion.
 * @param inY Y component of quaternion.
 * @param inZ Z component of quaternion.
 * @param inW W component of quaternion.
 */
inline Quaternionf::Quaternionf(float inX, float inY, float inZ, float inW)
{
    x = inX;
    y = inY;
    z = inZ;
    w = inW;
}

/**
 * @brief Set x, y, z and w components of current quaternion.
 * 
 * @param inX Value of x component.
 * @param inY Value of y component.
 * @param inZ Value of z component.
 * @param inW Value of w component.
 */
inline void Quaternionf::Set(float inX, float inY, float inZ, float inW)
{
    x = inX;
    y = inY;
    z = inZ;
    w = inW;
}

/**
 * @brief Set x, y, z and w compomemts of current quaternion with other quaternion.
 * 
 * @param aQuat Other quaternion to set the value of current quaternion.
 */
inline void Quaternionf::Set(const Quaternionf& aQuat)
{
    x = aQuat.x;
    y = aQuat.y;
    z = aQuat.z;
    w = aQuat.w;
}

/**
 * @brief Converts input quaternion to one which is conjugate quaternion of input.
 * 
 * @param q Input quaternion to conjugate.
 * @return Quaternionf Conjugate quaternion of input quaternion.
 */
inline Quaternionf Conjugate(const Quaternionf& q)
{
    return Quaternionf(-q.x, -q.y, -q.z, q.w);
}

/**
 * @brief Returns the Inverse of a normalized quaternion q. Ignore the division for sqrMagnitude for optimization.
 * 
 * @param q Input quaternion to inverse. q must be normalized otherwise it will trigger assert.
 * @return Quaternionf Inverse quaternion of input quaternion.
 */
inline Quaternionf Inverse(const Quaternionf& q)
{
    aeAssert(CompareApproximately(SqrMagnitude(q), 1.0f));
    Quaternionf res = Conjugate(q);
    return res;
}

/**
 * @brief Returns the Inverse of any non-zero-magnitude quaternion q. Include sqrMagnitude division for correctness.
 *
 * @param q Input quaternion to inverse. q must have non-zero-magnitude otherwise it will trigger assert.
 * @return Quaternionf Inverse quaternion of input quaternion.
 */
inline Quaternionf InverseSlow(const Quaternionf& q)
{
    aeAssert(!(CompareApproximately(SqrMagnitude(q), 0.0F)));
    Quaternionf res = Conjugate(q) / SqrMagnitude(q);
    return res;
}

/**
 * @brief Get the magnitude of input quaternion q.
 * 
 * @param q Input quaternion to calculate magnitude.
 * @return float Magnitude of input quaternion.
 */
inline float Magnitude(const Quaternionf& q)
{
    return SqrtImpl(SqrMagnitude(q));
}

/**
 * @brief Get the sqrt magnitude of input quaternion q.
 * 
 * @param q Input quaternion to calculate magnitude.
 * @return float Sqrt magnitude of input quaternion.
 */
inline float SqrMagnitude(const Quaternionf& q)
{
    return Dot(q, q);
}

/**
 * @brief Overload operator +=. Add the value of components of aQuat to current quaternion.
 * 
 * @param aQuat Quaternion to add value.
 * @return Quaternionf& Reference of current quaternion, *this.
 */
inline Quaternionf& Quaternionf::operator+=(const Quaternionf& aQuat)
{
    x += aQuat.x;
    y += aQuat.y;
    z += aQuat.z;
    w += aQuat.w;
    return *this;
}

/**
 * @brief Overload operator -=. Subtract value of current quaternion with aQuat.
 * 
 * @param aQuat Quaternion to subtract value.
 * @return Quaternionf& Reference of current quaternion, *this.
 */
inline Quaternionf& Quaternionf::operator-=(const Quaternionf& aQuat)
{
    x -= aQuat.x;
    y -= aQuat.y;
    z -= aQuat.z;
    w -= aQuat.w;
    return *this;
}

/**
 * @brief Overload operator *=. Scale data of current quaternion with aScalar.
 * 
 * @param aScalar The scaling fator to current quaternion.
 * @return Quaternionf& Reference of current quaternion, *this.
 */
inline Quaternionf& Quaternionf::operator*=(float aScalar)
{
    x *= aScalar;
    y *= aScalar;
    z *= aScalar;
    w *= aScalar;
    return *this;
}

/**
 * @brief Overload operator *=. Scale data of current quaternion with 1.0 /aScalar.
 * 
 * @param aScalar The scaling factor to current quaternion.
 * @return Quaternionf& Reference of current quaternion, *this.
 */
inline Quaternionf& Quaternionf::operator/=(const float aScalar)
{
    aeAssert(!(CompareApproximately(aScalar, 0.0F)));
    x /= aScalar;
    y /= aScalar;
    z /= aScalar;
    w /= aScalar;
    return *this;
}

/**
 * @brief Overload operator*=. Combines rotations of current quaterion and rhs and store result in current quaternion.
 * 
 * @param rhs Input quaternion to combine rotations.
 * @return Quaternionf& Reference of current quaternion, *this.
 */
inline Quaternionf& Quaternionf::operator*=(const Quaternionf& rhs)
{
    float tempx = w * rhs.x + x * rhs.w + y * rhs.z - z * rhs.y;
    float tempy = w * rhs.y + y * rhs.w + z * rhs.x - x * rhs.z;
    float tempz = w * rhs.z + z * rhs.w + x * rhs.y - y * rhs.x;
    float tempw = w * rhs.w - x * rhs.x - y * rhs.y - z * rhs.z;
    x = tempx;
    y = tempy;
    z = tempz;
    w = tempw;
    return *this;
}

/**
 * @brief Interpolates between q1 and q2 by t and normalizes the result afterwards.
 * 
 * @param q1 Input quaternion1 to lerp.
 * @param q2 Input quaternion2 to lerp.
 * @param t Interlplate parameter.
 * @return Quaternionf Result quaternion of interpolation.
 */
inline Quaternionf Lerp(const Quaternionf& q1, const Quaternionf& q2, float t)
{
    Quaternionf tmpQuat;
    // if (dot < 0), q1 and q2 are more than 360 deg apart.
    // The problem is that quaternions are 720deg of freedom.
    // so we - all components when lerping
    if (Dot(q1, q2) < 0.0F)
    {
        tmpQuat.Set(q1.x + t * (-q2.x - q1.x),
                    q1.y + t * (-q2.y - q1.y),
                    q1.z + t * (-q2.z - q1.z),
                    q1.w + t * (-q2.w - q1.w));
    }
    else
    {
        tmpQuat.Set(q1.x + t * (q2.x - q1.x),
                    q1.y + t * (q2.y - q1.y),
                    q1.z + t * (q2.z - q1.z),
                    q1.w + t * (q2.w - q1.w));
    }
    return Normalize(tmpQuat);
}

/**
 * @brief Get the dot product between two quaternions.
 * 
 * @param q1 Input quaternion1 to dot.
 * @param q2 Input quaternion2 to dot.
 * @return float The dot product result.
 */
inline float Dot(const Quaternionf& q1, const Quaternionf& q2)
{
    return (q1.x * q2.x + q1.y * q2.y + q1.z * q2.z + q1.w * q2.w);
}

/**
 * @brief Returns the angle disatance between two rotations lhs and rhs.
 * 
 * @param lhs Left-hand side quatenion.
 * @param rhs Right-hand side quaternion.
 * @return float The angle distance between two rotations.
 */
float AngularDistance(const Quaternionf& lhs, const Quaternionf& rhs);

/**
 * @brief Converts a quaternion to angle-axis representation (angles in degrees).
 * 
 * @param q Input quaternion.
 * @param axis Output rotation axis.
 * @param targetAngle Output rotation angle.
 */
inline void QuaternionToAxisAngle(const Quaternionf& q, Vector3f* axis, float* targetAngle)
{
    aeAssert(CompareApproximately(SqrMagnitude(q), 1.0F));

    auto q2 = q;
    if (q2.w < 0.0f)
        q2 *= -1;
    if (q2.w > 1.0f)
        q2.w = 1.0f;

    *targetAngle = 2.0f * acos(q2.w);
    if (CompareApproximately(*targetAngle, 0.0F))
    {
        *axis = Vector3f::xAxis();
        return;
    }

    float div = 1.0f / sqrt(1.0f - Sqr(q2.w));
    axis->Set(q2.x * div, q2.y * div, q2.z * div);
}

/**
 * @brief Converts angle-axis to quaternion represetation.
 * 
 * @param axis Input rotation axis.
 * @param angle Input rotation angle.
 * @return Quaternionf Output quaternion.
 */
inline Quaternionf AxisAngleToQuaternion(const Vector3f& axis, float angle)
{
    Quaternionf q;
    aeAssert(CompareApproximately(SqrMagnitude(axis), 1.0F));
    float halfAngle = angle * 0.5F;
    float s = sin(halfAngle);

    q.w = cos(halfAngle);
    q.x = s * axis.x;
    q.y = s * axis.y;
    q.z = s * axis.z;
    return q;
}

/**
 * @brief Converts axis-velocity to quaternion represetation.
 * 
 * @param axis The input rotation axis.
 * @param deltaTime The time to represent velocity.
 * @return Quaternionf Result quaternion.
 */
inline Quaternionf AngularVelocityToQuaternion(const Vector3f& axis, float deltaTime)
{
    float w = Magnitude(axis);
    if (w > Vector3f::epsilon())
    {
        float v = deltaTime * w * 0.5f;
        float q = cos(v);
        float s = sin(v) / w;

        Quaternionf integrated;
        integrated.w = q;
        integrated.x = s * axis.x;
        integrated.y = s * axis.y;
        integrated.z = s * axis.z;

        return NormalizeSafe(integrated);
    }
    else
    {
        return Quaternionf::identity();
    }
}

/**
 * @brief Converts angle-axis to quaternion represetation. Return identity if magnitude of axis is 0.
 * 
 * @param axis Input rotation axis.
 * @param angle Input rotation angle.
 * @return Quaternionf Output quaternion.
 */
inline Quaternionf AxisAngleToQuaternionSafe(const Vector3f& axis, float angle)
{
    Quaternionf q;
    float mag = Magnitude(axis);
    if (mag > 0.000001F)
    {
        float halfAngle = angle * 0.5F;

        q.w = cos(halfAngle);

        float s = sin(halfAngle) / mag;
        q.x = s * axis.x;
        q.y = s * axis.y;
        q.z = s * axis.z;
        return q;
    }
    else
    {
        return Quaternionf::identity();
    }
}

/**
 * @brief Generates a quaternion that rotates lhs into rhs.
 * 
 * @param lhs Direction of lhs.
 * @param rhs Direction of rhs.
 * @return Quaternionf Result quaternion.
 */
Quaternionf GAIA_LIB_EXPORT FromToQuaternionSafe(const Vector3f& lhs, const Vector3f& rhs);

/**
 * @brief Generates a quaternion that rotates lhs into rhs. From and to are assumed to be normalized
 * 
 * @param from Direction of from.
 * @param to Direction of to.
 * @return Quaternionf Result quaternion.
 */
Quaternionf GAIA_LIB_EXPORT FromToQuaternion(const Vector3f& from, const Vector3f& to);

/**
 * @brief Judge whether two queternions q1 and q2 equal to each other.
 * 
 * @param q1 Input quaternion1 to compare value.
 * @param q2 Input quaternion2 to compare value.
 * @param epsilon The max distance between two floats which can be regarded equal to each other.
 * @return true Q1 is equal to q2.
 * @return false Q1 is not equal to q2.
 */
inline bool CompareApproximately(const Quaternionf& q1, const Quaternionf& q2, float epsilon)
{
    //return SqrMagnitude (q1 - q2) < epsilon * epsilon;
    return (SqrMagnitude(q1 - q2) < epsilon * epsilon) || (SqrMagnitude(q1 + q2) < epsilon * epsilon);
    //return Abs (Dot (q1, q2)) > (1 - epsilon * epsilon);
}

/**
 * @brief Converts input quaternion to one with the same orientation but with a magnitude of 1.
 * If the magnitude of q is 0 and then return identity quaternion.
 * @param q Input quaternion to normalize.
 * @return Quaternionf Normalized quaternion.
 */
inline Quaternionf NormalizeSafe(const Quaternionf& q)
{
    float mag = Magnitude(q);
    if (mag < Vector3f::epsilon())
        return Quaternionf::identity();
    else
        return q / mag;
}

/**
 * @brief Normalize input quaternion q. The zero quaternion will be returned if magnitude of q is 0.
 * 
 * @param q Input quaternion to normalize.
 * @return Quaternionf Normalized quaternion.
 */
inline Quaternionf NormalizeFastEpsilonZero(const Quaternionf& q)
{
    float m = SqrMagnitude(q);
    if (m < Vector3f::epsilon())
        return Quaternionf(0.0F, 0.0F, 0.0F, 0.0F);
    else
        return q * FastInvSqrt(m);
}

/**
 * @brief Judge if quaternion f is finite. A quaternion is infite only when all components in quaternion is finite.
 * 
 * @param f Input quaternion to judge.
 * @return true Input quaternion is finite.
 * @return false Input quaternion is not finite.
 */
inline bool IsFinite(const Quaternionf& f)
{
    return IsFinite(f.x) & IsFinite(f.y) & IsFinite(f.z) & IsFinite(f.w);
}

NAMESPACE_AMAZING_ENGINE_END

#endif
