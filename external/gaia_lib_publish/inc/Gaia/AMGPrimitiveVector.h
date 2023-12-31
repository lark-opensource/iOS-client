/**
 * @file AMGPrimitiveVector
 * @author wangze (wangze.happy@bytedance.com)
 * @brief Primitive vector
 * @version 10.20.0
 * @date 2019-12-18
 * @copyright Copyright (c) 2019
 */
#pragma once

#include <functional>
#include <vector>
#include <initializer_list>
#include <assert.h>

#include "Gaia/AMGInclude.h"
#include "Gaia/Math/AMGHashFunction.h"
#include "Gaia/AMGRefBase.h"

NAMESPACE_AMAZING_ENGINE_BEGIN

/**
 * @brief Template of primitive vector private implement
 * @tparam T vector data type
 */
template <typename T>
class PrimitiveVectorPrivate : public RefBase
{
public:
    /// Default Constructor
    PrimitiveVectorPrivate() = default;

    /**
     * @brief Constructor
     * @param l initializer list
     */
    PrimitiveVectorPrivate(const std::initializer_list<T>& l)
        : mVars{l}
    {
    }

    /// Pass std::vector inside (without copying)
    PrimitiveVectorPrivate(std::vector<T> vec)
        : mVars(std::move(vec)){};

    /// Get vector size
    int32_t size() const { return static_cast<int32_t>(mVars.size()); }

    /// resize
    void resize(int32_t size)
    {
        mVars.resize(size);
    }

    /// Get whether empty or not
    bool empty() const { return !mVars.size(); }

    /// Get hash value of this vector
    uint32_t hash() const
    {
        uint32_t h = DJB2::hash((const uint8_t*)mVars.data(), size() * sizeof(T));
        return h;
    }

    /// Operater []
    const T& operator[](int32_t i) const
    {
        return mVars[i];
    }

    /// Operater []
    T& operator[](int32_t i)
    {
        return mVars[i];
    }

    /// Get data buffer
    const T* getBuffer() const
    {
        if (empty())
            return nullptr;
        return mVars.data();
    }

    /// Get data buffer
    T* getBuffer()
    {
        if (empty())
            return nullptr;
        return mVars.data();
    }

    auto& contents() { return mVars; }
    const auto& contents() const { return mVars; }

    /// Get data by index i
    const T& get(int32_t i) const
    {
        return mVars.at(i);
    }

    /**
     * @brief Set data
     * @param i index
     * @param var value
     */
    void set(int32_t i, const T& var)
    {
        if (i < 0 || i >= mVars.size())
            return;
        mVars[i] = var;
    }

    /// Push data into back of the vector
    void pushBack(const T& var)
    {
        mVars.push_back(var);
    }

    /// Push data into front of the vector
    void pushFront(const T& var)
    {
        insert(0, var);
    }

    /// Get front data
    T front() const
    {
        if (empty())
        {
            aeAssert(false);
            return T();
        }
        return *mVars.begin();
    }

    /// Get back data
    T back() const
    {
        if (empty())
        {
            aeAssert(false);
            return T();
        }
        return *mVars.rbegin();
    }

    /// Pop back data
    T popBack()
    {
        if (empty())
        {
            aeAssert(false);
            return T();
        }
        auto val = back();
        remove(size() - 1);
        return val;
    }

    /// Pop front data
    T popFront()
    {
        if (empty())
        {
            aeAssert(false);
            return T();
        }
        auto val = front();
        remove(0);
        return val;
    }

    /**
     * @brief Insert data
     * @param pos position to be inserted
     * @param var value to be inserted
     */
    void insert(int32_t pos, const T& var)
    {
        if (pos < 0 || pos > mVars.size())
            return;
        mVars.insert(mVars.begin() + pos, var);
    }

    /**
     * @brief Remove data
     * @param idx index
     */
    void remove(int32_t idx)
    {
        if (idx < 0 || idx >= mVars.size())
            return;
        mVars.erase(mVars.begin() + idx);
    }

    /**
     * @brief Clear vector
     */
    void clear()
    {
        mVars.clear();
    }

