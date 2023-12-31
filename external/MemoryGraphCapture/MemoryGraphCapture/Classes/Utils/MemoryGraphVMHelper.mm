//
//  MemoryGraphVMHelper.m
//  GDMDebugger
//
//  Created by brent.shu on 2019/11/7.
//

#import "MemoryGraphVMHelper.hpp"
#import "AWEMemoryAllocator.hpp"
#import "AWEMemoryGraphTimeChecker.hpp"

#import <mach/vm_statistics.h>
#import <mach/mach.h>
#import <malloc/malloc.h>
#import <algorithm>

namespace MemoryGraph {

#if defined(__i386__)

#define THREAD_STATE_COUTE x86_THREAD_STATE32_COUNT
#define THREAD_STATE x86_THREAD_STATE32
#define EXCEPTION_STATE_COUNT x86_EXCEPTION_STATE64_COUNT
#define EXCEPITON_STATE ARM_EXCEPTION_STATE32

#elif defined(__x86_64__)

#define THREAD_STATE_COUTE x86_THREAD_STATE64_COUNT
#define THREAD_STATE x86_THREAD_STATE64
#define EXCEPTION_STATE_COUNT x86_EXCEPTION_STATE64_COUNT
#define EXCEPITON_STATE x86_EXCEPTION_STATE64

#elif defined(__arm64__)

#define THREAD_STATE_COUTE ARM_THREAD_STATE64_COUNT
#define THREAD_STATE ARM_THREAD_STATE64
#define EXCEPTION_STATE_COUNT ARM_EXCEPTION_STATE64_COUNT
#define EXCEPITON_STATE ARM_EXCEPTION_STATE64

#elif defined(__arm__)

#define THREAD_STATE_COUTE ARM_THREAD_STATE_COUNT
#define THREAD_STATE ARM_THREAD_STATE
#define EXCEPITON_STATE ARM_EXCEPTION_STATE
#define EXCEPTION_STATE_COUNT ARM_EXCEPTION_STATE_COUNT

#else
#endif

#ifdef VM_MEMORY_MALLOC_MEDIUM
#define MEMORY_MALLOC_MEDIUM VM_MEMORY_MALLOC_MEDIUM
#else
#define MEMORY_MALLOC_MEDIUM 12
#endif

#define DEFAULT_MEMORY_NODE_MAX_COUNT 2500000
#define MEMORY_NODE_COST 39

static bool find_thread_sp(thread_t thread,vm_address_t *sp)
{
#if !TARGET_IPHONE_SIMULATOR
    mach_msg_type_number_t stateCount = THREAD_STATE_COUTE;
    _STRUCT_MCONTEXT _mcontext;
    kern_return_t ret = thread_get_state(thread, THREAD_STATE, (thread_state_t)&_mcontext.__ss, &stateCount);
    
    if (ret != KERN_SUCCESS) {
        return false;
    }
    stateCount = EXCEPTION_STATE_COUNT;
    ret = thread_get_state(thread, EXCEPITON_STATE, (thread_state_t)&_mcontext.__es, &stateCount);
    
    if (ret != KERN_SUCCESS) {
        return false;
    }
    
    if (_mcontext.__es.__exception != 0) {
        return false;
    }
    *sp = (vm_address_t)_mcontext.__ss.__sp;
    return true;
#else
    return false;
#endif
}

static void enumeratStackSp(std::function<void (void *sp, thread_t port)> callback) {
    thread_act_array_t thread_list;
    mach_msg_type_number_t thread_count;
    kern_return_t ret = task_threads(mach_task_self(), &thread_list, &thread_count);
    if (ret != KERN_SUCCESS) {
        return;
    }
    
    mach_port_t thread_self = mach_thread_self();
    for (mach_msg_type_number_t i = 0; i < thread_count; i++) {
        thread_t thread = thread_list[i];
        if (thread == thread_self) {
            continue;
        }
        
        vm_address_t stack_ptr;
        if (find_thread_sp(thread, &stack_ptr) && stack_ptr) {
            callback((void *)stack_ptr, thread);
        }
    }
    mach_port_deallocate(mach_task_self(), thread_self);
    for (mach_msg_type_number_t i = 0; i < thread_count; i++) {
        mach_port_deallocate(mach_task_self(), thread_list[i]);
    }
    vm_deallocate(mach_task_self(), (vm_address_t)thread_list, thread_count * sizeof(thread_t));
}

extern "C" bool mg_os_version_bigger_or_equal_to_15_4;

void enumeratHeap(std::function<void (void *ptr, uint32_t size)> callback) {
    auto mem_reader = [](task_t task, vm_address_t remote_address, vm_size_t size, void **local_memory) -> kern_return_t {
        *local_memory = (void*) remote_address;
        return KERN_SUCCESS;
    };
    
    auto mem_recorder = [](task_t task, void *baton, unsigned type, vm_range_t *ptrs, unsigned count) -> void {
        while(count--) {
            (*((std::function<void (void *ptr, uint32_t size)> *)baton))((void *)ptrs->address, (uint32_t)ptrs->size);
            ptrs++;
        }
    };
    
    auto excluded_zone = g_malloc_zone();
    vm_address_t *zones = NULL;
    unsigned int zone_num;
    
    kern_return_t err = malloc_get_all_zones(mach_task_self(), mem_reader, &zones, &zone_num);
    if (KERN_SUCCESS == err)
    {
        for (int i = 0; i < zone_num; ++i)
        {
            auto zone = (const malloc_zone_t *)zones[i];
            if(zone == excluded_zone) {
                continue;
            }
            
            const char* zone_name = malloc_get_zone_name((malloc_zone_t *)zone);
            if (zone_name != NULL && strcmp(zone_name, "Matrix") == 0) {
                continue;
            }
            
            task_t task = mach_task_self();
            if (mg_os_version_bigger_or_equal_to_15_4) {
                const char* zone_name = malloc_get_zone_name((malloc_zone_t*)zone);
                /* 15.4的webkit malloc zone会挂起自身线程，产生极大概率的死锁*/
                if ((zone_name != NULL) && strcmp(zone_name, "WebKit Malloc") == 0) {
                    task = 0x10086;
                }
            }
            
            if (zone && zone->introspect && zone->introspect->enumerator) {
                zone->introspect->enumerator(task,
                                             &callback,
                                             MALLOC_PTR_IN_USE_RANGE_TYPE,
                                             (vm_address_t)zone,
                                             mem_reader,
                                             mem_recorder);
            }
        }
    }
}

MemoryGraphVMHelper::MemoryGraphVMHelper(bool naive_version, size_t max_memory_usage):
m_heap_map(nil), m_vm_vec(), m_stack_vec(), m_ptr_mask(0), m_err(), m_stack_thread_map() {
    if (!naive_version) {
        void *ptr = malloc_zone_malloc(g_malloc_zone(), sizeof(ZONE_HASH(uintptr_t, uintptr_t)));
        m_heap_map = new(ptr) ZONE_HASH(uintptr_t, uintptr_t);
        size_t heap_counter = 0;
        size_t count_limit = max_memory_usage > 39 ? max_memory_usage / 39 : DEFAULT_MEMORY_NODE_MAX_COUNT;
        // Add Heap
        enumeratHeap([&](void *ptr, size_t size) {
            if (!m_err.is_ok) return ;
            VMInfo vm_info = {(uint32_t)size, VMInfoType::Heap};
            m_add_vm(ptr, vm_info);
            if (++heap_counter > count_limit) {
                m_err = Error(ErrorType::NodesIsOverLimit, "VMHelper init");
                if (!m_heap_map->empty()) {
                    m_heap_map->clear();
                    m_heap_map = nil;
                }
            }
        });
    }
    
    // Add VM
    kern_return_t krc = KERN_SUCCESS;
    vm_address_t address = 0;
    vm_size_t size = 0;
    uint32_t depth = 1;
    auto pagesize = vm_kernel_page_size;
    while (true) {
        if (MemoryGraphTimeChecker.vmCheckPoint("time out when vm region recurse")) {
            return;
        }
#ifdef __LP64__
        struct vm_region_submap_info_64 info;
        mach_msg_type_number_t count = VM_REGION_SUBMAP_INFO_COUNT_64;
        krc = vm_region_recurse_64(mach_task_self(), &address, &size, &depth, (vm_region_info_64_t)&info, &count);
#else
        struct vm_region_submap_info info;
        mach_msg_type_number_t count = VM_REGION_SUBMAP_INFO_COUNT;
        krc = vm_region_recurse(mach_task_self(), &address, &size, &depth, (vm_region_info_t)&info, &count);
#endif
        if (krc == KERN_INVALID_ADDRESS){
            break;
        }
        
        auto current_address = address;
        if (!info.is_submap) {
            address += size;
            // filter stack/malloc/memory area which can be transfer to disk(TEXT,SHARED MMAP etc)
            if (info.user_tag == VM_MEMORY_MALLOC ||
                info.user_tag == VM_MEMORY_MALLOC_SMALL ||
                info.user_tag == VM_MEMORY_MALLOC_TINY ||
                info.user_tag == VM_MEMORY_MALLOC_NANO ||
                info.user_tag == MEMORY_MALLOC_MEDIUM ||
                info.user_tag == VM_MEMORY_MALLOC_LARGE ||
                info.user_tag == VM_MEMORY_MALLOC_HUGE ||
                info.user_tag == VM_MEMORY_MALLOC_LARGE_REUSABLE ||
                info.user_tag == VM_MEMORY_MALLOC_LARGE_REUSED ||
                info.user_tag == VM_MEMORY_REALLOC ||
                info.user_tag == VM_MEMORY_ANALYSIS_TOOL ||
                info.external_pager != 0) {
                continue;
            }
            
            auto tag = info.user_tag;
            if (tag == VM_MEMORY_TCMALLOC) {
                tag = VMInfoType::WebKitHeap;
            }
            
            // record dirty + swapped size
            if (info.pages_dirtied || info.pages_swapped_out) {
                uint32_t dirty_size = (uint32_t)((info.pages_dirtied + info.pages_swapped_out) * pagesize);
                VMInfo vm_info = {tag == VM_MEMORY_STACK ? (uint32_t)size : dirty_size, (VMInfoType)tag};
                m_ptr_mask |= (uintptr_t)current_address;
                m_vm_vec.push_back({(void *)current_address, vm_info});
                
                if (info.user_tag == VM_MEMORY_STACK) {
                    m_stack_vec.push_back({(void *)current_address, nullptr, (uint32_t)size, dirty_size, 0});
                }
            }
        } else {
            ++depth;
        }
    }
    
    // sort for binary search
    std::sort(m_vm_vec.begin(), m_vm_vec.end(), [](const VM_TYPE& lhs, const VM_TYPE& rhs) {
        return lhs.first < rhs.first;
    });
    
    std::sort(m_stack_vec.begin(), m_stack_vec.end(), [](const StackInfo& lhs, const StackInfo& rhs) {
        return lhs.ptr < rhs.ptr;
    });
    
    // save memory
    m_vm_vec.shrink_to_fit();
    m_stack_vec.shrink_to_fit();
    
    // mask setup
    m_ptr_mask = ~m_ptr_mask;
    
    // live stack match
    enumeratStackSp([&](void *sp, thread_t port) {
        auto begin = m_stack_vec.begin();
        auto end = m_stack_vec.end();
        
        auto first = std::upper_bound(begin, end, sp, [](void *left, const StackInfo& right) {
            return (uintptr_t)left < (uintptr_t)right.ptr + right.size;
        });
        auto it =
        first != end && (sp >= first->ptr && (uintptr_t)sp < (uintptr_t)first->ptr + first->size) ?
        first :
        end;
        if (it != end) {
            it->sp = sp;
            m_stack_thread_map.insert({(uintptr_t)it->ptr, port});
            it->in_use_size = MIN(it->dirty_size, (uint32_t)(it->size - ((uintptr_t)sp - (uintptr_t)it->ptr)));
        }
    });
}

/*
 二分法确认ptr落在哪一个VM：Stack的范围内
 */
uintptr_t MemoryGraphVMHelper::stackWhichContainsAddress(uintptr_t ptr) {
    auto begin = m_stack_vec.begin();
    auto end = m_stack_vec.end();
    
    auto first = std::upper_bound(begin, end, (void*)ptr, [](void *left, const StackInfo& right) {
        return (uintptr_t)left < (uintptr_t)right.ptr + right.size;
    });
    auto it =
    first != end && (ptr >= (uintptr_t)first->ptr && (uintptr_t)ptr < (uintptr_t)first->ptr + first->size) ?
    first :
    end;
    if (it != end) {
        return (uintptr_t)(it->ptr);
    }
    return 0;
}

MemoryGraphVMHelper::~MemoryGraphVMHelper() {
    if (m_heap_map) {
      m_heap_map = nil;
    }
}

const Error &
MemoryGraphVMHelper::err() {
    return m_err;
}

void
MemoryGraphVMHelper::m_add_vm(void *ptr, VMInfo &info) {
#ifdef __LP64__
    // all info save in pointer
    m_ptr_mask |= (uintptr_t)ptr;
    void *value = nullptr;
    memcpy(&value, &info, sizeof(VMInfo));
    m_heap_map->insert({(uintptr_t)ptr, (uintptr_t)value});
#else
    // wait to complete
#endif
}

void
MemoryGraphVMHelper::enumeratStack(std::function<void (StackInfo &stack_info)> callback) {
    for (auto it = m_stack_vec.begin(); it != m_stack_vec.end(); ++it) {
        callback(*it);
        if (MemoryGraphTimeChecker.isTimeOut) {
            break;
        }
    }
}

void
MemoryGraphVMHelper::enumeratVm(std::function<void (void *ptr, VMInfo &vm_info)> callback) {
    if (m_heap_map) {
        static bool heapTimeOut = false;
        for(auto it = m_heap_map->begin();it != m_heap_map->end();it++) {
            if (heapTimeOut) {
                return;
            }
            void *value = (void *)(it->second);
            void *key = (void *)(it->first);
            VMInfo *vm_info = (VMInfo *)(&value);
            auto size = malloc_size(key);
            if (size) {
                vm_info->size = size;
                callback(key,*vm_info);
                if (MemoryGraphTimeChecker.isTimeOut) {
                    heapTimeOut = true;
                }
            }
        }
        heapTimeOut = false;
        if (MemoryGraphTimeChecker.isTimeOut) {
            return;
        }
    } else {
        enumeratHeap([&callback](void *ptr, size_t size) {
            auto r_size = malloc_size(ptr);
            if (r_size) {
                VMInfo vm_info = {(uint32_t)r_size, VMInfoType::Heap};
                callback(ptr, vm_info);
            }
        });
    }
    
    for (auto it = m_vm_vec.begin(); it != m_vm_vec.end(); ++it) {
        callback(it->first, it->second);
        if (MemoryGraphTimeChecker.isTimeOut) {
            MemoryGraphTimeChecker.errstr = "time out when analysis VM";
            return;
        }
    }
}

bool
MemoryGraphVMHelper::is_potential_ptr(void *ptr) {
    return ptr && ((uintptr_t)ptr & m_ptr_mask) == 0;
}

// return 0 if not exist or invalid
const VMInfo &
MemoryGraphVMHelper::vm_info(void *&ptr) {
#ifdef __LP64__
    // all info save in pointer
    // heap search
    auto it = m_heap_map->find((uintptr_t)ptr);
    if (it != m_heap_map->end()) {
        void *value = (void *)(it->second);
        VMInfo *vm_info = (VMInfo *)(&value);
        return *vm_info;
    } else {
        // vm search
        if (m_vm_vec.empty()) {
            return {0};
        }
        
        // do binary seach in vm
        auto begin = m_vm_vec.cbegin();
        auto end = m_vm_vec.cend();
        auto last = end - 1;
        
        // before binary search, we do a simple filter first
        if ((uintptr_t)ptr < (uintptr_t)begin->first || (uintptr_t)ptr >= (uintptr_t)last->first + last->second.size) {
            return {0};
        }
        
        // do binary search
        auto first = std::upper_bound(begin, end, ptr, [](void *left, const VM_TYPE& right) {
            return (uintptr_t)left < (uintptr_t)right.first + right.second.size;
        });
        auto it =
        first != end && (ptr >= first->first && (uintptr_t)ptr < (uintptr_t)first->first + first->second.size) ?
        first :
        end;
        if (it == end) {
            // not found
            return {0};
        } else {
            ptr = it->first;
            return it->second;
        }
    }
#else
    // wait to support
    return {0};
#endif
}

size_t m_physicalfootprint_after_ios9(void) {
    u_int64_t memoryUsageInByte = 0;
    task_vm_info_data_t vmInfo;
    mach_msg_type_number_t count = TASK_VM_INFO_COUNT;
    kern_return_t kernelReturn = task_info(mach_task_self(), TASK_VM_INFO, (task_info_t) &vmInfo, &count);
    if(kernelReturn == KERN_SUCCESS) {
        memoryUsageInByte = (int64_t) vmInfo.phys_footprint;
    }
    return memoryUsageInByte;
}

size_t m_physicalfootprint_before_ios9(void) {
    int64_t memoryUsageInByte = 0;
    struct task_basic_info taskBasicInfo;
    mach_msg_type_number_t size = sizeof(taskBasicInfo);
    kern_return_t kernelReturn = task_info(mach_task_self(), TASK_BASIC_INFO, (task_info_t) &taskBasicInfo, &size);
    if(kernelReturn == KERN_SUCCESS) {
        memoryUsageInByte = (int64_t) taskBasicInfo.resident_size;
    }
    return memoryUsageInByte;
}

size_t physicalfootprint() {
    if (@available(iOS 9.0, *)) {
        return m_physicalfootprint_after_ios9();
    } else {
        return m_physicalfootprint_before_ios9();
    }
}

} // MemoryGraph
