//  HMDOOMLockingDetector.c
//
//  some like that
//

#include <stddef.h>
#include <stdatomic.h>
#include "HMDOOMLockingDetector.h"

static atomic_uintptr_t shared_function_ptr = 0;

static HMDOOMLockingDetector_OOMLockingFunction_t _Nullable getLockingFunction(void);

bool HMDOOMLockingDetector_isOOMLocking(void) {
    HMDOOMLockingDetector_OOMLockingFunction_t _Nullable function = getLockingFunction();
    if(function != NULL) return function();
    return false;
}

HMD_EXTERN void HMDOOMLockingDetector_registerOOMLockingFunction(HMDOOMLockingDetector_OOMLockingFunction_t _Nonnull function) {
    
    // second time register result in error
    static atomic_flag onceToken = ATOMIC_FLAG_INIT;
    if(atomic_flag_test_and_set_explicit(&onceToken, memory_order_relaxed)) DEBUG_RETURN_NONE;
    
    if(function == NULL) DEBUG_RETURN_NONE;
    
    atomic_store_explicit(&shared_function_ptr, (uintptr_t)function, memory_order_release);
}

static HMDOOMLockingDetector_OOMLockingFunction_t _Nullable getLockingFunction(void) {
    
    uintptr_t ptr = atomic_load_explicit(&shared_function_ptr, memory_order_acquire);
    if(ptr == 0) return NULL;
    
    return (HMDOOMLockingDetector_OOMLockingFunction_t _Nonnull)ptr;
}
