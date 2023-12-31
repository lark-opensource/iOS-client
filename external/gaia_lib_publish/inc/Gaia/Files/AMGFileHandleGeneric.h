/*==================================================================================
Created:            2017.10.10
Author:             Panhw
==================================================================================*/
#pragma once

#include "Gaia/Files/AMGFileHandle.h"

NAMESPACE_AMAZING_ENGINE_BEGIN

class GAIA_LIB_EXPORT FileHandleGeneric : public FileHandle
{
public:
    explicit FileHandleGeneric(FILE* pFILE)
        : _pFILE(pFILE)
    {
    }
    ~FileHandleGeneric()
    {
        fclose(_pFILE);
        _pFILE = nullptr;
    }

    virtual size_t Tell() override
    {
        return (size_t)ftell(_pFILE);
    }

    virtual bool Seek(size_t uNewPos) override
    {
        return fseek(_pFILE, (long)uNewPos, SEEK_SET) == 0;
    }

    virtual bool InvSeek(size_t uNewInvPos = 0) override
    {
        return fseek(_pFILE, -long(uNewInvPos), SEEK_END) == 0;
    }

    virtual bool Read(void* pDst, size_t uReadLengthToBytes) override
    {
        fread(pDst, uReadLengthToBytes, 1, _pFILE);
        return !ferror(_pFILE);
    }

    virtual bool Write(const void* pSrc, size_t uWriteLengthToBytes) override
    {
        fwrite(pSrc, uWriteLengthToBytes, 1, _pFILE);
        return !ferror(_pFILE);
    }

private:
    FILE* _pFILE;
};

NAMESPACE_AMAZING_ENGINE_END
