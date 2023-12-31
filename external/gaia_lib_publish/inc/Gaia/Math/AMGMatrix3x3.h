/**
 * @file AMGMatrix3x3.h
 * @author fanjiaqi(fanjiaqi.837@bytedance.com) 
 * @brief 3X3 Matrix Definition for Math Calculation.
 * @version 0.1
 * @date 2019-11-22
 * 
 * @copyright Copyright (c) 2019
 * 
 */
#pragma once

#include "Gaia/Math/AMGVector3.h"

NAMESPACE_AMAZING_ENGINE_BEGIN
/**
 * @brief Matrix3x3f This class define the 3x3 matrix for math calculation.
 * 
 */
class GAIA_LIB_EXPORT Matrix3x3f
{
public:
    /**
     * @brief Data of matrix.
     * 
     */
    float m_Data[9] = {1.f, 0.f, 0.f, 0.f, 1.f, 0.f, 0.f, 0.f, 1.f};

    /**
     * @brief Construct a new Matrix3x3f object.
     * 
     */
    Matrix3x3f() {}

    /**
     * @brief Construct a new Matrix3x3f object.
     * 
     * @param m00 Value of (0, 0).
     * @param m01 Value of (1, 0).
     * @param m02 Value of (2, 0).
     * @param m10 Value of (0, 1).
     * @param m11 Value of (1, 1).
     * @param m12 Value of (2, 1).
     * @param m20 Value of (0, 2).
     * @param m21 Value of (1, 2).
     * @param m22 Value of (2, 2).
     */
    Matrix3x3f(float m00, float m01, float m02, float m10, float m11, float m12, float m20, float m21, float m22)
    {
        Get(0, 0) = m00;
        Get(1, 0) = m10;
        Get(2, 0) = m20;
        Get(0, 1) = m01;
        Get(1, 1) = m11;
        Get(2, 1) = m21;
        Get(0, 2) = m02;
        Get(1, 2) = m12;
        Get(2, 2) = m22;
    }
    /**
     * @brief Construct a new Matrix 3x 3f object
     * 
     * @param m Input matrix.
     */
    explicit Matrix3x3f(const class Matrix4x4f& m);
    /**
     * @brief Construct a new Matrix 3x 3f object
     * 
     * @param data Input data.
     */
    explicit Matrix3x3f(const float data[9]);

    /**
     * @brief The Get function accesses the matrix in std math convention.
     * m0,0 m0,1 m0,2
     * m1,0 m1,1 m1,2
     * m2,0 m2,1 m2,2
     * 
     * The floats are laid out:
     * m0   m3   m6
     * m1   m4   m7
     * m2   m5   m8
     * 
     * @param row Row index, range 0~2.
     * @param column Column index, range 0~2.
     * @return float& The reference of target element.
     */
    float& Get(int row, int column)
    {
        if (row < 0 || row > 2)
        {
            return m_Data[0];
        }
        if (column < 0 || column > 2)
        {
            return m_Data[0];
        }
        return m_Data[row + (column * 3)];
    }
    /**
     * @brief The Get function accesses the matrix in std math convention.
     *
     * @param row Row index, range 0~2.
     * @param column Column index, range 0~2.
     * @return const float& The reference of target element.
     */
    const float& Get(int row, int column) const
    {
        if (row < 0 || row > 2)
        {
            return m_Data[0];
        }
        if (column < 0 || column > 2)
        {
            return m_Data[0];
        }
        return m_Data[row + (column * 3)];
    }

    /**
     * @brief Regard the matrix as a vector, get the value at position row.
     * 
     * @param row Index, range 0~8.
     * @return float& The reference of target element.
     */
    float& operator[](int row) { return m_Data[row]; }
    /**
     * @brief Regard the matrix as a vector, get the value at position row.
     * 
     * @param row row Index, range 0~8.
     * @return float The value of target element.
     */
    float operator[](int row) const { return m_Data[row]; }

    /**
     * @brief Get data pointer.
     * 
     * @return float* The data pointer.
     */
    float* GetPtr() { return m_Data; }
    /**
     * @brief Get data pointer.
     * 
     * @return const float* The data pointer.
     */
    const float* GetPtr() const { return m_Data; }

