//
//  HMDObjcRuntime.h
//  Pods
//
//  Created by yuanzhangjing on 2019/11/27.
//

#ifndef HMDObjcRuntime_h
#define HMDObjcRuntime_h

#include <stdio.h>
#include <stdbool.h>
#include "hmd_objc_apple.h"

#ifdef __cplusplus
extern "C" {
#endif

void hmd_init_objc_metaclass(void);

uintptr_t hmd_objc_NSObject_metaclass(void);

uintptr_t hmd_objc_NSProxy_metaclass(void);

bool hmd_objc_is_tag_pointer(void *ptr);

bool hmd_objc_isMetaClass(const struct class_t* const class);

bool hmd_objc_isRootClass(const struct class_t* const class);

const char* hmd_objc_className(const struct class_t* const class);

int hmd_get_tagged_slot(void *ptr);

uintptr_t hmd_get_tagged_payload(void *ptr);

#ifdef __cplusplus
} // extern "C"
#endif

#endif /* HMDObjcRuntime_h */
