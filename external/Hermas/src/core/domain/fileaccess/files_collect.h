//
// Created by bytedance on 2020/8/19.
//

#ifndef HERMAS_FILES_COLLECT_H
#define HERMAS_FILES_COLLECT_H

#include <string>
#include "file_path.h"
#include <memory>

namespace hermas {

class FilesCollect final {
public:
    explicit FilesCollect(const FilePath& path);
    ~FilesCollect() = default;

public:
	FilePath getPath();
    unsigned long Size();
    bool HasNextFile();
	FilePath NextFilePath();

private:
    void init();

private:
	FilePath m_path;
    std::unique_ptr<FilePath[]> m_subfiles_relative_path;
    unsigned long m_size;
    int m_index = 0;
};

} //namespace hermas

#endif //HERMAS_FILES_COLLECT_H