    /**
     * @brief Get column's data pointer.
     *
     * @return Vector3f* The column's data pointer.
     */
    Vector3f* GetColumnPtr(int col) { return (Vector3f*)(m_Data + col * 3); }
    /**
     * @brief Get column's data pointer.
     *
     * @return const Vector3f* The column's data pointer.
     */
    const Vector3f* GetColumnPtr(int col) const { return (Vector3f*)(m_Data + col * 3); }

    /**
     * @brief Get data of one column with column index.
     * 
     * @param col Column index, range 0~2.
     * @return Vector3f A Vector that contains data of the column.
     */
    Vector3f GetColumn(int col) const { return Vector3f(Get(0, col), Get(1, col), Get(2, col)); }
    /**
     * @brief Overload operator=, convert a matrix4x4 to matrix3x3.
     * 
     * @param m Input matrix4x4f, the data within column 0~3 and row 0~3 will be used.
     * @return Matrix3x3f& The reference to current matrix.
     */
    Matrix3x3f& operator=(const class Matrix4x4f& m);

    /**
     * @brief Overload operator*=, set current matrix to the result of multiplication of current matrix and inM.
     * 
     * @param inM Input matrix3x3f.
     * @return Matrix3x3f& The reference to current matrix.
     */
    Matrix3x3f& operator*=(const Matrix3x3f& inM);
    /**
     * @brief Overload operator*=, set current matrix to the result of multiplication of current matrix and inM.
     * 
     * @param inM Input matrix4x4f, the data within column 0~3 and row 0~3 will be used.
     * @return Matrix3x3f& The reference to current matrix.
     */
    Matrix3x3f& operator*=(const class Matrix4x4f& inM);
    /**
     * @brief Overload operator*, calculate result of multiplication of matrix lhs and rhs.
     * 
     * @param lhs The left multiplier.
     * @param rhs The right multiplier.
     * @return Matrix3x3f The calculation result.
     */
    friend Matrix3x3f operator*(const Matrix3x3f& lhs, const Matrix3x3f& rhs)
    {
        Matrix3x3f temp(lhs);
        temp *= rhs;
        return temp;
    }
    /**
     * @brief Calculate the result of multiplication of vector3 inV and current matrix.
     * 
     * @param inV Input vector.
     * @return Vector3f Result vector.
     */
    Vector3f MultiplyVector3(const Vector3f& inV) const;
    /**
     * @brief Calculate the result of multiplication of vector3 inV and current matrix, set result to output.
     * 
     * @param inV Input vector.
     * @param output Result vector.
     */
    void MultiplyVector3(const Vector3f& inV, Vector3f& output) const;
    /**
     * @brief Calculate the result of multiplication of vector3 inV and current matrix, same as MultiplyVector3.
     * 
     * @param inV Input point.
     * @return Vector3f Result point.
     */
    Vector3f MultiplyPoint3(const Vector3f& inV) const { return MultiplyVector3(inV); }
    /**
     * @brief Calculate the result of multiplication of transposed vector3 inV and current matrix.
     * 
     * @param inV Input vector.
     * @return Vector3f Transposed result vector.
     */
    Vector3f MultiplyVector3Transpose(const Vector3f& inV) const;
    /**
     * @brief Calculate the result of multiplication of transposed vector3 inV and current matrix, same as MultiplyVector3Transpose.
     * 
     * @param inV Input vector.
     * @return Vector3f Transposed result pointer3.
     */
    Vector3f MultiplyPoint3Transpose(const Vector3f& inV) const { return MultiplyVector3Transpose(inV); }
    /**
     * @brief Overload operator *=, multiply every element in current matrix with float f.
     * 
     * @param f Input float.
     * @return Matrix3x3f& The reference to current matrix.
     */
    Matrix3x3f& operator*=(float f);
    /**
     * @brief Overload operator /=, divide every element in current matrix with float f.
     * 
     * @param f Input float.
     * @return Matrix3x3f& The reference to current matrix.
     */
    Matrix3x3f& operator/=(float f) { return *this *= (1.0F / f); }
    /**
     * @brief Get the Determinant of current matrix.
     * 
     * @return float The Determinant value.
     */
    float GetDeterminant() const;

