//
//  AWEMemoryGraphUtils.mm
//  Hello
//
//  Created by brent.shu on 2019/10/22.
//  Copyright © 2019 brent.shu. All rights reserved.
//

#import "AWEMemoryGraphUtils.hpp"
#import "AWEMemoryAllocator.hpp"
#import "AWEMemoryNodeCursor.hpp"
#import "AWEMachOImageHelper.hpp"
#import "AWEMemoryGraphTimeChecker.hpp"

#import <objc/runtime.h>
#import <malloc/malloc.h>
#import <unordered_map>
#import <vector>
#import <unordered_set>
#import <dlfcn.h>
#include <mach-o/arch.h>


namespace MemoryGraph {

using USED_STR_TYPE = std::pair<ZONE_STRING, bool>;
using CPP_VT_TYPE   = std::pair<const ZONE_STRING, int>;

static ZONE_SET(uintptr_t)               *global_cache_ptr_dic;
static ZONE_SET(uintptr_t)               *global_rw_t_ptr_dic;
static ZONE_SET(uintptr_t)               *global_rw_ext_t_dic;
static ZONE_SET(uintptr_t)               *global_method_array_t_dic;
static ZONE_SET(uintptr_t)               *global_property_array_t_dic;
static ZONE_SET(uintptr_t)               *global_protocol_array_t_dic;

static CFMutableDictionaryRef               global_cls_ptr_dic;
static CFMutableDictionaryRef               global_cf_type_dic;
static ZONE_HASH(ZONE_STRING, uint32_t)     *global_str_dic;
static ZONE_HASH(uintptr_t, CPP_VT_TYPE)    *global_cpp_vt_dic;
static ZONE_VECTOR(USED_STR_TYPE)           *global_str_vec;
static MemoryGraphVMHelper                  *global_vm_helper;
static ZONE_SET(size_t)                     *global_valid_cftype_ids;
static int str_index_counter = 0;
static Class CFTypeClass = nil;

// How much the mask is shifted by.
static constexpr uintptr_t maskShift = 48;
// Additional bits after the mask which must be zero. msgSend
// takes advantage of these additional bits to construct the value
// `mask << 4` from `_maskAndBuckets` in a single instruction.
static constexpr uintptr_t maskZeroBits = 4;
// The mask applied to `_maskAndBuckets` to retrieve the buckets pointer.
#define FAST_DATA_MASK  0x00007ffffffffff8UL
void *caclute_meta_class(void *key) {
    void *potential_ptr = *(void **)key;
    uintptr_t potential_ptr_fix = (uintptr_t)potential_ptr & FAST_DATA_MASK;
    return (void *)potential_ptr_fix;
}
void *caclute_class_cache_ptr(void *key) {
    uintptr_t addr = (uintptr_t)key;
    void *potential_ptr = *((void **)(addr + 16));
    static uintptr_t bucketsMask = ((uintptr_t)1 << (maskShift - maskZeroBits)) - 1;
    uintptr_t potential_ptr_fix = (uintptr_t)potential_ptr & bucketsMask;
    void *ptr_cache = (void *)potential_ptr_fix;
    return ptr_cache;
}
void *caclute_class_rwt_ptr(void *key) {
    uintptr_t addr = (uintptr_t)key;
    void *potential_ptr = nullptr;
    uintptr_t potential_ptr_fix = 0;
    potential_ptr = *((void **)(addr + 32));
    potential_ptr_fix = (uintptr_t)potential_ptr & FAST_DATA_MASK;
    void *ptr_rwt = (void *)potential_ptr_fix;
    return ptr_rwt;
}
void *caclute_class_rw_ext_ptr(void *key) {
    uintptr_t addr = (uintptr_t)key;
    void *potential_ptr = *((void **)(addr + 8));
    if(((uintptr_t)potential_ptr & 1) == 1) {
        uintptr_t potential_ptr_fix = (uintptr_t)potential_ptr & (~1);
        void *ptr_rwt = (void *)potential_ptr_fix;
        return ptr_rwt;
    } else {
        return nullptr;
    }
}
void *caclute_method_array_ptr(void *key) {
    uintptr_t addr = (uintptr_t)key;
    void *potential_ptr = *((void **)(addr + 8));
    uintptr_t potential_ptr_fix = (uintptr_t)potential_ptr & (~1);
    if(potential_ptr_fix != 0) {
        void *ptr_rwt = (void *)potential_ptr_fix;
        return ptr_rwt;
    } else {
        return nullptr;
    }
}
void *caclute_property_array_ptr(void *key) {
    uintptr_t addr = (uintptr_t)key;
    void *potential_ptr = *((void **)(addr + 16));
    uintptr_t potential_ptr_fix = (uintptr_t)potential_ptr & (~1);
    if(potential_ptr_fix != 0) {
        void *ptr_rwt = (void *)potential_ptr_fix;
        return ptr_rwt;
    } else {
        return nullptr;
    }
}
void *caclute_protocol_array_ptr(void *key) {
    uintptr_t addr = (uintptr_t)key;
    void *potential_ptr = *((void **)(addr + 24));
    uintptr_t potential_ptr_fix = (uintptr_t)potential_ptr & (~1);
    if(potential_ptr_fix != 0) {
        void *ptr_rwt = (void *)potential_ptr_fix;
        return ptr_rwt;
    } else {
        return nullptr;
    }
}
void setup_global_str_map() {
    str_index_counter = 0;
    
    global_cls_ptr_dic = CFDictionaryCreateMutable(g_zone_allocator(), 0, NULL, NULL);
    
    global_cf_type_dic = CFDictionaryCreateMutable(g_zone_allocator(), 0, NULL, NULL);
    
    void *ptr = malloc_zone_malloc(g_malloc_zone(), sizeof(ZONE_HASH(ZONE_STRING, uint32_t)));
    global_str_dic = new(ptr) ZONE_HASH(ZONE_STRING, uint32_t);
    
    ptr = malloc_zone_malloc(g_malloc_zone(), sizeof(ZONE_VECTOR(USED_STR_TYPE)));
    global_str_vec = new(ptr) ZONE_VECTOR(USED_STR_TYPE);
    
    ptr = malloc_zone_malloc(g_malloc_zone(), sizeof(ZONE_HASH(uintptr_t, CPP_VT_TYPE)));
    global_cpp_vt_dic = new(ptr) ZONE_HASH(uintptr_t, CPP_VT_TYPE);
    
    ptr = malloc_zone_malloc(g_malloc_zone(), sizeof(ZONE_SET(size_t)));
    global_valid_cftype_ids = new(ptr) ZONE_SET(size_t);
    
    ptr = malloc_zone_malloc(g_malloc_zone(), sizeof(ZONE_SET(uintptr_t)));
    global_cache_ptr_dic = new(ptr) ZONE_SET(uintptr_t);
    
    ptr = malloc_zone_malloc(g_malloc_zone(), sizeof(ZONE_SET(uintptr_t)));
    global_rw_t_ptr_dic = new(ptr) ZONE_SET(uintptr_t);
    
    ptr = malloc_zone_malloc(g_malloc_zone(), sizeof(ZONE_SET(uintptr_t)));
    global_rw_ext_t_dic = new(ptr) ZONE_SET(uintptr_t);
    
    ptr = malloc_zone_malloc(g_malloc_zone(), sizeof(ZONE_SET(uintptr_t)));
    global_method_array_t_dic = new(ptr) ZONE_SET(uintptr_t);
    
    ptr = malloc_zone_malloc(g_malloc_zone(), sizeof(ZONE_SET(uintptr_t)));
    global_property_array_t_dic = new(ptr) ZONE_SET(uintptr_t);
    
    ptr = malloc_zone_malloc(g_malloc_zone(), sizeof(ZONE_SET(uintptr_t)));
    global_protocol_array_t_dic = new(ptr) ZONE_SET(uintptr_t);
}

void setup_cf_class_if_needed() {
    if (!CFTypeClass) {
        CFTypeClass = NSClassFromString(@"__NSCFType");
    }
}

void destory_global_str_map() {
    if (global_cls_ptr_dic) {
        global_cls_ptr_dic = nil;
    }
    
    if (global_cache_ptr_dic) {
        global_cache_ptr_dic = nil;
    }
    
    if (global_rw_t_ptr_dic) {
        global_rw_t_ptr_dic = nil;
    }
    
    if (global_rw_ext_t_dic) {
        global_rw_ext_t_dic = nil;
    }
    
    if (global_method_array_t_dic) {
        global_method_array_t_dic = nil;
    }
    
    if (global_property_array_t_dic) {
        global_property_array_t_dic = nil;
    }
    
    if (global_protocol_array_t_dic) {
        global_property_array_t_dic = nil;
    }
    
    if (global_cf_type_dic) {
        global_cf_type_dic = nil;
    }
    
    if (global_str_dic) {
        global_str_dic = nil;
    }
    
    if (global_str_vec) {
        global_str_vec = nil;
    }
    
    if (global_cpp_vt_dic) {
        global_cpp_vt_dic = nil;
    }
    
    if (global_valid_cftype_ids) {
        global_valid_cftype_ids = nil;
    }
}

void setup_global_vm_helper(bool naive_version, size_t max_memory_usage) {
    void *ptr = malloc_zone_malloc(g_malloc_zone(), sizeof(MemoryGraphVMHelper));
    global_vm_helper = new(ptr) MemoryGraphVMHelper(naive_version, max_memory_usage);
}

void setup_global_cpp_vt_dic() {
    getVtableMap([](uintptr_t ptr, const ZONE_STRING &str) {
        global_cpp_vt_dic->insert({ptr, {std::move(str), -1}});
    });
}

void setup_valid_cftypeids() {
    getValidCFTypeIDs(*global_valid_cftype_ids);
}

void destory_global_vm_helper() {
    if (global_vm_helper) {
        global_vm_helper = nullptr;
    }
}

int index_of_cls(void *cls, void *instance) {
    if (cls == CFTypeClass) {
        auto cfId = CFGetTypeID((CFTypeRef)instance);
        auto idx = ((uintptr_t)CFDictionaryGetValue(global_cf_type_dic, (void *)cfId));
        if (!idx) {
            idx = increase_str_count();
            CFDictionarySetValue(global_cf_type_dic, (void *)cfId, (void *)idx);
        }
        return (int)idx;
    } else {
        auto idx = ((uintptr_t)CFDictionaryGetValue(global_cls_ptr_dic, (void *)cls));
        if (idx == -1) {
            idx = increase_str_count();
            CFDictionarySetValue(global_cls_ptr_dic, (void *)cls, (void *)idx);
        }
        return (int)idx;
    }
}

int str_index_of_cpp_object(void *ptr) {
    if (global_cpp_vt_dic->size() == 0) return -1;
    
    auto vtable = *((uintptr_t *)ptr);
    auto it = global_cpp_vt_dic->find(vtable);
    if (it != global_cpp_vt_dic->end()) {
        auto idx = it->second.second;
        if (idx == -1) {
            idx = increase_str_count();
            it->second.second = idx;
        }
        return idx;
    }
    return -1;
}

uintptr_t vtable_of_cpp_object(const void *ptr) {
    if (global_cpp_vt_dic->size() == 0) return 0;
    
    auto vtable = *((uintptr_t *)ptr);
    auto it = global_cpp_vt_dic->find(vtable);
    return it != global_cpp_vt_dic->end() ? vtable : 0;
}

ZONE_STRING name_of_vtable(uintptr_t vtable) {
    if (global_cpp_vt_dic->size() == 0) return "";
    
    auto it = global_cpp_vt_dic->find(vtable);
    if (it != global_cpp_vt_dic->end()) {
        return it->second.first;
    }
    return "";
}

void mark_used_str_idx(int idx) {
    if (idx < global_str_vec->size() && idx >= 0) {
        global_str_vec->at(idx).second = true;
    }
}

int index_of_str(const ZONE_STRING &str) {
    if (!str.size()) {
        return -1;
    }
    
    auto it = global_str_dic->find(str);
    if (it != global_str_dic->end()) {
        return it->second;
    } else {
        auto index = increase_str_count();
        global_str_dic->insert({str, index});
        return index;
    }
}

const VMInfo & vm_info_of_ptr(void *&ptr) {
    return global_vm_helper->vm_info(ptr);
}

int str_count() {
    return str_index_counter;
}

int increase_str_count() {
    return ++str_index_counter;
}

NSString* getDemangleName(NSString * mangleName){
    static char* (*swift_demangle)(const char *mangledName,
                                   size_t mangledNameLength,
                                   char *outputBuffer,
                                   size_t *outputBufferSize,
                                   uint32_t flags) = nullptr;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        swift_demangle = (char *(*)(const char *, size_t, char *, size_t *, uint32_t))dlsym(RTLD_DEFAULT, "swift_demangle");
    });
    if (swift_demangle != nullptr) {
        size_t demangledSize = 0;
        char *demangleName = swift_demangle(mangleName.UTF8String, mangleName.length, nullptr, &demangledSize, 0);
        if (demangleName != nullptr) {
            NSString *demangleNameStr = [NSString stringWithFormat:@"%s",demangleName];
            free(demangleName);
            return demangleNameStr;
        }
    }
    return mangleName;
}

