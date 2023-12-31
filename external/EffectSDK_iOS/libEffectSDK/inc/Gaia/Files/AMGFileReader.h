/**
 * @file AMGFileReader.h
 * @author wangze (wangze.happy@bytedance.com)
 * @brief File reader
 * @version 10.21.0
 * @date 2019-12-19
 * @copyright Copyright (c) 2019
 */
#pragma once

#include "Gaia/AMGInclude.h"
#include "Gaia/Files/AMGArchive.h"
#include "Gaia/Files/AMGFileHandle.h"

NAMESPACE_AMAZING_ENGINE_BEGIN

/**
 * @brief File reader
 */
class GAIA_LIB_EXPORT FileReader : public Archive
{
    FileReader(const FileReader&) = delete;
    FileReader& operator=(const FileReader&) = delete;

public:
    /**
     * @brief Constructor
     * @param pFileHandle file handle
     * @param sFileName file name
     * @param uFileSize file size
     */
    FileReader(FileHandle* pFileHandle, const char* sFileName, size_t uFileSize);
    /**
     * @brief Destructor
     */
    ~FileReader();

    /// Get current position
    virtual size_t Tell() override
    {
        return _uPos;
    }

    /// Get file size
    virtual size_t Size() override
    {
        return _uFileSize;
    }

    /// Close file
    virtual void Close() override
    {
        if (_pFileHandle)
        {
            _pFileHandle->release();
            _pFileHandle = nullptr;
        }
    }

    /// Seek to position \uPos
    virtual void Seek(size_t uPos) override
    {
        aeAssert(uPos <= _uFileSize);
        if (uPos >= _uBufferBasePos && uPos < _uBufferBasePos + _uBufferCount)
        {
            _uPos = uPos;
        }
        else
        {
            if (!_pFileHandle->Seek(uPos))
            {
                AELOGE(AE_GAME_TAG, "FileReader::Seek Failed !");
            }
            _uPos = uPos;
            _uBufferBasePos = _uPos;
            _uBufferCount = 0;
        }
    }

    /// Serialize \pData
    virtual bool Serialize(void* pData, size_t uLen) override;

    /// Get file full name
    std::string& getFullFileName()
    {
        return _sFileName;
    }

protected:
    bool InternalPrecache();

private:
    String _sFileName;
    FileHandle* _pFileHandle;
    size_t _uFileSize;
    size_t _uPos;
    size_t _uBufferBasePos;
    size_t _uBufferCount;
    uint8_t _pBuffer[2048];
};

NAMESPACE_AMAZING_ENGINE_END
