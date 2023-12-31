//
// Created by bytedance on 2020/8/19.
//

#ifndef HERMAS_FILE_UTIL_H
#define HERMAS_FILE_UTIL_H

#include <vector>
#include <memory>
#include "file_path.h"

namespace hermas
{
    enum class FileSysType {
        kOnlyFile,
        kOnlyFolder,
        kAll
    };

	// Get all files in the given dir path, default will include sub dirs.
	std::vector<FilePath> GetFilesName(const FilePath& dir, FileSysType type = FileSysType::kAll);

    // Get all files in the given dir path recursively
    std::vector<FilePath> GetFilesNameRecursively(const FilePath& dir);

    // Rename file name
    void RenameFile(const FilePath& src_path, const FilePath& dst_path);

	// Get file real size
	long long GetFileSize(const FilePath& file_path);

	// Make dir at given path
	bool Mkdir(const FilePath& path);
	// Create multiple levels of directories
	bool Mkdirs(const FilePath& file_path);
	// Fill file zero
	bool FillFileZero(int fd, size_t start_pos, size_t size);

	std::string GetFileData(const FilePath& file_path);

    // confirm if file exits
    bool IsFileExits (FilePath& file_path);

}

#endif //HERMAS_FILE_UTIL_H

#ifdef HERMAS_WIN
#define SEPARATOR L"\\"
#else
#define SEPARATOR "/"
#endif
