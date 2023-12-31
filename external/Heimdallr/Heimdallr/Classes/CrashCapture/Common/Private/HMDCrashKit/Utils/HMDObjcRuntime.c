//
//  HMDObjcRuntime.c
//  Pods
//
//  Created by yuanzhangjing on 2019/11/27.
//

#include "HMDObjcRuntime.h"
#include <objc/runtime.h>
#include <stdatomic.h>
#include "hmd_memory.h"
static atomic_uintptr_t _object_meta_cls;
static atomic_uintptr_t _proxy_meta_cls;

void hmd_init_objc_metaclass(void) {
    Class cls1 = objc_getMetaClass("NSObject");
    Class cls2 = objc_getMetaClass("NSProxy");
    atomic_store_explicit(&_object_meta_cls,(uintptr_t)cls1,memory_order_release);
    atomic_store_explicit(&_proxy_meta_cls,(uintptr_t)cls2,memory_order_release);
}

uintptr_t hmd_objc_NSObject_metaclass(void) {
    return atomic_load_explicit(&_object_meta_cls,memory_order_acquire);
}

uintptr_t hmd_objc_NSProxy_metaclass(void) {
    return atomic_load_explicit(&_proxy_meta_cls,memory_order_acquire);
}

bool hmd_objc_is_tag_pointer(void *ptr) {
#if SUPPORT_TAGGED_POINTERS
    if (((uintptr_t)ptr & TAG_MASK)) {
        return true;
    }
#endif
    return false;
}

static inline bool getClassRO(const struct class_t* const class, struct class_ro_t *ro)
{
    if (class == NULL || ro == NULL) {
        return false;
    }
    uintptr_t ptr = class->data_NEVER_USE & (~WORD_MASK);
    struct class_rw_t rw = {0};
    if (hmd_async_read_memory(ptr, &rw, sizeof(rw)) == HMD_ESUCCESS) {
        if (hmd_async_read_memory((hmd_vm_address_t)rw.ro, ro, sizeof(*ro)) == HMD_ESUCCESS) {
            return true;
        }
    }
    return false;
}

bool hmd_objc_isMetaClass(const struct class_t* const class)
{
    struct class_ro_t ro = {0};
    if (getClassRO(class, &ro)) {
        return (ro.flags & RO_META) != 0;
    }
    return false;
}

bool hmd_objc_isRootClass(const struct class_t* const class)
{
    struct class_ro_t ro = {0};
    if (getClassRO(class, &ro)) {
        return (ro.flags & RO_ROOT) != 0;
    }
    return false;
}

const char* hmd_objc_className(const struct class_t* const class)
{
    struct class_ro_t ro = {0};
    if (getClassRO(class, &ro)) {
        return ro.name;
    }
    return NULL;
}

int hmd_get_tagged_slot(void *ptr) {
#if SUPPORT_TAGGED_POINTERS
    return (int)((((uintptr_t)ptr) >> TAG_SLOT_SHIFT) & TAG_SLOT_MASK);
#else
    return 0;
#endif
}

uintptr_t hmd_get_tagged_payload(void *ptr) {
#if SUPPORT_TAGGED_POINTERS
    return (((uintptr_t)ptr) << TAG_PAYLOAD_LSHIFT) >> TAG_PAYLOAD_RSHIFT;
#else
    return (uintptr_t)ptr;
#endif
}
