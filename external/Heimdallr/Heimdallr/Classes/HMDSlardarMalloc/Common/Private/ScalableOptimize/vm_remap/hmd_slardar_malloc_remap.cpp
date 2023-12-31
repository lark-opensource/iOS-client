//
//  SlardarMallocRemap.c
//  Heimdallr
//
//  Created by zhouyang11 on 2022/12/28.
//

#include "hmd_slardar_malloc_remap.h"
#include <sys/mman.h>
#include <mach/vm_statistics.h>
#include <pthread/pthread.h>
#include <mutex>
#include "HMDMacro.h"
#include <string.h>
#include <unordered_map>
#include <mach/vm_page_size.h>
#include "hmd_mmap_allocator.h"
#include "hmd_vm_remap_util.h"
#include "hmd_vm_recorder.h"
#include "hmd_virtual_memory_macro.h"
#include <mach/mach_init.h>
#include "HMDCompactUnwind.hpp"
#include "hmd_user_exception_wrapper.h"

#define memory_logging_type_free 0
#define memory_logging_type_generic 1 /* anything that is not allocation/deallocation */
#define memory_logging_type_alloc 2 /* malloc, realloc, etc... */
#define memory_logging_type_dealloc 4 /* free, realloc, etc... */
#define memory_logging_type_vm_allocate 16 /* vm_allocate or mmap */
#define memory_logging_type_vm_deallocate 32 /* vm_deallocate or munmap */
#define memory_logging_type_mapped_file_or_shared_mem 128 /* mmap or vm_map or vm_remap */

typedef void(malloc_logger_t)(uint32_t type, uintptr_t arg1, uintptr_t arg2, uintptr_t arg3, uintptr_t result,
                              uint32_t num_hot_frames_to_skip);

extern malloc_logger_t *__syscall_logger;

using namespace HMDVirtualMemoryManager;

// Thread Info for Logging
typedef mach_port_t thread_id;

using namespace HMDVirtualMemoryManager;
using namespace std;
using HMDVMRecorderMap = unordered_map<const char*, HMDVMRecorder*>;
using HMDSlardarMallocBinaryScope = std::pair<uintptr_t, size_t>;

