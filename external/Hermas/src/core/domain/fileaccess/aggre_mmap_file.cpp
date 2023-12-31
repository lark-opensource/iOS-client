//
//  aggre_mmap_file.cpp
//  Hermas
//
//  Created by liuhan on 2022/1/20.
//

#include <stdio.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/mman.h>

#include "log.h"
#include "file_util.h"
#include "aggre_mmap_file.h"

namespace hermas {

static const char* TAG = "AggreMmapFile";

AggreMmapFile::AggreMmapFile(const FilePath& file_path)
    : m_file_path(file_path)
    , m_fd(INVALID_FILE_HANDLE)
    , m_file_len(0) // 文件长度
    , mp_mmap_file(nullptr) { }

AggreMmapFile::~AggreMmapFile() { }

bool AggreMmapFile::CreatAggreFile(int aggre_file_max_size) {
    bool ret = false;
    const char* error_info = nullptr;
    #define BREAK_IF(c, s)  if ( (c) ) { error_info = s; break; }

    do {
        m_fd = open(m_file_path.charValue(), O_CREAT|O_RDWR, S_IRWXU|S_IRGRP|S_IXGRP|S_IROTH|S_IXOTH);
        BREAK_IF(m_fd < 0 || m_fd == INVALID_FILE_HANDLE, "create failed");

        int mmap_file_max_len = aggre_file_max_size;

        // Truncate the file
        bool fillRet = FillFileZero(m_fd, 0, mmap_file_max_len);
        BREAK_IF(!fillRet, "fill file zero failed");

        mp_mmap_file = static_cast<char *>(mmap(nullptr, mmap_file_max_len, PROT_READ | PROT_WRITE, MAP_SHARED, m_fd, 0));
        BREAK_IF(INVALID_MMAP == mp_mmap_file, "new mmap failed");
        mp_mmap_file_content = mp_mmap_file + sizeof(int32_t);
        m_file_len = mmap_file_max_len;
        
        
        // All Done
        ret = true;
    } while ( false );

    if ( ret == false ) {
        loge(TAG, "file: %s, %s!! errorno = %d", m_file_path.sstrValue().c_str(), error_info, errno);
        CloseFile();
    }
    
    
    return ret;
}

bool AggreMmapFile::OpenAggreFile() {
    bool ret = false;
    long long file_size = 0;
    const char* error_info = nullptr;
#define BREAK_IF(c, s)  if ( (c) ) { error_info = s; break; }

    do {
        auto file_path = m_file_path.charValue();
        m_fd = open(file_path, O_RDWR, S_IRWXU|S_IRGRP|S_IXGRP|S_IROTH|S_IXOTH);
        BREAK_IF(m_fd < 0 || m_fd == INVALID_FILE_HANDLE, "open failed");

        int min_file_size = getpagesize();
        long long file_size = GetFileSize(m_file_path);
        BREAK_IF(file_size < min_file_size, "file size too small than page size");

        m_file_len = file_size;
        mp_mmap_file = static_cast<char *>(mmap(nullptr, static_cast<size_t>(m_file_len), PROT_READ | PROT_WRITE, MAP_SHARED, m_fd, 0));
        BREAK_IF(INVALID_MMAP == mp_mmap_file, "re-mmap error");
        mp_mmap_file_content = mp_mmap_file + sizeof(int32_t);
//        m_content_len = GetContentLen();

//        BREAK_IF(0 == m_content_len || m_content_len > file_size, "format version unsupported error");

        // All Done
        ret = true;
    } while ( false );

    if ( ret == false ) {
        int errcode = errno;
        
        loge(TAG, "file: %s, %s!! file_size = %lld, errorno = %d", m_file_path.sstrValue().c_str(), error_info, file_size, errcode);
        CloseFile();
    }
    return ret;
}

void AggreMmapFile::CloseFile() {
    if (mp_mmap_file != nullptr && mp_mmap_file != INVALID_MMAP) {
        if (-1 == munmap(mp_mmap_file, m_file_len)) {
            loge(TAG, "close file: %s, munmap error!!", m_file_path.sstrValue().c_str());
        }
    }
    mp_mmap_file = nullptr;
    if ( m_fd != INVALID_FILE_HANDLE ) {
        CLOSE_FILE_HANDLE(m_fd);
        m_fd = INVALID_FILE_HANDLE;
    }
}

bool AggreMmapFile::WriteAggreFile(const char *record, int32_t record_len, int32_t file_offset) {
    if (!mp_mmap_file) {
        loge("AggreMmapFile", "The value of mp_mmap_file is NULL.");
        return false;
    }
    if (!CheckFileSize(record_len, file_offset)) {
        return false;
    }
    logi("RecordAggregation", "Write aggre record. file_offset = %d, record length = %d, file length = %d", file_offset, record_len, m_file_len);
    memcpy(mp_mmap_file + file_offset, record, record_len);
    return true;
}

bool AggreMmapFile::WriteRecordAndLength(const char *record, int32_t record_len, int32_t file_offset) {
    if (!CheckAndExpandFileSize(record_len + sizeof(int32_t), record_len + sizeof(int32_t), file_offset)) {
        loge("AggreMmapFile", "File is too small and file grow failed.");
        return false;
    }
    memcpy(mp_mmap_file + file_offset, &record_len, sizeof(int32_t));
    file_offset += sizeof(int32_t);
    memcpy(mp_mmap_file + file_offset, record, static_cast<size_t>(record_len));
    return true;
}

std::string AggreMmapFile::ReadAggreFile(int32_t file_offset, int32_t block_len) {
    if (!mp_mmap_file) {
        loge("AggreMmapFile", "The value of mp_mmap_file is NULL.");
        return "";
    }
    if (!CheckFileSize(block_len, file_offset)) {
        return "";
    }
    logi("RecordAggregation", "Read aggre record. file_offset = %d, record length = %d, file length = %d", file_offset, block_len, m_file_len);
    std::string record = std::string(mp_mmap_file + file_offset, static_cast<unsigned long>(block_len));
    return record;
}

int32_t AggreMmapFile::ReadRecordLength(int32_t file_offset, int32_t length) {
    int32_t record_len;
    memcpy(&record_len, mp_mmap_file + file_offset, length);
    return record_len;
}

// 内存地址未必连续
bool AggreMmapFile::CheckAndExpandFileSize(int required_len, int expand_len, int32_t file_offset) {
    if ((file_offset + required_len) > m_file_len) {
        if (ftruncate(m_fd, m_file_len + expand_len) == 0) {
            m_file_len += expand_len;
            
            mp_mmap_file = static_cast<char *>(mmap(nullptr, static_cast<size_t>(m_file_len), PROT_READ | PROT_WRITE, MAP_SHARED, m_fd, 0));
            
            logi("AggreMmapFile", "file grow from %ll to %ll", (m_file_len - expand_len) / (1024 * 1024), m_file_len /(1024 * 1024));
            return true;
        } else {
            return false;
        }
    }
    return true;
}

bool AggreMmapFile::CheckFileSize(int required_len, int32_t file_offset) {
    if ((file_offset + required_len) > m_file_len) {
        return false;
    } else {
        return true;
    }
}



}