void ennmulate_str(std::function<void (const ZONE_STRING &str, int index, bool &stop)> call_back) {
    if (!call_back) {
        return ;
    }
    
    auto malloc_zone = g_malloc_zone();
    if (!malloc_zone) {
        return ;
    }
    
    // CFType
    {
        auto applier = [](const void *key, const void *value, void *context) {
            auto cfId = (CFTypeID)key;
            auto index = (uintptr_t)value;
            auto desc = is_valid_cftype_id(cfId) ? CFCopyTypeIDDescription(cfId) : nil;
            auto desc_len = desc ? CFStringGetLength(desc) : 0;
            auto desc_char = "__NSCFType";
            if (desc_len) {
                char *buffer = (char *)malloc_zone_calloc(g_malloc_zone(), desc_len + 1, sizeof(char)); // not need to free
                if (CFStringGetCString(desc, buffer, desc_len + 1, kCFStringEncodingUTF8)) {
                    desc_char = buffer;
                }
            }
            
            bool need_break = false;
            (*((std::function<void (const ZONE_STRING &cls_name, int index, bool &stop)> *)context))(desc_char, (int)index, need_break);
            if (desc) CFRelease(desc);
            if (need_break) {
                return ;
            }
        };
        CFDictionaryApplyFunction(global_cf_type_dic, applier, &call_back);
    }
    // normal cls
    {
        auto applier = [](const void *key, const void *value, void *context) {
            auto ptr = key;
            auto index = (uintptr_t)value;
            if (index == -1) { // not used
                return ;
            }
            id cls = (__bridge id)ptr;
            auto cls_name = class_getName(cls) ?: "";
            
            NSString *name = [NSString stringWithUTF8String:cls_name];
            // swift mangle name may have "$" at end , will cause bad-demangle
            if ([name hasSuffix:@"$"]) {
                name = [name substringToIndex:name.length-1];
            }
            name = getDemangleName(name);
            
            bool need_break = false;
            (*((std::function<void (const ZONE_STRING &cls_name, int index, bool &stop)> *)context))(name.UTF8String, (int)index, need_break);
            if (need_break) {
                return ;
            }
        };
        CFDictionaryApplyFunction(global_cls_ptr_dic, applier, &call_back);
    }
    
    // cpp str
    {
        for (auto it = global_cpp_vt_dic->begin(); it != global_cpp_vt_dic->end(); ++it) {
            if (it->second.second == -1) {
                continue;
            }
            
            bool need_break = false;
            call_back(it->second.first, it->second.second, need_break);
            if (need_break) {
                break;
            }
        }
    }
    
    // normal str
    {
        for (auto idx = 0; idx < global_str_vec->size(); ++idx) {
            auto &pair = global_str_vec->at(idx);
            if (!pair.second) {
                continue;
            }
            
            bool need_break = false;
            call_back(pair.first, idx, need_break);
            if (need_break) {
                break;
            }
        }
    }
}

