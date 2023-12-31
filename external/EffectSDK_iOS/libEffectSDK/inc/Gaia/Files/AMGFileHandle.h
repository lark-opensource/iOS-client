/**
 * @file AMGFileHandle.h
 * @author wangze (wangze.happy@bytedance.com)
 * @brief File handle
 * @version 10.21.0
 * @date 2019-12-19
 * @copyright Copyright (c) 2019
 */
#pragma once
#include "Gaia/AMGPrerequisites.h"
#include "Gaia/AMGRefBase.h"

NAMESPACE_AMAZING_ENGINE_BEGIN

/**
 * @brief File handle class
 */
class GAIA_LIB_EXPORT FileHandle : public RefBase
{
public:
    /// Get file size
    size_t Size()
    {
        size_t uCurrent = Tell();
        InvSeek();
        size_t uResult = Tell();
        Seek(uCurrent);
        return uResult;
    }

    /// Get current position
    virtual size_t Tell() = 0;

    /// Seek to position \uNewPos
    virtual bool Seek(size_t uNewPos) = 0;

    /// Inverse seek to position \uNewInvPos
    virtual bool InvSeek(size_t uNewInvPos = 0) = 0;

    /**
     * @brief Read data
     * @param pDst destination buffer pointer
     * @param uReadLengthToBytes data size by types
     * @return success or failure
     */
    virtual bool Read(void* pDst, size_t uReadLengthToBytes) = 0;

    /**
     * @brief Write data
     * @param pSrc source buffer pointer
     * @param uWriteLengthToBytes data size by types
     * @return success or failure 
     */
    virtual bool Write(const void* pSrc, size_t uWriteLengthToBytes) = 0;
};

NAMESPACE_AMAZING_ENGINE_END
