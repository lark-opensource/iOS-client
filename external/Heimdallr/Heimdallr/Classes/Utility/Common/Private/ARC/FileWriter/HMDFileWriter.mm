//
//  HMDFileWriter.cpp
//  Heimdallr
//
//  Created by bytedance on 2023/1/16.
//

#import "HMDFileWriter.hpp"

#import <sys/mman.h>
#import <unistd.h>
#import <sys/stat.h>
#import <malloc/malloc.h>

namespace HMDFileWriter {
const size_t DEFAULT_FILE_SIZE = getpagesize();

Writer::Writer(const std::string &path, size_t capacity, size_t max_capcity):
m_err(), m_current_size(0), m_capacity(0), m_max_capacity(max_capcity), m_fd(-1),
m_buffer(nullptr), m_cursor(nullptr), m_path() {
    if (!path.size()) {
        m_err = Error(ErrorType::LogicalError, "writer init null path");
        return ;
    }
    m_path = path;
    
    auto ns_path = [NSString stringWithUTF8String:path.c_str()];
    if (![[NSFileManager defaultManager] fileExistsAtPath:ns_path]) {
        if (![[NSFileManager defaultManager] createFileAtPath:ns_path contents:nullptr attributes:nil]) {
            m_err = Error(ErrorType::CreateFileFailed, "writer init");
            return ;
        }
    }
    
    m_fd = open(path.c_str(), O_RDWR, S_IRWXU);
    if (m_fd == -1) {
        m_err = Error(ErrorType::OpenFileFailed, "writer init");
        return ;
    }
    // 文件每次扩容固定大小，然后采用懒加载的方式进行分段映射
    if (ftruncate(m_fd, max_capcity) != 0) {
        m_err = Error(ErrorType::TruncateFileFailed, "writer extend");
        return ;
    }
    
    m_ensure_size(capacity, false);
}

void
Writer::m_ensure_size(size_t size, bool auto_ext) {
    if (auto_ext) {
//        size += 1024 * 1024 * 10;
        size += DEFAULT_FILE_SIZE; //每次映射10k文件到内存中
    }
    
    size = round_page(size);
    
    if (m_buffer) {
        if (munmap(m_buffer, m_capacity) != 0) {
            m_err = Error(ErrorType::MunmapFailed, "writer extend");
            return ;
        }
        m_current_size += m_capacity;
    }
    
    while (size + m_current_size > m_max_capacity) {
        if (ftruncate(m_fd, m_max_capacity + DEFAULT_FILE_SIZE) != 0) {
            m_err = Error(ErrorType::TruncateFileFailed, "writer extend");
            return ;
        }
        m_max_capacity += DEFAULT_FILE_SIZE;
    }
    
    m_buffer = (char *)mmap(nullptr, size, PROT_READ | PROT_WRITE, MAP_SHARED, m_fd, m_current_size);
    if (m_buffer == MAP_FAILED) {
        m_err = Error(ErrorType::MMapFailed, "writer extend");
        m_buffer = nullptr;
        return ;
    }
    m_current_usage = 0;
    m_capacity = size;
    m_cursor = m_buffer;
}

Writer::~Writer() {
    if (!end()) {
        if (m_buffer) {
            munmap(m_buffer, m_capacity);
        }
        
        if (m_fd != -1) {
            close(m_fd);
        }
    }
}

size_t
Writer::capacity() {
    return m_current_size + m_capacity;
}

const Error&
Writer::err() {
    return m_err;
}

size_t
Writer::size() {
    return m_current_size + m_current_usage;
}

const std::string &
Writer::path() {
    return m_path;
}
    
bool
Writer::append(const void *src, size_t len) {
    size_t current_free_size = m_capacity - m_current_usage;
    char* new_src = (char*)src;
    size_t new_len = len;
    if (current_free_size < len) {
        memcpy(m_cursor, src, current_free_size);
        new_len = len - current_free_size;
        new_src += current_free_size;
        m_current_usage += current_free_size;
        m_ensure_size(new_len, true);
    }
    if (m_err.is_ok) {
        memcpy(m_cursor, new_src, new_len);
        m_cursor += new_len;
        m_current_usage += new_len;
    }
    return m_err.is_ok;
}

void
Writer::content(const void *&buffer, size_t &size) {
    buffer = m_buffer;
    size = m_current_usage;
}

bool
Writer::end() {
    if (m_fd == -1) {
        return true;
    }
    
    if (m_buffer && munmap(m_buffer, m_capacity) != 0) {
        m_err = Error(ErrorType::MunmapFailed, "writer end");
        return false;
    }
    
    if (ftruncate(m_fd, m_current_size + m_current_usage) != 0) {
        m_err = Error(ErrorType::TruncateFileFailed, "writer extend");
        return false;
    }
    
    if (close(m_fd) == 0) {
        m_fd = -1;
    } else {
        m_err = Error(ErrorType::CloseFileFailed, "writer end");
        return false;
    }
    
    return true;
}

void
Writer::f_sync() {
    if (m_err.is_ok && m_buffer) {
        msync(m_buffer, m_current_usage, MS_SYNC);
    }
}

void
Writer::reset() {
    m_current_usage = 0;
    m_current_size = 0;
    m_cursor = m_buffer;
}

Reader::Reader(const std::string &path): m_is_ready(false), m_fd(-1), m_err() {
    if (!path.size()) {
        m_err = Error(ErrorType::LogicalError, "reader init null path");
        return ;
    }
    
    auto ns_path = [NSString stringWithUTF8String:path.c_str()];
    if (![[NSFileManager defaultManager] fileExistsAtPath:ns_path]) {
        m_err = Error(ErrorType::FileNotExist, "reader init");
        return ;
    }
    
    m_fd = open(path.c_str(), O_RDONLY, S_IRUSR);
    if (m_fd == -1) {
        m_err = Error(ErrorType::OpenFileFailed, "reader init");
        return ;
    }
    
    struct stat st = {};
    if (fstat(m_fd, &st) != -1) {
        m_content_size = static_cast<size_t>(st.st_size);
        if (!m_content_size) {
            m_err = Error(ErrorType::ReadEmptyFile, "reader init");
        }
    } else {
        m_err = Error(ErrorType::GetFileStateFailed, "reader init");
    }
}

Reader::~Reader() {
    if (m_fd != -1) {
        close(m_fd);
    }
}

const Error &
Reader::err() {
    return m_err;
}

bool
Reader::readBytes(size_t offset, size_t len, void *buffer) {
    if (offset + len > m_content_size) {
        m_err = Error(ErrorType::InvalidRead, "reader read");
        return false;
    }
    
    if (lseek(m_fd, offset, SEEK_SET) == -1) {
        m_err = Error(ErrorType::SeekFailed, "reader read");
        return false;
    }
    
    ssize_t result = read(m_fd, buffer, len);
    if (result != len) {
        m_err = Error(ErrorType::InvalidReadResult, "reader read");
        return false;
    }
    
    return true;
}

} // HMDFileWriter
