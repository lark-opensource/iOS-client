#ifdef __cplusplus
#ifndef _BACH_OBJECT_H_
#define _BACH_OBJECT_H_

#include <stdint.h>
#include <string>
#include "Gaia/AMGPrimitiveVector.h"
#include "Gaia/AMGPrerequisites.h"
#include "Gaia/Math/AMGColor.h"
#include "Gaia/Math/AMGRect.h"
#include "Gaia/Math/AMGQuaternion.h"
#include "Bach/BachCommon.h"
#include "Bach/Base/BachAlgorithmGraphicsInfo.h"

NAMESPACE_BACH_BEGIN

enum class BachType
{
    NIL,
    INT,
    REAL,
    STRING,

    VEC2,
    VEC3,
    VEC4,

    MAT3,
    MAT4,

    QUAT,
    COLOR,
    RECT,

    INT8_VECTOR,
    INT16_VECTOR,
    INT32_VECTOR,
    INT64_VECTOR,

    UINT8_VECTOR,
    UINT16_VECTOR,
    UINT32_VECTOR,

    FLOAT_VECTOR,
    DOUBLE_VECTOR,

    STRING_VECTOR,

    VEC2_VECTOR,
    VEC3_VECTOR,
    VEC4_VECTOR,

    QUAT_VECTOR,

    MAT3_VECTOR,
    MAT4_VECTOR,

    GRAPHICS_INFO,

    MAP,
    VECTOR,
};

class BachMap;
class BachVector;
namespace proto
{
class Object;
}
class BACH_EXPORT BachObject
{
public:
    BachObject()
    {
        mType = BachType::NIL;
    }

    BachObject(const BachObject& other)
    {
        copyFrom(other);
    }

    BachObject(bool b)
    {
        mType = BachType::INT;
        u.i = b;
    }

    BachObject(int8_t i)
    {
        mType = BachType::INT;
        u.i = i;
    }

    BachObject(int16_t i)
    {
        mType = BachType::INT;
        u.i = i;
    }

    BachObject(int32_t i)
    {
        mType = BachType::INT;
        u.i = i;
    }

    BachObject(uint8_t i)
    {
        mType = BachType::INT;
        u.i = i;
    }

    BachObject(uint16_t i)
    {
        mType = BachType::INT;
        u.i = i;
    }

    BachObject(uint32_t i)
    {
        mType = BachType::INT;
        u.i = i;
    }

    BachObject(int64_t i)
    {
        mType = BachType::INT;
        u.i = i;
    }

    BachObject(float f)
    {
        mType = BachType::REAL;
        u.d = f;
    }

    BachObject(double d)
    {
        mType = BachType::REAL;
        u.d = d;
    }

    BachObject(const std::string& s)
    {
        mType = BachType::STRING;
        u.s = new std::string(s);
    }

    BachObject(const char* s)
    {
        mType = BachType::STRING;
        u.s = new std::string(s);
    }

    BachObject(char* s)
    {
        mType = BachType::STRING;
        u.s = new std::string(s);
    }

    BachObject(const AmazingEngine::Vector2f& o)
    {
        mType = BachType::VEC2;
        u.v2 = new AmazingEngine::Vector2f(o);
    }

    BachObject(const AmazingEngine::Vector3f& o)
    {
        mType = BachType::VEC3;
        u.v3 = new AmazingEngine::Vector3f(o);
    }

    BachObject(const AmazingEngine::Vector4f& o)
    {
        mType = BachType::VEC4;
        u.v4 = new AmazingEngine::Vector4f(o);
    }

    BachObject(const AmazingEngine::Matrix3x3f& o)
    {
        mType = BachType::MAT3;
        u.m3 = new AmazingEngine::Matrix3x3f(o);
    }

    BachObject(const AmazingEngine::Matrix4x4f& o)
    {
        mType = BachType::MAT4;
        u.m4 = new AmazingEngine::Matrix4x4f(o);
    }

    BachObject(const AmazingEngine::Quaternionf& o)
    {
        mType = BachType::QUAT;
        u.q = new AmazingEngine::Quaternionf(o);
    }

    BachObject(const AmazingEngine::Color& o)
    {
        mType = BachType::COLOR;
        u.color = new AmazingEngine::Color(o);
    }

    BachObject(const AmazingEngine::Rect& o)
    {
        mType = BachType::RECT;
        u.rect = new AmazingEngine::Rect(o);
    }

    BachObject(const AmazingEngine::Int8Vector& o)
    {
        mType = BachType::INT8_VECTOR;
        new (&u.i8arr) AmazingEngine::Int8Vector(o);
    }

