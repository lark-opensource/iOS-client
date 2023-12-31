/*==================================================================================
Created:            2017.10.11
Author:             Panhw
==================================================================================*/
#pragma once

#include "Gaia/AMGInclude.h"
#include "Gaia/Files/AMGMemoryStream.h"
#include "Gaia/Files/AMGMemoryReader.h"
#include "Gaia/Files/AMGMemoryWriter.h"
#include "Gaia/Files/AMGFileHandleGeneric.h"
#include "Gaia/Files/AMGFileDescriptor.h"
#include "Gaia/Files/AMGFileReader.h"
#include "Gaia/Files/AMGFileWriter.h"
#if AMAZING_PLATFORM != AMAZING_WINDOWS
#include <unistd.h>
#endif
#include <string.h>
#include <functional>
#include "Gaia/Files/AMGFile.h"

NAMESPACE_AMAZING_ENGINE_BEGIN

enum enFileCreateFlags
{
    eFileCreate_Text = 0x00,
    eFileCreate_Binary = 0x01,
    eFileCreate_Append = 0x02,
};

/**
 * @brief header of encrypted data
 */
struct GAIA_LIB_EXPORT AMGSHeader
{
    char magic[8];           ///< "AMGS" + 4 num
    uint32_t version;        ///< version
    uint32_t type;           ///< resource type
    uint32_t content_offset; ///< offset of encrypted data
};

/**
 * @brief encrypted resource type
 */
enum class GAIA_LIB_EXPORT AMGSEncryptedResourceType
{
    Lua,
    Shader,
    Unknown,
};

class GAIA_LIB_EXPORT GAIA_LIB_EXPORT FileUtils
{
public:
    enum : char
    {
        WINDOWS_PART = '\\',
        LINUX_PART = '/',
#if AMAZING_PLATFORM == AMAZING_WINDOWS
        CURR_DIR_PART = WINDOWS_PART,
        NON_CURR_DIR_PART = LINUX_PART,
#else
        CURR_DIR_PART = LINUX_PART,
        NON_CURR_DIR_PART = WINDOWS_PART,
#endif
    };
public:
    static Archive* CreateMemoryReader(const void* pData, size_t uSize);
    static Archive* CreateMemoryWriter(MemoryStream* pTargetStream);
    static Archive* CreateFileReader(const char* sFullFileName);
    static Archive* CreateFileWriter(const char* sFullFileName, int32_t iWriteFlags = eFileCreate_Binary);

    static std::string GetExecWorkDir();
    static std::string MergeDir(const std::string& sLeftDir, const std::string& sRightDir);
    static std::string MergeDir(const char* sLeftDir, const char* sRightDir);
    static std::string FormatDir(const char* sDir);

    /**
     * set callback of create file. called in CreateFileReader and CreateFileWriter
     * @param callback
     */
    static void setCreateFileHandleCallback(const std::function<bool(const char*, int, size_t&, FileHandle*&)>& callback);

    static void setReadFileCallback(const std::function<bool(const char*, std::unique_ptr<File>&)>& ptr);
    static std::unique_ptr<File> readFile(const char* filePath);

    /**
     * set callback of writeToFile
     * @param callback
     */
    static void setWriteFileCallback(const std::function<bool(const char*, unsigned char*, unsigned int, bool&)>& callback);
    static bool writeToFile(const char* filePath, unsigned char* data, unsigned int length);

    static std::string getFileExtension(const std::string& filePath);

    static std::string getFileWithoutExtension(const std::string& filePath);

    static std::vector<std::string> getDirFiles(const std::string& dir);
    static std::vector<std::string> getAllFiles(const std::string& dir);

    static std::string getFileDir(const std::string& filePath);

    static long long getFileSize(const std::string& dir);

    static std::vector<std::string> getDirFilesByExtension(const std::string& dir,
                                                           const std::string& extension);

    /**
     * set callback of IsFileExist, the callback will be called in IsFileExist
     * @param callback
     */
    static void setIsFileExistCallback(const std::function<bool(const char*, bool&)>& callback);
    static bool IsFileExist(const std::string& uri);
    static void CheckAndCompleteFileDir(std::string& dir);

    static bool isDir(const std::string& path);
    static bool isAbsolutePath(const std::string& path);
    static bool isLink(const std::string& path);

    static std::string getAbsolutePath(const std::string& path);

    /**
     * simplify the file path and standardize the path separator
     * @param path filepath
     * @return normalized filepath
     * example
     * 1. simplified path
     * ../abc/.//../xyz => ../xyz
     * /abc/../xyz => /xyz
     * 2. standardize the path separator
     * In posix: \\abc/\\xyz => /abc/xyz
     * In windows: C:/abc\\\\/xyz => C:\\abc\\xyz
     */
    static std::string normalizeFilePath(const std::string& path);

    /**
     * set callback of syncLoadCore
     * @param callback
     */
    static void setSyncLoadCoreCallback(const std::function<bool(const char*, bool&)>& callback);

    /**
     * sync load file from path
     * @param  file path or identification
     */
    static void syncLoadCore(const char*);

    static bool copyFile(const std::string& src, const std::string& dst);

#if defined(__ANDROID_API__) || defined(TARGET_OS_ANDROID)
    static int32_t getFileDescriptor(const std::string& uri);

private:
    static std::string getFileExtensionByFilDes(int32_t fildes);
    static Archive* CreateFileDescriptorReader(int32_t fildes, int32_t flag = eFileCreate_Binary);
#endif
};

NAMESPACE_AMAZING_ENGINE_END