void enumeratVm(std::function<void (void *ptr, VMInfo &vm_info)> callback) {
    global_vm_helper->enumeratVm(callback);
}

extern "C" Class * objc_copyRealizedClassList(unsigned int *) __attribute__((weak_import));

/// runtime API hold runtimelock, CANNOT do THIS after suspend
static void generate_class_ptr_set() {
    unsigned int cls_count = 0;
    Class *classes = NULL;
    if (objc_copyRealizedClassList != NULL) {
        classes = objc_copyRealizedClassList(&cls_count);
    }else {
        classes = objc_copyClassList(&cls_count);
    }
    for (int i = 0; i < cls_count; i++) {
        Class c = classes[i];
        ivar_cache_push_class(c);
        CFDictionarySetValue(global_cls_ptr_dic, (__bridge void *)c, (void *)(uintptr_t)-1);
    }
    free(classes);
    
    // transform str dic to vec
    global_str_vec->resize(str_count() + 1);
    global_str_vec->at(0) = {}; // not used st;
    
    for (auto it = global_str_dic->begin(); it != global_str_dic->end(); ++it) {
        global_str_vec->at(it->second) = {it->first, false};
    }
    global_str_vec->shrink_to_fit();
    // clean dic
    global_str_dic->clear();
    global_str_dic->rehash(0);
}