    BachObject(const AmazingEngine::Int16Vector& o)
    {
        mType = BachType::INT16_VECTOR;
        new (&u.i16arr) AmazingEngine::Int16Vector(o);
    }

    BachObject(const AmazingEngine::Int32Vector& o)
    {
        mType = BachType::INT32_VECTOR;
        new (&u.i32arr) AmazingEngine::Int32Vector(o);
    }

    BachObject(const AmazingEngine::Int64Vector& o)
    {
        mType = BachType::INT64_VECTOR;
        new (&u.i64arr) AmazingEngine::Int64Vector(o);
    }

    BachObject(const AmazingEngine::UInt8Vector& o)
    {
        mType = BachType::UINT8_VECTOR;
        new (&u.u8arr) AmazingEngine::UInt8Vector(o);
    }

    BachObject(const AmazingEngine::UInt16Vector& o)
    {
        mType = BachType::UINT16_VECTOR;
        new (&u.u16arr) AmazingEngine::UInt16Vector(o);
    }

    BachObject(const AmazingEngine::UInt32Vector& o)
    {
        mType = BachType::UINT32_VECTOR;
        new (&u.u32arr) AmazingEngine::UInt32Vector(o);
    }

    BachObject(const AmazingEngine::FloatVector& o)
    {
        mType = BachType::FLOAT_VECTOR;
        new (&u.farr) AmazingEngine::FloatVector(o);
    }

    BachObject(const AmazingEngine::DoubleVector& o)
    {
        mType = BachType::DOUBLE_VECTOR;
        new (&u.darr) AmazingEngine::DoubleVector(o);
    }

    BachObject(const AmazingEngine::StringVector& o)
    {
        mType = BachType::STRING_VECTOR;
        new (&u.sarr) AmazingEngine::StringVector(o);
    }

    BachObject(const AmazingEngine::Vec2Vector& o)
    {
        mType = BachType::VEC2_VECTOR;
        new (&u.v2arr) AmazingEngine::Vec2Vector(o);
    }

    BachObject(const AmazingEngine::Vec3Vector& o)
    {
        mType = BachType::VEC3_VECTOR;
        new (&u.v3arr) AmazingEngine::Vec3Vector(o);
    }

    BachObject(const AmazingEngine::Vec4Vector& o)
    {
        mType = BachType::VEC4_VECTOR;
        new (&u.v4arr) AmazingEngine::Vec4Vector(o);
    }

    BachObject(const AmazingEngine::QuatVector& o)
    {
        mType = BachType::QUAT_VECTOR;
        new (&u.qarr) AmazingEngine::QuatVector(o);
    }

    BachObject(const AmazingEngine::Mat3Vector& o)
    {
        mType = BachType::MAT3_VECTOR;
        new (&u.m3arr) AmazingEngine::Mat3Vector(o);
    }

    BachObject(const AmazingEngine::Mat4Vector& o)
    {
        mType = BachType::MAT4_VECTOR;
        new (&u.m4arr) AmazingEngine::Mat4Vector(o);
    }

    BachObject(const Bach::GraphicsInfo& info)
    {
        mType = BachType::GRAPHICS_INFO;
        new (&u.graphicsInfo) Bach::GraphicsInfo();
        copyGraphicsInfo(info);
    }

    BachObject(const Bach::BachMap* info);

    BachObject(const Bach::BachVector* vec);

    ~BachObject()
    {
        reset();
    }

    BachObject& operator=(const BachObject& v)
    {
        if (this == &v)
        {
            return *this;
        }
        reset();
        copyFrom(v);
        return *this;
    }

    bool operator==(const BachObject& other)
    {
        return isEqual(other);
    }

    bool operator!=(const BachObject& other)
    {
        return !isEqual(other);
    }

    BachObject clone() const;

    bool isNil() const { return mType == BachType::NIL; }

    bool isInt() const { return mType == BachType::INT; }

    bool isReal() const { return mType == BachType::REAL; }

    bool isString() const { return mType == BachType::STRING; }

    bool isInt8Vector() const { return mType == BachType::INT8_VECTOR; }
    bool isInt16Vector() const { return mType == BachType::INT16_VECTOR; }
    bool isInt32Vector() const { return mType == BachType::INT32_VECTOR; }
    bool isInt64Vector() const { return mType == BachType::INT64_VECTOR; }

    bool isUInt8Vector() const { return mType == BachType::UINT8_VECTOR; }
    bool isUInt16Vector() const { return mType == BachType::UINT16_VECTOR; }
    bool isUInt32Vector() const { return mType == BachType::UINT32_VECTOR; }

