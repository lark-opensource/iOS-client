//
//  AWEMemoryGraphWriter.hpp
//  MemoryGraphDemo
//
//  Created by brent.shu on 2019/10/28.
//  Copyright © 2019 brent.shu. All rights reserved.
//

#ifndef AWEMemoryGraphWriter_hpp
#define AWEMemoryGraphWriter_hpp

#import "AWEMemoryAllocator.hpp"
#import "AWEMemoryGraphErrorDefines.hpp"

#import <string>

namespace MemoryGraph {
// 采用分段映射，避免虚拟内存过多
class Writer {
    int m_fd;               // 句柄
    size_t m_current_size;  // 本次之前映射的文件总大小，不包含本次映射
    size_t m_capacity;      // 本次文件映射的最大范围
    size_t m_max_capacity;  // 文件最大容量
    std::string m_path;
    Error m_err;
    char *m_buffer;         // 本次映射mmap的起始地址
    char *m_cursor;         // 可写位置 m_buffer+m_current_usage
    size_t m_current_usage; // 本次文件映射已写入内容占用的size
    void m_ensure_size(size_t size, bool auto_ext);
    void m_ensure_size_for_write(size_t size, bool auto_ext);
public:
    Writer(const std::string &path, size_t capacity, size_t max_capcity);
    ~Writer();
    
    const Error& err();
    
    bool append(const void *src, size_t len);
    
    bool write(const void *src, size_t offset, size_t len);
    
    void content(const void *&buffer, size_t &size);
    
    size_t size();
    
    size_t capacity();
    
    const std::string &path();
    
    bool end();
    
    void f_sync();
    
    void reset();
};

class Reader {
    int m_fd;
    bool m_is_ready;
    size_t m_content_size;
    Error m_err;
public:
    Reader(const std::string &path);
    ~Reader();
    
    const Error& err();
    
    bool readBytes(size_t offset, size_t len, void *buffer);
};

} // MemoryGraph

#endif /* AWEMemoryGraphWriter_hpp */
