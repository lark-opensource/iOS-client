/**
 * @file AMGRefBase.h
 * @author Zhao Chenxiang (zhaochenxiang@bytedance.com)
 * @brief RefBase is the base class of all classes that need Reference count.
 * @version 0.1
 * @date 2018-08-09
 * 
 * @copyright Copyright (c) 2019
 * 
 */

#pragma once

#include <atomic>

#include "Gaia/AMGPrerequisites.h"
#include <set>
NAMESPACE_AMAZING_ENGINE_BEGIN
/**
 * @brief RefBase is the base class of all classes that need Reference count.
 *  
 */
struct GAIA_LIB_EXPORT RefBase
{
protected:
    mutable std::atomic_int mdRefCount;

public:
    /**
     * @brief Construct a new Ref Base object.
     * 
     */
    RefBase()
        : mdRefCount(0)
    {
    }
    /**
     * @brief Increase current ref count.
     * 
     */
    virtual void retain() const;
    /**
     * @brief Decrease current ref count, and delete self if ref count reaches zero.
     * 
     */
    virtual void release() const;
    /**
     * @brief Decrease ref count.
     * 
     */
    virtual void reduce() const;
    /**
     * @brief Get current ref count.
     * 
     * @return int Value of current ref count.
     */
    virtual int getRefCount() const;
    /**
     * @brief Destroy the Ref Base object.
     * 
     */
    virtual ~RefBase();
    //    static std::set<RefBase*> gRefBases;
};

NAMESPACE_AMAZING_ENGINE_END