    bool isFloatVector() const { return mType == BachType::FLOAT_VECTOR; }
    bool isDoubleVector() const { return mType == BachType::DOUBLE_VECTOR; }
    bool isStringVector() const { return mType == BachType::STRING_VECTOR; }

    bool isVec2Vector() const { return mType == BachType::VEC2_VECTOR; }
    bool isVec3Vector() const { return mType == BachType::VEC3_VECTOR; }
    bool isVec4Vector() const { return mType == BachType::VEC4_VECTOR; }
    bool isQuatVector() const { return mType == BachType::QUAT_VECTOR; }
    bool isMat3Vector() const { return mType == BachType::MAT3_VECTOR; }
    bool isMat4Vector() const { return mType == BachType::MAT4_VECTOR; }

    bool isVec2() const { return mType == BachType::VEC2; }
    bool isVec3() const { return mType == BachType::VEC3; }
    bool isVec4() const { return mType == BachType::VEC4; }
    bool isRect() const { return mType == BachType::RECT; }
    bool isQuat() const { return mType == BachType::QUAT; }
    bool isColor() const { return mType == BachType::COLOR; }

    bool isMat3() const { return mType == BachType::MAT3; }
    bool isMat4() const { return mType == BachType::MAT4; }

    bool isGraphicsInfo() const { return mType == BachType::GRAPHICS_INFO; }
    bool isMap() const { return mType == BachType::MAP; }
    bool isVector() const { return mType == BachType::VECTOR; }

    int32_t asInt32() const
    {
        return static_cast<int32_t>(asInt());
    }

    int64_t asInt() const
    {
        return operator int64_t();
    }

    double asReal() const
    {
        return operator double();
    }

    std::string asString() const
    {
        return operator std::string();
    }

    AmazingEngine::Int8Vector asInt8Vector() const
    {
        return operator AmazingEngine::Int8Vector();
    }

    AmazingEngine::Int16Vector asInt16Vector() const
    {
        return operator AmazingEngine::Int16Vector();
    }

    AmazingEngine::Int32Vector asInt32Vector() const
    {
        return operator AmazingEngine::Int32Vector();
    }

    AmazingEngine::Int64Vector asInt64Vector() const
    {
        return operator AmazingEngine::Int64Vector();
    }

    AmazingEngine::UInt8Vector asUInt8Vector() const
    {
        return operator AmazingEngine::UInt8Vector();
    }

    AmazingEngine::UInt16Vector asUInt16Vector() const
    {
        return operator AmazingEngine::UInt16Vector();
    }

    AmazingEngine::UInt32Vector asUInt32Vector() const
    {
        return operator AmazingEngine::UInt32Vector();
    }

    AmazingEngine::FloatVector asFloatVector() const
    {
        return operator AmazingEngine::FloatVector();
    }

    AmazingEngine::DoubleVector asDoubleVector() const
    {
        return operator AmazingEngine::DoubleVector();
    }

    AmazingEngine::StringVector asStringVector() const
    {
        return operator AmazingEngine::StringVector();
    }

    AmazingEngine::Vec2Vector asVec2Vector() const
    {
        return operator AmazingEngine::Vec2Vector();
    }

    AmazingEngine::Vec3Vector asVec3Vector() const
    {
        return operator AmazingEngine::Vec3Vector();
    }

    AmazingEngine::Vec4Vector asVec4Vector() const
    {
        return operator AmazingEngine::Vec4Vector();
    }

    AmazingEngine::QuatVector asQuatVector() const
    {
        return operator AmazingEngine::QuatVector();
    }

    AmazingEngine::Mat3Vector asMat3Vector() const
    {
        return operator AmazingEngine::Mat3Vector();
    }

    AmazingEngine::Mat4Vector asMat4Vector() const
    {
        return operator AmazingEngine::Mat4Vector();
    }

    AmazingEngine::Vector2f asVec2() const
    {
        return operator AmazingEngine::Vector2f();
    }

    AmazingEngine::Vector3f asVec3() const
    {
        return operator AmazingEngine::Vector3f();
    }

    AmazingEngine::Vector4f asVec4() const
    {
        return operator AmazingEngine::Vector4f();
    }
    AmazingEngine::Quaternionf asQuat() const
    {
        return operator AmazingEngine::Quaternionf();
    }

    AmazingEngine::Rect asRect() const
    {
        return operator AmazingEngine::Rect();
    }

    AmazingEngine::Color asColor() const
    {
        return operator AmazingEngine::Color();
    }

