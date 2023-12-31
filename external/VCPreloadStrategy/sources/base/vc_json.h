#pragma once
#ifndef PRELOAD_VC_JSON_H
#define PRELOAD_VC_JSON_H

#include "json.h"
#include "vc_base.h"

#include <memory>

VC_NAMESPACE_BEGIN

/**
 * @brief All-in-one json class for strategy center
 *
 * This is a wrapper of jsoncpp, without using exceptions.
 *
 * For method returning @c VCJson, a invalid value would be returned
 * to indicate errors. It is the caller's responsibility to check
 * @c isInvalid().
 */
class VCJson {
    template <typename Iterator>
    class IteratorImpl;

public:
    /// enum of json value types
    enum class ValueType : int8_t {
        Invalid = -1,
        Null,
        Object,
        Array,
        String,
        Bool,
        IntegerNumber,
        UnsignedNumber,
        RealNumber,
    };

    // Member types

    using size_type = size_t;
    // using reference = VCJson &;
    // using const_reference = const VCJson &;
    using iterator = IteratorImpl<Json::ValueIterator>;
    using const_iterator = IteratorImpl<Json::ValueConstIterator>;

    // Constructor/Destructor

    /// construct as type
    VCJson(ValueType type) {
        if (type == ValueType::Invalid) {
            mValue = nullptr;
        } else {
            mValue = std::make_shared<Json::Value>(TypeConvert(type));
        }
    }

    /// construct as null (default)
    VCJson(std::nullptr_t = nullptr) :
            mValue(std::make_shared<Json::Value>(Json::nullValue)) {}

    /// construct as value v
    template <typename CompatibleType,
              typename = typename std::enable_if<
                      std::is_constructible<Json::Value,
                                            CompatibleType>::value>::type>
    VCJson(CompatibleType v) : mValue(std::make_shared<Json::Value>(v)) {}

    /// copy construct
    VCJson(const VCJson &other) :
            mValue(std::make_shared<Json::Value>(*other.mValue)) {}

    /// move construct
    VCJson(VCJson &&other) noexcept : mValue(std::move(other.mValue)) {}

    ~VCJson() = default;

    // Assignments

    /// copy assignment
    VCJson &operator=(const VCJson &other);
    /// undefined move assignment: force copy
    // VCJson &operator=(VCJson &&other) = delete;

    // Iterators

    iterator begin();
    const_iterator begin() const;
    const_iterator cbegin() const;
    iterator end();
    const_iterator end() const;
    const_iterator cend() const;
    /*
    iterator rbegin();
    const_iterator rbegin() const;
    const_iterator crbegin() const;
    iterator rend();
    const_iterator rend() const;
    const_iterator crend() const;
    */

    // Capacity

    /**
     * Return true if empty array, empty object, or null;
     * otherwise, false.
     */
    bool empty() const;
    size_type size() const;

    // Observers

    ValueType type() const;
    VCString typeName() const;
    bool isNull() const;
    bool isObject() const;
    bool isArray() const;
    bool isString() const;
    bool isBool() const;
    bool isNumber() const;
    bool isIntegerNumber() const;
    bool isUnsignedNumber() const;
    bool isRealNumber() const;
    bool isInvalid() const;

    template <ValueType type>
    bool is() const;

    // Lookup

    /*
    iterator find(VCStrCRef key);
    const_iterator find(VCStrCRef key) const;
    */
    /**
     * Check if object contains specified key.
     * return @c false if not @c isObject().
     */
    bool contains(VCStrCRef key) const;

    // Modifiers

    /**
     * Clear the content of json. Invalid value will become null afterwards.
     * Does not change json type otherwise.
     */
    void clear() noexcept;

    /**
     * Append @c val to json array.
     * No effect if type is not @c ValueType::Array or @c ValueType::Null.
     * @param val value to append
     * @return whether @c val is actually appended
     */
    bool append(const VCJson &val);

    // Element access

    /**
     * WARNING: returning by VALUE instead of by reference is COUNTERINTUITIVE.
     * Because we do not own a sub-object of type VCJson, it is impossible to
     * return by reference. Caller should pay extra attention here.
     */

