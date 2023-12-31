/**
 * @file AMGSharePtr.h
 * @author Zhao Chenxiang(zhaochenxiang@bytedance.com)
 * @brief Smart ptr.
 * @version 0.1
 * @date 2019-11-25
 * 
 * @copyright Copyright (c) 2019
 * 
 */

#pragma once

#include "Gaia/AMGPrerequisites.h"
#include "Gaia/AMGRefBase.h"

NAMESPACE_AMAZING_ENGINE_BEGIN
/**
 * @brief SharePtr is a smart pointer class that retains shared ownership of class instance through a pointer.
 * Several SharePtr may own the same instance.
 * The instance is destroyed and its memory deallocated when its ref count decrease to 0.
 * SharePtr can only own instance that is derived from class RefBase.
 * 
 * @tparam T Ref class type, must be derived from RefBase class.
 */

template <class T, class Enable = void>
class SharePtr
{
private:
    T* mPtr;

public:
    /**
     * @brief Construct a new Share Ptr object
     * 
     */
    SharePtr()
        : mPtr(nullptr)
    {
    }
    /**
     * @brief Construct a new Share Ptr object with a pointer of specialization type T.
     * 
     * @param _p Pointer of an instance.
     */
    SharePtr(T* _p)
    {
        //mPtr = const_cast<T*>(_p);
        mPtr = _p;
        if (mPtr != nullptr)
            mPtr->retain();
    }

    /**
     * @brief Construct a new Share Ptr object with a pointer of specialization type U other than T.
     * 
     * @tparam U Type of other class instance.
     * @param _p Pointer of an instance.
     */
    template <typename U>
    SharePtr(U* _p)
    {
        static_assert(std::is_convertible<U*, T*>::value, "type error!");
        mPtr = (_p);
        if (mPtr != nullptr)
            mPtr->retain();
    }
    /**
     * @brief Construct a new Share Ptr instance with other Share Ptr which has same specialization type T.
     * 
     * @param _p Other share ptr instance.
     */
    SharePtr(const SharePtr<T>& _p)
        : mPtr(_p.mPtr)
    {
        if (mPtr != nullptr)
            mPtr->retain();
    }
    /**
     * @brief Construct a new Share Ptr instance with other share ptr which has different specialization type U.
     * 
     * @tparam U Specialization type of other share ptr.
     * @param other Other share ptr instance.
     */
    template <typename U>
    SharePtr(const SharePtr<U>& other)
        : mPtr(static_cast<T*>(other.get()))
    {
        if (mPtr != nullptr)
            mPtr->retain();
    }
    /**
     * @brief Destroy the Share Ptr object.
     * 
     */
    ~SharePtr()
    {
        if (mPtr != nullptr)
        {
            mPtr->release();
        }
    }

    //    T* release()
    //    {
    //        if (!mPtr) return nullptr;
    //        T* rawPtr = mPtr;
    //        mPtr = nullptr;
    //        rawPtr->reduce();
    //        return rawPtr;
    //    }
    /**
     * @brief Get the pointer of instance owned currently.
     * 
     * @return T* Pointer of instance.
     */
    T* get() const
    {
        return mPtr;
    }
    /**
     * @brief Get pointer owned currently, and set current pointer to nullptr.
     * 
     * @return T* Pointer of instance owned currently.
     */
    T* transfer()
    {
        if (mPtr != nullptr)
        {
            mPtr->reduce();
        }
        auto ret = mPtr;
        mPtr = nullptr;
        return ret;
    }

