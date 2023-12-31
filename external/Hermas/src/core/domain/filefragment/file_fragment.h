//
//  file_fragment.hpp
//  FileFragment
//
//  Created by zhouyang11 on 2022/1/24.
//

#ifndef file_fragment_hpp
#define file_fragment_hpp

#include "file_fragment_config.h"
#include "file_fragment_store_rb.h"
#include "file_fragment_header.h"
#include <vector>

namespace hermas {

class MemoryAllocator{
    
    class FileManager {
    private:
        int fd = -1;
        size_t file_size = 0;
        FFFileFragmentConfig config;
    public:
        /// 初始化文件
        /// @return 文件的fd
        int initilize(FFFileFragmentConfig& config);
        bool file_grow(size_t size, size_t* grow_size);
        void file_free();
        void file_close();
        ~FileManager() = default;
    };
    
private:
    /// used for debug or data analysis
    size_t file_current_capacity = 0;
    size_t file_avail_size = 0;
    size_t file_used_size = 0;
    file_map_header_t mapHdr;
    /// tail of the linklist, used for insert new node when file size grow
    file_map_entry_t link_tail;
    /// record memory block info {start_address, length}
    std::vector<std::pair<uintptr_t, size_t>> memoryBlockInfoList;
    
    FileManager file_manager;
public:
    int fd;
    MemoryAllocator(FFFileFragmentConfig& config);
    void* malloc(size_t size);
    void free(void* addr);
    ~MemoryAllocator() = default;
    
    void file_free();
    void file_close();
private:
    /// manipulate linklist and rbtree
    void _file_map_store_entry_link_rb( struct file_map_header *mapHdr, file_map_entry_t entry, rb_tree_type tree_type);
    void _file_map_store_entry_unlink_rb(struct file_map_header *mapHdr, file_map_entry_t entry, rb_tree_type tree_type);
    /// after mmap we should adjust current rbtrees and linked list
    /// @param entry entry->vme_length >=  size
    /// @param size same as mmap_operation
    void adjust_content_for_alloc(file_map_entry_t entry, size_t size);
    /// no enough space for size, increase the file and remalloc
    /// @param size size fo malloc
    void* malloc_slow_path(size_t size);
};

};

#endif /* file_fragment_hpp */