static void generate_oc_class_ptr_set() {
    unsigned int cls_count = 0;
    Class *classes = NULL;
    void **all_classes = (void **)malloc((2) * sizeof(void *));
    if (objc_copyRealizedClassList != NULL) {
        classes = objc_copyRealizedClassList(&cls_count);
    }else {
        classes = objc_copyClassList(&cls_count);
    }
    global_cache_ptr_dic->reserve(cls_count);
    global_rw_t_ptr_dic->reserve(cls_count);
    for (int i = 0; i < cls_count; i++) {
        Class c = classes[i];
        ivar_cache_push_class(c);
        CFDictionarySetValue(global_cls_ptr_dic, (__bridge void *)c, (void *)(uintptr_t)-1);
        
        void *meta_class = object_getClass(c);
        all_classes[0] = (__bridge void *)c;
        all_classes[1] = meta_class;
        for(int j=0;j<2;j++) {
            if(all_classes[j] == nullptr) continue;
            void *cls_cache = caclute_class_cache_ptr(all_classes[j]);
            void *cls_rw_t = caclute_class_rwt_ptr(all_classes[j]);
            global_cache_ptr_dic->insert((uintptr_t)cls_cache);
            global_rw_t_ptr_dic->insert((uintptr_t)cls_rw_t);
            void *cls_rw_ext_t = caclute_class_rw_ext_ptr(cls_rw_t);
            if(cls_rw_ext_t == nullptr) {
                continue;
            }
            global_rw_ext_t_dic->insert((uintptr_t)cls_rw_ext_t);
            void *method_array_ptr = caclute_method_array_ptr(cls_rw_ext_t);
            if(method_array_ptr != nullptr) {
                global_method_array_t_dic->insert((uintptr_t)method_array_ptr);
            }
            void *property_array_t = caclute_property_array_ptr(cls_rw_ext_t);
            if(property_array_t != nullptr) {
                global_property_array_t_dic->insert((uintptr_t)property_array_t);
            }
            void *protocol_array_t = caclute_protocol_array_ptr(cls_rw_ext_t);
            if(protocol_array_t != nullptr) {
                global_protocol_array_t_dic->insert((uintptr_t)protocol_array_t);
            }
        }
    }
    free(classes);
    free(all_classes);
    
    // transform str dic to vec
    global_str_vec->resize(str_count() + 1);
    global_str_vec->at(0) = {}; // not used st;
    
    for (auto it = global_str_dic->begin(); it != global_str_dic->end(); ++it) {
        global_str_vec->at(it->second) = {it->first, false};
    }
    global_str_vec->shrink_to_fit();
    // clean dic
    global_str_dic->clear();
    global_str_dic->rehash(0);
}