    /**
     * @brief Find data from \start
     * @param var value
     * @param start start position to be found
     * @return int32_t index of the value in the vector
     * @return -1 value no found in the vector 
     */
    int32_t find(const T& var, int32_t start = 0) const
    {
        for (int32_t i = start; i < mVars.size(); ++i)
        {
            if (var == mVars[i])
                return i;
        }
        return -1;
    }

    /**
     * @brief Reverse find data from \start
     * @param var value 
     * @param start reverse start position to be found
     * @return int32_t index of the value in the vector
     * @return -1 value no found in the vector 
     */
    int32_t rfind(const T& var, int32_t start = -1) const
    {
        if (size() == 0)
            return -1;

        if (start < 0)
        {
            start += size();
        }

        if (start < 0 || start >= size())
        {
            start = size() - 1;
        }

        for (int i = start; i >= 0; i--)
        {

            if (mVars[i] == var)
            {
                return i;
            };
        };

        return -1;
    }

    /**
     * @brief find last position of \var
     * @param var value
     * @return int32_t index of the value in the vector
     * @return -1 value no found in the vector 
     */
    int32_t findLast(const T& var) const
    {
        return rfind(var);
    }

    /**
     * @brief Number of occurrences of \var 
     * @param var value
     * @return int32_t number of occurrences
     */
    int32_t count(const T& var) const
    {
        if (size() == 0)
            return 0;

        int count = 0;
        for (int i = 0; i < size(); i++)
        {

            if (mVars[i] == var)
            {
                count++;
            };
        };

        return count;
    }

    /**
     * @brief Test if the vector has value \var
     * @param var value
     * @return true has \var
     * @return false has not
     */
    bool has(const T& var) const
    {
        return find(var, 0) != -1;
    }

    /**
     * @brief Erase value
     * @param var value
     */
    void erase(const T& var)
    {
        auto it = std::find(mVars.begin(), mVars.end(), var);
        if (it != mVars.end())
        {
            mVars.erase(it);
        }
    }

    /**
     * @brief Sort the vector
     * @param asc is ascending order or not
     */
    void sort(bool asc = true)
    {
        if (asc)
            std::sort(mVars.begin(), mVars.end(), std::less<T>());
        else
            std::sort(mVars.begin(), mVars.end(), std::greater<T>());
    }

    /// Shuffle the vector
    void shuffle()
    {
        const int32_t n = size();
        if (n < 2)
            return;
        T* data = mVars.data();
        for (int i = n - 1; i >= 1; i--)
        {
            const int j = rand() % (i + 1);
            std::swap(data[i], data[j]);
        }
    }
    /// Reverse the vector
    void reverse()
    {
        for (int32_t i = 0; i < size() / 2; i++)
        {
            T* p = mVars.data();
            std::swap(p[i], p[size() - i - 1]);
        }
    }

    bool isEqual(const PrimitiveVectorPrivate& other) const
    {
        if (size() != other.size())
        {
            return false;
        }
        for (int32_t i = 0; i < size(); ++i)
        {
            if (get(i) != other.get(i))
            {
                return false;
            }
        }
        return true;
    }

private:
    std::vector<T> mVars;
};

/**
 * @brief Template of primitive vector
 * @tparam T vector data type
 */
template <typename T>
class PrimitiveVector
{
public:
    /**
     * @brief Constructor
     */
    PrimitiveVector()
    {
        mPriv = new PrimitiveVectorPrivate<T>;
        mPriv->retain();
    }
    /**
     * @brief Copy Constructor
     * @param other another vector
     */
    PrimitiveVector(const PrimitiveVector& other)
    {
        mPriv = other.mPriv;
        mPriv->retain();
    }
    /**
     * @brief Constructor
     * @param l initializer list
     */
    PrimitiveVector(const std::initializer_list<T>& l)
    {
        mPriv = new PrimitiveVectorPrivate<T>{l};
        mPriv->retain();
    }

    /// Pass std::vector<T> inside (without copying)
    PrimitiveVector(std::vector<T> vec)
        : mPriv(new PrimitiveVectorPrivate<T>(std::move(vec)))
    {
        mPriv->retain();
    }

    /**
     * @brief Destructor
     */
    ~PrimitiveVector()
    {
        if (mPriv)
        {
            mPriv->release();
            mPriv = nullptr;
        }
    }

