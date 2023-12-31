//
//  DAVFile.cpp
//  PixelPlatform
//
//  Created by bytedance on 2021/3/8.
//

#include "DAVFile.h"
#include "file_platform.h"
#include "zip.h"

using namespace davinci::file;

bool DAVFile::removeDir(const std::string &dir) {
    return ::rmoveDir(dir.data());
}

bool DAVFile::removeFile(const std::string &filename) {
    return ::removeFile(filename.data());
}

int DAVFile::copy(const std::string &srcFilePath, const std::string &dstFilePath) {
    return ::copyFile(srcFilePath.data(), dstFilePath.data());
}


bool DAVFile::isDir(const std::string &path) {
    return ::isDir(path.data());
}

bool DAVFile::isDirExist(const std::string &path) {
#ifndef _WIN32
    int mode = R_OK | W_OK | X_OK;
    if (::access_platform(path.c_str(), mode) != 0) {
        return false;
    }
#else
    if (!isFileExist(path.c_str())) {
        return false;
    }
#endif
    return true;
}

bool DAVFile::isFile(const std::string &path) {
    return ::isFile(path.data());
}

int DAVFile::write(const std::string &path, const void *data, size_t len) {
    if (::wirteToFile(path.data(), data, len) == 0) {
        return (int) len;
    }
    return -1;
}

int DAVFile::read(const std::string &path, std::string &res) {
    return ::readFileString(path.data(), res);
}

int DAVFile::getFileList(const std::string &dirent, std::vector<std::string> &fileList) {
    return ::getFileList(dirent.data(), fileList);
}

int DAVFile::mkdir(const std::string &path, int mode) {
    return ::mkdir_platform(path.data(), mode);
}

bool DAVFile::isFileExist(const std::string &path) {
    return ::isFileExist(path.data());
}

bool DAVFile::unZip(const char *zipName, const char *dir,
                    int (*on_extract)(const char *filename, void *arg), void *arg) {
    auto result = zip_extract(zipName, dir, on_extract, arg);
    return result == 0;
}

bool DAVFile::zip(const char *zipname, const char *filenames[], size_t len) {
    auto result = zip_create(zipname, filenames, len);
    return result == 0;
}

bool DAVFile::renameFile(const char *oldName, const char *newName) {
    auto result = ::renameFile(oldName, newName);
    return result == 0;
}

bool DAVFile::unZipSafely(const char *zipPath, const char *unZipPath, bool deleteZipAfterUnZip) {
    bool unZipSuccess = false;
    try {
        auto unzipTemp = std::string(unZipPath) + "_temp";
        if (davinci::file::DAVFile::isDirExist(unzipTemp)) {
            davinci::file::DAVFile::removeDir(unzipTemp);
        }
        if (davinci::file::DAVFile::unZip(zipPath, unzipTemp.c_str(), nullptr, nullptr)) {
            if (davinci::file::DAVFile::isDirExist(unZipPath)) {
                davinci::file::DAVFile::removeDir(unZipPath);
            }
            if (davinci::file::DAVFile::renameFile(unzipTemp.c_str(), unZipPath)) {
                unZipSuccess = true;
            }
        }
    } catch (std::exception &e) {
        unZipSuccess = false;
    }
    if (deleteZipAfterUnZip) {
        davinci::file::DAVFile::removeFile(zipPath);
    }
    return unZipSuccess;
}
