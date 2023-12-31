/**
 * @file AMGMatrix4x4.h
 * @author fanjiaqi (fanjiaqi.837@bytedance.com)
 * @brief 4X4 Matrix Definition for Math Calculation.
 * @version 0.1
 * @date 2019-12-05
 * 
 * @copyright Copyright (c) 2019
 * 
 */
#ifndef MATRIX4X4_H
#define MATRIX4X4_H

#include "Gaia/Math/AMGVector3.h"
#include "Gaia/Math/AMGVector4.h"

NAMESPACE_AMAZING_ENGINE_BEGIN

class Matrix3x3f;
class Matrix4x4f;
class Quaternionf;

/**
 * @brief The definition of transform type.
 * 
 */
enum TransformType
{
    kNoScaleTransform = 0,
    kUniformScaleTransform = 1 << 0,
    kNonUniformScaleTransform = 1 << 1,
    kOddNegativeScaleTransform = 1 << 2
};
//ENUM_FLAGS(TransformType);

/**
 * @brief Judge whether input type is NoScaleTransform,
 * 
 * @param type Input type.
 * @return true Current input type is NoScaleTransform.
 * @return false Current input type is not NoScaleTransform.
 */
inline bool IsNoScaleTransform(TransformType type)
{
    return type == kNoScaleTransform;
}

/**
 * @brief Judge whether input type is NonUniformScaleTransform.
 * 
 * @param type Input type.
 * @return true Current input type is NonUniformScaleTransform.
 * @return false Current input type is not NonUniformScaleTransform.
 */
inline bool IsNonUniformScaleTransform(TransformType type)
{
    return (type & kNonUniformScaleTransform) != 0;
}

/**
 * @brief Return the type of current input transform matrix.
 * 
 * @param matrix Current input transform matrix.
 * @param outUniformScale The value of scale if the type is UniformScaleTransform.
 * @param epsilon The max error to decide two floats equal.
 * @return TransformType The transform type of input matrix.
 */
TransformType GAIA_LIB_EXPORT ComputeTransformType(const Matrix4x4f& matrix, float& outUniformScale, float epsilon = Vector3f::epsilon());

/**
 * @brief Invert matrix m.
 * 
 * @param m The data address of input matrix.
 * @param out The adress to store inverse matrix if the input has inverse matrix.
 * @return true The input matrix has inverse matrix.
 * @return false The input matrix does not have inverse matrix.
 */
bool GAIA_LIB_EXPORT InvertMatrix4x4_Full(const float* m, float* out);

/**
 * @brief Invert 3D transformation matrix (not perspective).
 * 
 * @param m The data address of input matrix.
 * @param out The address to store inverse matrix if the input has inverse matrix.
 * @return true The input matrix has inverse matrix.
 * @return false The input matrix does not have inverse matrix.
 */
bool GAIA_LIB_EXPORT InvertMatrix4x4_General3D(const float* m, float* out);

/// Matrices in unity are column major.
class GAIA_LIB_EXPORT Matrix4x4f
{
public:
    /**
     * @brief The array to store data of current matrix.
     * 
     */
    float m_Data[16] = {1.f, 0.f, 0.f, 0.f, 0.f, 1.f, 0.f, 0.f, 0.f, 0.f, 1.f, 0.f, 0.f, 0.f, 0.f, 1.f};

    ///@todo: Can't be Transfer optimized because Transfer doesn't write the same as memory layout
    //	DECLARE_SERIALIZE_NO_PPTR (Matrix4x4f)
    /**
     * @brief Construct a new Matrix4x4 object
     * 
     */
    Matrix4x4f() {}

    /**
     * @brief Construct a new Matrix4x4 object from other matrix.
     * 
     * @param other Other matrix.
     */
    Matrix4x4f(const Matrix3x3f& other);

    /**
     * @brief Construct a new Matrix4x4 object from data array.
     * 
     * @param data The adress of data array.
     */
    explicit Matrix4x4f(const float data[16]);

    /**
     * @brief Get the data at position [row, column].
     * 
     * @param row The row index, from 0~3.
     * @param column The column index, from 0~3.
     * @return float& The reference to data at position [row, column].
     */
    float& Get(int row, int column)
    {
        if (row < 0 || row > 3)
        {
            return m_Data[0];
        }
        if (column < 0 || column > 3)
        {
            return m_Data[0];
        }
        return m_Data[row + (column * 4)];
    }

    /**
     * @brief Get the data at position [row, column].
     * 
     * @param row The row index, from 0~3.
     * @param column The column index, from 0~3.
     * @return const float& The reference to data at position [row, column].
     */
    const float& Get(int row, int column) const
    {
        if (row < 0 || row > 3)
        {
            return m_Data[0];
        }
        if (column < 0 || column > 3)
        {
            return m_Data[0];
        }
        return m_Data[row + (column * 4)];
    }

    /**
     * @brief Get the address of data array.
     * 
     * @return float* The address of data array.
     */
    float* GetPtr() { return m_Data; }

    /**
     * @brief Get the adress of data array.
     * 
     * @return const float* The address of data array.
     */
    const float* GetPtr() const { return m_Data; }

