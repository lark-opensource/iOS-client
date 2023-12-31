#include <stdio.h>
#include <sys/stat.h>
#include <unistd.h>
#include <string>
#include <vector>
#include "DAVFileExport.h"

#ifndef _BYTED_RENDER_CORE_FILE_PLATFORM_H_
#define _BYTED_RENDER_CORE_FILE_PLATFORM_H_

#if defined(_MSC_VER)
typedef struct _stat _stat_platform_st;
#else
typedef struct stat _stat_platform_st;
#endif

#ifdef __cplusplus
extern "C"
{
#endif
FILE DAV_FILE_EXPORT *fopen_platform(char const *filename, char const *mode);

int access_platform(const char *filename, int mode);

int stat_platform(const char *filename, _stat_platform_st *const _stat);

int mkdir_platform(const char *filename, int mode);

int rmoveDir(const char *dir);

int removeFile(const char *file);

int renameFile(const char *oldName, const char *newName);

int copyFile(const char *srcFilePath, const char *dstFilePath);

bool isDir(const char *path);

bool isFile(const char *path);

bool isFileExist(const char *path);

int wirteToFile(const char *path, const void *data, size_t len);

int readFileString(const char *path, std::string &res);

int DAV_FILE_EXPORT closeFile(FILE *f);

#ifdef __cplusplus
}
#endif

/// 获取目录下的所有item
/// @param dirent 扫描目录
/// @param fileList [out] 输出结果
int getFileList(std::string dirent, std::vector<std::string> &fileList);

/// 根据文件路径字符串，使用 '/' 分割，取最后一部分作为文件名
/// @param filePath 文件路径
const std::string fileDisplayName(const std::string &filePath);

#if defined(_MSC_VER) && defined(__cplusplus)
std::wstring UTF8toWideChar(const std::string& acpstr);
std::string WideChartoUTF8(const std::wstring& wStr);
std::string UTF8toACP(const std::string& acpstr);
#endif

#endif
