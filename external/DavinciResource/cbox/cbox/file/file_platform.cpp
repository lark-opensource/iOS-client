#include "file_platform.h"

#include <iostream>
#include <fstream>
#include <string.h>

#if defined(_MSC_VER)
#include <Windows.h>
#else

#include <unistd.h>
#include <dirent.h>

#endif

#define GETBIT(v, bit) (((v)&(bit)) == (bit))

FILE *fopen_platform(char const *filename, char const *mode) {
    FILE *f;
#if defined(_MSC_VER)
    wchar_t wMode[64];
    wchar_t wFilename[1024];
    if (0 == MultiByteToWideChar(CP_UTF8 /* UTF8 */, 0, filename, -1, wFilename, sizeof(wFilename)))
        return 0;

    if (0 == MultiByteToWideChar(CP_UTF8 /* UTF8 */, 0, mode, -1, wMode, sizeof(wMode)))
        return 0;

    f = _wfopen(wFilename, wMode);
#else
    f = fopen(filename, mode);
#endif
    return f;
}

int access_platform(const char *filename, int mode) {
#if defined(_MSC_VER)
    wchar_t wFilename[1024];

    if (0 == MultiByteToWideChar(CP_UTF8 /* UTF8 */, 0, filename, -1, wFilename, sizeof(wFilename)))
        return false;

    return _waccess(wFilename, mode);
#else
    return access(filename, mode);
#endif
}

int stat_platform(char const *const filename, _stat_platform_st *const _stat) {
#if defined(_MSC_VER)
    wchar_t wFilename[1024];

    if (0 == MultiByteToWideChar(CP_UTF8 /* UTF8 */, 0, filename, -1, wFilename, sizeof(wFilename)))
        return false;

    return _wstat(wFilename, _stat);
#else
    return stat(filename, _stat);
#endif
}

int mkdir_platform(char const *const filename, int mode) {
#if defined(_MSC_VER)
    wchar_t wFilename[1024];

    if (0 == MultiByteToWideChar(CP_UTF8 /* UTF8 */, 0, filename, -1, wFilename, sizeof(wFilename)))
        return false;

    return _wmkdir(wFilename);
#else
    return mkdir(filename, mode);
#endif
}

#if defined(_MSC_VER)
int rmoveDirW(std::wstring& path) {
    
    std::wstring wsFindPath = path;
    wsFindPath.append(L"/*.*");

    std::wstring wsCurrentFile;
    WIN32_FIND_DATAW wfd;
    HANDLE h = FindFirstFileW(wsFindPath.c_str(), &wfd);
    if (h == INVALID_HANDLE_VALUE)
    {
        return -1;
    }
    do
    {
        if (lstrcmpW(wfd.cFileName, L".") == 0 ||
            lstrcmpW(wfd.cFileName, L"..") == 0)
        {
            continue;
        }
        wsCurrentFile.assign(path);
        wsCurrentFile.append(L"/");
        wsCurrentFile.append(wfd.cFileName);
        if (wfd.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY)
        {
            rmoveDirW(wsCurrentFile);
        }
        else
        {
            DeleteFileW(wsCurrentFile.c_str());
        }
    } while (FindNextFileW(h, &wfd));
   
    FindClose(h);
    RemoveDirectoryW(path.c_str());
    return 0;
}
#endif

int rmoveDir(const char *path) {
#if defined(_MSC_VER)
    if (path == nullptr || strlen(path) <= 0) return -1;
    std::wstring wsPath = UTF8toWideChar(path);
    if (isFile(path)) {
        DeleteFileW(wsPath.c_str());
        return 0;
    }
    
    return rmoveDirW(wsPath);
#else
    DIR *d = opendir(path);
    size_t path_len = strlen(path);
    int r = -1;

    if (d) {
        struct dirent *p;

        r = 0;

        while (!r && (p = readdir(d))) {
            int r2 = -1;
            char *buf;
            size_t len;

            /* Skip the names "." and ".." as we don't want to recurse on them. */
            if (!strcmp(p->d_name, ".") || !strcmp(p->d_name, "..")) {
                continue;
            }

            len = path_len + strlen(p->d_name) + 2;
            buf = (char *) malloc(len);

            if (buf) {
                struct stat statbuf;

                snprintf(buf, len, "%s/%s", path, p->d_name);

                if (!stat(buf, &statbuf)) {
                    if (S_ISDIR(statbuf.st_mode)) {
                        r2 = rmoveDir(buf);
                    } else {
                        r2 = unlink(buf);
                    }
                }

                free(buf);
            }

            r = r2;
        }

        closedir(d);
    }

    if (!r) {
        r = rmdir(path);
    }

    return r;
#endif
}