    /**
     * @brief Overload operator[]. Get the data at position index.
     * 
     * @param index The input position index.
     * @return float The data at position index.
     */
    float operator[](int index) const { return m_Data[index]; }

    /**
     * @brief Overload operator[]. Get the data at position index.
     * 
     * @param index The input position index.
     * @return float& The data at position index.
     */
    float& operator[](int index) { return m_Data[index]; }

    /**
     * @brief Overload operator*=. Set current matrix to the result of multiplication of inM and current matrix. 
     * 
     * @param inM Input matrix to multiply current matrix.
     * @return Matrix4x4f& Reference to current matrix, *this.
     */
    Matrix4x4f& operator*=(const Matrix4x4f& inM);

    /** 
     * @brief Overload operator=. First current matrix to identity matrix and then set the value of left top 3x3matrix to m.
     * 
     * @param m Input 3X3 matrix.
     * @return Matrix4x4f& Reference to current matrix, *this.
     */
    Matrix4x4f& operator=(const Matrix3x3f& m);

    /**
     * @brief Multiply left-top 3X3 matrix of current matrix with inV.
     * 
     * @param inV Input vector3.
     * @return Vector3f The result of multiplication.
     */
    Vector3f MultiplyVector3(const Vector3f& inV) const;

    /**
     * @brief Multiply left-top 3X3 matrix of current matrix with inV.
     * 
     * @param inV Input vector3.
     * @param output Output vector3.
     */
    void MultiplyVector3(const Vector3f& inV, Vector3f& output) const;

    /**
     * @brief Multiply current matrix with inV perspectively.
     * 
     * @param inV Input vector3 to multiply.
     * @param output Output vector3 to store result.
     * @return true The foruth item of result vector4 is not 0.
     * @return false The fourth item of result vector4 is 0.
     */
    bool PerspectiveMultiplyVector3(const Vector3f& inV, Vector3f& output) const;

    /**
     * @brief Multiply left-top 3X3 matrix of current matrix with inV.
     * 
     * @param inV Input vector3.
     * @return Vector3f The result of multiplication.
     */
    Vector3f MultiplyPoint3(const Vector3f& inV) const;

    /**
     * @brief Multiply left-top 3X3 matrix of current matrix with inV.
     * 
     * @param inV Input vector3.
     * @param output Output vector3.
     */
    void MultiplyPoint3(const Vector3f& inV, Vector3f& output) const;

    /**
     * @brief Multiply current matrix with inV perspectively.
     * 
     * @param inV Input vector3 to multiply.
     * @param output Output vector3 to store result.
     * @return true The foruth item of result vector4 is not 0.
     * @return false The fourth item of result vector4 is 0.
     */
    bool PerspectiveMultiplyPoint3(const Vector3f& inV, Vector3f& output) const;

    /**
     * @brief The fourth row subtract inV to get new vector3, and then multiply left-top 3X3 matrix of current transposed matrix with the new vector.
     * 
     * @param inV Input vector3 to multiply.
     * @return Vector3f The result of multiplication.
     */
    Vector3f InverseMultiplyPoint3Affine(const Vector3f& inV) const;

    /**
     * @brief Multiply left-top 3X3 matrix of current transposed matrix with inV.
     * 
     * @param inV Input vector3 to multiply.
     * @return Vector3f The result of multiplication.
     */
    Vector3f InverseMultiplyVector3Affine(const Vector3f& inV) const;

    /**
     * @brief Multiply current matrix with inV.
     * 
     * @param inV Input vector4 to multiply.
     * @return Vector4f The result of multiplication.
     */
    Vector4f MultiplyVector4(const Vector4f& inV) const;

    /**
     * @brief Multiply current matrix with inV, and then store the result to output.
     * 
     * @param inV Input vector4 to multiply.
     * @param output The result of multiplication.
     */
    void MultiplyVector4(const Vector4f& inV, Vector4f& output) const;

    /**
     * @brief Judge whether current matrix is an identity matrix.
     * 
     * @param epsilon The max distance of two floats which are Considered equal.
     * @return true Current matrix is an identity matrix.
     * @return false Current matrix is not an identity matrix.
     */
    bool IsIdentity(float epsilon = Vector3f::epsilon()) const;

    /**
     * @brief Get the determinant of current matrix.
     * 
     * @return double The value of determinant of current matrix.
     */
    double GetDeterminant() const;

    /**
     * @brief Invert current matrix if it has an inverse matrix.
     * 
     * @return Matrix4x4f& Reference of current matrix, *this.
     */
    Matrix4x4f& Invert_Full()
    {
        InvertMatrix4x4_Full(m_Data, m_Data);
        return *this;
    }

    /**
     * @brief Get the inverse matrix of inM and store the result ot outM.
     * 
     * @param inM The input matrix to invert.
     * @param outM The ouput matrix to store the inverse matrix of inM.
     * @return true The input matrix inM has an inverse matrix.
     * @return false The input matrix inM does not have an inverse matrix.
     */
    static bool Invert_Full(const Matrix4x4f& inM, Matrix4x4f& outM)
    {
        return InvertMatrix4x4_Full(inM.m_Data, outM.m_Data);
    }