ContextManager::ContextManager(): is_degrade_version(false) {
    setup_cf_class_if_needed();
}

void
ContextManager::init_none_suspend_required_info(bool do_leak_node_calibration) {
    setup_global_str_map();
    bool isIOS14 = false;
    if (@available(iOS 14, *)) {//>=ios14.0
        isIOS14 = true;
    }
    if (isIOS14 && do_leak_node_calibration) {
        generate_oc_class_ptr_set();//获取oc运行时所有的内存节点，包括元类、cache、class_rw_t、method_array_t、property_array_t、protocal_array_t
    } else {
        generate_class_ptr_set();
    }
}

void
ContextManager::init_suspend_required_info(bool naive_version, size_t max_memory_usage, bool do_cpp_symbolic) {
    if (do_cpp_symbolic) setup_global_cpp_vt_dic();
    setup_valid_cftypeids();
    setup_global_vm_helper(naive_version, max_memory_usage);
    if (MemoryGraphTimeChecker.isTimeOut) return;
    is_degrade_version = !global_vm_helper->err().is_ok;
    MemoryGraphTimeChecker.checkPoint("time out when capture node");
}

ContextManager::~ContextManager() {
    clear_ivar_cache();
    destory_global_vm_helper();
    destory_global_str_map();
    g_malloc_zone_destory();
}

