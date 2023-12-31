//
//  AWEMemoryGraphUtils.hpp
//  Hello
//
//  Created by brent.shu on 2019/10/20.
//  Copyright © 2019 brent.shu. All rights reserved.
//

#ifndef AWEMemoryGraphUtils_hpp
#define AWEMemoryGraphUtils_hpp

#import "AWEMemoryAllocator.hpp"
#import "MemoryGraphVMHelper.hpp"
#import "AWEMemoryGraphNode.hpp"
#import "ThreadManager.hpp"

#import <vector>

namespace MemoryGraph {

struct ContextManager {
    ContextManager();
    
    ~ContextManager();
    
    bool is_degrade_version;
    
    void init_none_suspend_required_info(bool do_leak_node_calibration);
    
    void init_suspend_required_info(bool naive_version, size_t max_memory_usage, bool do_cpp_symbolic);
};

void ennmulate_str(std::function<void (const ZONE_STRING &str, int index, bool &stop)> call_back);

MemoryGraphVMHelper *vm_helper();

CFMutableDictionaryRef cls_ptr_helper();

ZONE_SET(uintptr_t)* cls_cache_ptr_helper();

ZONE_SET(uintptr_t)* cls_rwt_ptr_helper();

int str_count();

int increase_str_count();

Class cls_of_ptr(void *ptr, size_t size);

int index_of_cls(void *cls, void *instance);

int index_of_str(const ZONE_STRING &str);

void mark_used_str_idx(int idx);

bool is_potential_ptr(void *ptr);

bool is_cf_cls(Class cls);

uintptr_t vtable_of_cpp_object(const void *ptr);

ZONE_STRING name_of_vtable(uintptr_t vtable);

int  str_index_of_cpp_object(void *ptr);

const VMInfo & vm_info_of_ptr(void *&ptr);

bool is_valid_cftype_id(size_t type_id);

bool is_autorelease_pool_page(void *ptr, size_t size);

inline bool is_arm64() {
#if __LP64__
    return true;
#else
    return false;
#endif
}

} // MemoryGraph

#endif /* AWEMemoryGraphUtils_h */
