/**
 * @file AMGFileDescriptor.h
 * @author aojian (aojian@bytedance.com)
 * @brief file descriptor
 * @version 0.1
 * @date 2021-05-14
 * 
 * @copyright Copyright (c) 2021
 * 
 */

#if defined(__ANDROID_API__) || defined(TARGET_OS_ANDROID)
#pragma once
#include <unistd.h>
#include "Gaia/Files/AMGFileHandle.h"

NAMESPACE_AMAZING_ENGINE_BEGIN

class GAIA_LIB_EXPORT FileDescriptor : public FileHandle
{
public:
    explicit FileDescriptor(int32_t fildes)
        : m_fildes(fildes)
    {
    }

    ~FileDescriptor()
    {
        if (m_fildes > 0)
            close(m_fildes);
    }

    virtual size_t Tell() override
    {
        return (size_t)lseek(m_fildes, 0, SEEK_CUR);
    }

    virtual bool Seek(size_t uNewPos) override
    {
        return lseek(m_fildes, (long)uNewPos, SEEK_SET) == 0;
    }

    virtual bool InvSeek(size_t uNewInvPos = 0) override
    {
        return lseek(m_fildes, -long(uNewInvPos), SEEK_END) == 0;
    }

    virtual bool Read(void* pDst, size_t uReadLengthToBytes) override
    {
        return read(m_fildes, pDst, uReadLengthToBytes) != -1;
    }

    virtual bool Write(const void* pSrc, size_t uWriteLengthToBytes) override
    {
        return write(m_fildes, pSrc, uWriteLengthToBytes) != -1;
    }

private:
    int32_t m_fildes = 0;
};

NAMESPACE_AMAZING_ENGINE_END

#endif