int removeFile(const char *file) {
#if defined(_MSC_VER)
    if (file == nullptr || strlen(file) <= 0) return -1;
    std::wstring wsPath = UTF8toWideChar(file);
    if (DeleteFileW(wsPath.c_str())) {
        return 0;
    }
#else
    if (remove(file) == 0) {
        return 0;
    }
#endif
    return -1;
}

int renameFile(const char *oldName, const char *newName) {
#if defined(_MSC_VER)
    if (oldName == nullptr || strlen(oldName) <= 0 || newName == nullptr || strlen(newName) <= 0) return -1;
    std::wstring wsOldName = UTF8toWideChar(oldName);
    std::wstring wsNewName = UTF8toWideChar(newName);
	return _wrename(wsOldName.c_str(), wsNewName.c_str());
#else
    return rename(oldName, newName);
#endif
}

int copyFile(const char *srcFilePath, const char *dstFilePath) {
    //size_t len;
    //FILE *src,*dst;
    //char buf[1024] = {0};

    //src = fopen(srcFilePath,"r+");
    //if(!src){
    //    perror("fopen srcFilePath error!");
    //    return -1;
    //}
    //dst = fopen(dstFilePath,"w+");
    //if(!dst){
    //    perror("fopen dstFilePath error!");
    //    return -1;
    //}

    //while((len = fread(buf, 1 , 1024, src)) > 0){
    //    fwrite(buf, 1, len, dst);
    //}

    ////关闭文件
    //fclose(src);
    //fclose(dst);
    //
    //return 0;
    std::ifstream inFile;
    std::ofstream outFile;
#if defined(_MSC_VER)
    std::wstring filePathInW = UTF8toWideChar(srcFilePath);
    inFile.open(filePathInW, std::ios::binary);//打开源文件  
#else
    inFile.open(srcFilePath, std::ios::binary);//打开源文件 
#endif
    if (inFile.fail())//打开源文件失败  
    {
        inFile.close();
        outFile.close();
        return -1;
    }
#if defined(_MSC_VER)
    std::wstring filePathOutW = UTF8toWideChar(dstFilePath);
    outFile.open(filePathOutW, std::ios::binary);//创建目标文件  
#else
    outFile.open(dstFilePath, std::ios::binary);//创建目标文件  
#endif

    if (outFile.fail())//创建文件失败  
    {
        outFile.close();
        inFile.close();
        return -1;
    } else//复制文件
    {
        outFile << inFile.rdbuf();
        outFile.close();
        inFile.close();
        return 0;
    }
}

bool isDir(const char *path) {
#if defined(_MSC_VER)
    wchar_t wFilename[1024];

    if (0 == MultiByteToWideChar(CP_UTF8 /* UTF8 */, 0, path, -1, wFilename, sizeof(wFilename)))
        return false;
    DWORD dwAttr = GetFileAttributesW(wFilename);
    if (dwAttr == -1) return false;
    if ((dwAttr & FILE_ATTRIBUTE_DIRECTORY) != 0) {
        return true;
    }

    return false;
#else
    struct stat s;
    if (stat(path, &s) == 0) {
        return s.st_mode & S_IFDIR;
    }
    return false;
#endif
}

bool isFile(const char *path) {
#if defined(_MSC_VER)
    wchar_t wFilename[1024];

    if (0 == MultiByteToWideChar(CP_UTF8 /* UTF8 */, 0, path, -1, wFilename, sizeof(wFilename)))
        return false;
    DWORD dwAttr = GetFileAttributesW(wFilename);
    if (dwAttr == -1) return false;
    if ((dwAttr & FILE_ATTRIBUTE_DIRECTORY) != 0) {
        return false;
    }

    return true;
#else
    struct stat s;
    if (stat(path, &s) == 0) {
        return s.st_mode & S_IFREG;
    }
    return false;
#endif
}

bool isFileExist(const char *path) {
#if defined(_MSC_VER)
    wchar_t wFilename[1024];

    if (0 == MultiByteToWideChar(CP_UTF8 /* UTF8 */, 0, path, -1, wFilename, sizeof(wFilename)))
        return false;

    DWORD dwAttr = GetFileAttributesW(wFilename);
    if (dwAttr == -1) return false;
    return true;
#else
    struct stat s;
    return (stat(path, &s) == 0 && s.st_mode & S_IFREG);
#endif
}

int wirteToFile(const char *path, const void *data, size_t len) {
    FILE *fd = fopen_platform(path, "w+");
    if (fd == NULL) {
        return -1;
    }
    int ret = 0;
    if (fwrite(data, len, 1, fd) != 1) {
        ret = -1;
    }
    ret = closeFile(fd);

    return ret;
}

