/**
 * @file AMGFile.h
 * @author wangze (wangze.happy@bytedance.com)
 * @brief File
 * @version 10.21.0
 * @date 2019-12-19
 * @copyright Copyright (c) 2019
 */
#ifndef _AMAZINGENGINE_BYTED_RENDER_CORE_FILE_H_
#define _AMAZINGENGINE_BYTED_RENDER_CORE_FILE_H_

#pragma once
#include <sys/types.h>
#include "Gaia/AMGPrerequisites.h"

#include "Gaia/Platform/AMGPlatformDef.h"
#if AMAZING_PLATFORM == AMAZING_WINDOWS
#include <stdint.h>
/// Type define u_int8_t
typedef uint8_t u_int8_t;
/// Type define u_int16_t
typedef uint16_t u_int16_t;
/// Type define u_int32_t
typedef uint32_t u_int32_t;
#endif

NAMESPACE_AMAZING_ENGINE_BEGIN

/**
 * @brief File
 */
class GAIA_LIB_EXPORT File
{
public:
    /**
     * @brief Constructor
     * @param path file path
     * @param name file name
     * @param content file content's buffer pointer
     * @param length file content's buffer length
     */
    File(const char* path, const char* name, u_int8_t* content, long length)
        : m_path(path)
        , m_name(name)
        , m_content(content)
        , m_length(length)
    {
    }

    /**
     * @brief Get the file content 
     * @return u_int8_t* content's buffer pointer
     */
    u_int8_t* getContent() const
    {
        return m_content.get();
    }

    /**
     * @brief Get the file content's buffer length
     * @return long content's buffer length
     */
    long getLength() const
    {
        return m_length;
    }

    /// Get file path
    const std::string& getPath() const
    {
        return m_path;
    }

    /// Get file name
    const std::string& getName() const
    {
        return m_name;
    }

    /// Get is file valid or not
    bool isValid()
    {
        return m_content && m_length > 0;
    }

    /// Destructor
    ~File()
    {
        // AELOGD(AE_GAME_TAG, "File %s dtor...... %d", m_name.c_str(), nullptr == m_content.get());
    }

private:
    std::string m_path;
    std::string m_name;
    std::unique_ptr<u_int8_t> m_content;
    long m_length = 0;
};

NAMESPACE_AMAZING_ENGINE_END

#endif // _AMAZINGENGINE_BYTED_RENDER_CORE_FILE_H_