    /**
     * Returns the mapped value of key.
     * If no such key exists, an invalid value is returned.
     */
    VCJson at(VCStrCRef key);
    /**
     * Returns the mapped value of key.
     * If no such key exists, an invalid value is returned.
     */
    const VCJson at(VCStrCRef key) const;
    /**
     * Returns the mapped value of key.
     * If no such key exists, a null value is silently inserted.
     */
    VCJson operator[](VCStrCRef key);
    // VCJson operator[](VCStrCRef key) const;

    VCJson at(size_type idx);
    const VCJson at(size_type idx) const;
    VCJson operator[](size_type idx);
    const VCJson operator[](size_type idx) const;

    /**
     * Returns value of type @c T mapped by key.
     * @c defaultValue is returned if key not found,
     * or value is inconvertible to @c T.
     */
    template <typename T>
    T value(VCStrCRef key, const T &defaultValue) const {
        if (mValue == nullptr) {
            LOGW("[VCJson] value: calling on invalid value");
            return defaultValue;
        }
        if (!mValue->isObject() && !mValue->isNull()) {
            LOGE("[VCJson] value: calling on wrong value type: %s",
                 TypeName(TypeConvert(mValue->type())).c_str());
            return defaultValue;
        }
        Json::Value res = mValue->get(key, defaultValue);
        if (JsonIsHelper<T>(res) || JsonIsConvertible<T>(res))
            return JsonAsHelper<T>(res);
        else {
            LOGE("[VCJson] value: gotten type %s differs from T",
                 TypeName(TypeConvert(res.type())).c_str());
            return defaultValue;
        }
    }

    inline VCString value(VCStrCRef key, const char *defaultValue) const {
        return value(key, VCString(defaultValue));
    }

    // template <typename T>
    // T get() const;

    /**
     * Convert current value to @c T into @c v.
     * Does not change @c v if conversion is impossible.
     * @param v variable to accept the converted value
     * @return whether conversion is succeeded
     */
    template <typename T>
    bool getTo(T &v) const {
        if (mValue == nullptr ||
            (!JsonIsHelper<T>(*mValue) && !JsonIsConvertible<T>(*mValue)))
            return false;
        v = JsonAsHelper<T>(*mValue);
        return true;
    }

    // template <typename T>
    // operator T() const;

    // Serialization/deserialization

    /**
     * Dump(serialize) current value to string.
     * @param humanReadable whether to output a human readable (styled) format
     * or compact format
     * @return dumped string
     */
    VCString dump(bool humanReadable = false) const;

    /**
     * Parse(deserialize) from a compatible input.
     * @tparam InputType A compatible input type
     * @param input input to read from
     * @return deserialized JSON value; in case of a parse error, the return
     * value type will be @c ValueType::Invalid.
     */
    template <typename InputType>
    inline static const VCJson parse(InputType &&input) {
        return parse<VCStrCRef>(VCString(std::forward<InputType>(input)));
    }

    template <typename InputIt>
    inline static const VCJson parse(InputIt first, InputIt last) {
        return parse(VCString(first, last));
    }

private:
    std::shared_ptr<Json::Value> mValue;

    static ValueType TypeConvert(Json::ValueType type);
    static Json::ValueType TypeConvert(ValueType type);
    static VCString TypeName(ValueType type);

    VCJson(std::shared_ptr<Json::Value> ptr) : mValue(std::move(ptr)) {}

    /**
     * Check if @c value is convertible to @c T.
     * @tparam T target type
     * @param value value to convert
     */
    template <typename T>
    inline static bool JsonIsConvertible(const Json::Value &value) {
        Json::Value v = T();
        if (value.isConvertibleTo(v.type())) {
            return true;
        }
        return false;
    }

    /**
     * Specialized templates for Json::Value::isT()
     * @tparam T target type
     */
    template <typename T>
    static bool JsonIsHelper(const Json::Value &value) = delete;
    /**
     * Specialized templates for Json::Value::asT()
     * Caution: check type before convert
     * @tparam T target type
     * @return converted value
     */
    template <typename T>
    static T JsonAsHelper(const Json::Value &value) = delete;
};

template <>
VCJson VCJson::value(VCStrCRef key, const VCJson &defaultValue) const;

template <>
const VCJson VCJson::parse(VCStrCRef input);

