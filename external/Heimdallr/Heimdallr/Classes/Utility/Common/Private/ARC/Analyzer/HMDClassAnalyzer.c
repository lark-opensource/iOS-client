//
//  HMDClassAnalyzer.c
//  iOS
//
//  Created by sunrunwang on 2022/11/17.
//

#include <mach/mach.h>
#include "HMDClassAnalyzer.h"
#include "HMDMacro.h"

// config shared cache rrelative direct selectors
#define FIND_SELECTOR_DIRECT_IN_SAHRED_CACHE 1
#define FAST_DATA_MASK  UINT64_C(0x00007FFFFFFFFFF8)
#define RO_META         UINT32_C(1<<0)
#define RW_REALIZED     UINT32_C(1<<31)
#define RW_REALIZING    UINT32_C(1<<19)

typedef struct objc_class {
    uint64_t isa;
    uint64_t superclass;
    uint64_t cache;
    uint64_t vtable;
    uint64_t data_rw;
} objc_class_t;

typedef struct objc_class_data_rw {
    uint32_t flags;
    uint32_t useless_stuff;         // witness and index..
    uint64_t ro_or_rw_ext;          // ro_or_rw_ext
    // Class firstSubclass;         // well we don't need them
    // Class nextSiblingClass;
} objc_class_data_rw_t;

typedef struct objc_class_ro_t {
    uint32_t flags;
    uint32_t instanceStart;
    uint32_t instanceSize;
    uint32_t reserved;
    uint64_t ivarLayout;
    uint64_t name;
    uint64_t baseMethods;
    uint64_t baseProtocols;
    uint64_t ivars;
    uint64_t weakIvarLayout;
    uint64_t baseProperties;
} objc_class_ro_t;

typedef struct objc_class_rw_ext {
    objc_class_ro_t *ro_data;
//    class_ro_t_authed_ptr<const class_ro_t> ro;   // well we don't need them
//    method_array_t methods;
//    property_array_t properties;
//    protocol_array_t protocols;
//    char *demangledName;
//    uint32_t version;
} objc_class_rw_ext_t;

#define HMD_CLASS_ANALYZER_OBJC_MAX_CLASS_NAME_STORAGE_COUNT UINT64_C(256)

static bool read_memory(void * _Nonnull from, void * _Nonnull to, vm_size_t size, bool unsafe_memory_access);

bool HMDClassAnalyzer_unsafeClassGetSuperClass(HMDUnsafeClass _Nonnull aClass, HMDUnsafeClass _Nullable  * _Nonnull superClass) {
    if(aClass != NULL && superClass != NULL) {
        
        if(VM_ADDRESS_CONTAIN(aClass)) {
            
            objc_class_t class;
            if(read_memory(aClass, &class, sizeof(class), false)) {
                
                if(VM_ADDRESS_CONTAIN(class.superclass)) {
                    superClass[0] = (void *)class.superclass;
                    return true;
                }
            }
        }
    } DEBUG_ELSE
    return false;
}

bool HMDClassAnalyzer_unsafeClassGetName(HMDUnsafeClass _Nonnull aClass, uint8_t * _Nonnull name, size_t length) {
#ifdef __LP64__
    if(aClass != NULL && name != NULL && length > 0) {
        if(VM_ADDRESS_CONTAIN(aClass)) {
            
            objc_class_t class;
            if(read_memory(aClass, &class, sizeof(class), false)) {
                
                uint64_t class_rw_address = class.data_rw & FAST_DATA_MASK;
                
                objc_class_data_rw_t class_rw_data;
                if(VM_ADDRESS_CONTAIN(class_rw_address) && read_memory((void *)class_rw_address, &class_rw_data, sizeof(class_rw_data), false)) {
                    
                    if(class_rw_data.flags & RW_REALIZED) {
                        
                        uint64_t ro_or_rw_ext = class_rw_data.ro_or_rw_ext;
                        
                        if(ro_or_rw_ext & UINT64_C(0x1)) {
                            
                            uint64_t class_rw_ext_address = ro_or_rw_ext;
                            class_rw_ext_address &= ~UINT64_C(0x1);
                            
                            objc_class_rw_ext_t class_rw_ext;
                            if(read_memory((void *)class_rw_ext_address, &class_rw_ext, sizeof(class_rw_ext), false)) {
                                COMPILE_ASSERT(sizeof(objc_class_ro_t *) == sizeof(uint64_t));
                                uint64_t class_ro_address = (uint64_t)class_rw_ext.ro_data;
                                
                                objc_class_ro_t class_ro_data;
                                if(read_memory((void *)class_ro_address, &class_ro_data, sizeof(class_ro_data), false)) {
                                
                                    uint64_t name_address = class_ro_data.name;
                                    uint8_t tempName[HMD_CLASS_ANALYZER_OBJC_MAX_CLASS_NAME_STORAGE_COUNT];
                                    
                                    if(read_memory((void *)name_address, &tempName, sizeof(tempName), false)) {
                                        
                                        uint64_t class_name_length = 0;
                                        while (class_name_length < HMD_CLASS_ANALYZER_OBJC_MAX_CLASS_NAME_STORAGE_COUNT) {
                                            if(tempName[class_name_length] == '\0') break;
                                            class_name_length++;
                                        }
                                        
                                        if(class_name_length < HMD_CLASS_ANALYZER_OBJC_MAX_CLASS_NAME_STORAGE_COUNT) {
                                            uint64_t index = 0;
                                            while (index < (length - 1) && index < class_name_length) {
                                                name[index] = tempName[index];
                                                index++;
                                            }
                                            name[index] = '\0';
                                            return true;
                                        }
                                    }
                                }
                            }
                        } else {
                            
                            uint64_t class_ro_address = ro_or_rw_ext;
                            
                            objc_class_ro_t class_ro_data;
                            if(read_memory((void *)class_ro_address, &class_ro_data, sizeof(class_ro_data), false)) {
                                
                                uint64_t name_address = class_ro_data.name;
                                uint8_t tempName[HMD_CLASS_ANALYZER_OBJC_MAX_CLASS_NAME_STORAGE_COUNT];
                                
                                if(read_memory((void *)name_address, &tempName, sizeof(tempName), false)) {
                                    
                                    uint64_t class_name_length = 0;
                                    while (class_name_length < HMD_CLASS_ANALYZER_OBJC_MAX_CLASS_NAME_STORAGE_COUNT) {
                                        if(tempName[class_name_length] == '\0') break;
                                        class_name_length++;
                                    }
                                    
                                    if(class_name_length < HMD_CLASS_ANALYZER_OBJC_MAX_CLASS_NAME_STORAGE_COUNT) {
                                        uint64_t index = 0;
                                        while (index < (length - 1) && index < class_name_length) {
                                            name[index] = tempName[index];
                                            index++;
                                        }
                                        name[index] = '\0';
                                        return true;
                                    }
                                }
                                
                            }
                        }
                    }
                }
            }
        }
    } DEBUG_ELSE
#endif
    return false;
}

static bool read_memory(void * _Nonnull from, void * _Nonnull to, vm_size_t size, bool unsafe_memory_access) {
    if(from == NULL || to == NULL) return false;
    
    if(unsafe_memory_access) {
        // direct memory access
        memcpy(to, from, size);
        return true;
    } else {
        // safe memory access
        vm_size_t storage_size = size;
        if(vm_read_overwrite(mach_task_self(), (vm_address_t)from, size, (vm_address_t)to, &storage_size) == KERN_SUCCESS)
            return true;
        else return false;
    }
}
