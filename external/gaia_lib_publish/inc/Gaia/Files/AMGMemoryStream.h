/**
 * @file AMGMemoryStream.h
 * @author wangze (wangze.happy@bytedance.com)
 * @brief Memory stream
 * @version 10.21.0
 * @date 2019-12-19
 * @copyright Copyright (c) 2019
 */
#pragma once

#include "Gaia/Files/AMGArchive.h"
#include "Gaia/Files/AMGFileHandle.h"

NAMESPACE_AMAZING_ENGINE_BEGIN

/**
 * @brief Memory stream class
 */
class GAIA_LIB_EXPORT MemoryStream : public FileHandle
{
    MemoryStream(const MemoryStream&) = delete;
    MemoryStream& operator=(const MemoryStream&) = delete;

public:
    /// Constructor
    MemoryStream();
    /**
     * @brief Constructor
     * @param pDatas data buffer pointer
     * @param uSize data buffer size
     */
    MemoryStream(const void* pDatas, size_t uSize);
    /// Destructor
    ~MemoryStream();

    /// Get data buffer pointer
    const void* Data() const
    {
        return _pDatas;
    }

    /// Get current position
    virtual size_t Tell() override
    {
        return _uPos;
    }

    /// Seek to position \uNewPos
    virtual bool Seek(size_t uNewPos) override
    {
        if (uNewPos <= _uSize)
        {
            _uPos = uNewPos;
            return true;
        }
        return false;
    }

    /// Inverse seek to position \uNewInvPos
    virtual bool InvSeek(size_t uNewInvPos = 0) override
    {
        if (uNewInvPos <= _uSize)
        {
            _uPos = _uSize - uNewInvPos;
            return true;
        }
        return false;
    }

    /**
     * @brief Read data
     * @param pDst destination buffer pointer
     * @param uReadLengthToBytes data size by types
     * @return success or failure
     */
    virtual bool Read(void* pDst, size_t uReadLengthToBytes) override
    {
        if (_uPos + uReadLengthToBytes > _uSize)
            return false;
        memcpy(pDst, _pDatas + _uPos, uReadLengthToBytes);
        _uPos += uReadLengthToBytes;
        return true;
    }

    /**
     * @brief Write data
     * @param pSrc source buffer pointer
     * @param uWriteLengthToBytes data size by types
     * @return success or failure 
     */
    virtual bool Write(const void* pSrc, size_t uWriteLengthToBytes) override
    {
        if (_uPos + uWriteLengthToBytes > _uCapacity)
        {
            if (!InternalRealloc(_uPos + uWriteLengthToBytes))
                return false;
        }
        memcpy(_pDatas + _uPos, pSrc, uWriteLengthToBytes);
        _uPos += uWriteLengthToBytes;
        _uSize = _uPos > _uSize ? _uPos : _uSize;
        return true;
    }

protected:
    bool InternalRealloc(size_t uNewSize)
    {
        do
        {
            if (_uCapacity)
                _uCapacity *= 2;
            else
                _uCapacity = uNewSize;
        } while (_uCapacity < uNewSize);
        _pDatas = (uint8_t*)realloc(_pDatas, _uCapacity);
        return _pDatas != nullptr;
    }

protected:
    size_t _uPos;
    size_t _uSize;
    size_t _uCapacity;
    uint8_t* _pDatas;
};

NAMESPACE_AMAZING_ENGINE_END
