/**
 * @file AMGFileWriter.h
 * @author wangze (wangze.happy@bytedance.com)
 * @brief File write
 * @version 10.21.0
 * @date 2019-12-19
 * @copyright Copyright (c) 2019
 */
#pragma once

#include "Gaia/Files/AMGArchive.h"
#include "Gaia/Files/AMGFileHandle.h"

NAMESPACE_AMAZING_ENGINE_BEGIN

/**
 * @brief File write
 */
class GAIA_LIB_EXPORT FileWriter : public Archive
{
    FileWriter(const FileWriter&) = delete;
    FileWriter& operator=(const FileWriter&) = delete;

public:
    /**
     * @brief Constructor
     * @param pFileHandle file handle
     * @param sFullName full file name
     * @param uCurrPos current position
     */
    FileWriter(FileHandle* pFileHandle, const char* sFullName, size_t uCurrPos);
    /**
     * @brief Destructor
     */
    ~FileWriter();

    /// Get current position
    virtual size_t Tell() override
    {
        return _uPos;
    }

    /// Get file size
    virtual size_t Size() override
    {
        Flush();
        return _pFileHandle->Size();
    }

    /// Close file
    virtual void Close() override
    {
        if (_pFileHandle)
        {
            Flush();
            _pFileHandle->release();
            _pFileHandle = nullptr;
        }
    }

    /// Seek to position \uPos
    void Seek(size_t uPos) override
    {
        Flush();
        if (!_pFileHandle->Seek(uPos))
        {
            AELOGE(AE_GAME_TAG, "FileWriter::Seek Failed! CurrPos: %lu", uPos);
        }
        _uPos = uPos;
    }

    /// Serialize \pData
    bool Serialize(void* pData, size_t uLen) override;

    /// Flush
    void Flush() override
    {
        if (_uBufferCount)
        {
            aeAssert(_uBufferCount <= sizeof(_pBuffer));
            if (!_pFileHandle->Write(_pBuffer, _uBufferCount))
            {
                AELOGE(AE_GAME_TAG, "FileWriter::Flush Failed!");
            }
            _uBufferCount = 0;
        }
    }
#if BEF_FEATURE_CONFIG_WEB_COLORFUL_TEXT
    std::vector<char> getWebTextFileBuffer() override
    {
        return fileBuffer;
    }
#endif
private:
    std::string _sFileName;
    FileHandle* _pFileHandle;
    size_t _uPos;
    size_t _uBufferCount;
    uint8_t _pBuffer[2048];
#if BEF_FEATURE_CONFIG_WEB_COLORFUL_TEXT
    std::vector<char> fileBuffer;
#endif
};

NAMESPACE_AMAZING_ENGINE_END