    /**
     * @brief Invert 3D transformation matrix(left-top 3X3 matrix) of inM and store the result ot outM.
     * 
     * @param inM The input matrix to invert.
     * @param outM The output matrix to store the result.
     * @return true The 3D transformation matrix of inM has an inverse matrix.
     * @return false The 3D transformation matrix of inM does not have an inverse matrix.
     */
    static bool Invert_General3D(const Matrix4x4f& inM, Matrix4x4f& outM)
    {
        return InvertMatrix4x4_General3D(inM.m_Data, outM.m_Data);
    }

    /**
     * @brief Transpos current matrix.
     * 
     * @return Matrix4x4f& Reference to current matrix, *this.
     */
    Matrix4x4f& Transpose();

    /**
     * @brief Copy the data of inM to current matrix.
     * 
     * @param inM Input matrix to copy.
     * @return Matrix4x4f& Reference to current matrix, *this.
     */
    Matrix4x4f& Copy(const Matrix4x4f& inM);

    /**
     * @brief Set current matrix to identity matrix.
     * 
     * @return Matrix4x4f& Reference to current matrix, *this.
     */
    Matrix4x4f& SetIdentity();

    /**
     * @brief Set current matrix to a perspective projection matrix with parameter.
     * 
     * @param fovy Field of view.
     * @param aspect Aspect ratio.
     * @param zNear Z value of near clipping plane.
     * @param zFar Z value of far clipping plane.
     * @return Matrix4x4f& Reference to current matrix, *this.
     */
    Matrix4x4f& SetPerspective(float fovy, float aspect, float zNear, float zFar);

    /**
     * @brief Set current matrix to a perspective projection matrix with parameter.
     * 
     * @param cotanHalfFOV Cotan value of field of view angle.
     * @param zNear Z value of near clipping plane.
     * @param zFar Z value of far clipping plane.
     * @return Matrix4x4f& Reference to current matrix, *this.
     */
    Matrix4x4f& SetPerspectiveCotan(float cotanHalfFOV, float zNear, float zFar);

    /**
     * @brief Set current matrix to a orthogonal projection matrix with parameter.
     * 
     * @param left Coordinate of left clipping plane.
     * @param right Coordinate of right clipping plane.
     * @param bottom Coordinate of bottom clipping plane.
     * @param top Coordinate of top clipping plane.
     * @param zNear Z value of near clipping plane.
     * @param zFar Z value of far clipping plane.
     * @return Matrix4x4f& Reference to current matrix, *this.
     */
    Matrix4x4f& SetOrtho(float left, float right, float bottom, float top, float zNear, float zFar);

    /**
     * @brief Set current matrix to a perspective projection matrix with parameter of frustum.
     * 
     * @param left Coordinate of left border of near clipping plane.
     * @param right Coordinate of right border of near clipping plane.
     * @param bottom Coordinate of bottom border of near clipping plane.
     * @param top Coordinate of top border of near clipping plane.
     * @param nearval Z value of near clipping plane.
     * @param farval Z value of far clipping plane.
     * @return Matrix4x4f& Reference of current matrix, *this.
     */
    Matrix4x4f& SetFrustum(float left, float right, float bottom, float top, float nearval, float farval);

    /**
     * @brief Get first 3 elements of first columm.
     * 
     * @return Vector3f The first 3 elements of first column.
     */
    Vector3f GetAxisX() const;

    /**
     * @brief Get first 3 elements of second columm.
     * 
     * @return Vector3f The first 3 elements of second column.
     */
    Vector3f GetAxisY() const;

    /**
     * @brief Get first 3 elements of third column.
     * 
     * @return Vector3f The first 3 elements of third column.
     */
    Vector3f GetAxisZ() const;

    /**
     * @brief Get first 3 elements of fourth column.
     * 
     * @return Vector3f The first 3 elements of fourth column.
     */
    Vector3f GetPosition() const;

    /**
     * @brief Get 4 elements of target row.
     * 
     * @param row Target row index.
     * @return Vector4f The elements of target row.
     */
    Vector4f GetRow(int row) const;

    /**
     * @brief Get 4 elements of target column.
     * 
     * @param col Target column index.
     * @return Vector4f The elements of target column.
     */
    Vector4f GetColumn(int col) const;
    // these set only these components of the matrix, everything else is untouched!

    /**
     * @brief Set first 3 elements of first column.
     * 
     * @param v The value to set.
     */
    void SetAxisX(const Vector3f& v);

    /**
     * @brief Set first  3 elements of second column.
     * 
     * @param v The value to set.
     */
    void SetAxisY(const Vector3f& v);

    /**
     * @brief Set first 3 elements of third column.
     * 
     * @param v The value to set.
     */
    void SetAxisZ(const Vector3f& v);

    /**
     * @brief Set first 3 element of fourth column.
     * 
     * @param v The value to set.
     */
    void SetPosition(const Vector3f& v);

    /**
     * @brief Set value of elements in target row with v.
     * 
     * @param row The index of target row.
     * @param v The value to set.
     */
    void SetRow(int row, const Vector4f& v);

