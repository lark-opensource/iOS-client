/**
 * @file AMGArchive.h
 * @author wangze (wangze.happy@bytedance.com)
 * @brief File System Archive
 * @version 10.21.0
 * @date 2019-12-19
 * @copyright Copyright (c) 2019
 */
#pragma once
#include "Gaia/AMGPrerequisites.h"
#include "Gaia/AMGRefBase.h"

NAMESPACE_AMAZING_ENGINE_BEGIN

/**
 * @brief Archive
 */
class GAIA_LIB_EXPORT Archive : public RefBase
{
public:
    /// Get size
    virtual size_t Size() = 0;

    /// Get current position
    virtual size_t Tell() = 0;

    /// Seek to position \uPos
    virtual void Seek(size_t uPos) = 0;

    /// Close
    virtual void Close() = 0;

    /// Serialize \pData
    virtual bool Serialize(void* pData, size_t uLen) = 0;

    /// Flush
    virtual void Flush() {}
#if BEF_FEATURE_CONFIG_WEB_COLORFUL_TEXT
    virtual std::vector<char> getWebTextFileBuffer()
    {
        return std::vector<char>();
    }
#endif

public:
    /// Friend function operator << for type int8_t
    friend Archive& operator<<(Archive& Ar, int8_t& i8)
    {
        Ar.Serialize(&i8, sizeof(int8_t));
        return Ar;
    }

    /// Friend function operator << for type uint8_t
    friend Archive& operator<<(Archive& Ar, uint8_t& ui8)
    {
        Ar.Serialize(&ui8, sizeof(uint8_t));
        return Ar;
    }

    /// Friend function operator << for type bool
    friend Archive& operator<<(Archive& Ar, bool& b)
    {
        Ar.Serialize(&b, sizeof(bool));
        return Ar;
    }

    /// Friend function operator << for type uint16_t
    friend Archive& operator<<(Archive& Ar, uint16_t& ui16)
    {
        Ar.Serialize(&ui16, sizeof(uint16_t));
        return Ar;
    }

    /// Friend function operator << for type int16_t
    friend Archive& operator<<(Archive& Ar, int16_t& i16)
    {
        Ar.Serialize(&i16, sizeof(int16_t));
        return Ar;
    }

    /// Friend function operator << for type uint32_t
    friend Archive& operator<<(Archive& Ar, uint32_t& ui32)
    {
        Ar.Serialize(&ui32, sizeof(uint32_t));
        return Ar;
    }

    /// Friend function operator << for type int32_t
    friend Archive& operator<<(Archive& Ar, int32_t& i32)
    {
        Ar.Serialize(&i32, sizeof(int32_t));
        return Ar;
    }

    /// Friend function operator << for type float
    friend Archive& operator<<(Archive& Ar, float& f)
    {
        Ar.Serialize(&f, sizeof(float));
        return Ar;
    }

    /// Friend function operator << for type double
    friend Archive& operator<<(Archive& Ar, double& F)
    {
        Ar.Serialize(&F, sizeof(double));
        return Ar;
    }

    /// Friend function operator << for type int64_t
    friend Archive& operator<<(Archive& Ar, int64_t& i64)
    {
        Ar.Serialize(&i64, sizeof(int64_t));
        return Ar;
    }

    /// Friend function operator << for type uint64_t
    friend Archive& operator<<(Archive& Ar, uint64_t& ui64)
    {
        Ar.Serialize(&ui64, sizeof(uint64_t));
        return Ar;
    }

protected:
    Archive() {}
    virtual ~Archive() {}
};

NAMESPACE_AMAZING_ENGINE_END
