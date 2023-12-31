//
// Created by bytedance on 2020/8/19.
//


#include "mmap_write_file.h"

#include <sys/mman.h>
#include <mach/mach.h>
#include <sys/param.h>
#include <unistd.h>
#include <fcntl.h>
#include <system_error>
#include <string.h>


#include "env.h"
#include "log.h"
#include "file_util.h"
#include "time_util.h"

namespace hermas {

static const char* TAG = "MmapFile";
static const int g_max_file_size = 20 * 1024 * 1024;

MmapWriteFile::MmapWriteFile(const FilePath& file_path)
        : MmapFile(file_path)
        , m_first_log_wrote(false) { }

MmapWriteFile::~MmapWriteFile() { }

bool MmapWriteFile::CreateWriteFile(E_FileType file_type, Env::ERecordEncryptVer encrypt_ver, int assigned_max_file_size) {
    bool ret = false;
    const char* error_info = nullptr;
    #define BREAK_IF(c, s)  if ( (c) ) { error_info = s; loge("hermas", s); break; }

    do {
		m_fd = open(m_file_path.charValue(), O_CREAT|O_RDWR, S_IRWXU|S_IRGRP|S_IXGRP|S_IROTH|S_IXOTH);
        BREAK_IF(m_fd < 0 || m_fd == INVALID_FILE_HANDLE, "create failed");
        
        int mmap_file_max_len = 0;
        if (assigned_max_file_size <= 0) {
            mmap_file_max_len = GlobalEnv::GetInstance().GetMaxFileSize();
        } else {
            mmap_file_max_len = assigned_max_file_size;
        }
        

        // Truncate the file
        // avoid ftruncate crash
        bool fillRet = FillFileZero(m_fd, 0, mmap_file_max_len);
        BREAK_IF(!fillRet, "fill file zero failed");

        mp_mmap_file = static_cast<char *>(mmap(nullptr, mmap_file_max_len, PROT_READ | PROT_WRITE, MAP_SHARED, m_fd, 0));
        BREAK_IF(INVALID_MMAP == mp_mmap_file, "new mmap failed");
        
        m_file_len = mmap_file_max_len;
        mp_mmap_file_offset = mp_mmap_file;
        m_file_type = file_type;
        m_encrypt_ver = encrypt_ver;
        m_start_time = CurTimeMillis();
        m_stop_time = m_start_time;

        // init file head
        char file_head[FILE_HEAD_LEN] = {0};
        memcpy(file_head, FILE_HEAD, FILE_HEAD_LEN);

        file_head[FILE_HEAD_INDEX_FILE_TYPE] = m_file_type;
        file_head[FILE_HEAD_INDEX_ENCRYPT_VER] = static_cast<char>(m_encrypt_ver);
        memcpy(mp_mmap_file_offset, file_head, FILE_HEAD_LEN);
        memcpy(mp_mmap_file + FILE_HEAD_INDEX_START_TIME, &m_start_time, sizeof(int64_t));
        memcpy(mp_mmap_file + FILE_HEAD_INDEX_STOP_TIME, &m_stop_time, sizeof(int64_t));
        
        mp_mmap_file_offset += FILE_HEAD_LEN;
        SyncContentLen(FILE_HEAD_LEN);
        // All Done
        ret = true;
    } while ( false );

    if ( ret == false ) {
        loge(TAG, "file: %s, %s!! errorno = %d", m_file_path.sstrValue().c_str(), error_info, errno);
        CloseFile();
    }
    return ret;
}



bool MmapWriteFile::Write(const char *record, int32_t record_len, bool is_header) {

    bool is_first_log = false;
    if (!is_header && !m_first_log_wrote) {
        is_first_log = true;
    }
    if (!CheckFileSizeAndExpandIfFirst(record_len + sizeof(int32_t), is_first_log)) {
        return false;
    }

    memcpy(mp_mmap_file_offset, &record_len, sizeof(int32_t));
    mp_mmap_file_offset += sizeof(int32_t);

    memcpy(mp_mmap_file_offset, record, static_cast<size_t>(record_len));
    mp_mmap_file_offset += record_len;

    SyncContentLen(m_content_len + sizeof(int32_t) + record_len);
    UpdateStopTime();
    
    if (is_first_log) {
        m_first_log_wrote = true;
    }
    return true;
}

void MmapWriteFile::CloseFile() {
   MmapFile::CloseFile();
}

void MmapWriteFile:: SyncContentLen(int len) {
    m_content_len = len;
    memcpy(mp_mmap_file + FILE_HEAD_INDEX_CONTENT_LEN, &len, sizeof(int32_t));
}

void MmapWriteFile::UpdateStopTime() {
    m_stop_time = CurTimeMillis();
    memcpy(mp_mmap_file + FILE_HEAD_INDEX_STOP_TIME, &m_stop_time, sizeof(int64_t));
}

bool MmapWriteFile::CheckFileSizeExcludeFirstRecord(int required_len) {
    if (m_content_len == 0) {
        return true;
    }
    int max_file_line = GlobalEnv::GetInstance().GetMaxFileSize();
    if ((m_content_len + sizeof(int32_t) + required_len) > max_file_line) {
        return false;
    } else {
        return true;
    }
}

/**
 * 暂时先不扩容，直接判断是不是会超过文件的最大行数，如果会超过就直接报错强行flush然后重新写入到新文件里面去
 * 如果文件首次写入有效日志，会扩容，避免单条大日志(超过文件阈值)丢失；最大可接收的日志20M
 * @return false if expand fail, else true.
 *
 */
bool MmapWriteFile::CheckFileSizeAndExpandIfFirst(int required_len, bool is_first_log) {
    int ori_max_file_len = m_file_len;
    int new_max_file_len = m_content_len + required_len;
    if ((new_max_file_len) <= ori_max_file_len) {
        return true;
    }
    bool required_len_valid = new_max_file_len < g_max_file_size;
    
    if (is_first_log && required_len_valid) {
        new_max_file_len = (int)round_page(new_max_file_len);
        if (ftruncate(m_fd, new_max_file_len) == 0) {
            long offset = mp_mmap_file_offset - mp_mmap_file;
            m_file_len = new_max_file_len;
            mp_mmap_file = static_cast<char *>(mmap(nullptr, static_cast<size_t>(m_file_len), PROT_READ | PROT_WRITE, MAP_SHARED, m_fd, 0));
            mp_mmap_file_offset = mp_mmap_file + offset;
            logi(TAG, "write file grow from %ll to %ll", ori_max_file_len / (1024 * 1024), m_file_len /(1024 * 1024));
            return true;
        }
    }
    return false;
}

} //namespace hermas