    /**
     * @brief Set value of elements in target column with v.
     * 
     * @param col The index of target column.
     * @param v The value to set.
     */
    void SetColumn(int col, const Vector4f& v);

    /**
     * @brief Set current matrix to a translate matrix which represents translation vector inTrans.
     * 
     * @param inTrans Translate vector.
     * @return Matrix4x4f& The referenece of current matrix, *this.
     */
    Matrix4x4f& SetTranslate(const Vector3f& inTrans);

    /**
     * @brief Set current matrix to a matrix which contains normalized orthogonal basis inX, inY and inZ.
     * 
     * @param inX The first basis of orthogonal basis.
     * @param inY The second basis of orthogonal basis.
     * @param inZ The third basis of orthogonal basis.
     * @return Matrix4x4f& The reference of current matrix, *this.
     */
    Matrix4x4f& SetOrthoNormalBasis(const Vector3f& inX, const Vector3f& inY, const Vector3f& inZ);

    /**
     * @brief Set current matrix to a mtrix which contains inversed normalized orthogonal basis inX, inY and inZ.
     * 
     * @param inX The first basis of orthogonal basis.
     * @param inY The second basis of orthogonal basis.
     * @param inZ The third basis of orthogonal basis.
     * @return Matrix4x4f& The reference of current matrix, *this.
     */
    Matrix4x4f& SetOrthoNormalBasisInverse(const Vector3f& inX, const Vector3f& inY, const Vector3f& inZ);

    /**
     * @brief Set current matrix to a scaling matrix with scaling factor inScale.
     * 
     * @param inScale Scaling factor.
     * @return Matrix4x4f& The reference of current matrix, *this.
     */
    Matrix4x4f& SetScale(const Vector3f& inScale);

    /**
     * @brief Set current matrix to a matrix which contains normalized orthogonal basis inX, inY and inZ and also represents translation vector inPosition.
     * 
     * @param inPosition Translate vector.
     * @param inX The first basis of orthogonal basis.
     * @param inY The second basis of orthogonal basis.
     * @param inZ The third basis of orthogonal basis.
     * @return Matrix4x4f& The rederence of current matrix, *this.
     */
    Matrix4x4f& SetPositionAndOrthoNormalBasis(const Vector3f& inPosition, const Vector3f& inX, const Vector3f& inY, const Vector3f& inZ);

    /**
     * @brief Transform current matrix with translate vector inTrans.
     * 
     * @param inTrans Translate vector.
     * @return Matrix4x4f& The reference of current matrix, *this.
     */
    Matrix4x4f& Translate(const Vector3f& inTrans);

    /**
     * @brief Add the translation part of current matrix with inTrans.
     * 
     * @param inTrans Translation vector.
     * @return Matrix4x4f& The reference of current matrix, *this.
     */
    Matrix4x4f& AddTranslate(const Vector3f& inTrans);

    /**
     * @brief Transform current matrix with scaling vector inScale.
     * 
     * @param inScale Scaling vector.
     * @return Matrix4x4f& The reference of current matrix, *this.
     */
    Matrix4x4f& Scale(const Vector3f& inScale);

    /**
     * @brief Set current matrix to a rotation matrix that rotates a vector called "from" into another vector called "to".
     * 
     * @param from The "from" vector.
     * @param to The "to" vector.
     * @return Matrix4x4f& The rederence of current matrix, *this.
     */
    Matrix4x4f& SetFromToRotation(const Vector3f& from, const Vector3f& to);

    /**
     * @brief Set current matrix with translate vector pos and rotation quaternion q.
     * 
     * @param pos Translate vector.
     * @param q Rotation quaternion.
     */
    void SetTR(const Vector3f& pos, const Quaternionf& q);

    /**
     * @brief Set current matrix with translate vector pos, rotation quaternion q and scaling vector s.
     * 
     * @param pos Translate vector.
     * @param q Rotation quaternion.
     * @param s Scaling vector.
     */
    void SetTRS(const Vector3f& pos, const Quaternionf& q, const Vector3f& s);

    /**
     * @brief Set current matrix with translate vector pos, rotation quaternion q, scaling vector s and skewing vector skew.
     *
     * @param pos Translate vector.
     * @param q Rotation quaternion.
     * @param s Scaling vector.
     * @param skew Skewing vector.
     */
    void SetTRSS(const Vector3f& pos, const Quaternionf& q, const Vector3f& s, const Vector3f& skew);

    /**
     * @brief Set current matrix with inverse of translate vector pos and inverse of rotation quaternion q.
     * 
     * @param pos Translate vector.
     * @param q Rotation quaternion.
     */
    void SetTRInverse(const Vector3f& pos, const Quaternionf& q);

    /**
     * @brief Decompose current matrix into translate vector pos, scaling vector scale and rotation quaternion quat.
     * 
     * @param pos The decomposed translate vector.
     * @param scale The decomposed scaling vector.
     * @param quat The decomposed rotation quaternion.
     */
    void getDecompose(Vector3f* pos, Vector3f* scale, Quaternionf* quat) const;