template <>
inline bool VCJson::JsonIsHelper<bool>(const Json::Value &value) {
    return value.isBool();
}

template <>
inline bool VCJson::JsonIsHelper<Json::Int>(const Json::Value &value) {
    return value.isInt();
}

template <>
inline bool VCJson::JsonIsHelper<Json::UInt>(const Json::Value &value) {
    return value.isUInt();
}

template <>
inline bool VCJson::JsonIsHelper<Json::Int64>(const Json::Value &value) {
    return value.isInt64();
}

template <>
inline bool VCJson::JsonIsHelper<Json::UInt64>(const Json::Value &value) {
    return value.isUInt64();
}

template <>
inline bool VCJson::JsonIsHelper<double>(const Json::Value &value) {
    return value.isDouble();
}

template <>
inline bool VCJson::JsonIsHelper<float>(const Json::Value &value) {
    return value.isDouble();
}

template <>
inline bool VCJson::JsonIsHelper<JSONCPP_STRING>(const Json::Value &value) {
    return value.isString();
}

template <>
inline bool VCJson::JsonAsHelper<bool>(const Json::Value &value) {
    return value.asBool();
}

template <>
inline Json::Int VCJson::JsonAsHelper<Json::Int>(const Json::Value &value) {
    return value.asInt();
}

template <>
inline Json::UInt VCJson::JsonAsHelper<Json::UInt>(const Json::Value &value) {
    return value.asUInt();
}

template <>
inline Json::Int64 VCJson::JsonAsHelper<Json::Int64>(const Json::Value &value) {
    return value.asInt64();
}

template <>
inline Json::UInt64
VCJson::JsonAsHelper<Json::UInt64>(const Json::Value &value) {
    return value.asUInt64();
}

template <>
inline double VCJson::JsonAsHelper<double>(const Json::Value &value) {
    return value.asDouble();
}

template <>
inline JSONCPP_STRING
VCJson::JsonAsHelper<JSONCPP_STRING>(const Json::Value &value) {
    return value.asString();
}

template <>
inline float VCJson::JsonAsHelper<float>(const Json::Value &value) {
    return value.asFloat();
}

template <>
inline const char *
VCJson::JsonAsHelper<const char *>(const Json::Value &value) {
    return value.asCString();
}

template <typename Iterator>
class VCJson::IteratorImpl {
    static_assert(
            std::is_same<Iterator, Json::ValueIterator>::value ||
                    std::is_same<Iterator, Json::ValueConstIterator>::value,
            "For internal use only");
    friend class VCJson;

private:
    IteratorImpl(const Iterator &iter) : mIter(iter) {}

    Iterator mIter;

public:
    using difference_type = ptrdiff_t;
    using value_type = typename std::conditional<
            std::is_same<Iterator, Json::ValueConstIterator>::value,
            const VCJson,
            VCJson>::type;
    using pointer = std::shared_ptr<value_type>;
    using reference = value_type;
    using iterator_category = std::bidirectional_iterator_tag;

    reference operator*() const;
    pointer operator->() const;

    template <typename U>
    IteratorImpl &operator=(const IteratorImpl<U> &other) {
        mIter = other.mIter;
        return *this;
    }

    template <typename U>
    bool operator!=(const IteratorImpl<U> &other) const {
        return mIter != other.mIter;
    }

    template <typename U>
    bool operator==(const IteratorImpl<U> &other) const {
        return mIter == other.mIter;
    }

    template <typename U>
    difference_type operator-(const IteratorImpl<U> other) const {
        return mIter - other.mIter;
    }

    IteratorImpl &operator++() {
        ++mIter;
        return *this;
    }

    IteratorImpl operator++(int) {
        auto ret(*this);
        operator++();
        return ret;
    }

    IteratorImpl &operator--() {
        --mIter;
        return *this;
    }

    IteratorImpl operator--(int) {
        auto ret(*this);
        operator--();
        return ret;
    }

    /**
     * @return key of an object iterator
     */
    VCString key() const {
        return mIter.name();
    }

    /**
     * @return value of an object iterator
     */
    value_type value() const {
        return operator*();
    }
};

VC_NAMESPACE_END

#endif // PRELOAD_VC_JSON_H