    AmazingEngine::Matrix3x3f asMat3() const
    {
        return operator AmazingEngine::Matrix3x3f();
    }

    AmazingEngine::Matrix4x4f asMat4() const
    {
        return operator AmazingEngine::Matrix4x4f();
    }

    const GraphicsInfo& getGraphicsInfo() const
    {
        return u.graphicsInfo;
    }

    GraphicsInfo& getGraphicsInfo()
    {
        return u.graphicsInfo;
    }

    BachMap* asMap() const
    {
        return operator BachMap*();
    }

    BachVector* asVector() const
    {
        return operator BachVector*();
    }

    operator int8_t() const;

    operator int16_t() const;

    operator int32_t() const;

    operator uint8_t() const;

    operator uint16_t() const;

    operator uint32_t() const;

    operator int64_t() const;

    operator float() const;

    operator double() const;

    operator std::string() const;

    operator AmazingEngine::Int8Vector() const;

    operator AmazingEngine::Int16Vector() const;

    operator AmazingEngine::Int32Vector() const;

    operator AmazingEngine::Int64Vector() const;

    operator AmazingEngine::UInt8Vector() const;

    operator AmazingEngine::UInt16Vector() const;

    operator AmazingEngine::UInt32Vector() const;

    operator AmazingEngine::FloatVector() const;

    operator AmazingEngine::DoubleVector() const;

    operator AmazingEngine::StringVector() const;

    operator AmazingEngine::Vec2Vector() const;

    operator AmazingEngine::Vec3Vector() const;

    operator AmazingEngine::Vec4Vector() const;

    operator AmazingEngine::QuatVector() const;

    operator AmazingEngine::Mat3Vector() const;

    operator AmazingEngine::Mat4Vector() const;

    operator AmazingEngine::Vector2f() const;

    operator AmazingEngine::Vector3f() const;

    operator AmazingEngine::Vector4f() const;

    operator AmazingEngine::Rect() const;

    operator AmazingEngine::Color() const;

    operator AmazingEngine::Quaternionf() const;

    operator AmazingEngine::Matrix3x3f() const;

    operator AmazingEngine::Matrix4x4f() const;

    operator BachMap*() const;

    operator BachVector*() const;

    BachType getType() const { return mType; }

private:
    friend bool operator==(const BachObject& a, const BachObject& b);
    friend bool operator!=(const BachObject& a, const BachObject& b);
    friend void BachObjectToPbObject(const BachObject& object, proto::Object& pbObject);
    friend void PbObjectToBachObject(const proto::Object& pbObject, BachObject& object);

    void reset();
    void copyFrom(const BachObject& other);
    bool isEqual(const BachObject& other) const;

    void copyGraphicsInfo(const GraphicsInfo& info);

    union Member
    {
        int64_t i;

        double d;

        std::string* s;

        AmazingEngine::Vector2f* v2;
        AmazingEngine::Vector3f* v3;
        AmazingEngine::Vector4f* v4;

        AmazingEngine::Matrix3x3f* m3;
        AmazingEngine::Matrix4x4f* m4;

        AmazingEngine::Quaternionf* q;
        AmazingEngine::Color* color;
        AmazingEngine::Rect* rect;

        AmazingEngine::Int8Vector i8arr;
        AmazingEngine::Int16Vector i16arr;
        AmazingEngine::Int32Vector i32arr;
        AmazingEngine::Int64Vector i64arr;

        AmazingEngine::UInt8Vector u8arr;
        AmazingEngine::UInt16Vector u16arr;
        AmazingEngine::UInt32Vector u32arr;

        AmazingEngine::FloatVector farr;
        AmazingEngine::DoubleVector darr;

        AmazingEngine::StringVector sarr;

        AmazingEngine::Vec2Vector v2arr;
        AmazingEngine::Vec3Vector v3arr;
        AmazingEngine::Vec4Vector v4arr;

        AmazingEngine::QuatVector qarr;

        AmazingEngine::Mat3Vector m3arr;
        AmazingEngine::Mat4Vector m4arr;

        Bach::GraphicsInfo graphicsInfo;
        Bach::BachMap* map;
        Bach::BachVector* vec;

        Member()
        {
        }
        ~Member()
        {
        }

    } u;
    BachType mType;
};

inline bool operator==(const BachObject& a, const BachObject& b)
{
    return a.isEqual(b);
}

inline bool operator!=(const BachObject& a, const BachObject& b)
{
    return !a.isEqual(b);
}
NAMESPACE_BACH_END

#endif

#endif