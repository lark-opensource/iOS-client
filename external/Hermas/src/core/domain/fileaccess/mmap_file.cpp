//
// Created by bytedance on 2020/8/6.
//
#include "mmap_file.h"

#ifdef PLATFORM_WIN
#include <windows.h>
#else
#include <sys/mman.h>
#include <unistd.h>
#endif

#include "log.h"
#include "env.h"

namespace hermas {

static const char* TAG = "MmapFile";

MmapFile::MmapFile(const FilePath& file_path)
    : m_file_path(file_path)
    , m_file_type(FILE_TYPE_NONE)
    , m_encrypt_ver(Env::ERecordEncryptVer::NONE)
    , m_fd(INVALID_FILE_HANDLE)
#ifdef PLATFORM_WIN
    , m_hmap(INVALID_MMAP)
#endif
    , m_file_len(0) // 文件长度
    , m_content_len(0) // mmap file 写了内容的长度
    , mp_mmap_file(nullptr)
    , mp_mmap_file_offset(nullptr)
    , m_offset(0) { }

MmapFile::~MmapFile() { }

const FilePath& MmapFile::GetFilePath() const {
    return m_file_path;
}

MmapFile::E_FileType MmapFile::GetFileType() const {
    return m_file_type;
}

Env::ERecordEncryptVer MmapFile::GetEncryptVersion() const {
    return m_encrypt_ver;
}

int64_t MmapFile::GetStartTime() const {
    return m_start_time;
}

int64_t MmapFile::GetStopTime() const {
    return m_stop_time;
}

void MmapFile::CloseFile() {
#ifdef PLATFORM_WIN
    if (mp_mmap_file != nullptr) {
        UnmapViewOfFile(mp_mmap_file);
    }
    if ( m_hmap != INVALID_MMAP ) {
        CLOSE_FILE_HANDLE(m_hmap);
    }
    m_hmap = nullptr;
#else
    if (mp_mmap_file != nullptr && mp_mmap_file != INVALID_MMAP) {
        if (-1 == munmap(mp_mmap_file, m_file_len)) {
            loge(TAG, "close file: %s, munmap error!!", m_file_path.sstrValue().c_str());
        }
    }
#endif
    mp_mmap_file = nullptr;
    if ( m_fd != INVALID_FILE_HANDLE ) {
        CLOSE_FILE_HANDLE(m_fd);
        m_fd = INVALID_FILE_HANDLE;
    }
}

} //namespace hermas