    /**
     * @brief Decompose current matrix into translate vector pos, scaling vector scale, rotation quaternion quat and shear vector skew.
     *
     * @param pos The decomposed translate vector.
     * @param scale The decomposed scaling vector.
     * @param quat The decomposed rotation quaternion.
     * @param skew The decomposed skewing vector.
     */
    void getDecompose(Vector3f* pos, Vector3f* scale, Quaternionf* quat, Vector3f* skew) const;

    /**
     * @brief Identity matrix.
     * 
     */
    static const Matrix4x4f& identity();

    /**
     * @brief Rotate specified axis so that it collinear with the provided one.
     *
     * @param axisId specify the axis you wanna change.
     * @param axis spcecify target direction. axis can be of any length.
     */
    void alignAxisWith(int axisId, Vector3f const& axis);
};

/**
 * @brief Judge the data of two matrixs equal to each other.
 * 
 * @param lhs Input left matrix to judge.
 * @param rhs Input right matrix to judge.
 * @param dist The max distance to regard two floats are same to each other.
 * @return true The data of two matrixs equal to each other.
 * @return false The data of two matrixs do not equal to each other. 
 */
bool GAIA_LIB_EXPORT CompareApproximately(const Matrix4x4f& lhs, const Matrix4x4f& rhs, float dist = Vector3f::epsilon());

/**
 * @brief Transforms an array of vertices.
 * 
 * @param matrix Tranformation matrix and left-top 3x3 matrix will be used.
 * @param input The address of the array of input vertices.
 * @param ouput The address of the array of output vertices.
 * @param count The number of the array of input vertices.
 */
void GAIA_LIB_EXPORT TransformPoints3x3(const Matrix4x4f& matrix, const Vector3f* input, Vector3f* ouput, int count);

/**
 * @brief Transform an array of vertices.
 * 
 * @param matrix Transformation matrix and top 3X4 matrix will be used.
 * @param input The address of the array of input vertices.
 * @param ouput The address of the array of output vertices.
 * @param count The number of the array of input vertices.
 */
void GAIA_LIB_EXPORT TransformPoints3x4(const Matrix4x4f& matrix, const Vector3f* input, Vector3f* ouput, int count);

/**
 * @brief Transform an array of vertices.
 * 
 * @param matrix Tranformation matrix and left-top 3x3 matrix will be used.
 * @param input The address of the array of input vertices.
 * @param inStride The offset of input address.
 * @param ouput The address of the array of output vertices.
 * @param outStride The offset of output address.
 * @param count The number of the array of input vertices.
 */
void GAIA_LIB_EXPORT TransformPoints3x3(const Matrix4x4f& matrix, const Vector3f* input, size_t inStride, Vector3f* ouput, size_t outStride, int count);

/**
 * @brief Transform an array of vertices.
 * 
 * @param matrix Transformation matrix and top 3X4 matrix will be used.
 * @param input The address of the array of input vertices.
 * @param inStride The offset of input address.
 * @param ouput The address of the array of output vertices.
 * @param outStride The offset of output address.
 * @param count The number of the array of input vertices.
 */
void GAIA_LIB_EXPORT TransformPoints3x4(const Matrix4x4f& matrix, const Vector3f* input, size_t inStride, Vector3f* ouput, size_t outStride, int count);

/**
 * @brief Multiply the top 3x4 part of lhs and rhs and store the result in res.
 * 
 * @param lhs The input left matrix to multiply.
 * @param rhs The input right matrix to multiply.
 * @param res The matrix to store the result of multiplation.
 */
void GAIA_LIB_EXPORT MultiplyMatrices3x4(const Matrix4x4f& lhs, const Matrix4x4f& rhs, Matrix4x4f& res);

/**
 * @brief Multiply lhs and rhs anf then store the result in res.
 * 
 * @param lhs The input left matrix to multiply.
 * @param rhs The input right matrix to multiply.
 * @param res The matrix to store the reuslt of multiplation.
 */
inline void GAIA_LIB_EXPORT MultiplyMatrices4x4REF(const Matrix4x4f* __restrict lhs, const Matrix4x4f* __restrict rhs, Matrix4x4f* __restrict res)
{
    aeAssert(lhs && rhs && res);
    for (int i = 0; i < 4; i++)
    {
        res->m_Data[i] = lhs->m_Data[i] * rhs->m_Data[0] + lhs->m_Data[i + 4] * rhs->m_Data[1] + lhs->m_Data[i + 8] * rhs->m_Data[2] + lhs->m_Data[i + 12] * rhs->m_Data[3];
        res->m_Data[i + 4] = lhs->m_Data[i] * rhs->m_Data[4] + lhs->m_Data[i + 4] * rhs->m_Data[5] + lhs->m_Data[i + 8] * rhs->m_Data[6] + lhs->m_Data[i + 12] * rhs->m_Data[7];
        res->m_Data[i + 8] = lhs->m_Data[i] * rhs->m_Data[8] + lhs->m_Data[i + 4] * rhs->m_Data[9] + lhs->m_Data[i + 8] * rhs->m_Data[10] + lhs->m_Data[i + 12] * rhs->m_Data[11];
        res->m_Data[i + 12] = lhs->m_Data[i] * rhs->m_Data[12] + lhs->m_Data[i + 4] * rhs->m_Data[13] + lhs->m_Data[i + 8] * rhs->m_Data[14] + lhs->m_Data[i + 12] * rhs->m_Data[15];
    }
}
/**
 * @brief Copy the data from lhs to res.
 * 
 * @param lhs The matrix to copy data from.
 * @param res The matrix to copy data to.
 */
