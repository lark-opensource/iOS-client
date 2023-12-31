//
//  HMDISAHookOptimization.c
//  Pods
//
//  Created by sunrunwang on yesterday
//

#include <pthread.h>
#include <stdio.h>
#include <string.h>
#include <stdbool.h>
#include <stdatomic.h>
#include <objc/runtime.h>
#include "HMDMacro.h"
#include "HMDISAHookOptimization.h"

#if __arm64__ && __LP64__
extern objc_hook_getClass HMDISAHookOptimization_previous_function;
BOOL HMDISAHookOptimization_objc_hook_getClass(const char * _Nonnull name,
                                                      Class _Nullable * _Nonnull outClass);

#else
static objc_hook_getClass HMDISAHookOptimization_previous_function = NULL;
static BOOL HMDISAHookOptimization_objc_hook_getClass(const char * _Nonnull name,
                                                      Class _Nullable * _Nonnull outClass);
#endif

#pragma mark - Exported

void HMDISAHookOptimization_initialization(void) {
    static atomic_flag onceToken = ATOMIC_FLAG_INIT;
    if(atomic_flag_test_and_set_explicit(&onceToken, memory_order_relaxed)) return;
    
    if (__builtin_available(iOS 12.2, *)) {
        if(((void *)objc_setHook_getClass) != NULL) {
            objc_setHook_getClass(HMDISAHookOptimization_objc_hook_getClass, &HMDISAHookOptimization_previous_function);
        }
    }
    
    DEBUG_LOG("[ISAHookOptimization] optimization enabled, please pair before/after_objc_allocate_classPair");
}

#pragma mark - not arm64 compact
// 如果不是 arm64 架构的话

#if !(__arm64__ && __LP64__)

static bool HMDISAHookOptimization_main_thread_mark = false;

int HMDISAHookOptimization_before_objc_allocate_classPair(void) {
    int pthread_main_return = pthread_main_np();
    
    if(pthread_main_return == 0) return pthread_main_return;

    HMDISAHookOptimization_main_thread_mark = true;
    
    return pthread_main_return;
}

void HMDISAHookOptimization_after_objc_allocate_classPair(int pthread_main_return) {
    if(pthread_main_return == 0) return;
    
    DEBUG_ASSERT(HMDISAHookOptimization_main_thread_mark);

    HMDISAHookOptimization_main_thread_mark = false;
}

static BOOL HMDISAHookOptimization_objc_hook_getClass(const char * _Nonnull name,
                                                      Class _Nullable * _Nonnull outClass) {
    DEBUG_ASSERT(name != NULL);
    DEBUG_ASSERT(outClass != NULL);
    
    if(pthread_main_np() == 0) {
        return HMDISAHookOptimization_previous_function(name, outClass);
    }
    
    if(!HMDISAHookOptimization_main_thread_mark) {
        return HMDISAHookOptimization_previous_function(name, outClass);
    }
    
    outClass[0] = NULL;
    
    return NO;
}

#endif /* !(__arm64__ && __LP64__) */

