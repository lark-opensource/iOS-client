/**
 * @file AMGPrimitiveNumber.h
 * @author fanwenjie (fanwenjie.tiktok@bytedance.com)
 * @brief Primitive Integer
 * @version 10.20.0
 * @date 2020-02-18
 * @copyright Copyright (c) 2020
 */
#pragma once

#include <functional>

#include "Gaia/AMGInclude.h"
#include "Gaia/AMGRefBase.h"

NAMESPACE_AMAZING_ENGINE_BEGIN

/**
 * @brief Template of primitive integer
 * @tparam T integer data type
 */
template <typename T, typename E = typename std::enable_if_t<std::is_integral<T>::value>>
class PrimitiveNumber;

/**
 * @brief Template of primitive integer
 * @tparam T integer data type
 */
template <typename T>
class PrimitiveNumber<T>
{
public:
    /**
     * @brief data size
     */
    static constexpr auto size = sizeof(T);

    /**
     * @brief data size
     */
    typedef T type;

    /**
     * @brief Constructor
     */
    PrimitiveNumber()
    {
    }
    /**
     * @brief Copy Constructor
     * @param other another integer
     */
    PrimitiveNumber(const PrimitiveNumber& other)
    {
        this->mValue = other.mValue;
    }

    /**
     * @brief Copy Constructor
     * @param v value
     */
    PrimitiveNumber(const T v)
    {
        this->mValue = v;
    }

    /**
     * @brief Destructor
     */
    ~PrimitiveNumber()
    {
    }

    /**
     * @brief Operator =
     * @param other another integer
     * @return PrimitiveNumber& this integer
     */
    PrimitiveNumber& operator=(const PrimitiveNumber& other)
    {
        this->mValue = other.mValue;
        return *this;
    }

    /**
     * @brief Get value
     * @return value
     */
    const T get() const
    {
        return mValue;
    }

    /**
     * @brief Get value
     * @return value
     */
    operator T() const
    {
        return mValue;
    }

    /**
     * @brief Set value
     * @param val value to be setted
     */
    void set(const T& val)
    {
        mValue = val;
    }

    /// Clone the integer
    PrimitiveNumber<T> copy() const
    {
        PrimitiveNumber<T> val;
        val.mValue = this->mValue;
        return val;
    }

protected:
    T mValue = 0;
};

/// 8 bits Signed Integer
using Integer8 = PrimitiveNumber<int8_t>;
/// 16 bits Signed Integer
using Integer16 = PrimitiveNumber<int16_t>;
/// 32 bits Signed Integer
using Integer32 = PrimitiveNumber<int32_t>;
/// 64 bits Signed Integer
using Integer64 = PrimitiveNumber<int64_t>;

/// 8 bits Unsigned Integer
using Unsigned8 = PrimitiveNumber<uint8_t>;
/// 16 bits Unsigned Integer
using Unsigned16 = PrimitiveNumber<uint16_t>;
/// 32 bits Unsigned Integer
using Unsigned32 = PrimitiveNumber<uint32_t>;

NAMESPACE_AMAZING_ENGINE_END