void GAIA_LIB_EXPORT CopyMatrixREF(const float* __restrict lhs, float* __restrict res);

/**
 * @brief Transpose input matrix lhs and store result in res.
 * 
 * @param lhs The matrix to transpose.
 * @param res The matrix to store the transposed result.
 */
void GAIA_LIB_EXPORT TransposeMatrix4x4REF(const Matrix4x4f* __restrict lhs, Matrix4x4f* __restrict res);

/**
 * @brief Multiply matrix array.
 * 
 * @param arrayA The address of input left matrix array to multiply.
 * @param arrayB The address of inpur right matrix array to multiply.
 * @param arrayRes The address of output matrix array to store the result of multiplation.
 * @param count The size of input matrix array.
 */
void GAIA_LIB_EXPORT MultiplyMatrixArray4x4REF(const Matrix4x4f* __restrict arrayA, const Matrix4x4f* __restrict arrayB,
                                               Matrix4x4f* __restrict arrayRes, size_t count);

/**
 * @brief Multiply matrix array. Foreach R[i] = BASE * A[i] * B[i]
 * 
 * @param base The address of input matrix array BASE.
 * @param arrayA The address of input matrix array arrayA.
 * @param arrayB The address of input matrix array arrayB.
 * @param arrayRes The address of output matrix array to store the result of multiplation.
 * @param count The size of input matrix array.
 */
void GAIA_LIB_EXPORT MultiplyMatrixArrayWithBase4x4REF(const Matrix4x4f* __restrict base,
                                                       const Matrix4x4f* __restrict arrayA, const Matrix4x4f* __restrict arrayB,
                                                       Matrix4x4f* __restrict arrayRes, size_t count);

#define CopyMatrix CopyMatrixREF
#define TransposeMatrix4x4 TransposeMatrix4x4REF
#define MultiplyMatrices4x4 MultiplyMatrices4x4REF
#define MultiplyMatrixArray4x4 MultiplyMatrixArray4x4REF
#define MultiplyMatrixArrayWithBase4x4 MultiplyMatrixArrayWithBase4x4REF

/**
 * @brief Get first 3 elements of first columm.
 * 
 * @return Vector3f The first 3 elements of first column.
 */
inline Vector3f Matrix4x4f::GetAxisX() const
{
    return Vector3f(Get(0, 0), Get(1, 0), Get(2, 0));
}

/**
 * @brief Get first 3 elements of second columm.
 * 
 * @return Vector3f The first 3 elements of second column.
 */
inline Vector3f Matrix4x4f::GetAxisY() const
{
    return Vector3f(Get(0, 1), Get(1, 1), Get(2, 1));
}

/**
 * @brief Get first 3 elements of third column.
 * 
 * @return Vector3f The first 3 elements of third column.
 */
inline Vector3f Matrix4x4f::GetAxisZ() const
{
    return Vector3f(Get(0, 2), Get(1, 2), Get(2, 2));
}

/**
 * @brief Get first 3 elements of fourth column.
 * 
 * @return Vector3f The first 3 elements of fourth column.
 */
inline Vector3f Matrix4x4f::GetPosition() const
{
    return Vector3f(Get(0, 3), Get(1, 3), Get(2, 3));
}

/**
 * @brief Get 4 elements of target row.
 * 
 * @param row Target row index.
 * @return Vector4f The elements of target row.
 */
inline Vector4f Matrix4x4f::GetRow(int row) const
{
    return Vector4f(Get(row, 0), Get(row, 1), Get(row, 2), Get(row, 3));
}

/**
 * @brief Get 4 elements of target column.
 * 
 * @param col Target column index.
 * @return Vector4f The elements of target column.
 */
inline Vector4f Matrix4x4f::GetColumn(int col) const
{
    return Vector4f(Get(0, col), Get(1, col), Get(2, col), Get(3, col));
}

/**
 * @brief Set first 3 elements of first column.
 * 
 * @param v The value to set.
 */
inline void Matrix4x4f::SetAxisX(const Vector3f& v)
{
    Get(0, 0) = v.x;
    Get(1, 0) = v.y;
    Get(2, 0) = v.z;
}

/**
 * @brief Set first  3 elements of second column.
 * 
 * @param v The value to set.
 */
inline void Matrix4x4f::SetAxisY(const Vector3f& v)
{
    Get(0, 1) = v.x;
    Get(1, 1) = v.y;
    Get(2, 1) = v.z;
}

/**
 * @brief Set first 3 elements of third column.
 * 
 * @param v The value to set.
 */
inline void Matrix4x4f::SetAxisZ(const Vector3f& v)
{
    Get(0, 2) = v.x;
    Get(1, 2) = v.y;
    Get(2, 2) = v.z;
}

