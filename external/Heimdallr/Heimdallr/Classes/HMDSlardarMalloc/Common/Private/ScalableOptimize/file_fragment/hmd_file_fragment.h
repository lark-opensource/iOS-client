//
//  file_fragment.hpp
//  FileFragment
//
//  Created by zhouyang11 on 2022/1/24.
//

#ifndef file_fragment_hpp
#define file_fragment_hpp

#include "hmd_virtual_memory_macro.h"
#include "hmd_file_fragment_store_rb.h"
#include "hmd_file_fragment_header.h"
#include "hmd_mmap_memory_allocator.hpp"
#include <vector>
#include <unordered_map>
#include <mutex>

//#define DECODE_MEMORYBLOCK_ADDR(block) (((block)->mixed_addr) & 0x7fffffffffffffff)
//#define ENCODE_MEMORYBLOCK_ADDR(addr) (addr | 0x8000000000000000)

#define DECODE_MEMORYBLOCK_ADDR(block) (((block)->mixed_addr))
#define ENCODE_MEMORYBLOCK_ADDR(addr) (addr)

using MemoryAllocatStatus = std::pair<size_t, size_t>;
using namespace HMDMMapAllocator;

namespace HMDMemoryAllocator {

class MemoryAllocator{
    
    class FileManager {
    private:
        int fd = -1;
        size_t file_size = 0;
        MemoryAllocatorConfig config;
    public:
        /// 初始化文件
        /// @return 文件的fd
        int initilize(MemoryAllocatorConfig& config);
        bool file_grow(size_t size, size_t* grow_size);
        void file_free();
        void file_close();
        ~FileManager();
    };
    
    struct MemoryBlock {
        uintptr_t mixed_addr;
        size_t size;
        ZONE_HASH(int, bool)* map = NULL;
        
        MemoryBlock(uintptr_t addr, size_t size, bool need_initlize_map):mixed_addr(addr), size(size) {
            if (need_initlize_map) {
                void* ptr = malloc_zone_malloc(g_malloc_zone(), sizeof(ZONE_HASH(int, bool)));
                map = new(ptr) ZONE_HASH(int, bool)();
            }
        }
        
        ~MemoryBlock() {
            if (map != NULL) {
                delete map;
            }
        }
        
    };
    
private:
    /// used for debug or data analysis
    size_t file_current_capacity = 0;
    size_t file_avail_size = 0;
    size_t file_used_size = 0;
    size_t align_size;
    file_map_header_t mapHdr;
    /// tail of the linklist, used for insert new node when file size grow
    file_map_entry_t link_tail;
    /// record memory block info {start_address, length}
    ZONE_VECTOR(MemoryBlock*) memoryBlockInfoList;
    MemoryAllocatorConfig allocator_config;
    FileManager file_manager;
    std::mutex* internal_mutex;
    int error = 0; // 0 means no error, 1 fd fail, 2 mmap fail
public:
    int fd;
    MemoryAllocator(MemoryAllocatorConfig& config);
    void* malloc(size_t size);
    void free(void* ptr, size_t size);
    ~MemoryAllocator();
    void file_free(void);
    void file_close(void);
    int error_code(void);
    MemoryAllocatStatus status(void);
    bool check_address(uintptr_t, size_t);
    void enumerate_tree(void);
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
    file_map_entry_t malloc_slow_path(size_t size);
    void free_mmap_ptr(uintptr_t addr, size_t size, file_map_entry_t entry_to_be_freed);
    void check_memory_lock(uintptr_t addr, size_t size);
    void internal_free(void* ptr, size_t size);
    void internal_lock();
    void internal_unlock();
};

};

#endif /* file_fragment_hpp */