namespace  {
unordered_set<std::string> mapped_tag_set;

const char* identifier = NULL;
//CFImageSymbolInfo mach_vm_deallocate_function = {0};
//CFImageSymbolInfo mach_vm_map_function = {0};
HMDSlardarMallocBinaryScope libSystemKernelTextSegmentScope;

#if HMDSlardarMallocMultiInstance == 0

HMDVMRecorder *recorder_instance = NULL;

#endif

pthread_key_t s_thread_info_key = 0;
typedef union {
    uint64_t value;
    struct {
        uint32_t t_id;
        bool is_ignore;
    } detail;
} thread_info_for_logging_t;

uint64_t current_thread_info_for_logging() {
    uint64_t value = (uintptr_t)pthread_getspecific(s_thread_info_key);
    
    if (value == 0) {
        thread_info_for_logging_t thread_info;
        thread_info.detail.is_ignore = false;
        thread_info.detail.t_id = pthread_mach_thread_np(pthread_self());
        pthread_setspecific(s_thread_info_key, (void *)(uintptr_t)thread_info.value);
        return thread_info.value;
    }
    
    return value;
}

void set_curr_thread_ignore_logging(bool ignore) {
    thread_info_for_logging_t thread_info;
    thread_info.value = current_thread_info_for_logging();
    thread_info.detail.is_ignore = ignore;
    pthread_setspecific(s_thread_info_key, (void *)(uintptr_t)thread_info.value);
}

bool is_thread_ignoring_logging() {
    thread_info_for_logging_t thread_info;
    thread_info.value = current_thread_info_for_logging();
    return thread_info.detail.is_ignore;
}

pthread_rwlock_t* global_rwmutex() {
    static pthread_rwlock_t mutex = PTHREAD_RWLOCK_INITIALIZER;
    return &mutex;
}

HMDVMRecorderMap* global_recorder_map() {
    static HMDVMRecorderMap* global_map = new HMDVMRecorderMap();
    return global_map;
}

bool vm_memory_malloc_check(int tag) {
    return mapped_tag_set.find(to_string(tag)) != mapped_tag_set.end();
}

HMDVMRecorder*
find_recorder(const char* identifier) {
#if HMDSlardarMallocMultiInstance == 0
    return recorder_instance;
#else
    HMDVMRecorder *res = NULL;
    pthread_rwlock_rdlock(global_rwmutex());
    auto it = global_recorder_map()->find(identifier);
    auto end = global_recorder_map()->end();
    if (it == end) {
        ff_assert(0);
        res = NULL;
    }else {
        res = it->second;
    }
    pthread_rwlock_unlock(global_rwmutex());
    return res;
#endif
}

CLANG_DIAGNOSTIC_PUSH
CLANG_DIAGNOSTIC_IGNORE_UNUSED_FUNCTION
void
destroy_recorder(const char* identifier) {
    CLANG_DIAGNOSTIC_POP
    HMDVMRecorder *res = NULL;
    pthread_rwlock_wrlock(global_rwmutex());
    auto it = global_recorder_map()->find(identifier);
    auto end = global_recorder_map()->end();
    if (it == end) {
        ff_assert(0);
        res = NULL;
    }else {
        res = it->second;
        global_recorder_map()->erase(it);
        delete res;
    }
    pthread_rwlock_unlock(global_rwmutex());
}

void slardar_malloc_memory_event_callback(uint32_t type_flags, uintptr_t zone_ptr, uintptr_t arg2, uintptr_t arg3, uintptr_t return_val, uint32_t num_hot_to_skip) {
    
    /*
     * vmmap / vmremap / mmap
     if (type_flags & memory_logging_type_mapped_file_or_shared_mem) {
     return;
     }
     */
    
    if (is_thread_ignoring_logging()) {
        // Prevent a thread from deadlocking against itself if vm_allocate() or malloc()
        // is called below here, from woking thread or dumping thread
        return;
    }
    
    size_t size = 0;
    uintptr_t ptr_arg = 0;
    
    if (type_flags & memory_logging_type_vm_deallocate) {
        ptr_arg = arg2;
        if (ptr_arg == 0 || (ptr_arg & PAGE_MASK)) {
            return; // free(nil)
        }
        uintptr_t end = round_page(ptr_arg + arg3);
        size = end - ptr_arg;
        
        if (size <= 0) {
            return;
        }
        
#ifdef HMDBytestDefine
        bool check_address = hmd_mmap_memory_allocator_check_address(identifier, ptr_arg, size);
        ff_assert(check_address == false);
#endif
        auto recorder = find_recorder(identifier);
        bool find = recorder->matchPairSimplifiedVersion((void*)ptr_arg, size);
        if (find) {
            set_curr_thread_ignore_logging(true);
            uintptr_t lr = (uintptr_t)__builtin_return_address(0);
            if (lr < libSystemKernelTextSegmentScope.first || lr >=  libSystemKernelTextSegmentScope.second) {
                ff_printf("ff- type = free and match, address = 0x%lx, size = %ld. not mach_vm_deallocate.\n", ptr_arg, size);
                hmd_slardar_malloc_trigger_user_exception_and_upload("not mach_vm_deallocate");
            }else {
                ff_printf("ff- type = free and match, address = 0x%lx, size = %ld\n", ptr_arg, size);
                MatchedSet matched_set;
                find = recorder->matchAndAdjustPair((void*)ptr_arg, size, matched_set);
                if (find) {
                    for (auto it = matched_set.begin(); it != matched_set.end(); it++) {
                        MatchedPair pair = *it;
                        hmd_free(identifier, (void*)pair.first, pair.second);
                    }
                }
#ifdef hmd_memory_map_log_enable
                hmd_mmap_allocator_status(identifier);
#endif
            }
            set_curr_thread_ignore_logging(false);
            
        }
    }else if ((type_flags & memory_logging_type_vm_allocate) && (type_flags & memory_logging_type_mapped_file_or_shared_mem)) {
        if (return_val == 0 || return_val == (uintptr_t)MAP_FAILED) {
            return;
        }
        size = (size_t)round_page(arg2);
        ptr_arg = return_val;
        
        int tag = 0;
        VM_GET_FLAGS_ALIAS(type_flags, tag);
        
#ifdef HMDBytestDefine
        if (tag != VM_MEMORY_REALLOC) {
            bool check_address = hmd_mmap_memory_allocator_check_address(identifier, ptr_arg, size);
            assert(check_address == false);
        }
#endif
        void* ptr = nullptr;
        if (vm_memory_malloc_check(tag) == true) {
            set_curr_thread_ignore_logging(true);
            
#ifdef HMDBytestDefine
            uintptr_t lr = (uintptr_t)__builtin_return_address(0);
            if (lr < libSystemKernelTextSegmentScope.first || lr >=  libSystemKernelTextSegmentScope.second) {
                ff_printf("ff- type = alloc, address = 0x%lx, size = %ld. not mach_vm_map.\n", ptr_arg, size);
                hmd_slardar_malloc_trigger_user_exception_and_upload("not mach_vm_map");
            }
            auto recorder = find_recorder(identifier);
            bool find = recorder->matchPairSimplifiedVersion_test((void*)ptr_arg, size);
            if (find) {
                ff_printf("ff- vm_alloc_twice: ptr = 0x%lx, size = %ld\n", ptr_arg, size);
                hmd_slardar_malloc_trigger_user_exception_and_upload("vm_alloc_twice");
                return;
            }
#endif
            
            ptr = hmd_alloc(identifier, size);
            if (ptr != nullptr) {
                bool res = hmd_vm_remap((void*)ptr_arg, ptr, (size_t)size);
                if (res) {
                    auto recorder = find_recorder(identifier);
                    recorder->record((void*)ptr_arg, size, ptr);
                }else {
                    hmd_free(identifier, ptr, 0);
                    ff_assert(0);
                }
            }
            ff_printf("ff- type = alloc, address = 0x%lx, size = %zu, tag = %d, mapped_size = 0x%lx\n", ptr_arg, size, tag, (uintptr_t)ptr);
            set_curr_thread_ignore_logging(false);
#ifdef hmd_memory_map_log_enable
            hmd_mmap_allocator_status(identifier);
#endif
        }
    }
}

/*
CFImageSymbolInfo symbol_scope_name(const char* symbol_name) {
    CFLibraryInfoRef info = CFLibraryInfoCreate();
    CFImageSymbolInfo symbolInfo = {0};
    CFLibraryInfo_searchSymbol(info, &symbolInfo, symbol_name, true);
    ff_printf("test-- symbol_name: %s found, base = 0x%lx\n", (char*)symbolInfo.name, symbolInfo.base);
    return symbolInfo;
}
 */

void hmd_slardar_malloc_image_callback(hmd_async_image_t *image,int index,bool *stop,void *ctx) {
    if (strstr(image->macho_image.name, "libsystem_kernel.dylib") != NULL) {
        *stop = true;
        libSystemKernelTextSegmentScope = std::make_pair(image->macho_image.text_segment.addr, image->macho_image.text_segment.addr+image->macho_image.text_segment.size);
    }
}

bool calculateLibSystemKernelScope(void) {
    hmd_async_enumerate_image_list(hmd_slardar_malloc_image_callback, NULL);
    if (libSystemKernelTextSegmentScope.first != 0 && libSystemKernelTextSegmentScope.second != 0) {
        return true;
    }
    return false;
}

bool adjust_remapped_data(HMDMMapAllocatorConfig& config) {
    if (config.remapped_tag_array != NULL && strlen(config.remapped_tag_array) >= 0) {
        char * strc = new char[strlen(config.remapped_tag_array)+1];
        strcpy(strc, config.remapped_tag_array);   //string转换成C-string
        char* temp = ::strtok(strc, ",");
        while (temp != NULL) {
            mapped_tag_set.emplace(string(temp));
            temp = strtok(NULL, ",");
        }
        delete[] strc;
        return true;
    }
    return false;
}
}