    /**
     * @brief Operator =
     * @param other another vector
     * @return PrimitiveVector& this vector
     */
    PrimitiveVector& operator=(const PrimitiveVector& other)
    {
        if (mPriv == other.mPriv)
            return *this;

        if (mPriv)
        {
            mPriv->release();
            mPriv = nullptr;
        }
        mPriv = other.mPriv;
        mPriv->retain();
        return *this;
    }

    /**
     * @brief Check if the private pointers of two PrimitiveVectors are equal
     * @param other another PrimitiveVector
     * @return bool true if their private pointers are equal
     */
    bool operator==(const PrimitiveVector& other) const
    {
        return mPriv == other.mPriv;
    }

    /**
     * @brief Check if the values of two PrimitiveVectors are equal
     * @param other another PrimitiveVector
     * @return bool true if their intrinsic values are equal
     */
    bool isEqual(const PrimitiveVector& other) const
    {
        return mPriv->isEqual(*other.mPriv);
    }

    /**
     * @brief Operator []
     * @param i index
     * @return const T& data at index i
     */
    const T& operator[](int32_t i) const
    {
        return (*mPriv)[i];
    }

    /**
     * @brief Operator []
     * @param i index
     * @return T& data at index i
     */
    T& operator[](int32_t i)
    {
        return (*mPriv)[i];
    }

    /// Get data buffer
    const T* getBuffer() const
    {
        return mPriv->getBuffer();
    }

    /// Get data buffer
    T* getBuffer()
    {
        return mPriv->getBuffer();
    }

    /// Get data buffer size
    int32_t getBufferSize() const
    {
        return getBufferSizeImpl();
    }

    /// Get vector size
    int32_t size() const
    {
        return mPriv->size();
    }

    /**
     * @brief Resize the vector
     * @param size new size
     */
    void resize(int32_t size)
    {
        mPriv->resize(size);
    }

    /// Get whether the vector is empty or not
    bool empty() const
    {
        return mPriv->empty();
    }

    /// Clear the vector
    void clear()
    {
        mPriv->clear();
    }

    /**
     * @brief Get value at index i
     * @param i index
     * @return value at index i
     */
    const T& get(int32_t i) const
    {
        return mPriv->get(i);
    }

    /**
     * @brief Set value at index i
     * @param i index
     * @param val value to be setted
     */
    void set(int32_t i, const T& val)
    {
        mPriv->set(i, val);
    }

    /// Get hash value of current vector
    uint32_t hash() const
    {
        return mPriv->hash();
    }

    /// Get front data
    T front() const
    {
        return mPriv->front();
    }

    /// Get back data
    T back() const
    {
        return mPriv->back();
    }

    /// Push data into back of the vector
    void pushBack(const T& val)
    {
        mPriv->pushBack(val);
    }

    /// Push data into front of the vector
    void pushFront(const T& val)
    {
        mPriv->pushFront(val);
    }

    /// Pop back data
    T popBack()
    {
        return mPriv->popBack();
    }

    /// Pop front data
    T popFront()
    {
        return mPriv->popFront();
    }

    /**
     * @brief Map operator
     * @param func mapping function
     * @return mapped vector 
     */
    PrimitiveVector map(std::function<T(const T&)> func)
    {
        PrimitiveVector ret;
        for (int32_t i = 0; i < size(); ++i)
        {
            ret.pushBack(func((*this)[i]));
        }
        return ret;
    }

    /**
     * @brief Reduce operator
     * @param func reducing function
     * @return T redeced vector
     */
    T reduce(std::function<T(const T&, const T&)> func)
    {
        if (empty())
            return T();
        if (size() == 1)
            return (*this)[0];

        T ret = (*this)[0];
        for (int32_t i = 1; i < size(); ++i)
        {
            ret = func(ret, (*this)[i]);
        }
        return ret;
    }

    /**
     * @brief Insert data
     * @param pos position to be inserted
     * @param var value to be inserted
     */
    void insert(int32_t pos, const T& var)
    {
        mPriv->insert(pos, var);
    }

    /**
     * @brief Remove data
     * @param idx index
     */
    void remove(int32_t idx)
    {
        mPriv->remove(idx);
    }

    /// Clone the vector
    PrimitiveVector<T> copy() const
    {
        return copyImpl();
    }

