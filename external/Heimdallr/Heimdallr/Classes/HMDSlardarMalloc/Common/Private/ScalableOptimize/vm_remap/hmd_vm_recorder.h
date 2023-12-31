//
//  HMDVMRecorder.hpp
//  Heimdallr
//  
//  Created by zhouyang11 on 2023/2/20
//

#ifndef HMDVMRecorder_hpp
#define HMDVMRecorder_hpp

#include <stdio.h>
#include <unordered_set>
#include "hmd_virtual_address_store_header.h"
#include <pthread/pthread.h>
#include "hmd_mmap_memory_allocator.hpp"

using namespace HMDMMapAllocator;

namespace HMDVirtualMemoryManager {

struct SimplePairHash {
    std::size_t operator()(const std::pair<uintptr_t, size_t>& p) const {
        return p.first ^ p.second;
    }
};

using EntrySet = ENTRY_ZONE_SET(HMDVirtualMemoryManager::file_map_entry_t);
using MatchedPair = std::pair<uintptr_t, size_t>;
using MatchedSet = MATCHED_ZONE_SET(MatchedPair, SimplePairHash);

class HMDVMRecorder {
private:
    file_map_header_t mapHdr;
    pthread_rwlock_t rwLock;
    bool _matchPair(void* ptr, size_t size, EntrySet& entrys_to_be_free, EntrySet& entrys_to_be_insert, MatchedSet &matched_set);
    bool _matchAndAdjustPair(void* ptr, size_t size, MatchedSet &matched_set);
    bool _matchPairSimplified(void* ptr, size_t size);
    bool _matchPairSimplified_test(void* ptr, size_t size);
public:
    HMDVMRecorder();
    ~HMDVMRecorder();
    
    void record(void* ptr, size_t size, void* mapped_ptr);
    
    bool matchPairSimplifiedVersion(void* ptr, size_t size);
    bool matchPairSimplifiedVersion_test(void* ptr, size_t size);
    bool matchAndAdjustPair(void* ptr, size_t size, MatchedSet &matched_set);
    
    bool matchPair(void* ptr, size_t size, EntrySet& entrys_to_be_free, EntrySet& entrys_to_be_insert, MatchedSet &matched_set);
    void adjustPair(EntrySet &entrys_to_be_free, EntrySet &entrys_to_be_insert);
    
    void enumeratorStorage(void);
};

}

#endif /* HMDVMRecorder_hpp */
