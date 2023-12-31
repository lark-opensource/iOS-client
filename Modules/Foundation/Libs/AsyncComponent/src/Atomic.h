//
//  Atomic.h
//  Pods
//
//  Created by qihongye on 2019/9/23.
//

#ifndef Atomic_h
#define Atomic_h

#include <stdatomic.h>

#define MAKE(type)\
    struct catmc_atomic_##type {\
        _Atomic type value;\
    };\
\
    static __inline__ __attribute__((__always_inline__))\
    struct catmc_atomic_##type *catmc_atomic_##type##_create(type value) {\
        struct catmc_atomic_##type *wrapper = malloc(sizeof(*wrapper));\
        atomic_init(&wrapper->value, value);\
        return wrapper;\
    }\
\
    static __inline__ __attribute__((__always_inline__))\
    void catmc_atomic_##type##_destroy(struct catmc_atomic_##type *wrapper) {\
        free(wrapper);\
        wrapper = NULL;\
    }\
\
    static __inline__ __attribute__((__always_inline__))\
    bool catmc_atomic_##type##_compare_and_exchange(struct catmc_atomic_##type *wrapper, type expected, type desired) {\
        type expected_copy = expected;\
        return atomic_compare_exchange_strong(&wrapper->value, &expected_copy, desired);\
    }\
\
    static __inline__ __attribute__((__always_inline__))\
    type catmc_atomic_##type##_add(struct catmc_atomic_##type *wrapper, type value) {\
        return atomic_fetch_add_explicit(&wrapper->value, value, memory_order_relaxed);\
    }\
\
    static __inline__ __attribute__((__always_inline__))\
    type catmc_atomic_##type##_sub(struct catmc_atomic_##type *wrapper, type value) {\
        return atomic_fetch_sub_explicit(&wrapper->value, value, memory_order_relaxed);\
    }\
\
    static __inline__ __attribute__((__always_inline__))\
    type catmc_atomic_##type##_exchange(struct catmc_atomic_##type *wrapper, type value) {\
        return atomic_exchange_explicit(&wrapper->value, value, memory_order_relaxed);\
    }\
\
    static __inline__ __attribute__((__always_inline__))\
    type catmc_atomic_##type##_load(struct catmc_atomic_##type *wrapper) {\
        return atomic_load_explicit(&wrapper->value, memory_order_relaxed);\
    }\
\
    static __inline__ __attribute__((__always_inline__))\
    void catmc_atomic_##type##_store(struct catmc_atomic_##type *wrapper, type value) {\
        atomic_store_explicit(&wrapper->value, value, memory_order_relaxed);\
    }\
\
\

MAKE(uintptr_t)

#endif /* Atomic_h */
