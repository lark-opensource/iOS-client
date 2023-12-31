//
//  file_fragment.cpp
//  FileFragment
//
//  Created by zhouyang11 on 2022/1/24.
//

#include "hmd_file_fragment.h"
#include <mach/vm_param.h>
#include "hmd_file_fragment_util.h"
#include <sys/mman.h>
#include <sys/param.h>
#include <fcntl.h>
#include <unistd.h>
#include <string.h>
#include <stdio.h>
#include "hmd_slardar_malloc_remap.h"

#define MMapFileFlags (MAP_SHARED | MAP_FILE)
#define MMapAnoyFlags (MAP_PRIVATE | MAP_ANON)
#define MMapProt (PROT_READ|PROT_WRITE)
#define MlockSliceCountMin 1

using namespace HMDMemoryAllocator;

namespace {
void adjust_memory_allocator_config(MemoryAllocatorConfig& config) {
    if (config.mlockType == HMDMMapMlockTypeSliceLock && config.mlock_slice_count == 0) {
        config.mlock_slice_count = MlockSliceCountMin;
    }
    if (config.file_path == NULL || strlen(config.file_path) == 0) {
        config.file_path = HMDMemoryAllocator::mmap_file_tmp_path(config.identifier);
    }
}
}
 
namespace HMDMemoryAllocator {

int
MemoryAllocator::FileManager::initilize(MemoryAllocatorConfig &configIn) {
    config = configIn;
    fd = open(config.file_path, O_CREAT|O_RDWR|O_TRUNC, S_IRUSR|S_IWUSR);
    if (fd != -1) {
        if (ftruncate(fd, config.file_initial_size) == 0) {
            file_size = config.file_initial_size;
            ff_printf("ff-file grop from 0M to %luM\n", file_size/k_mb);
            return fd;
        }
    }
    return -1;
}

bool
MemoryAllocator::FileManager::file_grow(size_t size, size_t* grow_size) {
    size = roundup(size, config.file_grow_step);
    size_t new_size = file_size + size;
    if (new_size > config.file_max_size) {
        return false;
    }
    if (ftruncate(fd, new_size) == 0) {
        file_size = new_size;
        *grow_size = size;
        ff_printf("ff-file grop from %luM to %luM\n", (file_size-size)/k_mb, file_size/k_mb);
        return true;
    }
    return false;
}

void
MemoryAllocator::FileManager::file_free() {
    if (fd != -1) {
        ftruncate(fd, 0);
        close(fd);
    }
}

void
MemoryAllocator::FileManager::file_close() {
    if (fd != -1) {
        close(fd);
        rmdir(config.file_path);
    }
}

MemoryAllocator::FileManager::~FileManager() {
    file_close();
}

MemoryAllocatStatus
MemoryAllocator::status() {
    return std::make_pair(file_avail_size, file_used_size);
}
int
MemoryAllocator::error_code() {
    return error;
}

MemoryAllocator::MemoryAllocator(MemoryAllocatorConfig& config):file_avail_size(config.file_initial_size), file_current_capacity(config.file_initial_size), mapHdr(NULL), link_tail(NULL), align_size(config.page_aligned?PAGE_SIZE:8), allocator_config(config) {
    
    adjust_memory_allocator_config(allocator_config);
    fd = file_manager.initilize(allocator_config);
    if (fd == -1) {
        error = 1;
        return;
    }
    
    mapHdr = (file_map_header_t)::malloc_zone_calloc(g_malloc_zone(), 1, sizeof(file_map_header));
    file_map_store_init_rb(mapHdr);
    
    file_map_entry_t entry = allocate_file_entry_memory;
    entry->vme_length = config.file_initial_size;
    entry->vme_start = 0;
    entry->in_use = false;
    
    uintptr_t new_addr = reinterpret_cast<uintptr_t>(mmap(NULL, config.file_initial_size, PROT_READ|PROT_WRITE, MMapFileFlags, fd, 0));
    if (new_addr == -1) {
        error = 2;
        return;
    }
    
    if (allocator_config.mlockType == HMDMMapMlockTypeSliceLock && allocator_config.mlock_slice_count == MlockSliceCountMin) {
        mlock((void*)new_addr, config.file_initial_size);
    }
    
    ENCODE_ENTRY_ADDR(entry, new_addr);
    mapHdr->rb_size_head_store.rbh_root = &(entry->size_store);
    link_tail = entry;
    
    void* ptr = malloc_zone_malloc(g_malloc_zone(), sizeof(MemoryBlock));
    MemoryBlock* bptr = new(ptr) MemoryBlock(ENCODE_MEMORYBLOCK_ADDR(new_addr), entry->vme_length, allocator_config.mlockType == HMDMMapMlockTypeSliceLock && allocator_config.mlock_slice_count != MlockSliceCountMin);
    
    memoryBlockInfoList.push_back(bptr);
    if (config.need_internal_mutex_lock) {
        internal_mutex = new std::mutex();
    }
}

MemoryAllocator::~MemoryAllocator() {
    delete internal_mutex;
}

void
MemoryAllocator::file_free() {
    if (mapHdr != NULL) {
        ::free(mapHdr);
        mapHdr = NULL;
    }
    while (link_tail != NULL) {
        void* tmp = link_tail;
        link_tail = link_tail->vme_prev;
        deallocate_file_entry_memory(tmp);
    }
    for (auto iter = memoryBlockInfoList.begin(); iter != memoryBlockInfoList.end(); iter++) {
        ::munmap((void*)DECODE_MEMORYBLOCK_ADDR(*iter), (*iter)->size);
        ff_printf("munmap addr = 0x%lx, length = %lu\n", DECODE_MEMORYBLOCK_ADDR(*iter), (*iter)->size);
    }
    file_manager.file_free();
}

void
MemoryAllocator::file_close() {
    if (mapHdr != NULL) {
        ::free(mapHdr);
        mapHdr = NULL;
    }
    while (link_tail != NULL) {
        void* tmp = link_tail;
        link_tail = link_tail->vme_prev;
        deallocate_file_entry_memory(tmp);
    }
    for (auto iter = memoryBlockInfoList.begin(); iter != memoryBlockInfoList.end(); iter++) {
        ::munmap((void*)DECODE_MEMORYBLOCK_ADDR(*iter), (*iter)->size);
        ff_printf("munmap addr = 0x%lx, length = %lu\n", DECODE_MEMORYBLOCK_ADDR(*iter), (*iter)->size);
    }
    file_manager.file_close();
}

void
MemoryAllocator::_file_map_store_entry_link_rb( struct file_map_header *mapHdr, file_map_entry_t entry, rb_tree_type tree_type) {
    if (tree_type == rb_tree_type_size) {
        file_avail_size += entry->vme_length;
    }else if(tree_type == rb_tree_type_addr) {
        file_used_size += entry->vme_length;
    }
    file_map_store_entry_link_rb(mapHdr, NULL, entry, tree_type);
}

void
MemoryAllocator::_file_map_store_entry_unlink_rb(struct file_map_header *mapHdr, file_map_entry_t entry, rb_tree_type tree_type) {
    if (tree_type == rb_tree_type_size) {
        file_avail_size -= entry->vme_length;
    }else if(tree_type == rb_tree_type_addr) {
        file_used_size -= entry->vme_length;
    }
    file_map_store_entry_unlink_rb(mapHdr, entry, tree_type);
}

void inline
MemoryAllocator::internal_lock() {
    likely_if(allocator_config.need_internal_mutex_lock) {
        internal_mutex->lock();
    }
}

void inline
MemoryAllocator::internal_unlock() {
    likely_if(allocator_config.need_internal_mutex_lock) {
        internal_mutex->unlock();
    }
}

void*
MemoryAllocator::malloc(size_t size) {
    size = align_up(size, align_size);
    file_map_entry_t result;
    void* res = NULL;
    
    internal_lock();
    
    if(file_map_store_lookup_entry_rb(mapHdr, size, &result, NULL, NULL, rb_tree_type_size) == false) {
        result = malloc_slow_path(size);
        unlikely_if (result == NULL) {
            if (allocator_config.use_anony_map_after_file_exhaust == true) {
                res = ::mmap(NULL, size, MMapProt, MMapAnoyFlags, -1, 0);
            }else {
                res = NULL;
            }
            internal_unlock();
            return res;
        }
    }
    res = (void*)(DECODE_ENTRY_ADDR(result));
    adjust_content_for_alloc(result, size);
    
    if (allocator_config.mlockType == HMDMMapMlockTypeDynamicLock) {
        mlock(res, size);
    }else if (allocator_config.mlockType == HMDMMapMlockTypeSliceLock && allocator_config.mlock_slice_count > MlockSliceCountMin) {
        check_memory_lock((uintptr_t)res, size);
    }
    
    internal_unlock();
    
    memset(res, 0, size);
    return res;
}

void
MemoryAllocator::check_memory_lock(uintptr_t addr, size_t size) {
    
    auto it = std::find_if(memoryBlockInfoList.begin(), memoryBlockInfoList.end(), [addr, size](MemoryBlock* block){
        if (addr >= DECODE_MEMORYBLOCK_ADDR(block) && (addr+size) <= (DECODE_MEMORYBLOCK_ADDR(block)+block->size)) {
            return true;
        }else {
            return false;
        }
    });
    if (it == memoryBlockInfoList.end()) {
        ff_printf("ff-where does this address belong to?\n");
        ff_assert(0);
        return;
    }
    MemoryBlock* block = *it;
    size_t slice = block->size/allocator_config.mlock_slice_count;
    uint8_t start_index = (addr - DECODE_MEMORYBLOCK_ADDR(block))/slice;
    uint8_t end_index = (addr + size - DECODE_MEMORYBLOCK_ADDR(block))/slice;
    for(;start_index <= end_index; start_index++) {
        if (block->map->find(start_index) != block->map->end()) {
            continue;
        }
        block->map->emplace(start_index, true);
        mlock((void*)(DECODE_MEMORYBLOCK_ADDR(block) + slice*start_index), slice);
        ff_printf("ff-mlock addr = 0x%lx, end at 0x%lx, length = %ld\n", DECODE_MEMORYBLOCK_ADDR(block) + slice*start_index, DECODE_MEMORYBLOCK_ADDR(block) + slice*start_index+slice, slice);
    }
}

file_map_entry_t
MemoryAllocator::malloc_slow_path(size_t size) {
    // 文件需要扩容
    size_t grow_size = 0;
    if (file_manager.file_grow(size, &grow_size) == false) {
        return NULL;
    }
    off_t offset = file_current_capacity;
    file_current_capacity += grow_size;
    
    void* new_memory_block_addr = ::mmap((void*)ENTRY_RIGHT_BOUNDRY(link_tail), grow_size, MMapProt, MMapFileFlags, fd, offset);
    
    if (new_memory_block_addr == (void*)-1) {
        return NULL;
    }
    
    if (allocator_config.mlockType == HMDMMapMlockTypeSliceLock && allocator_config.mlock_slice_count == MlockSliceCountMin) {
        mlock((new_memory_block_addr), grow_size);
    }
    
    if ((uintptr_t)new_memory_block_addr == ENTRY_RIGHT_BOUNDRY(link_tail)) {
        auto last_item_iter = memoryBlockInfoList.end() - 1;
        (*last_item_iter)->size = (*last_item_iter)->size + grow_size;
        if (link_tail->in_use == false) {
            _file_map_store_entry_unlink_rb(mapHdr, link_tail, rb_tree_type_size);
            link_tail->vme_length += grow_size;
            _file_map_store_entry_link_rb(mapHdr, link_tail, rb_tree_type_size);
            return link_tail;
        }
    }else {
        void *ptr = malloc_zone_malloc(g_malloc_zone(), sizeof(MemoryBlock));
        MemoryBlock *bptr = new(ptr) MemoryBlock(ENCODE_MEMORYBLOCK_ADDR((uintptr_t)new_memory_block_addr), grow_size, allocator_config.mlock_slice_count != MlockSliceCountMin);
        memoryBlockInfoList.push_back(bptr);
    }
    file_map_entry_t res = allocate_file_entry_memory;
    res->vme_length = grow_size;
    res->vme_start = offset;
    res->vme_prev = link_tail;
    ENCODE_ENTRY_ADDR(res, (uintptr_t)new_memory_block_addr);
    link_tail->vme_next = res;
    link_tail = res;
    _file_map_store_entry_link_rb(mapHdr, link_tail, rb_tree_type_size);
    return res;
}

void
MemoryAllocator::adjust_content_for_alloc(file_map_entry_t entry, size_t size) {
    if (entry->vme_length == size) {
        /*
         entry size equal to mmap size
         1. delete entry from rb_size_tree
         2. insert entry into rb_addr_tree
         3. mark entry as in_use
         */
        _file_map_store_entry_unlink_rb(mapHdr, entry, rb_tree_type_size);
        _file_map_store_entry_link_rb(mapHdr, entry, rb_tree_type_addr);
        entry->in_use = true;
    }else if (entry->vme_length > size){
        /*
         entry size bigger than mmap size, divide orign entry into two parts: entry equal to size and entry left
         1. delete orig entry from rb_size_tree, release orig entry
         2. insert the entry left back to rb_size_tree
         3. insert entry equal to size into rb_addr_tree and mark as in_use
         4. adjust the relationship on the linked list
         */
        file_map_entry_t entry_to_addr_rbtree = allocate_file_entry_memory;
        file_map_entry_t entry_backto_size_rbtree = allocate_file_entry_memory;
        
        if (entry == link_tail) {
            link_tail = entry_backto_size_rbtree;
        }
        
        entry_to_addr_rbtree->in_use = true;
        ENCODE_ENTRY_ADDR(entry_to_addr_rbtree, DECODE_ENTRY_ADDR(entry));
        entry_to_addr_rbtree->vme_start = entry->vme_start;
        entry_to_addr_rbtree->vme_length = size;
        entry_to_addr_rbtree->vme_next = entry_backto_size_rbtree;
        entry_to_addr_rbtree->vme_prev = entry->vme_prev;
        if (entry->vme_prev != NULL) {
            entry->vme_prev->vme_next = entry_to_addr_rbtree;
        }
        
        entry_backto_size_rbtree->in_use = false;
        entry_backto_size_rbtree->vme_start = entry->vme_start+size;
        entry_backto_size_rbtree->vme_length = entry->vme_length-size;
        entry_backto_size_rbtree->vme_next = entry->vme_next;
        entry_backto_size_rbtree->vme_prev = entry_to_addr_rbtree;
        ENCODE_ENTRY_ADDR(entry_backto_size_rbtree, DECODE_ENTRY_ADDR(entry) + size);
        if (entry->vme_next != NULL) {
            entry->vme_next->vme_prev = entry_backto_size_rbtree;
        }

        _file_map_store_entry_unlink_rb(mapHdr, entry, rb_tree_type_size);
        _file_map_store_entry_link_rb(mapHdr, entry_backto_size_rbtree, rb_tree_type_size);
        _file_map_store_entry_link_rb(mapHdr, entry_to_addr_rbtree, rb_tree_type_addr);

        deallocate_file_entry_memory(entry);

    }else {
        ff_printf("ff-entry smaller than required size, some thing must goes wrong\n");
        ff_assert(0);
    }
    ff_assert((file_used_size+file_avail_size) == file_current_capacity);
}

void
MemoryAllocator::free(void *ptr, size_t size) {
    if (allocator_config.need_internal_mutex_lock) {
        std::lock_guard<std::mutex> lock(*internal_mutex);
        internal_free(ptr, size);
        if (allocator_config.mlockType == HMDMMapMlockTypeDynamicLock) {
            munlock(ptr, size);
        }
    }else {
        internal_free(ptr, size);
    }
}

void
MemoryAllocator::internal_free(void* ptr, size_t size) {
    uintptr_t addr = align_down((uintptr_t)ptr, align_size);
    size = align_up(size, align_size);
    file_map_entry_t entry_to_be_freed;
    file_map_entry_t entry_prev;
    file_map_entry_t entry_next;
    bool res = file_map_store_lookup_entry_rb(mapHdr, addr, &entry_to_be_freed, &entry_prev, &entry_next, rb_tree_type_addr);
    if (res == true) {
        if (size == 0) {
            size = entry_to_be_freed->vme_length - (addr - DECODE_ENTRY_ADDR(entry_to_be_freed));
        }
        if ((addr + size) <= ENTRY_RIGHT_BOUNDRY(entry_to_be_freed)) {
            free_mmap_ptr(addr, size, entry_to_be_freed);
        }else {
            size_t size_to_be_freed = ENTRY_RIGHT_BOUNDRY(entry_to_be_freed)-addr;
            free_mmap_ptr(addr, size_to_be_freed, entry_to_be_freed);
            internal_free((void*)ENTRY_RIGHT_BOUNDRY(entry_to_be_freed), size - size_to_be_freed);
        }
    }else {
        if (entry_prev == NULL && entry_next == NULL) {
            ff_printf("ff-address rbtree is empty\n");
        }
        
        ff_printf("ff- mmap free addr = 0x%lx, length = %ld", (uintptr_t)ptr, size);
        
        if (entry_next == NULL || (addr + size) <= DECODE_ENTRY_ADDR(entry_next)) {
            auto it = std::find_if(memoryBlockInfoList.begin(), memoryBlockInfoList.end(), [addr](MemoryBlock* block){
                if (DECODE_MEMORYBLOCK_ADDR(block) <= addr && DECODE_MEMORYBLOCK_ADDR(block)+block->size > addr) {
                    return true;
                }else {
                    return false;
                }
            });
            if (it != memoryBlockInfoList.end()) {
                ff_printf("ff- free addr = 0x%lx not allocated or already being freed\n", addr);
                ff_enumerate_tree();
                ff_print_end();
                ff_assert(0);
            }else {
                ff_enumerate_tree();
                ff_print_end();
                ff_assert(0);
            }
            ::munmap((void*)addr, size);
            ff_printf("ff-free anonymous addr = 0x%lx, end at 0x%lx, length = %ld\n", addr, addr+size, size);
        }else {
            ff_enumerate_tree();
            ff_print_end();
            ff_assert(0);
            size_t size_to_be_freed = DECODE_ENTRY_ADDR(entry_next) - addr;
            ::munmap((void*)addr, size_to_be_freed);
            ff_printf("ff-free anonymous addr = 0x%lx, end at 0x%lx, length = %ld\n", addr, addr+size_to_be_freed, size_to_be_freed);
            internal_free((void*)(DECODE_ENTRY_ADDR(entry_next)), size-size_to_be_freed);
        }
    }
}

void
MemoryAllocator::free_mmap_ptr(uintptr_t addr, size_t length, file_map_entry_t entry_to_be_freed) {
    
    ff_printf("ff-free addr = 0x%lx, length = %ld, entry start at 0x%lx, end at 0x%lx, file_start = %ld\n", addr, length,  DECODE_ENTRY_ADDR(entry_to_be_freed), ENTRY_RIGHT_BOUNDRY(entry_to_be_freed), entry_to_be_freed->vme_start);
    /*
     1. delete orign entry from addr rbtree
     2. deal with left orign entry if exists
     3. deal with right origin entry if exists
     4. insert new entry into size rbtree
     5. deal with free node before/after the new entry
     */
    _file_map_store_entry_unlink_rb(mapHdr, entry_to_be_freed, rb_tree_type_addr);
    
    file_map_entry_t entry_prev = entry_to_be_freed->vme_prev;
    file_map_entry_t entry_next = entry_to_be_freed->vme_next;
    
    file_map_entry_t entry_insert_to_size_rb = NULL;
    
    /*
     begin
     */
    file_map_entry_t entry_back_to_addr_rb_left = NULL;
    file_map_entry_t entry_back_to_addr_rb_right = NULL;
    
    // left orgin entry
    if (addr > DECODE_ENTRY_ADDR(entry_to_be_freed)) {
        entry_back_to_addr_rb_left = allocate_file_entry_memory;
        entry_back_to_addr_rb_left->vme_start = entry_to_be_freed->vme_start;
        entry_back_to_addr_rb_left->vme_length = addr-DECODE_ENTRY_ADDR(entry_to_be_freed);
        entry_back_to_addr_rb_left->in_use = true;
        entry_back_to_addr_rb_left->vme_prev = entry_prev;
        ENCODE_ENTRY_ADDR(entry_back_to_addr_rb_left, DECODE_ENTRY_ADDR(entry_to_be_freed));
        if (entry_prev != NULL) {
            entry_prev->vme_next = entry_back_to_addr_rb_left;
        }
        entry_prev = entry_back_to_addr_rb_left;
        _file_map_store_entry_link_rb(mapHdr, entry_back_to_addr_rb_left, rb_tree_type_addr);
    }
    
    // right orign entry
    if ((addr + length) < ENTRY_RIGHT_BOUNDRY(entry_to_be_freed)) {
        entry_back_to_addr_rb_right = allocate_file_entry_memory;
        entry_back_to_addr_rb_right->vme_start = entry_to_be_freed->vme_start+(addr-DECODE_ENTRY_ADDR(entry_to_be_freed)+length);
        entry_back_to_addr_rb_right->vme_length = entry_to_be_freed->vme_length - (addr-DECODE_ENTRY_ADDR(entry_to_be_freed)+length);
        entry_back_to_addr_rb_right->in_use = true;
        entry_back_to_addr_rb_right->vme_next = entry_next;
        ENCODE_ENTRY_ADDR(entry_back_to_addr_rb_right, addr+length);
        if (entry_next != NULL) {
            entry_next->vme_prev = entry_back_to_addr_rb_right;
        }
        entry_next = entry_back_to_addr_rb_right;
        _file_map_store_entry_link_rb(mapHdr, entry_back_to_addr_rb_right, rb_tree_type_addr);
    }
    /*
     end
     */
    // do some merge job
    if (entry_prev != NULL && entry_prev->in_use == false && ENTRY_RIGHT_BOUNDRY(entry_prev) == addr) {
        _file_map_store_entry_unlink_rb(mapHdr, entry_prev, rb_tree_type_size);
        entry_insert_to_size_rb = entry_prev;
//        if (link_tail == entry_to_be_freed) {
//            link_tail = entry_insert_to_size_rb;
//        }
        entry_prev = entry_prev->vme_prev;
        entry_insert_to_size_rb->vme_length += length;
    }
    if (entry_next != NULL && entry_next->in_use == false && ENTRY_RIGHT_BOUNDRY(entry_to_be_freed) == DECODE_ENTRY_ADDR(entry_next)) {
        _file_map_store_entry_unlink_rb(mapHdr, entry_next, rb_tree_type_size);
        if (entry_insert_to_size_rb == NULL) {
            entry_insert_to_size_rb = entry_next;
            entry_insert_to_size_rb->vme_start -= length;
            entry_insert_to_size_rb->vme_length += length;
            ENCODE_ENTRY_ADDR(entry_insert_to_size_rb, addr);
            entry_next = entry_next->vme_next;
        }else {
            entry_insert_to_size_rb->vme_length += entry_next->vme_length;
            if (link_tail == entry_next) {
                link_tail = entry_insert_to_size_rb;
            }
            file_map_entry_t tmp_entry = entry_next;
            entry_next = entry_next->vme_next;
            deallocate_file_entry_memory(tmp_entry);
        }
    }
    bool should_free_entry = true; // whether to free 'entry_to_be_freed'
    if (entry_insert_to_size_rb == NULL) {
        should_free_entry = false;
        entry_insert_to_size_rb = entry_to_be_freed;
        entry_insert_to_size_rb->in_use = false;
        entry_insert_to_size_rb->vme_start = entry_to_be_freed->vme_start+(addr-DECODE_ENTRY_ADDR(entry_to_be_freed));
        ENCODE_ENTRY_ADDR(entry_insert_to_size_rb, addr);
        entry_insert_to_size_rb->vme_length = length;
    }

    // adjust releationship
    entry_insert_to_size_rb->vme_prev = entry_prev;
    if (entry_prev != NULL) {
        entry_prev->vme_next = entry_insert_to_size_rb;
    }
    entry_insert_to_size_rb->vme_next = entry_next;
    if (entry_next != NULL) {
        entry_next->vme_prev = entry_insert_to_size_rb;
    }
    
    _file_map_store_entry_link_rb(mapHdr, entry_insert_to_size_rb, rb_tree_type_size);

    if (should_free_entry) {
        deallocate_file_entry_memory(entry_to_be_freed);
    }
    
    ff_assert((file_used_size + file_avail_size) == file_current_capacity);
}

bool
MemoryAllocator::check_address(uintptr_t addr, size_t size) {
    auto it = std::find_if(memoryBlockInfoList.begin(), memoryBlockInfoList.end(), [addr, size](MemoryBlock* block){
        if ((addr >= (DECODE_MEMORYBLOCK_ADDR(block)+block->size)) ||
            (addr + size <= DECODE_MEMORYBLOCK_ADDR(block))) {
            return false;
        }else {
            return true;
        }
    });
    if (it != memoryBlockInfoList.end()) {
        return true;
    }
    return false;
}

void
MemoryAllocator::enumerate_tree() {
    internal_mutex->lock();
    file_map_enumerate_rb(mapHdr, rb_tree_type_addr);
    file_map_enumerate_rb(mapHdr, rb_tree_type_size);
    internal_mutex->unlock();
    
    vmrecorder_enumerator(allocator_config.identifier);
}
}