int readFileString(const char *path, std::string &res) {
    FILE *fd = fopen_platform(path, "rb");
    if (fd == NULL) {
        return -1;
    }
    fseek(fd, 0, SEEK_END);
    long filesize = ftell(fd);
    rewind(fd);

    char *buffer = (char *) malloc(filesize + 1);
    memset(buffer, 0, filesize + 1);

    if (fread(buffer, 1, filesize, fd) != filesize) {
        free(buffer);
        closeFile(fd);
        return -1;
    }
    res = std::string(buffer);
    free(buffer);
    closeFile(fd);

    return filesize;
}

int closeFile(FILE *f) {
    return fclose(f);
}

int getFileList(std::string dirent, std::vector<std::string> &fileList) {
#if defined(_MSC_VER)
    HANDLE hFileFind;
    WIN32_FIND_DATAW findData;

    std::wstring wDirent = UTF8toWideChar(dirent);
    std::wstring wsFileFind = wDirent + L"/*.*";
    hFileFind = ::FindFirstFileW(wsFileFind.c_str(), &findData);
    if (hFileFind == INVALID_HANDLE_VALUE)
    {
        return -1;
    }

    BOOL bHasData = TRUE;
    while (bHasData == TRUE)
    {
        if (::wcscmp(findData.cFileName, L".") != 0 &&
            ::wcscmp(findData.cFileName, L"..") != 0)
        {
            // wchar to utf8
            std::string fileName = WideChartoUTF8(findData.cFileName);
            fileList.push_back(fileName);
        }

        bHasData = FindNextFileW(hFileFind, &findData);
    }

    ::FindClose(hFileFind);

    return 0;
#else
    DIR *p_dir;
    struct dirent *p_dirent;

    if ((p_dir = opendir((dirent).c_str())) == NULL) {
        return -1;
    }

    while ((p_dirent = readdir(p_dir))) {
        std::string s(p_dirent->d_name);
        if (s != "." && s != "..")
            fileList.push_back(s);
    }
    closedir(p_dir);

    return 0;
#endif
}

const std::string fileDisplayName(const std::string &filePath) {
    std::vector<std::string> res;
    if ("" == filePath) return "";

    const std::string delim = "/";

    char *strs = new char[filePath.length() + 1];
    strcpy(strs, filePath.c_str());

    char *d = new char[delim.length() + 1];
    strcpy(d, delim.c_str());

    char *p = strtok(strs, d);
    while (p) {
        std::string s = p;
        res.push_back(s);
        p = strtok(NULL, d);
    }

    delete[] strs;
    delete[] d;

    if (res.size() == 0) {
        return "";
    }

    return res[res.size() - 1];
}

#if defined(_MSC_VER)
std::wstring UTF8toWideChar(const std::string& acpstr) {
    DWORD dWideBufSize = MultiByteToWideChar(CP_UTF8, 0, (LPCSTR)acpstr.c_str(), -1, NULL, 0);
    wchar_t* pWideBuf = new wchar_t[dWideBufSize];
    wmemset(pWideBuf, 0, dWideBufSize);
    MultiByteToWideChar(CP_UTF8, 0, (LPCSTR)acpstr.c_str(), -1, pWideBuf, dWideBufSize);

    std::wstring widestr = pWideBuf;
    delete[] pWideBuf;
    return widestr;
}

std::string WideChartoUTF8(const std::wstring& wStr) {

    INT len = ::WideCharToMultiByte(CP_UTF8, 0, wStr.c_str(), -1, NULL, 0, NULL, NULL);
    if (len <= 0)
    {
        return "";
    }

    char* szUtf8 = new char[len];
    memset(szUtf8, 0, len);
    ::WideCharToMultiByte(CP_UTF8, 0, wStr.c_str(), -1, szUtf8, len, NULL, NULL);

    std::string utf8Str = szUtf8;
    delete[] szUtf8;
    return utf8Str;
}

std::string UTF8toACP(const std::string& utf8str) {
    DWORD dWideBufSize = MultiByteToWideChar(CP_UTF8, 0, (LPCSTR)utf8str.c_str(), -1, NULL, 0);
    wchar_t* pWideBuf = new wchar_t[dWideBufSize];
    wmemset(pWideBuf, 0, dWideBufSize);
    MultiByteToWideChar(CP_UTF8, 0, (LPCSTR)utf8str.c_str(), -1, pWideBuf, dWideBufSize);

    DWORD dACPBufSize = WideCharToMultiByte(CP_ACP, 0, (LPCWSTR)pWideBuf, -1, NULL, 0, NULL, NULL);

    char* pACPBuf = new char[dACPBufSize];
    memset(pACPBuf, 0, dACPBufSize);
    WideCharToMultiByte(CP_ACP, 0, (LPCWSTR)pWideBuf, -1, pACPBuf, dACPBufSize, NULL, NULL);

    std::string acpstr = pACPBuf;
    delete[] pWideBuf;
    delete[] pACPBuf;
    return acpstr;
}
#endif