bool slardar_vm_alloc_start(HMDMMapAllocatorConfig config) {
    if (enable_vm_map(config) && adjust_remapped_data(config)) {
        identifier = config.identifier;
        pthread_key_create(&s_thread_info_key, NULL);
        __syscall_logger = slardar_malloc_memory_event_callback;
        return true;
    }
    return false;
}

bool enable_vm_map(MemoryAllocatorConfig config) {
    bool res = hmd_mmap_memory_allocator_init(config);
    if (!res) {
        return false;
    }
    
    /*
     mach_vm_deallocate_function = symbol_scope_name("_mach_vm_deallocate");
     mach_vm_map_function = symbol_scope_name("_mach_vm_map");
     */
    
    bool success = calculateLibSystemKernelScope();
    if (!success) {
        return false;
    }
    
#if HMDSlardarMallocMultiInstance == 0
    recorder_instance = new HMDVMRecorder();
#else
    pthread_rwlock_rdlock(global_rwmutex());
    if (global_recorder_map()->find(config.identifier) != global_recorder_map()->end()) {
        ff_assert(0);
        pthread_rwlock_unlock(global_rwmutex());
        return false;
    }
    pthread_rwlock_unlock(global_rwmutex());
    auto recorder = new HMDVMRecorder();
    
    pthread_rwlock_wrlock(global_rwmutex());
    global_recorder_map()->emplace(config.identifier, recorder);
    pthread_rwlock_unlock(global_rwmutex());
#endif
    return true;
}