/**
 * @brief Set first 3 element of fourth column.
 * 
 * @param v The value to set.
 */
inline void Matrix4x4f::SetPosition(const Vector3f& v)
{
    Get(0, 3) = v.x;
    Get(1, 3) = v.y;
    Get(2, 3) = v.z;
}

/**
 * @brief Set value of elements in target row with v.
 * 
 * @param row The index of target row.
 * @param v The value to set.
 */
inline void Matrix4x4f::SetRow(int row, const Vector4f& v)
{
    Get(row, 0) = v.x;
    Get(row, 1) = v.y;
    Get(row, 2) = v.z;
    Get(row, 3) = v.w;
}

/**
 * @brief Set value of elements in target column with v.
 * 
 * @param col The index of target column.
 * @param v The value to set.
 */
inline void Matrix4x4f::SetColumn(int col, const Vector4f& v)
{
    Get(0, col) = v.x;
    Get(1, col) = v.y;
    Get(2, col) = v.z;
    Get(3, col) = v.w;
}

/**
 * @brief Multiply left-top 3X3 matrix of current matrix with v.
 * 
 * @param v Input vector3.
 * @return Vector3f The result of multiplication.
 */
inline Vector3f Matrix4x4f::MultiplyPoint3(const Vector3f& v) const
{
    Vector3f res;
    res.x = m_Data[0] * v.x + m_Data[4] * v.y + m_Data[8] * v.z + m_Data[12];
    res.y = m_Data[1] * v.x + m_Data[5] * v.y + m_Data[9] * v.z + m_Data[13];
    res.z = m_Data[2] * v.x + m_Data[6] * v.y + m_Data[10] * v.z + m_Data[14];
    return res;
}

/**
 * @brief Multiply left-top 3X3 matrix of current matrix with v.
 * 
 * @param v Input vector3.
 * @param output Output vector3.
 */
inline void Matrix4x4f::MultiplyPoint3(const Vector3f& v, Vector3f& output) const
{
    output.x = m_Data[0] * v.x + m_Data[4] * v.y + m_Data[8] * v.z + m_Data[12];
    output.y = m_Data[1] * v.x + m_Data[5] * v.y + m_Data[9] * v.z + m_Data[13];
    output.z = m_Data[2] * v.x + m_Data[6] * v.y + m_Data[10] * v.z + m_Data[14];
}

/**
 * @brief Multiply left-top 3X3 matrix of current matrix with v.
 * 
 * @param v Input vector3.
 * @return Vector3f The result of multiplication.
 */
inline Vector3f Matrix4x4f::MultiplyVector3(const Vector3f& v) const
{
    Vector3f res;
    res.x = m_Data[0] * v.x + m_Data[4] * v.y + m_Data[8] * v.z;
    res.y = m_Data[1] * v.x + m_Data[5] * v.y + m_Data[9] * v.z;
    res.z = m_Data[2] * v.x + m_Data[6] * v.y + m_Data[10] * v.z;
    return res;
}

/**
 * @brief Multiply left-top 3X3 matrix of current matrix with v.
 * 
 * @param v Input vector3.
 * @param output Output vector3.
 */
inline void Matrix4x4f::MultiplyVector3(const Vector3f& v, Vector3f& output) const
{
    output.x = m_Data[0] * v.x + m_Data[4] * v.y + m_Data[8] * v.z;
    output.y = m_Data[1] * v.x + m_Data[5] * v.y + m_Data[9] * v.z;
    output.z = m_Data[2] * v.x + m_Data[6] * v.y + m_Data[10] * v.z;
}

/**
 * @brief Multiply current matrix with v.
 * 
 * @param v Input vector4 to multiply.
 * @return Vector4f The result of multiplication.
 */
inline Vector4f Matrix4x4f::MultiplyVector4(const Vector4f& v) const
{
    Vector4f res;
    res.x = m_Data[0] * v.x + m_Data[4] * v.y + m_Data[8] * v.z + m_Data[12] * v.w;
    res.y = m_Data[1] * v.x + m_Data[5] * v.y + m_Data[9] * v.z + m_Data[13] * v.w;
    res.z = m_Data[2] * v.x + m_Data[6] * v.y + m_Data[10] * v.z + m_Data[14] * v.w;
    res.w = m_Data[3] * v.x + m_Data[7] * v.y + m_Data[11] * v.z + m_Data[15] * v.w;
    return res;
}

/**
 * @brief Multiply current matrix with v, and then store the result to output.
 * 
 * @param v Input vector4 to multiply.
 * @param output The result of multiplication.
 */
inline void Matrix4x4f::MultiplyVector4(const Vector4f& v, Vector4f& output) const
{
    output.x = m_Data[0] * v.x + m_Data[4] * v.y + m_Data[8] * v.z + m_Data[12] * v.w;
    output.y = m_Data[1] * v.x + m_Data[5] * v.y + m_Data[9] * v.z + m_Data[13] * v.w;
    output.z = m_Data[2] * v.x + m_Data[6] * v.y + m_Data[10] * v.z + m_Data[14] * v.w;
    output.w = m_Data[3] * v.x + m_Data[7] * v.y + m_Data[11] * v.z + m_Data[15] * v.w;
}