MemoryGraphVMHelper *vm_helper() {
    return global_vm_helper;
}
CFMutableDictionaryRef cls_ptr_helper() {
    return global_cls_ptr_dic;
}
ZONE_SET(uintptr_t)* cls_cache_ptr_helper()
{
    return global_cache_ptr_dic;
}
ZONE_SET(uintptr_t)* cls_rwt_ptr_helper()
{
    return global_rw_t_ptr_dic;
}

// arm64e指针验签会利用地址中未使用的高位对地址进行验签，用户态地址最大为0000007fffffffff https://llvm.org/devmtg/2019-10/slides/McCall-Bougacha-arm64e.pdf
#define kMemoryGraphPAC_Mask 0x007fff8000000000ULL
#define KMemoryGraphArm64ePAC_ISA_MASK 0x007ffffffffffff8ULL

Class cls_of_ptr(void *ptr, size_t size) {
    static bool isArm64eAndIOS15 = false;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        const NXArchInfo* archInfo = NXGetLocalArchInfo();
        if (archInfo && archInfo->name) {
            const char* arch_name = archInfo->name;
            if (strcmp(arch_name, "arm64e") == 0) {
                if (@available(iOS 15, *)) {
                    isArm64eAndIOS15 = true;
                }
            }
        }
    });
    if (isArm64eAndIOS15) {
        // 先拿到isa指针，再对比高位确认是否有冗余的值
        if(((*(uintptr_t*)ptr & KMemoryGraphArm64ePAC_ISA_MASK) & kMemoryGraphPAC_Mask) != 0) {
            return nil;
        }
    }
    Class cls = object_getClass((__bridge id)ptr);
    return
    cls && CFDictionaryContainsKey(global_cls_ptr_dic, cls) &&
    (cls == CFTypeClass ? true : size >= class_getInstanceSize(cls)) ?
    cls :
    nil;
}

static char     const kPoolPageMagic[]= "\xa1\xa1\xa1\xa1""AUTORELEASE!";
static uint64_t const kPoolPageMagic0 = *((uint64_t *)&kPoolPageMagic);
static uint64_t const kPoolPageMagic1 = *((uint64_t *)&kPoolPageMagic + 1);

bool is_autorelease_pool_page(void *ptr, size_t size) {
    if (size != PAGE_MIN_SIZE) {
        return false;
    }
    const uint64_t *mem = (uint64_t *)ptr;
    return (mem[0] == kPoolPageMagic0 && mem[1] == kPoolPageMagic1);
}

bool is_potential_ptr(void *ptr) {
    return global_vm_helper->is_potential_ptr(ptr);
}

bool is_cf_cls(Class cls) {
    return cls == CFTypeClass;
}

bool is_valid_cftype_id(size_t type_id) {
    return global_valid_cftype_ids->find(type_id) != global_valid_cftype_ids->end();
}

} // MemoryGraph
