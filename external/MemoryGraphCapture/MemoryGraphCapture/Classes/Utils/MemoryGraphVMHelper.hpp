//
//  MemoryGraphVMHelper.hpp
//  GDMDebugger
//
//  Created by brent.shu on 2019/11/7.
//

#import "AWEMemoryAllocator.hpp"
#import "AWEMemoryGraphErrorDefines.hpp"

#import <Foundation/Foundation.h>
#import <functional>
#import <vector>
#import <unordered_map>

namespace MemoryGraph {

enum VMInfoType: uint8_t {
    Heap = 198,
    Process = 199,
    Segment = 200,
    WebKitHeap = 201,
    ClassHelper = 202,
};

struct VMInfo {
    uint32_t size;
    VMInfoType type;
};

struct StackInfo {
    void     *ptr;        // vm pointer
    void     *sp;         // stack pointer
    uint32_t size;        // vm size
    uint32_t dirty_size;  // dirty vm size
    uint32_t in_use_size; // in use size (maxVmaddress - sp)
};

using VM_TYPE = std::pair<void *, VMInfo>;

class MemoryGraphVMHelper {
    ZONE_HASH(uintptr_t, uintptr_t) *m_heap_map;
    ZONE_VECTOR(VM_TYPE) m_vm_vec;
    ZONE_VECTOR(StackInfo) m_stack_vec;
    void m_add_vm(void *ptr, VMInfo &info);
    uintptr_t m_ptr_mask;
    Error m_err;
public:
    MemoryGraphVMHelper(bool naive_version, size_t max_memory_usage);
    ~MemoryGraphVMHelper();
    // 记录ptr和port的关系，方便后续确认符号名称
    ZONE_HASH(uintptr_t, thread_t) m_stack_thread_map;
    
    const Error &err();
    
    bool is_potential_ptr(void *ptr);
    
    // return 0 if not exist or invalid
    const VMInfo &vm_info(void *&ptr);
    
    void enumeratVm(std::function<void (void *ptr, VMInfo &vm_info)> callback);
    
    void enumeratStack(std::function<void (StackInfo &stack_info)> callback);
    
    /// return the address of stack which contains ptr
    /// @param ptr 
    uintptr_t stackWhichContainsAddress(uintptr_t ptr);
};

void enumeratHeap(std::function<void (void *ptr, uint32_t size)> callback);

size_t physicalfootprint();

} // MemoryGraph
