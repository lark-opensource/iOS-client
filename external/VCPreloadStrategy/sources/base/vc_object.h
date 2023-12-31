//
// Created by ByteDance on 2022/7/29.
//

#ifndef PRELOAD_SMART_TASK_OBJECT_H
#define PRELOAD_SMART_TASK_OBJECT_H

#include "vc_base.h"
#include "vc_json.h"
#include <unordered_map>

VC_NAMESPACE_BEGIN

enum ObjectType : int {
    OBJECT_NULL = 0,
    OBJECT_BOOL = 1,
    OBJECT_INT = 2,
    OBJECT_FLOAT = 3,
    OBJECT_STRING = 4,
    OBJECT_LIST = 5,
    OBJECT_DICT = 6,
    OBJECT_CLASS = 7,
    OBJECT_JSON = 8,
};

class Object : IVCPrintable {
public:
    Object(ObjectType type);

    bool isNull() {
        return mType == OBJECT_NULL;
    }

    bool isBool() {
        return mType == OBJECT_BOOL;
    }

    bool isInt() {
        return mType == OBJECT_INT;
    }

    bool isFloat() {
        return mType == OBJECT_FLOAT;
    }

    bool isString() {
        return mType == OBJECT_STRING;
    }

    bool isList() {
        return mType == OBJECT_LIST;
    }

    bool isDict() {
        return mType == OBJECT_DICT;
    }

    bool isClass() {
        return mType == OBJECT_CLASS;
    }

    bool isJson() {
        return mType == OBJECT_JSON;
    }

    virtual std::string TypeName() = 0;

    VCJson JSON();

    std::string toString() const override;

    const ObjectType mType;
};

class Null : public Object {
public:
    Null();

    virtual ~Null(){};

    virtual std::string TypeName() override;
};

class Bool : public Object {
public:
    Bool() = delete;

    Bool(bool b);

    virtual ~Bool(){};

    virtual std::string TypeName() override;

    bool data;
};

class Int : public Object {
public:
    Int() = delete;

    Int(int64_t i);

    virtual ~Int(){};

    virtual std::string TypeName() override;

    int64_t data;

public:
    inline bool operator<(const Int &o) const {
        return data < o.data;
    }

    inline bool operator<=(const Int &o) const {
        return data <= o.data;
    }

    inline bool operator>(const Int &o) const {
        return !(*this <= o);
    }

    inline Int operator+(const Int &o) {
        return Int(data + o.data);
    }

    inline Int operator-(const Int &o) {
        return Int(data - o.data);
    }

    inline Int &operator+=(const Int &o) {
        data += o.data;
        return *this;
    }

    inline Int &operator-=(const Int &o) {
        data -= o.data;
        return *this;
    }

    inline Int &operator+=(int64_t intVal) {
        data += intVal;
        return *this;
    }

    inline Int &operator-=(int64_t intVal) {
        data -= intVal;
        return *this;
    }
};

class Float : public Object {
public:
    Float() = delete;

    Float(double f);

    virtual ~Float(){};

    virtual std::string TypeName() override;

    double data;

public:
    inline bool operator<(const Float &o) const {
        return data < o.data;
    }

    inline bool operator<=(const Float &o) const {
        return data <= o.data;
    }

    inline bool operator>(const Float &o) const {
        return !(*this <= o);
    }

    inline Float operator+(const Float &o) {
        return Float(data + o.data);
    }

    inline Float operator-(const Float &o) {
        return Float(data - o.data);
    }

    inline Float &operator+=(const Float &o) {
        data += o.data;
        return *this;
    }

    inline Float &operator-=(const Float &o) {
        data -= o.data;
        return *this;
    }

    inline Float &operator+=(double doubleVal) {
        data += doubleVal;
        return *this;
    }

    inline Float &operator-=(double doubleVal) {
        data -= doubleVal;
        return *this;
    }
};

class String : public Object {
public:
    String() = delete;

    String(std::string s);

    virtual ~String(){};

    virtual std::string TypeName() override;

    std::string data;
};