    /**
     * @brief Transpose current matrix.
     * 
     * @return Matrix3x3f& The reference to current matrix.
     */
    Matrix3x3f& Transpose();

    /**
     * @brief Invert current matrix if it can be invertted.
     * 
     * @return true Invert the matrix successfully.
     * @return false The matrix cannot be invertted.
     */
    bool Invert();
    /**
     * @brief Invert current matrix if it can be invertted and then transpose it.
     * 
     */
    void InvertTranspose();
    /**
     * @brief Set current matrix to identity matrix.
     * 
     * @return Matrix3x3f& The reference to current matrix.
     */
    Matrix3x3f& SetIdentity();
    /**
     * @brief Set current matrix to zero matrix.
     * 
     * @return Matrix3x3f& The reference to current matrix.
     */
    Matrix3x3f& SetZero();
    /**
     * @brief Set current matrix to a rotation matrix that rotates a vector called "from" into another vector called "to".
     * 
     * @param from The "from" vector.
     * @param to The "to" vector.
     * @return Matrix3x3f& The reference to current matrix.
     */
    Matrix3x3f& SetFromToRotation(const Vector3f& from, const Vector3f& to);
    /**
     * @brief Set current matrix to a rotation matrix that rotates arbitrary angle around arbitrary axis.
     * 
     * @param rotationAxis The axis that rotates around.
     * @param radians The angle of rotation.
     * @return Matrix3x3f& The reference to current matrix.
     */
    Matrix3x3f& SetAxisAngle(const Vector3f& rotationAxis, float radians);
    /**
     * @brief Set current matrix to a matrix that forms an orthonormal basis.
     * 
     * @param inX The first basis of a set of orthonormal basis.
     * @param inY The second basis of a set of orthonormal basis.
     * @param inZ The third basis of a set of orthonormal basis.
     * @return Matrix3x3f& The reference of current matrix.
     */
    Matrix3x3f& SetOrthoNormalBasis(const Vector3f& inX, const Vector3f& inY, const Vector3f& inZ);
    /**
     * @brief Set current matrix to a matrix whose transposed matrix forms an orthonormal basis.
     * 
     * @param inX The first basis of a set of orthonormal basis.
     * @param inY The second basis of a set of orthonormal basis.
     * @param inZ The third basis of a set of orthonormal basis.
     * @return Matrix3x3f& The reference of current matrix.
     */
    Matrix3x3f& SetOrthoNormalBasisInverse(const Vector3f& inX, const Vector3f& inY, const Vector3f& inZ);
    /**
     * @brief Set current matrix to a scaling matrix with scaling factor.
     * 
     * @param inScale Input scaling factor.
     * @return Matrix3x3f& The reference of current matrix.
     */
    Matrix3x3f& SetScale(const Vector3f& inScale);
    /**
     * @brief Scaling current matrix with scaling factor.
     * 
     * @param inScale Input scaling factor.
     * @return Matrix3x3f& The Reference of current matrix.
     */
    Matrix3x3f& Scale(const Vector3f& inScale);
    /**
     * @brief Judge whether the current matrix is an identity matrix
     * 
     * @param threshold Equation threshold.
     * @return true Current matrix is an identity matrix.
     * @return false Current matrix is not an identity matrix.
     */
    bool IsIdentity(float threshold = Vector3f::epsilon());
    /**
     * @brief Zero matrix.
     * 
     */
    static const Matrix3x3f& zero();
    /**
     * @brief Identity matrix.
     * 
     */
    static const Matrix3x3f& identity();

    /**
     * @brief Set value of elements in target row with v.
     *
     * @param row The index of target row.
     * @param v The value to set.
     */
    void SetRow(int row, const Vector3f& v);

    /**
     * @brief Set value of elements in target column with v.
     *
     * @param col The index of target column.
     * @param v The value to set.
     */
    void SetColumn(int col, const Vector3f& v);
};

