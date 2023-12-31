//
//  semi_mmap_file.cpp
//  Hermas
//
//  Created by liuhan on 2022/6/14.
//

#include <fcntl.h>
#include <unistd.h>
#include <sys/mman.h>

#include "log.h"
#include "file_util.h"
#include "semi_mmap_file.h"
#include "file_service_util.h"
#include "semifinished_helper.h"

#include "file_fragment_util.h"

namespace hermas {

static const char* SemiFileTag = "Hermas_SemiMmapFile";

SemiMmapFile::SemiMmapFile(const FilePath& file_path)
:m_file_path(file_path)
,m_fd(INVALID_FILE_HANDLE)
,m_memory_allcator(nullptr)
,mp_mmap_file(nullptr)
{
}

bool SemiMmapFile::CreatSemiFile() {
    struct FFFileFragmentConfig fileConfig;
    fileConfig.file_path = m_file_path.charValue();
    fileConfig.file_min_capacity = 2 * k_mb;
    fileConfig.file_grow_step = 2 * k_mb;
#warning: 如果创建文件失败 什么时候重建
    m_memory_allcator = std::make_unique<MemoryAllocator>(fileConfig);
    m_fd = m_memory_allcator->fd;
    if (m_fd == INVALID_FILE_HANDLE) {
        return false;
    }
    return true;
}

bool SemiMmapFile::OpenSemiFile() {
    bool ret = false;
    long long file_size = 0;
    const char* error_info = nullptr;
#define BREAK_IF(c, s)  if ( (c) ) { error_info = s; break; }

    do {
        auto file_path = m_file_path.charValue();
        m_fd = open(file_path, O_RDWR, S_IRWXU|S_IRGRP|S_IXGRP|S_IROTH|S_IXOTH);
        BREAK_IF(m_fd < 0 || m_fd == INVALID_FILE_HANDLE, "open failed");

        int min_file_size = getpagesize();
        file_size = GetFileSize(m_file_path);
        BREAK_IF(file_size < min_file_size, "file size too small than page size");
        
        m_file_len = file_size;
        mp_mmap_file = static_cast<char *>(mmap(nullptr, static_cast<size_t>(m_file_len), PROT_READ | PROT_WRITE, MAP_SHARED, m_fd, 0));
        BREAK_IF(INVALID_MMAP == mp_mmap_file, "re-mmap error");
        // All Done
        ret = true;
    } while ( false );

    if ( ret == false ) {
        int errcode = errno;
        
        loge(SemiFileTag, "file: %s, %s!! file_size = %lld, errorno = %d", m_file_path.sstrValue().c_str(), error_info, m_file_len, errcode);
        CloseSemiFile();
    }
    return ret;
}

void SemiMmapFile::CloseSemiFile() {
    if (mp_mmap_file != nullptr && mp_mmap_file != INVALID_MMAP) {
        if (-1 == munmap(mp_mmap_file, m_file_len)) {
            loge(SemiFileTag, "close file: %s, munmap error!!", m_file_path.sstrValue().c_str());
        }
    }
    mp_mmap_file = nullptr;
    if ( m_fd != INVALID_FILE_HANDLE ) {
        CLOSE_FILE_HANDLE(m_fd);
        m_fd = INVALID_FILE_HANDLE;
    }
}

void SemiMmapFile::FreeSemiFile() {
    m_recordID_addr_map.clear();
    m_memory_allcator->file_free();
    m_memory_allcator.reset();
    m_fd = INVALID_FILE_HANDLE;
    RemoveFile(m_file_path);
}

bool SemiMmapFile::WriteSemiRecord(const std::string& record, const std::string& traceID, const std::string& spanID, bool isTrace) {
    if (m_fd == INVALID_FILE_HANDLE) {
        return false;
    }
    
    // 申请内存块
    int32_t record_len = (int32_t)record.length();
    int32_t block_len = record_len + SEMIRECORDHEADERLEN;
    
    block_len = align_up(block_len, 8);
    std::string exp_record = record;
    exp_record.resize(block_len - SEMIRECORDHEADERLEN, ' ');
    
    record_len = block_len - SEMIRECORDHEADERLEN;
    char *addr = (char*)(m_memory_allcator->malloc(block_len));
    
    // 存储内存块首地址与recordID映射
    if (isTrace) {
        m_recordID_addr_map[traceID] = addr;
    } else {
        m_recordID_addr_map[spanID] = addr;
    }
    
    // 写入isfree标志
    int blockOffset = 0;
    memcpy(addr, SEMIBLOCKISUSE, SEMIISUSELEN);
    // 写入日志长度
    blockOffset += 1;
    memcpy(addr + blockOffset, &block_len, SEMIBLOCKLENLEN);
    // 写入traceID和日志内容
    blockOffset += SEMIBLOCKLENLEN;
    std::string id_record = traceID + exp_record;
    memcpy(addr + blockOffset, id_record.c_str(), record_len + SEMITRACEIDLEN);
    return true;
}

std::string SemiMmapFile::ReadAndDeleteSemiRecord(const std::string &recordID, bool isTrace) {
    std::string record = "";
    int32_t block_len = 0;
    
    // 获取recordID对应的内存块首地址
    char *addr = FindInSemiMap(recordID, isTrace);
    if (addr == nullptr) {
        return "";
    }
    memcpy(&block_len, addr + SEMIISUSELEN, SEMIBLOCKLENLEN);
    
    // 计算日志长度
    int32_t record_len = block_len - SEMIRECORDHEADERLEN;
    // 获取日志内容
    record = std::string(addr + SEMIRECORDHEADERLEN, record_len);
    record.erase(record.find_last_not_of(" ") + 1);
    // 释放内存块
    DeleteSemiRecord(recordID, addr);
    
    return record;
}

bool SemiMmapFile::DeleteSemiRecord(const std::string &recordID, char *addr) {
    memcpy(addr, SEMIBLOCKISUSE, SEMIISUSELEN);
    m_memory_allcator->free(addr);
    m_recordID_addr_map.erase(recordID);
    return true;
}

bool SemiMmapFile::DeleteSemiRecord(const std::string &recordID, bool isTrace) {
    char *addr = FindInSemiMap(recordID, isTrace);
    if (addr != nullptr) {
        return DeleteSemiRecord(recordID, addr);
    }
    return false;
}

bool SemiMmapFile::ReadBlockIsUse(int32_t fileOffset) {
    std::string isUseStr = std::string(mp_mmap_file + fileOffset, SEMIISUSELEN);
    bool isUse = (isUseStr == "1");
    return isUse;
}

int32_t SemiMmapFile::ReadBlockLen(int32_t fileOffset) {
    int32_t record_len = 0;
    memcpy(&record_len, mp_mmap_file + fileOffset, SEMIBLOCKLENLEN);
    return record_len;
}

std::string SemiMmapFile::ReadSemiRecord(int32_t fileOffset, int32_t length) {
    if (length < 0) return "";
    std::string record = std::string(mp_mmap_file + fileOffset, length);
    record = record.erase(record.find_last_not_of(" ") + 1);
    return record;
}

std::string SemiMmapFile::ReadSemiTraceID(int32_t fileOffset) {
    std::string traceID = ReadSemiRecord(fileOffset, SEMITRACEIDLEN);
    return traceID;
}

char* SemiMmapFile::FindInSemiMap(const std::string& recordID, bool isTrace) {
    if (recordID.empty()) return nullptr;
    std::unordered_map<std::string, char *>::const_iterator got = m_recordID_addr_map.find(recordID);
    if (got != m_recordID_addr_map.end()) {
        return m_recordID_addr_map[recordID];
    } else {
        return nullptr;
    }
}

}