class List : public Object {
public:
    List();

    virtual ~List() = default;

    virtual std::string TypeName() override;

    void Append(const std::shared_ptr<Object> &value);

    void Append(bool value);

    void Append(int value);

    void Append(long value);

    void Append(long long value);

    void Append(unsigned int value);

    void Append(unsigned long value);

    void Append(unsigned long long value);

    void Append(double value);

    void Append(const char *value);

    void Append(const std::string &value);

    void Extend(const std::shared_ptr<List> &list);

    void Set(unsigned int idx, const std::shared_ptr<Object> &value);

    void Set(unsigned int idx, bool value);

    void Set(unsigned int idx, int value);

    void Set(unsigned int idx, long value);

    void Set(unsigned int idx, long long value);

    void Set(unsigned int idx, unsigned int value);

    void Set(unsigned int idx, unsigned long value);

    void Set(unsigned int idx, unsigned long long value);

    void Set(unsigned int idx, double value);

    void Set(unsigned int idx, const char *value);

    void Set(unsigned int idx, const std::string &value);

    std::shared_ptr<Object> &
    operator[](unsigned int idx); // 越界不抛异常，务必小心

    std::shared_ptr<Object> Get(unsigned int idx); // 越界返回nullptr

    size_t Size() const;

    std::vector<std::shared_ptr<Object>> data;
};

class Dict : public Object {
public:
    Dict();

    virtual ~Dict(){};

    virtual std::string TypeName() override;

    std::shared_ptr<Object> &operator[](const std::string &key);

    bool Contain(const std::string &key);

    void Remove(const std::string &key);

    void Set(const std::string &key, const std::shared_ptr<Object> &value);

    void Set(const std::string &key, bool value);

    void Set(const std::string &key, int value);

    void Set(const std::string &key, long value);

    void Set(const std::string &key, long long value);

    void Set(const std::string &key, unsigned int value);

    void Set(const std::string &key, unsigned long value);

    void Set(const std::string &key, unsigned long long value);

    void Set(const std::string &key, float value);

    void Set(const std::string &key, double value);

    void Set(const std::string &key, const std::string &value);

    void Set(const std::string &key, const char *value);

    std::shared_ptr<Object> Get(const std::string &key) const; //
    // 无对应Key则返回nullptr
    // 以下方法内部会对Item类型进行校验，若不符合需求，则返回nullptr
    std::shared_ptr<Bool> GetBool(const std::string &key) const;
    bool getBoolValue(VCStrCRef key, bool dVal = false) const;

    std::shared_ptr<Int> GetInt(const std::string &key) const;
    int64_t getIntValue(VCStrCRef key, int64_t dVal = 0) const;

    std::shared_ptr<Float> GetFloat(const std::string &key) const;
    double getFloatValue(VCStrCRef key, double dVal = 0) const;

    std::shared_ptr<String> GetStr(const std::string &key) const;
    VCString getStringValue(VCStrCRef key, VCStrCRef dVal = VCString()) const;

    std::shared_ptr<List> GetList(const std::string &key);

    std::shared_ptr<Dict> GetDict(const std::string &key) const;

    // 合并另个Dict, 若存在相同key，则覆盖
    void Merge(const std::shared_ptr<Dict> &obj);

    size_t Size() const;

public:
    // data仅用于遍历，对数据进行增删操作请使用封装接口
    std::unordered_map<std::string, std::shared_ptr<Object>> data;
};

class ObjectJson : public Object {
public:
    ObjectJson() = delete;
    virtual ~ObjectJson() = default;

    ObjectJson(const VCJson &json);

    virtual std::string TypeName() override;

public:
    VCJson data;
};

namespace ObjectUtils {
extern bool getBoolValue(Object *o, bool dValue);
extern int64_t getIntValue(Object *o, int64_t dValue);
extern double getFloatValue(Object *o, double dValue);
extern VCString getStringValue(Object *o, VCStrCRef dValue);
} // namespace ObjectUtils

VC_NAMESPACE_END

#endif // PRELOAD_SMART_TASK_OBJECT_H