/**
 * @brief Generates an orthornormal basis from a look at rotation, returns if it was successful.
 * 
 * @param viewVec The view vector of look rotation.
 * @param upVec The up vector of look rotation.
 * @param m The matrix that save the result orthornormal basis.
 * @return true Sucessfully generating an orthornormal basis.
 * @return false Failed to generate an orthornormal basis.
 */
bool GAIA_LIB_EXPORT LookRotationToMatrix(const Vector3f& viewVec, const Vector3f& upVec, Matrix3x3f* m);

/**
 * @brief Transform a matrix into Euler angle.
 * 
 * @param matrix Input matrix.
 * @param v The vector that save the transform result.
 * @return true Sucessfully transforming.
 * @return false Failed to transform.
 */
bool GAIA_LIB_EXPORT MatrixToEuler(const Matrix3x3f& matrix, Vector3f& v);
/**
 * @brief Transform an Euler angle to matrix.
 * 
 * @param v Input Euler angle.
 * @param matrix The matrix that save the transform result.
 */
void GAIA_LIB_EXPORT EulerToMatrix(const Vector3f& v, Matrix3x3f& matrix);

/**
 * @brief Calculate the result of multiplication of vector3 v and current matrix.
 * 
 * @param v Input vector.
 * @return Vector3f Result vector.
 */
inline Vector3f Matrix3x3f::MultiplyVector3(const Vector3f& v) const
{
    Vector3f res;
    res.x = m_Data[0] * v.x + m_Data[3] * v.y + m_Data[6] * v.z;
    res.y = m_Data[1] * v.x + m_Data[4] * v.y + m_Data[7] * v.z;
    res.z = m_Data[2] * v.x + m_Data[5] * v.y + m_Data[8] * v.z;
    return res;
}

/**
 * @brief Calculate the result of multiplication of vector3 v and current matrix, set result to output.
 * 
 * @param v Input vector.
 * @param output Result vector.
 */
inline void Matrix3x3f::MultiplyVector3(const Vector3f& v, Vector3f& output) const
{
    output.x = m_Data[0] * v.x + m_Data[3] * v.y + m_Data[6] * v.z;
    output.y = m_Data[1] * v.x + m_Data[4] * v.y + m_Data[7] * v.z;
    output.z = m_Data[2] * v.x + m_Data[5] * v.y + m_Data[8] * v.z;
}

/**
 * @brief Calculate the result of multiplication of transposed vector3 v and current matrix.
 * 
 * @param v Input vector.
 * @return Vector3f Transposed result vector.
 */
inline Vector3f Matrix3x3f::MultiplyVector3Transpose(const Vector3f& v) const
{
    Vector3f res;
    res.x = Get(0, 0) * v.x + Get(1, 0) * v.y + Get(2, 0) * v.z;
    res.y = Get(0, 1) * v.x + Get(1, 1) * v.y + Get(2, 1) * v.z;
    res.z = Get(0, 2) * v.x + Get(1, 2) * v.y + Get(2, 2) * v.z;
    return res;
}

/**
 * @brief Set value of elements in target row with v.
 *
 * @param row The index of target row.
 * @param v The value to set.
 */
inline void Matrix3x3f::SetRow(int row, const Vector3f& v)
{
    Get(row, 0) = v.x;
    Get(row, 1) = v.y;
    Get(row, 2) = v.z;
}

/**
 * @brief Set value of elements in target column with v.
 *
 * @param col The index of target column.
 * @param v The value to set.
 */
inline void Matrix3x3f::SetColumn(int col, const Vector3f& v)
{
    Get(0, col) = v.x;
    Get(1, col) = v.y;
    Get(2, col) = v.z;
}

/**
 * @brief Comparison of Matrix3x3
 * 
 * @param lhs left ref
 * @param rhs right ref
 * @param dist distance
 * @return true :equal
 * @return false :not equal
 */
bool GAIA_LIB_EXPORT CompareApproximately(const Matrix3x3f& lhs, const Matrix3x3f& rhs, float dist = Vector3f::epsilon());

/**
 * @brief Orthonormalizes the matrix.
 * 
 * @param matrix Input matrix to orthonormalizes.
 */
void GAIA_LIB_EXPORT OrthoNormalize(Matrix3x3f& matrix);

NAMESPACE_AMAZING_ENGINE_END