/**
 * @brief Multiply current matrix with inV perspectively.
 * 
 * @param v Input vector3 to multiply.
 * @param output Output vector3 to store result.
 * @return true The foruth item of result vector4 is not 0.
 * @return false The fourth item of result vector4 is 0.
 */
inline bool Matrix4x4f::PerspectiveMultiplyPoint3(const Vector3f& v, Vector3f& output) const
{
    Vector3f res;
    float w;
    res.x = Get(0, 0) * v.x + Get(0, 1) * v.y + Get(0, 2) * v.z + Get(0, 3);
    res.y = Get(1, 0) * v.x + Get(1, 1) * v.y + Get(1, 2) * v.z + Get(1, 3);
    res.z = Get(2, 0) * v.x + Get(2, 1) * v.y + Get(2, 2) * v.z + Get(2, 3);
    w = Get(3, 0) * v.x + Get(3, 1) * v.y + Get(3, 2) * v.z + Get(3, 3);
    if (Abs(w) > 1.0e-7f)
    {
        float invW = 1.0f / w;
        output.x = res.x * invW;
        output.y = res.y * invW;
        output.z = res.z * invW;
        return true;
    }
    else
    {
        output.x = 0.0f;
        output.y = 0.0f;
        output.z = 0.0f;
        return false;
    }
}

/**
 * @brief Multiply current matrix with v perspectively.
 * 
 * @param v Input vector3 to multiply.
 * @param output Output vector3 to store result.
 * @return true The foruth item of result vector4 is not 0.
 * @return false The fourth item of result vector4 is 0.
 */
inline bool Matrix4x4f::PerspectiveMultiplyVector3(const Vector3f& v, Vector3f& output) const
{
    Vector3f res;
    float w;
    res.x = Get(0, 0) * v.x + Get(0, 1) * v.y + Get(0, 2) * v.z;
    res.y = Get(1, 0) * v.x + Get(1, 1) * v.y + Get(1, 2) * v.z;
    res.z = Get(2, 0) * v.x + Get(2, 1) * v.y + Get(2, 2) * v.z;
    w = Get(3, 0) * v.x + Get(3, 1) * v.y + Get(3, 2) * v.z;
    if (Abs(w) > 1.0e-7f)
    {
        float invW = 1.0f / w;
        output.x = res.x * invW;
        output.y = res.y * invW;
        output.z = res.z * invW;
        return true;
    }
    else
    {
        output.x = 0.0f;
        output.y = 0.0f;
        output.z = 0.0f;
        return false;
    }
}

/**
 * @brief The fourth row subtract inV to get new vector3, and then multiply left-top 3X3 matrix of current transposed matrix with the new vector.
 * 
 * @param inV Input vector3 to multiply.
 * @return Vector3f The result of multiplication.
 */
inline Vector3f Matrix4x4f::InverseMultiplyPoint3Affine(const Vector3f& inV) const
{
    Vector3f v(inV.x - Get(0, 3), inV.y - Get(1, 3), inV.z - Get(2, 3));
    Vector3f res;
    res.x = Get(0, 0) * v.x + Get(1, 0) * v.y + Get(2, 0) * v.z;
    res.y = Get(0, 1) * v.x + Get(1, 1) * v.y + Get(2, 1) * v.z;
    res.z = Get(0, 2) * v.x + Get(1, 2) * v.y + Get(2, 2) * v.z;
    return res;
}

/**
 * @brief Multiply left-top 3X3 matrix of current transposed matrix with v.
 * 
 * @param v Input vector3 to multiply.
 * @return Vector3f The result of multiplication.
 */
inline Vector3f Matrix4x4f::InverseMultiplyVector3Affine(const Vector3f& v) const
{
    Vector3f res;
    res.x = Get(0, 0) * v.x + Get(1, 0) * v.y + Get(2, 0) * v.z;
    res.y = Get(0, 1) * v.x + Get(1, 1) * v.y + Get(2, 1) * v.z;
    res.z = Get(0, 2) * v.x + Get(1, 2) * v.y + Get(2, 2) * v.z;
    return res;
}

/**
 * @brief Judge if matrix f is finite. A matrix is infite only when all data in matrix is finite.
 * 
 * @param f Input matrix to judge.
 * @return true The matrix is infinite.
 * @return false The matrix is not infinite.
 */
inline bool IsFinite(const Matrix4x4f& f)
{
    return IsFinite(f.m_Data[0]) & IsFinite(f.m_Data[1]) & IsFinite(f.m_Data[2]) &
           IsFinite(f.m_Data[4]) & IsFinite(f.m_Data[5]) & IsFinite(f.m_Data[6]) &
           IsFinite(f.m_Data[8]) & IsFinite(f.m_Data[9]) & IsFinite(f.m_Data[10]) &
           IsFinite(f.m_Data[12]) & IsFinite(f.m_Data[13]) & IsFinite(f.m_Data[14]) & IsFinite(f.m_Data[15]);
}

NAMESPACE_AMAZING_ENGINE_END

#endif