//alloc
bool slardar_memory_remap(const char* identifier, void* src, size_t size) {
    void* ptr = nullptr;
    ptr = hmd_alloc(identifier, size);
    if (ptr != nullptr) {
        bool res = hmd_vm_remap(src, ptr, size);
        if (res) {
            auto recorder = find_recorder(identifier);
            recorder->record(src, size, ptr);
        }else {
            hmd_free(identifier, ptr, 0);
        }
        return true;
    }
#ifdef DEBUG
    hmd_mmap_allocator_status(identifier);
#endif
    return false;
}

//free
bool slardar_memory_unmap(const char* identifier, void* src, size_t size) {
    uintptr_t ptr_arg = (uintptr_t)src;
    if (ptr_arg == 0) {
        return false; // free(null)
    }
    size = (int32_t)round_page(size);
    auto recorder = find_recorder(identifier);
    
    bool find = recorder->matchPairSimplifiedVersion((void*)ptr_arg, size);
    if (find) {
        ff_printf("ff- type = free and match, address = 0x%lx, size = %zu\n", ptr_arg, size);
        MatchedSet matched_set;
        find = recorder->matchAndAdjustPair((void*)ptr_arg, size, matched_set);
        if (find) {
            for (auto it = matched_set.begin(); it != matched_set.end(); it++) {
                MatchedPair pair = *it;
                hmd_free(identifier, (void*)pair.first, pair.second);
            }
        }
        return true;
    }
    return false;
}

void vmrecorder_enumerator(const char* identifier) {
    auto recorder = find_recorder(identifier);
    recorder->enumeratorStorage();
}

void slardar_vm_alloc_stop(void) {
    if (identifier == NULL) {
        return;
    }
    if (__syscall_logger == slardar_malloc_memory_event_callback) {
        __syscall_logger = NULL;
    }
    // do some clear job
    /*
     destroy_recorder(identifier);
     hmd_mmap_memory_allocator_destory(identifier);
     g_malloc_zone_destory();
     */
}
