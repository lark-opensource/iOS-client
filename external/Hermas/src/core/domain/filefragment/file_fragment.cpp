//
//  file_fragment.cpp
//  FileFragment
//
//  Created by zhouyang11 on 2022/1/24.
//

#include "file_fragment.h"
//#include <mach/vm_page_size.h>
#include "file_fragment_util.h"
#include <sys/mman.h>
#include <sys/param.h>
#include <fcntl.h>
#include <unistd.h>
#include <string.h>
#include <stdio.h>

#define MmapFlags (MAP_SHARED | MAP_FILE)
#define allocate_file_entry_memory (file_map_entry_t)::calloc(1, sizeof(file_map_entry))
#define deallocate_file_entry_memory(x) ::free(x)
 
namespace hermas {

void record_memory_fragment_state(file_map_entry_t entry) {
    memcpy((void*)(entry->addr+memory_block_inuse_offset), &(entry->in_use), memory_block_inuse_bit);
    memcpy((void*)(entry->addr+memory_block_size_offset), &(entry->vme_length), memory_block_size_bit);
}

int
MemoryAllocator::FileManager::initilize(FFFileFragmentConfig &config) {
    if (strlen(config.file_path) <= 0) {
        return -1;
    }
    fd = open(config.file_path, O_CREAT|O_RDWR|O_TRUNC, S_IRUSR|S_IWUSR);
    if (fd != -1) {
        if (ftruncate(fd, config.file_min_capacity) == 0) {
            file_size = config.file_min_capacity;
            ff_printf("file grop from 0M to %luM\n", file_size/k_mb);
            return fd;
        }
    }
    return -1;
}

bool
MemoryAllocator::FileManager::file_grow(size_t size, size_t* grow_size) {
    size = roundup(size, config.file_grow_step);
    if (ftruncate(fd, file_size+size) == 0) {
        file_size += size;
        *grow_size = size;
        ff_printf("file grop from %luM to %luM\n", (file_size-size)/k_mb, file_size/k_mb);
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
    }
}

MemoryAllocator::MemoryAllocator(FFFileFragmentConfig& config):file_avail_size(config.file_min_capacity), file_current_capacity(config.file_min_capacity), mapHdr(NULL), link_tail(NULL) {
    
    fd = file_manager.initilize(config);
    if (fd == -1) {
        return;
    }
    
    mapHdr = (file_map_header_t)::malloc(sizeof(file_map_header));
    file_map_store_init_rb(mapHdr);
    
    file_map_entry_t entry = allocate_file_entry_memory;
    entry->vme_length = config.file_min_capacity;
    entry->vme_start = 0;
    entry->in_use = false;
    entry->addr = reinterpret_cast<uintptr_t>(mmap(NULL, config.file_min_capacity, PROT_READ|PROT_WRITE, MmapFlags, fd, 0));
    record_memory_fragment_state(entry);
    mapHdr->rb_size_head_store.rbh_root = &(entry->size_store);
    link_tail = entry;
    memoryBlockInfoList.push_back({entry->addr, entry->vme_length});
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
        ::munmap((void*)iter->first, iter->second);
        ff_printf("munmap addr = 0x%lx, length = %lu\n", iter->first, iter->second);
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
        ::munmap((void*)iter->first, iter->second);
        ff_printf("munmap addr = 0x%lx, length = %lu\n", iter->first, iter->second);
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

void*
MemoryAllocator::malloc(size_t size) {
    size = align_up(size, 8);
    file_map_entry_t result;
    void* res = NULL;
    if(file_map_store_lookup_entry_rb(mapHdr, size, &result, rb_tree_type_size) == false) {
        return malloc_slow_path(size);
    }else {
        res = reinterpret_cast<void*>(result->addr);
        adjust_content_for_alloc(result, size);
    }
    memset(res, 0, size);
    return res;
}

void*
MemoryAllocator::malloc_slow_path(size_t size) {
    // 文件需要扩容
    size_t grow_size = 0;
    if (file_manager.file_grow(size, &grow_size) == false) {
        return NULL;
    }
    void* new_memory_block_addr = mmap(NULL, grow_size, PROT_READ|PROT_WRITE, MmapFlags, fd, file_current_capacity);
    memoryBlockInfoList.push_back({(uintptr_t)new_memory_block_addr, grow_size});
    
    size_t unused_size = grow_size - size;

    file_map_entry_t used_entry = allocate_file_entry_memory;
    used_entry->vme_length = size;
    used_entry->vme_start = file_current_capacity;
    used_entry->vme_prev = link_tail;
    link_tail->vme_next = used_entry;
    used_entry->in_use = true;
    used_entry->addr = (uintptr_t)new_memory_block_addr;
    _file_map_store_entry_link_rb(mapHdr, used_entry, rb_tree_type_addr);

    if (unused_size > 0) {
        file_map_entry_t unused_entry = allocate_file_entry_memory;
        unused_entry->vme_length = unused_size;
        unused_entry->vme_start = file_current_capacity + size;
        unused_entry->vme_prev = used_entry;
        used_entry->vme_next = unused_entry;
        unused_entry->in_use = false;
        unused_entry->addr = (uintptr_t)new_memory_block_addr + size;
        record_memory_fragment_state(unused_entry);
        link_tail = unused_entry;
        _file_map_store_entry_link_rb(mapHdr, unused_entry, rb_tree_type_size);
    }else {
        link_tail = used_entry;
    }
    
    file_current_capacity += grow_size;

    ff_assert((file_used_size+file_avail_size) == file_current_capacity);
    ff_printf("alloc addr = 0x%lx, end at 0x%lx, length = %ld, file_start = %ld\n", used_entry->addr, used_entry->addr+size, size, used_entry->vme_start);
    return new_memory_block_addr;
}

void
MemoryAllocator::adjust_content_for_alloc(file_map_entry_t entry, size_t size) {
    
    ff_printf("alloc addr = 0x%lx, end at 0x%lx, length = %ld, file_start = %ld\n", entry->addr, entry->addr+size, size, entry->vme_start);
    
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
        entry_to_addr_rbtree->addr = entry->addr;
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
        entry_backto_size_rbtree->addr = entry->addr + size;
        if (entry->vme_next != NULL) {
            entry->vme_next->vme_prev = entry_backto_size_rbtree;
        }
        
        record_memory_fragment_state(entry_backto_size_rbtree);

        _file_map_store_entry_unlink_rb(mapHdr, entry, rb_tree_type_size);
        _file_map_store_entry_link_rb(mapHdr, entry_backto_size_rbtree, rb_tree_type_size);
        _file_map_store_entry_link_rb(mapHdr, entry_to_addr_rbtree, rb_tree_type_addr);

        deallocate_file_entry_memory(entry);

    }else {
        ff_printf("entry smaller than required size, some thing must goes wrong\n");
        ff_assert(0);
    }
    ff_assert((file_used_size+file_avail_size) == file_current_capacity);
}

void
MemoryAllocator::free(void *ptr) {
    uintptr_t addr = align_down((uintptr_t)ptr, 8);
    
    ff_assert((file_used_size + file_avail_size) == file_current_capacity);
    
    /*
    while (file_map_store_lookup_entry_rb(mapHdr, addr, &entry_to_be_freed, rb_tree_type_addr) != false &&
           (addr - entry_to_be_freed->addr + length > entry_to_be_freed->vme_length)) {
        ff_printf("test -- in free addr = %lx, end at %lx, length = %lx, entry->addr = %lx, end at %lx, length = %lx\n", addr, addr+length, length,  entry_to_be_freed->addr, entry_to_be_freed->addr+entry_to_be_freed->vme_length, entry_to_be_freed->vme_length);
        
         1. delete orign entry from addr rbtree
         2. deal with left orign entry if exists
         3. insert new entry into size rbtree
         4. deal with free node before the new entry
         
        _file_map_store_entry_unlink_rb(mapHdr, entry_to_be_freed, rb_tree_type_addr);
        
        file_map_entry_t entry_prev = entry_to_be_freed->vme_prev;
        file_map_entry_t entry_next = entry_to_be_freed->vme_next;
        
        file_map_entry_t entry_insert_to_size_rb = NULL;
        file_map_entry_t entry_back_to_addr_rb_left = NULL;
        
        // left orgin entry
        if (addr > entry_to_be_freed->addr) {
            entry_back_to_addr_rb_left = allocate_file_entry_memory;
            entry_back_to_addr_rb_left->vme_start = entry_to_be_freed->vme_start;
            entry_back_to_addr_rb_left->vme_length = addr-entry_to_be_freed->addr;
            entry_back_to_addr_rb_left->in_use = true;
            entry_back_to_addr_rb_left->vme_prev = entry_prev;
            entry_back_to_addr_rb_left->addr = entry_to_be_freed->addr;
            if (entry_prev != NULL) {
                entry_prev->vme_next = entry_back_to_addr_rb_left;
            }
            entry_prev = entry_back_to_addr_rb_left;
            _file_map_store_entry_link_rb(mapHdr, NULL, entry_back_to_addr_rb_left, rb_tree_type_addr);
        }
        
        // do some merge job
        if (entry_back_to_addr_rb_left == NULL && entry_prev->block_end == false && entry_prev != NULL && entry_prev->in_use == false) {
            _file_map_store_entry_unlink_rb(mapHdr, entry_prev, rb_tree_type_size);
            entry_insert_to_size_rb = entry_prev;
            entry_prev = entry_prev->vme_prev;
            entry_insert_to_size_rb->vme_length += entry_to_be_freed->vme_length;
        }
        if (entry_next != NULL && entry_next->in_use == false) {
            _file_map_store_entry_unlink_rb(mapHdr, entry_next, rb_tree_type_size);
            if (entry_insert_to_size_rb == NULL) {
                entry_insert_to_size_rb = entry_next;
                size_t length_to_free = entry_to_be_freed->vme_length-(addr-entry_to_be_freed->addr);
                entry_insert_to_size_rb->vme_start -= length_to_free;
                entry_insert_to_size_rb->vme_length += length_to_free;
                entry_next = entry_next->vme_next;
            }else {
                entry_insert_to_size_rb->vme_length += entry_next->vme_length;
                file_map_entry_t tmp_entry = entry_next;
                entry_next = entry_next->vme_next;
                deallocate_file_entry_memory(tmp_entry);
            }
        }
        if (entry_insert_to_size_rb == NULL) {
            entry_insert_to_size_rb = allocate_file_entry_memory;
            entry_insert_to_size_rb->in_use = false;
            entry_insert_to_size_rb->vme_start = entry_to_be_freed->vme_start+(addr-entry_to_be_freed->addr);
            entry_insert_to_size_rb->vme_length = entry_to_be_freed->vme_length-(addr-entry_to_be_freed->addr);
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
        
        _file_map_store_entry_link_rb(mapHdr, NULL, entry_insert_to_size_rb, rb_tree_type_size);

        length = length - (entry_to_be_freed->vme_length - (addr-entry_to_be_freed->addr));
        addr = entry_to_be_freed->addr + entry_to_be_freed->vme_length;
        deallocate_file_entry_memory(entry_to_be_freed);
        ff_assert((file_used_size + file_avail_size) == file_current_capacity);
    }
    */
    
    file_map_entry_t entry_to_be_freed;
    if(file_map_store_lookup_entry_rb(mapHdr, addr, &entry_to_be_freed, rb_tree_type_addr) == false) {
        ff_assert(0);
        return;
    }
    
    size_t length = entry_to_be_freed->vme_length;
    
    ff_printf("free addr = 0x%lx, end at 0x%lx, length = %ld, file_start = %ld\n", entry_to_be_freed->addr, entry_to_be_freed->addr+length, length, entry_to_be_freed->vme_start);
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
    file_map_entry_t entry_back_to_addr_rb_left = NULL;
    file_map_entry_t entry_back_to_addr_rb_right = NULL;
    
    // left orgin entry
    if (addr > entry_to_be_freed->addr) {
        entry_back_to_addr_rb_left = allocate_file_entry_memory;
        entry_back_to_addr_rb_left->vme_start = entry_to_be_freed->vme_start;
        entry_back_to_addr_rb_left->vme_length = addr-entry_to_be_freed->addr;
        entry_back_to_addr_rb_left->in_use = true;
        entry_back_to_addr_rb_left->vme_prev = entry_prev;
        entry_back_to_addr_rb_left->addr = entry_to_be_freed->addr;
        if (entry_prev != NULL) {
            entry_prev->vme_next = entry_back_to_addr_rb_left;
        }
        entry_prev = entry_back_to_addr_rb_left;
        _file_map_store_entry_link_rb(mapHdr, NULL, entry_back_to_addr_rb_left, rb_tree_type_addr);
    }
    
    // right orign entry
    if ((addr + length) < (entry_to_be_freed->addr+entry_to_be_freed->vme_length)) {
        entry_back_to_addr_rb_right = allocate_file_entry_memory;
        entry_back_to_addr_rb_right->vme_start = entry_to_be_freed->vme_start+(addr-entry_to_be_freed->addr+length);
        entry_back_to_addr_rb_right->vme_length = entry_to_be_freed->vme_length - (addr-entry_to_be_freed->addr+length);
        entry_back_to_addr_rb_right->in_use = true;
        entry_back_to_addr_rb_right->vme_next = entry_next;
        entry_back_to_addr_rb_right->addr = addr+length;
        if (entry_next != NULL) {
            entry_next->vme_prev = entry_back_to_addr_rb_right;
        }
        entry_next = entry_back_to_addr_rb_right;
        _file_map_store_entry_link_rb(mapHdr, NULL, entry_back_to_addr_rb_right, rb_tree_type_addr);
    }
     */
    // do some merge job
    if ( entry_prev != NULL && entry_prev->in_use == false && ENTRY_RIGHT_BOUNDRY(entry_prev) == addr) {
        _file_map_store_entry_unlink_rb(mapHdr, entry_prev, rb_tree_type_size);
        entry_insert_to_size_rb = entry_prev;
        if (link_tail == entry_to_be_freed) {
            link_tail = entry_insert_to_size_rb;
        }
        entry_prev = entry_prev->vme_prev;
        entry_insert_to_size_rb->vme_length += length;
    }
    if (entry_next != NULL && entry_next->in_use == false && ENTRY_RIGHT_BOUNDRY(entry_to_be_freed) == entry_next->addr) {
        _file_map_store_entry_unlink_rb(mapHdr, entry_next, rb_tree_type_size);
        if (entry_insert_to_size_rb == NULL) {
            entry_insert_to_size_rb = entry_next;
            entry_insert_to_size_rb->vme_start -= length;
            entry_insert_to_size_rb->vme_length += length;
            entry_insert_to_size_rb->addr = entry_to_be_freed->addr;
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
    if (entry_insert_to_size_rb == NULL) {
        entry_insert_to_size_rb = allocate_file_entry_memory;
        entry_insert_to_size_rb->in_use = false;
        entry_insert_to_size_rb->addr = entry_to_be_freed->addr;
        entry_insert_to_size_rb->vme_start = entry_to_be_freed->vme_start+(addr-entry_to_be_freed->addr);
        entry_insert_to_size_rb->vme_length = length;
        if (link_tail == entry_to_be_freed) {
            link_tail = entry_insert_to_size_rb;
        }
    }
    
    record_memory_fragment_state(entry_insert_to_size_rb);

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

    deallocate_file_entry_memory(entry_to_be_freed);
    
    ff_assert((file_used_size + file_avail_size) == file_current_capacity);
}

}
