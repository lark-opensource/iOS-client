//
// Created by bytedance on 2020/8/19.
//

#include "files_collect.h"

#include <vector>

#include "file_util.h"
#include "file_service.h"
#include "log.h"

using namespace hermas;

FilesCollect::FilesCollect(const FilePath& path)
    : m_path(path)
    , m_subfiles_relative_path(nullptr)
    , m_size(0)
    , m_index(0)
{}

FilePath FilesCollect::getPath()
{
    return m_path;
}

unsigned long FilesCollect::Size() {
    init();
    return m_size;
}

bool FilesCollect::HasNextFile() {
    init();
    return m_index < m_size;
}

FilePath FilesCollect::NextFilePath() {
    init();
	auto next_file = m_path.Append(m_subfiles_relative_path[m_index++]);
	return next_file;
}

void FilesCollect::init() {
    if (m_subfiles_relative_path == nullptr) {
		FilePath ready_interval_dir = m_path;

		std::vector<FilePath> sub_files = GetFilesName(m_path);
        int all_size = sub_files.size();
        m_subfiles_relative_path.reset(new FilePath[all_size]);

        for (int i = 0; i < all_size; i++) {
			FilePath relative_path = sub_files[i];
            if (relative_path == FilePath(".") || relative_path == FilePath("..")) {
                continue;
            }
            m_subfiles_relative_path[m_size++] = relative_path;
        }
    }
}