    //    operator const T* () const
    //    {
    //        return mPtr;
    //    }
    //
    //    operator T* () const
    //    {
    //        return mPtr;
    //    }
    /**
     * @brief Overload operator*, dereferences the stored pointer. The behavior is undefined if the stored pointer is null.
     * 
     * @return T& The result of dereferencing the owned pointer
     */
    T& operator*() const
    {
        return *mPtr;
    }
    /**
     * @brief Overload operator->, dereferences the stored pointer. The behavior is undefined if the stored pointer is null.
     * 
     * @return T* The owned pointer.
     */
    T* operator->(void) const
    {
        return mPtr;
    }
    /**
     * @brief Replaces the owned instance with newp.
     * 
     * @param newp Pointer of other instance.
     * @return SharePtr& Reference to self, *this.
     */
    SharePtr& operator=(T* newp)
    {
        if (newp != mPtr)
        {
            if (newp != nullptr)
            {
                newp->retain();
            }
            if (mPtr != nullptr)
            {
                mPtr->release();
            }
            mPtr = newp;
        }
        return *this;
    }
    /**
     * @brief Replaces the owned instance with newp
     * 
     * @tparam U Type of other pointer. U must can be coverted to T.
     * @param newp Pointer of other instance.
     * @return SharePtr& Reference to self, *this.
     */
    template <typename U>
    SharePtr& operator=(U* newp)
    {
        static_assert(std::is_convertible<U*, T*>::value, "type error");
        if (newp != mPtr)
        {
            if (newp != nullptr)
            {
                newp->retain();
            }
            if (mPtr != nullptr)
            {
                mPtr->release();
            }
            mPtr = newp;
        }
        return *this;
    }
    /**
     * @brief Replaces the owned instance with the one owned by newp.
     * 
     * @param newp Share ptr instance.
     * @return SharePtr& Reference to self, *this.
     */
    SharePtr& operator=(const SharePtr<T>& newp)
    {
        if (newp.mPtr != mPtr)
        {
            if (newp.mPtr != nullptr)
            {
                newp.mPtr->retain();
            }
            if (mPtr != nullptr)
            {
                mPtr->release();
            }
            mPtr = newp.mPtr;
        }
        return *this;
    }
    /**
     * @brief Replaces the owned instance with the one owned by newp.
     * 
     * @tparam U Implementation type of other share ptr. U must can be coverted to T
     * @param newp Share ptr instance.
     * @return SharePtr& Reference to self, *this.
     */
    template <typename U>
    SharePtr& operator=(const SharePtr<U>& newp)
    {
        if (newp.mPtr != mPtr)
        {
            if (newp.mPtr != nullptr)
            {
                newp.mPtr->retain();
            }
            if (mPtr != nullptr)
            {
                mPtr->release();
            }
            mPtr = newp.mPtr;
        }
        return *this;
    }
    /**
     * @brief Overload operator bool, checks if the owned pointer is not nullptr.
     * 
     * @return true Owned pointer is not nullptr.
     * @return false Owned pointer is nullptr.
     */
    explicit operator bool() const
    {
        return !isNull();
    }
    /**
     * @brief Checks if the owned pointer is nullptr.
     * 
     * @return true Owned pointer is nullptr.
     * @return false Owned pointer is not nullptr.
     */
    bool isNull() const
    {
        return mPtr == nullptr;
    }
    /**
     * @brief Overload operator!, checks if the owned pointer is nullptr.
     * 
     * @return true Owned pointer is nullptr.
     * @return false Owned pointer is not nullptr.
     */
    bool operator!() const
    {
        return mPtr == nullptr;
    }
    /**
     * @brief Overload operator==, compares with other pointer.
     * 
     * @param other Other pointer.
     * @return true Owned pointer is same as other pointer.
     * @return false Owned pointer is not same as other pointer.
     */
    bool operator==(T* other) const
    {
        return mPtr == other;
    }
    /**
     * @brief Overload operator!=, compares with other pointer.
     * 
     * @param other Other pointer.
     * @return true Owned pointer is not same as other pointer.
     * @return false Owned pointer is same as other pointer.
     */
    bool operator!=(T* other) const
    {
        return mPtr != other;
    }
};
/**
 * @brief Overload operator==, compares the owned pointer of two share ptrs.
 * 
 * @tparam T Implementation type of left share ptr instance.
 * @tparam U Implementation type of right share ptr instance.
 * @param a Left share ptr instance.
 * @param b Right share ptr instance.
 * @return true The owned pointer of two share ptrs is same.
 * @return false The owned pointer of two share ptrs is not same.
 */
template <class T, class U>
inline bool operator==(SharePtr<T> const& a, SharePtr<U> const& b)
{
    return a.get() == b.get();
}
/**
 * @brief Overload operator!=, compares the owned pointer of two share ptrs.
 * 
 * @tparam T Implementation type of left share ptr instance.
 * @tparam U Implementation type of right share ptr instance.
 * @param a Left share ptr instance.
 * @param b Right share ptr instance.
 * @return true The owned pointer of two share ptrs is not same.
 * @return false The owned pointer of two share ptrs is same.
 */
template <class T, class U>
inline bool operator!=(SharePtr<T> const& a, SharePtr<U> const& b)
{
    return a.get() != b.get();
}
/**
 * @brief Overload operator<, compares the owned pointer of two share ptrs.
 * 
 * @tparam T Implementation type of left share ptr instance.
 * @tparam U Implementation type of right share ptr instance.
 * @param a Left share ptr instance.
 * @param b Right share ptr instance.
 * @return true The owned pointer adress of left share ptr is smaller than right share ptr.
 * @return false The owned pointer adress of left share ptr is not smaller than right share ptr.
 */
template <class T, class U>
inline bool operator<(SharePtr<T> const& a, SharePtr<U> const& b)
{
    return a.get() < b.get();
}
/**
 * @brief Overload operator>, compares the owned pointer of two share ptrs.
 * 
 * @tparam T Implementation type of left share ptr instance.
 * @tparam U Implementation type of right share ptr instance.
 * @param a Left share ptr instance.
 * @param b Right share ptr instance.
 * @return true The owned pointer adress of left share ptr is larger than right share ptr.
 * @return false The owned pointer adress of left share ptr is not larger than right share ptr.
 */
template <class T, class U>
inline bool operator>(SharePtr<T> const& a, SharePtr<U> const& b)
{
    return a.get() > b.get();
}
/**
 * @brief Overload operator<=, compares the owned pointer of two share ptrs.
 * 
 * @tparam T Implementation type of left share ptr instance.
 * @tparam U Implementation type of right share ptr instance.
 * @param a Left share ptr instance.
 * @param b Right share ptr instance.
 * @return true The owned pointer adress of left share ptr is equal to or smaller than right share ptr.
 * @return false The owned pointer adress of left share ptr is not equal to or smaller than right share ptr.
 */
template <class T, class U>
inline bool operator<=(SharePtr<T> const& a, SharePtr<U> const& b)
{
    return a.get() <= b.get();
}
/**
 * @brief Overload operator>=, compares the owned pointer of two share ptrs.
 *  
 * @tparam T Implementation type of left share ptr instance.
 * @tparam U Implementation type of right share ptr instance.
 * @param a Left share ptr instance.
 * @param b Right share ptr instance.
 * @return true The owned pointer adress of left share ptr is equal to or larger than right share ptr.
 * @return false The owned pointer adress of left share ptr is not equal to or larger than right share ptr.
 */
template <class T, class U>
inline bool operator>=(SharePtr<T> const& a, SharePtr<U> const& b)
{
    return a.get() >= b.get();
}

NAMESPACE_AMAZING_ENGINE_END