    auto& contents() { return mPriv->contents(); }
    const auto& contents() const { return mPriv->contents(); }

    /**
     * @brief Find data from \start
     * @param var value
     * @param start start position to be found
     * @return int32_t index of the value in the vector
     * @return -1 value no found in the vector 
     */
    int32_t find(const T& var, int32_t start = 0) const
    {
        return mPriv->find(var, start);
    }

    /**
     * @brief Reverse find data from \start
     * @param var value 
     * @param start reverse start position to be found
     * @return int32_t index of the value in the vector
     * @return -1 value no found in the vector 
     */
    int32_t rfind(const T& var, int32_t start = -1) const
    {
        return mPriv->rfind(var, start);
    }

    /**
     * @brief find last position of \var
     * @param var value
     * @return int32_t index of the value in the vector
     * @return -1 value no found in the vector 
     */
    int32_t findLast(const T& var) const
    {
        return mPriv->findLast(var);
    }

    /**
     * @brief Number of occurrences of \var 
     * @param var value
     * @return int32_t number of occurrences
     */
    int32_t count(const T& var) const
    {
        return mPriv->count(var);
    }

    /**
     * @brief Test if the vector has value \var
     * @param var value
     * @return true has \var
     * @return false has not
     */
    bool has(const T& var) const
    {
        return mPriv->has(var);
    }

    /**
     * @brief Erase value
     * @param var value
     */
    void erase(const T& var)
    {
        mPriv->erase(var);
    }

    /// Sort the vector
    PrimitiveVector<T>& sort()
    {
        mPriv->sort();
        return *this;
    }

    /// Shuffle the vector
    void shuffle()
    {
        mPriv->shuffle();
    }

    /// Reverse the vector
    PrimitiveVector<T>& reverse()
    {
        mPriv->reverse();
        return *this;
    }

    void* getHandle()
    {
        return mPriv;
    }

private:
    inline PrimitiveVector<T> copyImpl() const
    {
        PrimitiveVector<T> arr;
        arr.resize(size());
        memcpy((void*)arr.getBuffer(), (void*)this->getBuffer(), this->getBufferSize());
        return arr;
    }

    inline int32_t getBufferSizeImpl() const
    {
        return sizeof(T) * size();
    }

protected:
    PrimitiveVectorPrivate<T>* mPriv = nullptr;
};

template <>
inline PrimitiveVector<std::string> PrimitiveVector<std::string>::copyImpl() const
{
    PrimitiveVector<std::string> arr;
    for (int i = 0; i < size(); ++i)
    {
        arr.pushBack(get(i));
    }
    return arr;
}

template <>
inline int32_t PrimitiveVector<std::string>::getBufferSizeImpl() const
{
    assert(false);
    return 0;
}

/// Int8 vector
using Int8Vector = PrimitiveVector<int8_t>;
/// Int16 vector
using Int16Vector = PrimitiveVector<int16_t>;
/// Int32 vector
using Int32Vector = PrimitiveVector<int32_t>;
/// Int64 vector
using Int64Vector = PrimitiveVector<int64_t>;

/// UInt8 vector
using UInt8Vector = PrimitiveVector<uint8_t>;
/// UInt16 vector
using UInt16Vector = PrimitiveVector<uint16_t>;
/// UInt32 vector
using UInt32Vector = PrimitiveVector<uint32_t>;

/// Float vector
using FloatVector = PrimitiveVector<float>;
/// Double vector
using DoubleVector = PrimitiveVector<double>;
/// String vector
using StringVector = PrimitiveVector<std::string>;

/// Vec2 vector
using Vec2Vector = PrimitiveVector<Vector2f>;
/// Vec3 vector
using Vec3Vector = PrimitiveVector<Vector3f>;
/// Vec4 vector
using Vec4Vector = PrimitiveVector<Vector4f>;

/// Quat vector
using QuatVector = PrimitiveVector<Quaternionf>;

//using Mat2Vector = PrimitiveVector<Mat2>;
/// Mat3 vector
using Mat3Vector = PrimitiveVector<Matrix3x3f>;
/// Mat4 vector
using Mat4Vector = PrimitiveVector<Matrix4x4f>;

NAMESPACE_AMAZING_ENGINE_END
