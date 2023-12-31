/**
 * @file AMGMemoryReader.h
 * @author wangze (wangze.happy@bytedance.com)
 * @brief Memory reader
 * @version 10.21.0
 * @date 2019-12-19
 * @copyright Copyright (c) 2019
 */
#pragma once

#include "Gaia/Files/AMGArchive.h"
#include "Gaia/Files/AMGMemoryStream.h"

NAMESPACE_AMAZING_ENGINE_BEGIN

/**
 * @brief Memory reader class
 */
class GAIA_LIB_EXPORT MemoryReader : public Archive
{
    MemoryReader(const MemoryReader&) = delete;
    MemoryReader& operator=(const MemoryReader&) = delete;

public:
    /**
     * @brief Constructor
     * @param pMemoryStream memory stream
     */
    MemoryReader(MemoryStream* pMemoryStream);

    /**
     * @brief Destructor
     */
    ~MemoryReader();

    /// Get current position
    virtual size_t Tell() override
    {
        return _uPos;
    }

    /// Get file size
    virtual size_t Size() override
    {
        return _uStreamSize;
    }

    /// Close file
    void Close() override
    {
        if (_pMemoryStream)
        {
            _pMemoryStream->release();
            _pMemoryStream = nullptr;
        }
    }

    /// Seek to position \uPos
    virtual void Seek(size_t uPos) override
    {
        if (!_pMemoryStream->Seek(uPos))
        {
            AELOGE(AE_GAME_TAG, "MemoryReader:Seek Error TotalSize:%lu, CurrPos:%lu, SeekPos:%lu", _uStreamSize, _uPos, uPos);
            return;
        }
        _uPos = uPos;
    }

    /// Serialize \pData
    virtual bool Serialize(void* pData, size_t uLen) override
    {
        if (!_pMemoryStream->Read(pData, uLen))
        {
            AELOGE(AE_GAME_TAG, "MemoryReader:Serialize Error TotalSize:%lu, CurrPos:%lu, ReadSize:%lu", _uStreamSize, _uPos, uLen);
            return false;
        }
        _uPos += uLen;
        return true;
    }

protected:
    size_t _uPos;
    size_t _uStreamSize;
    MemoryStream* _pMemoryStream;
};

NAMESPACE_AMAZING_ENGINE_END
