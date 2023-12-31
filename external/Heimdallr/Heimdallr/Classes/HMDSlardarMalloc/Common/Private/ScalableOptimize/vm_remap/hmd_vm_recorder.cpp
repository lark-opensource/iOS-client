//
//  HMDVMRecorder.cpp
//  Heimdallr
//  
//  Created by zhouyang11 on 2023/2/20
//

#include "hmd_vm_recorder.h"
#include "hmd_virtual_address_store_rb.h"
#include "hmd_mmap_memory_allocator.hpp"

namespace HMDVirtualMemoryManager {

HMDVMRecorder::HMDVMRecorder() {
    rwLock = PTHREAD_RWLOCK_INITIALIZER;
    mapHdr = (file_map_header_t)malloc_zone_calloc(HMDMMapAllocator::g_malloc_zone(), 1, sizeof(file_map_header));
    file_map_store_init_rb(mapHdr);
}

HMDVMRecorder::~HMDVMRecorder() {
    pthread_rwlock_destroy(&rwLock);
}

void
HMDVMRecorder::record(void* ptr, size_t size, void* mapped_ptr) {
    file_map_entry_t entry = allocate_file_entry_memory;
    entry->mixed_addr = (uintptr_t)ptr;
    entry->size = size;
    entry->mapped_addr = (uintptr_t)mapped_ptr;
    pthread_rwlock_wrlock(&rwLock);
    file_map_store_entry_link_rb(mapHdr, NULL, entry);
    pthread_rwlock_unlock(&rwLock);
}

bool
HMDVMRecorder::matchPairSimplifiedVersion(void *ptr, size_t size) {
    pthread_rwlock_rdlock(&rwLock);
    bool res = _matchPairSimplified(ptr, size);
    pthread_rwlock_unlock(&rwLock);
    return res;
}

bool
HMDVMRecorder::matchPairSimplifiedVersion_test(void *ptr, size_t size) {
    pthread_rwlock_rdlock(&rwLock);
    bool res = _matchPairSimplified_test(ptr, size);
    pthread_rwlock_unlock(&rwLock);
    return res;
}

bool
HMDVMRecorder::_matchPairSimplified_test(void* ptr, size_t size) {
    uintptr_t addr = (uintptr_t)ptr;
    file_map_entry_t entry_to_be_freed;
    file_map_entry_t entry_prev;
    file_map_entry_t entry_next;
    bool res = file_map_store_lookup_entry_rb(mapHdr, addr, &entry_to_be_freed, &entry_prev, &entry_next);
    if (res == true) {
        ff_assert(addr >= DECODE_ENTRY_ADDR(entry_to_be_freed) && addr < ENTRY_RIGHT_BOUNDRY(entry_to_be_freed));
        return true;
    }else {
        if (entry_next == NULL || (addr + size) <= DECODE_ENTRY_ADDR(entry_next)) {
            return false;
        }else {
            return true;
        }
    }
}

bool
HMDVMRecorder::_matchPairSimplified(void* ptr, size_t size) {
    uintptr_t addr = (uintptr_t)ptr;
    file_map_entry_t entry_to_be_freed;
    file_map_entry_t entry_prev;
    file_map_entry_t entry_next;
    bool res = file_map_store_lookup_entry_rb(mapHdr, addr, &entry_to_be_freed, &entry_prev, &entry_next);
    if (res == true) {
        ff_assert(addr >= DECODE_ENTRY_ADDR(entry_to_be_freed) && addr < ENTRY_RIGHT_BOUNDRY(entry_to_be_freed));
        return true;
    }else {
        if (entry_next == NULL || (addr + size) <= DECODE_ENTRY_ADDR(entry_next)) {
            return false;
        }else {
            return true;
        }
    }
}

bool
HMDVMRecorder::matchPair(void* ptr, size_t size, EntrySet& entrys_to_be_free, EntrySet& entrys_to_be_insert, MatchedSet &matched_set) {
    pthread_rwlock_rdlock(&rwLock);
    bool res = _matchPair(ptr, size, entrys_to_be_free, entrys_to_be_insert, matched_set);
    pthread_rwlock_unlock(&rwLock);
    return res;
}

bool
HMDVMRecorder::_matchPair(void* ptr, size_t size, EntrySet& entrys_to_be_free, EntrySet& entrys_to_be_insert, MatchedSet &matched_set) {
    uintptr_t addr = (uintptr_t)ptr;
    file_map_entry_t entry_to_be_freed;
    file_map_entry_t entry_prev;
    file_map_entry_t entry_next;
    bool res = file_map_store_lookup_entry_rb(mapHdr, addr, &entry_to_be_freed, &entry_prev, &entry_next);
    if (res == true) {
        ff_assert(addr >= DECODE_ENTRY_ADDR(entry_to_be_freed) && addr < ENTRY_RIGHT_BOUNDRY(entry_to_be_freed));
        
        file_map_entry_t entry_left_padding = nullptr;
        file_map_entry_t entry_right_padding = nullptr;
        size_t size_to_be_freed = size;
        if (addr > DECODE_ENTRY_ADDR(entry_to_be_freed)) {
            entry_left_padding = allocate_file_entry_memory;
            entry_left_padding->mixed_addr = DECODE_ENTRY_ADDR(entry_to_be_freed);
            entry_left_padding->mapped_addr = entry_to_be_freed->mapped_addr;
            entry_left_padding->size = addr - DECODE_ENTRY_ADDR(entry_to_be_freed);
            entrys_to_be_insert.emplace(entry_left_padding);
        }
        if (addr + size < ENTRY_RIGHT_BOUNDRY(entry_to_be_freed)) {
            entry_right_padding = allocate_file_entry_memory;
            entry_right_padding->mixed_addr = addr + size;
            entry_right_padding->mapped_addr = entry_to_be_freed->mapped_addr + (addr + size - DECODE_ENTRY_ADDR(entry_to_be_freed));
            entry_right_padding->size = entry_to_be_freed->size - (addr + size - DECODE_ENTRY_ADDR(entry_to_be_freed));
            entrys_to_be_insert.emplace(entry_right_padding);
        }else {
            size_to_be_freed = ENTRY_RIGHT_BOUNDRY(entry_to_be_freed) - addr;
        }
        matched_set.emplace(entry_to_be_freed->mapped_addr + addr - DECODE_ENTRY_ADDR(entry_to_be_freed), size_to_be_freed);
        entrys_to_be_free.emplace(entry_to_be_freed);
        
        if (entry_right_padding == nullptr && size > size_to_be_freed) {
            return _matchPair((void*)ENTRY_RIGHT_BOUNDRY(entry_to_be_freed), size-size_to_be_freed, entrys_to_be_free, entrys_to_be_insert, matched_set);
        }
        return true;
    }else {
        if (entry_prev == NULL && entry_next == NULL) {
            ff_printf("ff-address rbtree is empty\n");
            return false;
        }
        if (entry_next == NULL || (addr + size) <= DECODE_ENTRY_ADDR(entry_next)) {
            return matched_set.size() != 0;
        }else {
            return _matchPair((void*)DECODE_ENTRY_ADDR(entry_next), size-(DECODE_ENTRY_ADDR(entry_next) - addr), entrys_to_be_free, entrys_to_be_insert, matched_set);
        }
    }
}

void
HMDVMRecorder::adjustPair(EntrySet &entrys_to_be_free, EntrySet &entrys_to_be_insert) {
    pthread_rwlock_wrlock(&rwLock);
    for (auto it = entrys_to_be_free.begin(); it != entrys_to_be_free.end(); it++) {
        file_map_store_entry_unlink_rb(mapHdr, (file_map_entry_t)*it);
        deallocate_file_entry_memory(*it);
    }
    for (auto it = entrys_to_be_insert.begin(); it != entrys_to_be_insert.end(); it++) {
        file_map_store_entry_link_rb(mapHdr, NULL, (file_map_entry_t)*it);
    }
    pthread_rwlock_unlock(&rwLock);
}

bool
HMDVMRecorder::matchAndAdjustPair(void* ptr, size_t size, MatchedSet &matched_set) {
    pthread_rwlock_wrlock(&rwLock);
    bool res = _matchAndAdjustPair(ptr, size, matched_set);
    pthread_rwlock_unlock(&rwLock);
    return res;
}

bool
HMDVMRecorder::_matchAndAdjustPair(void* ptr, size_t size, MatchedSet &matched_set) {
    uintptr_t addr = (uintptr_t)ptr;
    file_map_entry_t entry_to_be_freed;
    file_map_entry_t entry_prev;
    file_map_entry_t entry_next;
    bool res = file_map_store_lookup_entry_rb(mapHdr, addr, &entry_to_be_freed, &entry_prev, &entry_next);
    if (res == true) {
        ff_assert(addr >= DECODE_ENTRY_ADDR(entry_to_be_freed) && addr < ENTRY_RIGHT_BOUNDRY(entry_to_be_freed));
        
        file_map_store_entry_unlink_rb(mapHdr, entry_to_be_freed);

        file_map_entry_t entry_left_padding = nullptr;
        file_map_entry_t entry_right_padding = nullptr;
        size_t size_to_be_freed = size;
        if (addr > DECODE_ENTRY_ADDR(entry_to_be_freed)) {
            entry_left_padding = allocate_file_entry_memory;
            entry_left_padding->mixed_addr = DECODE_ENTRY_ADDR(entry_to_be_freed);
            entry_left_padding->mapped_addr = entry_to_be_freed->mapped_addr;
            entry_left_padding->size = addr - DECODE_ENTRY_ADDR(entry_to_be_freed);
            file_map_store_entry_link_rb(mapHdr, NULL, entry_left_padding);
        }
        if (addr + size < ENTRY_RIGHT_BOUNDRY(entry_to_be_freed)) {
            entry_right_padding = allocate_file_entry_memory;
            entry_right_padding->mixed_addr = addr + size;
            entry_right_padding->mapped_addr = entry_to_be_freed->mapped_addr + (addr + size - DECODE_ENTRY_ADDR(entry_to_be_freed));
            entry_right_padding->size = entry_to_be_freed->size - (addr + size - DECODE_ENTRY_ADDR(entry_to_be_freed));
            file_map_store_entry_link_rb(mapHdr, NULL, entry_right_padding);
        }else {
            size_to_be_freed = ENTRY_RIGHT_BOUNDRY(entry_to_be_freed) - addr;
        }
        matched_set.emplace(entry_to_be_freed->mapped_addr + addr - DECODE_ENTRY_ADDR(entry_to_be_freed), size_to_be_freed);
        uintptr_t next_addr = ENTRY_RIGHT_BOUNDRY(entry_to_be_freed);

        deallocate_file_entry_memory(entry_to_be_freed);

        if (entry_right_padding == nullptr && size > size_to_be_freed) {
            return _matchAndAdjustPair((void*)next_addr, size-size_to_be_freed, matched_set);
        }
        return true;
    }else {
        /*
        if (entry_prev == NULL && entry_next == NULL) {
            ff_printf("ff-address rbtree is empty\n");
            return false;
        }
         */
        if (entry_next == NULL || (addr + size) <= DECODE_ENTRY_ADDR(entry_next)) {
            return matched_set.size() != 0;
        }else {
            return _matchAndAdjustPair((void*)DECODE_ENTRY_ADDR(entry_next), size-(DECODE_ENTRY_ADDR(entry_next) - addr), matched_set);
        }
    }
}

void
HMDVMRecorder::enumeratorStorage(void) {
    pthread_rwlock_rdlock(&rwLock);
    file_map_enumerate_rb(mapHdr);
    pthread_rwlock_unlock(&rwLock);
}

}

