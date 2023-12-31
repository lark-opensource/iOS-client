//
//  EEAtomic.h
//  Pods
//
//  Created by SolaWing on 2019/12/23.
//

#import <stdatomic.h>
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
#if defined(__cplusplus)
extern "C" {
#endif

typedef NS_CLOSED_ENUM(UInt32, MemoryOrder) {
  MemoryOrderRelaxed = memory_order_relaxed,
  MemoryOrderConsume = memory_order_consume,
  MemoryOrderAcquire = memory_order_acquire,
  MemoryOrderRelease = memory_order_release,
  MemoryOrderAcqRel = memory_order_acq_rel,
  MemoryOrderSeqCst = memory_order_seq_cst
};

#define ATOMIC_CREATE(Type) \
    struct c_atomic_##Type {\
        _Atomic(Type) value;\
    };\
\
    static __inline__ __attribute__((__always_inline__)) NS_SWIFT_NAME(c_atomic_##Type.create(_:))\
    struct c_atomic_##Type *c_atomic_##Type##_create(Type value) {\
        struct c_atomic_##Type *wrapper = (struct c_atomic_##Type *)malloc(sizeof(*wrapper));\
        atomic_init(&wrapper->value, value);\
        return wrapper;\
    }\
\
    static __inline__ __attribute__((__always_inline__)) NS_SWIFT_NAME(c_atomic_##Type.destroy(_:))\
    void c_atomic_##Type##_destroy(struct c_atomic_##Type *wrapper) {\
        free(wrapper);\
    }\
\
    static __inline__ __attribute__((__always_inline__)) NS_SWIFT_NAME(c_atomic_##Type.load(_:order:))\
    Type c_atomic_##Type##_load(struct c_atomic_##Type *wrapper, memory_order order) {\
        return atomic_load_explicit(&wrapper->value, order);\
    }\
\
    static __inline__ __attribute__((__always_inline__)) NS_SWIFT_NAME(c_atomic_##Type.store(_:value:order:))\
    void c_atomic_##Type##_store(struct c_atomic_##Type *wrapper, Type value, memory_order order) {\
        atomic_store_explicit(&wrapper->value, value, order);\
    }\
\
    static __inline__ __attribute__((__always_inline__)) NS_SWIFT_NAME(c_atomic_##Type.exchange(_:value:order:))\
    Type c_atomic_##Type##_exchange(struct c_atomic_##Type *wrapper, Type value, memory_order order) {\
        return atomic_exchange_explicit(&wrapper->value, value, order);\
    }\
\
    static __inline__ __attribute__((__always_inline__)) \
    NS_SWIFT_NAME(c_atomic_##Type.compare(_:expected:replace:weak:order:))\
    bool c_atomic_##Type##_compare_and_exchange(\
            struct c_atomic_##Type *wrapper, Type expected, Type desired, bool weak, memory_order order) {\
        if (weak) { \
            return atomic_compare_exchange_weak_explicit(\
                    &wrapper->value, &expected, desired, order, memory_order_relaxed); \
        } else { \
            return atomic_compare_exchange_strong_explicit(\
                    &wrapper->value, &expected, desired, order, memory_order_relaxed); \
        } \
    }\
\
    static __inline__ __attribute__((__always_inline__)) NS_SWIFT_NAME(c_atomic_##Type.add(_:value:order:))\
    Type c_atomic_##Type##_add(struct c_atomic_##Type *wrapper, Type value, memory_order order) {\
        return atomic_fetch_add_explicit(&wrapper->value, value, order);\
    }\
\
    static __inline__ __attribute__((__always_inline__)) NS_SWIFT_NAME(c_atomic_##Type.sub(_:value:order:))\
    Type c_atomic_##Type##_sub(struct c_atomic_##Type *wrapper, Type value, memory_order order) {\
        return atomic_fetch_sub_explicit(&wrapper->value, value, order);\
    }\
\
    static __inline__ __attribute__((__always_inline__)) NS_SWIFT_NAME(c_atomic_##Type.or(_:value:order:))\
    Type c_atomic_##Type##_or(struct c_atomic_##Type *wrapper, Type value, memory_order order) {\
        return atomic_fetch_or_explicit(&wrapper->value, value, order);\
    }\
\
    static __inline__ __attribute__((__always_inline__)) NS_SWIFT_NAME(c_atomic_##Type.xor(_:value:order:))\
    Type c_atomic_##Type##_xor(struct c_atomic_##Type *wrapper, Type value, memory_order order) {\
        return atomic_fetch_xor_explicit(&wrapper->value, value, order);\
    }\
\
    static __inline__ __attribute__((__always_inline__)) NS_SWIFT_NAME(c_atomic_##Type.and(_:value:order:))\
    Type c_atomic_##Type##_and(struct c_atomic_##Type *wrapper, Type value, memory_order order) {\
        return atomic_fetch_and_explicit(&wrapper->value, value, order);\
    }\


ATOMIC_CREATE(bool);
ATOMIC_CREATE(uintptr_t);
ATOMIC_CREATE(int64_t);
ATOMIC_CREATE(uint64_t);

struct c_dispatch_once_token {
    dispatch_once_t token;
};

static __inline__ __attribute__((__always_inline__)) NS_SWIFT_NAME(c_dispatch_once_token.create())
struct c_dispatch_once_token *c_dispatch_once_token_create(void) {
    struct c_dispatch_once_token *wrapper = (struct c_dispatch_once_token *)malloc(sizeof(*wrapper));
    wrapper->token = 0;
    atomic_thread_fence(memory_order_release);
    return wrapper;
}

static __inline__ __attribute__((__always_inline__)) NS_SWIFT_NAME(c_dispatch_once_token.destroy(_:))
void c_dispatch_once_token_destroy(struct c_dispatch_once_token *wrapper) { free(wrapper); }


static __inline__ __attribute__((__always_inline__)) NS_SWIFT_NAME(c_dispatch_once_token.exec(_:execute:))
void c_dispatch_once_token_exec(struct c_dispatch_once_token *wrapper, NS_NOESCAPE dispatch_block_t block) {
    atomic_thread_fence(memory_order_acquire);
    dispatch_once(&wrapper->token, block);
}
#ifdef __cplusplus
} // extern "C"
#endif // __cplusplus

NS_ASSUME_NONNULL_END
