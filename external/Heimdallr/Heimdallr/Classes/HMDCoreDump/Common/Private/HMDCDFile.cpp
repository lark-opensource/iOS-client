//
//  HMDCDFile.cpp
//  AWECloudCommand
//
//  Created by maniackk on 2020/10/13.
//

#include "HMDCDFile.hpp"

#import <sys/mman.h>
#import <unistd.h>
#import <sys/stat.h>
#import <sys/fcntl.h>
#import <string>


//promise path is valid, fileSize % pageSize == 0
CDFile::CDFile(const char *path, size_t fileSize):m_path(), m_fd(-1), m_fileSize(fileSize), m_isOk(false) {
    if (path == NULL) {
        return ;
    }

    m_path = path;
    m_fd = open(m_path, O_RDWR|O_CREAT, S_IRWXU);
    
    if (m_fd < 0) {
        return ;
    }
    
    // truncate会将参数fd指定的文件大小改为参数length指定的大小。
    if (ftruncate(m_fd, fileSize) != 0) {
        return ;
    }
    
    /**
     start：映射开始地址，设置NULL则让系统决定映射开始地址；映射成功后，返回该地址
     length：映射区域的长度，单位是Byte；
     prot：映射内存的保护标志，主要是读写相关，是位运算标志；（记得与下面fd对应句柄打开的设置一致）
     flags：映射类型，通常是文件和共享类型；
     fd：文件句柄；
     off_toffset：被映射对象的起点偏移；
     */
    // iPhone XR，大概只能映射1GB左右的文件
    m_buffer = (char *)mmap(nullptr, fileSize, PROT_READ | PROT_WRITE, MAP_SHARED, m_fd, 0);
    if (m_buffer == MAP_FAILED) {
        m_buffer = nullptr;
        return ;
    }
    m_cursor = m_buffer;
    m_isOk = true;
}

CDFile::~CDFile() {
    if (m_fd != -1) {
        close(m_fd);
    }
}

bool CDFile::setCursor(size_t newCursor) {
    if (m_buffer && m_isOk) {
        m_cursor = m_buffer + newCursor;
        return true;
    }
    m_isOk = false;
    return false;
}

bool CDFile::append(const void *src, size_t len) {
    if (!m_isOk) {
        return m_isOk;
    }
    m_isOk = (len <= (m_fileSize - (m_cursor - m_buffer)));
    if (m_buffer && m_isOk) {
        memcpy(m_cursor, src, len);
        m_cursor += len;
        return m_isOk;
    }
    return m_isOk;
}

bool CDFile::putHex64(__uint64_t value) {
    return this->append(&value, 8);
}

bool CDFile::putHex32(__uint32_t value) {
    return this->append(&value, 4);
}

bool CDFile::putHex32WithOffset(__uint32_t value, size_t offset) {
    if (m_buffer && m_isOk) {
        memcpy(m_buffer+offset, &value, 4);
        return true;
    }
    m_isOk = false;
    return false;
}

bool CDFile::end() {
    if ((!m_isOk) || (m_fd == -1)) {
        return false;
    }
    
    size_t size = m_cursor - m_buffer;
    memcpy(m_buffer+8, &size, 8);
    if (ftruncate(m_fd, size) != 0) {
        return false;
    }
    
    if (m_buffer && munmap(m_buffer, m_fileSize) != 0) {
        return false;
    }
    
    if (close(m_fd) == 0) {
        m_fd = -1;
    } else {
        return false;
    }
    return true;
}

bool CDFile::is_ok() {
    return m_isOk;
}
