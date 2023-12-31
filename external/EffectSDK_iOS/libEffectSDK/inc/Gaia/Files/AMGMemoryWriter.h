/**
 * @file AMGMemoryWriter.h
 * @author wangze (wangze.happy@bytedance.com)
 * @brief Memory writer
 * @version 10.21.0
 * @date 2019-12-19
 * @copyright Copyright (c) 2019
 */
#pragma once
#include "Gaia/Files/AMGArchive.h"
#include "Gaia/Files/AMGMemoryStream.h"

NAMESPACE_AMAZING_ENGINE_BEGIN

/**
 * @brief Memory writer
 */
class GAIA_LIB_EXPORT MemoryWriter : public Archive
{
    MemoryWriter(const MemoryWriter&) = delete;
    MemoryWriter& operator=(const MemoryWriter&) = delete;

public:
    /**
     * @brief Constructor
     * @param pMemoryStream memory stream
     */
    explicit MemoryWriter(MemoryStream* pMemoryStream);

    /**
     * @brief Destructor
     */
    ~MemoryWriter();

    /// Get current position
    virtual size_t Tell() override
    {
        return _pMemoryStream->Tell();
    }

    /// Get file size
    virtual size_t Size() override
    {
        return _pMemoryStream->Size();
    }

    /// Close file
    virtual void Close() override;

    /// Seek to position \uPos
    virtual void Seek(size_t uPos) override
    {
        if (!_pMemoryStream->Seek(uPos))
        {
            AELOGE(AE_GAME_TAG, "MemoryWriter:Seek Failed! SeekPos: %lu, CurrPos: %lu, TotalSize: %lu", uPos, Tell(), Size());
        }
    }

    /// Serialize \pData
    virtual bool Serialize(void* pData, size_t uLen) override
    {
        if (!_pMemoryStream->Write(pData, uLen))
        {
            AELOGE(AE_GAME_TAG, "MemoryWriter:Serialize Failed! WriterLen: %lu, CurrPos: %lu, TotalSize: %lu", uLen, Tell(), Size());
            return false;
        }
        return true;
    }

protected:
    MemoryStream* _pMemoryStream;
};

NAMESPACE_AMAZING_ENGINE_END
