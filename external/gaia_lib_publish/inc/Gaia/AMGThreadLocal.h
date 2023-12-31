/**
 * @file AMGThreadLocal.h
 * @author aojian (aojian@bytedance.com)
 * @brief ThreadLocal class enables you to create variables that can only be read and written by the same thread. 
 * @version 0.1
 * @date 2019-11-26
 * 
 * @copyright Copyright (c) 2019
 * 
 */

#ifndef _AE_BASE_THREADLOCAL_H
#define _AE_BASE_THREADLOCAL_H

#include "Gaia/AMGPrerequisites.h"
#include <thread>
#include <mutex>

#ifndef AE_THREAD_LOCAL
#define AE_THREAD_LOCAL 1
#endif

NAMESPACE_AMAZING_ENGINE_BEGIN

/**
 * @brief ThreadLocal class enables you to create variables that can only be read and written by the same thread. 
 * 
 * @tparam T Type of variables. The class will store pointer of type T.
 */
template <typename T>
class ThreadLocal
{
private:
    typedef std::unordered_map<std::thread::id, T*> TypeMap;

    mutable TypeMap mValues;
    mutable std::mutex mMutex;

public:
    /**
     * @brief Construct a new Thread Local object
     * 
     */
    ThreadLocal()
    {
    }
    /**
     * @brief Judge whether current thread has set variable.
     * 
     * @return true Current thread has set variable.
     * @return false Current thread has not set variable.
     */
    bool Has() const
    {
        std::lock_guard<std::mutex> lock(mMutex);
        return mValues.find(std::this_thread::get_id()) != mValues.end();
    }
    /**
     * @brief Set variable for current thread.
     *  
     * @param value The variable of current thread.
     */
    void Set(T* value)
    {
        auto threadId = std::this_thread::get_id();

        std::lock_guard<std::mutex> lock(mMutex);
        mValues[threadId] = value;
    }
    /**
     * @brief Get variable for current thread.
     * 
     * @return T* The variable of current thread.
     */
    T* Get() const
    {
        auto threadId = std::this_thread::get_id();

        std::lock_guard<std::mutex> lock(mMutex);
        auto it = mValues.find(threadId);
        if (it == mValues.end())
        {
            auto x = new T;
            mValues[threadId] = x;
            return x;
        }
        return it->second;
    }
};

NAMESPACE_AMAZING_ENGINE_END

#endif
