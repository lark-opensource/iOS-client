//
//  HMDLockHeader.h
//  Pods
//
//  Created by wangyinhui on 2021/8/20.
//

#ifndef HMDLockHeader_h
#define HMDLockHeader_h

#import <sys/queue.h>
#import <os/lock.h>
#import <pthread/sched.h>
#import <mach/mach.h>
#import <stdatomic.h>

OS_UNFAIR_LOCK_AVAILABILITY
typedef os_unfair_lock _hmd_pthread_lock;

#define DLOCK_OWNER_MASK            ((uint32_t)0xfffffffc)
#define DLOCK_WAITERS_BIT            ((uint32_t)0x00000001)
#define DLOCK_FAILED_TRYLOCK_BIT    ((uint32_t)0x00000002)

#pragma mark - rw

typedef struct {
    long sig;
    OS_UNFAIR_LOCK_AVAILABILITY _hmd_pthread_lock lock;
    uint32_t unused:29,
            misalign:1,
            pshared:2;
    uint32_t rw_flags;
#if defined(__LP64__)
    uint32_t _pad;
#endif
    uint32_t rw_tid[2]; // thread id of thread that has exclusive (write) lock
    uint32_t rw_seq[4]; // rw sequence id (at 128-bit aligned boundary)
    uint32_t rw_mis[4]; // for misaligned locks rw_seq will span into here
#if defined(__LP64__)
    uint32_t _reserved[34];
#else
    uint32_t _reserved[18];
#endif
} hmd_pthread_rwlock;

#pragma mark - pthread_mutex

typedef struct {
    long sig;
    OS_UNFAIR_LOCK_AVAILABILITY _hmd_pthread_lock lock;
    union {
        uint32_t value;
//        struct _pthread_mutex_options options;
    } mtxopts;
    int16_t prioceiling;
    int16_t priority;
#if defined(__LP64__)
    uint32_t _pad;
#endif
    uint32_t m_tid[2]; // thread id of thread that has mutex locked
    uint32_t m_seq[2]; // mutex sequence id
    uint32_t m_mis[2]; // for misaligned locks m_tid/m_seq will span into here
#if defined(__LP64__)
    uint32_t _reserved[4];
#else
    uint32_t _reserved[1];
#endif
} hmd_pthread_mutex;


#pragma mark - unfair
typedef semaphore_t _hmd_dispatch_sema4_t;
#define ULL_WAITERS    1U
#if defined(__LP64__)
#define    PAD_(t)    (sizeof(uint32_t) <= sizeof(t) \
? 0 : sizeof(uint32_t) - sizeof(t))
#else
#define    PAD_(t)    (sizeof(uint64_t) <= sizeof(t) \
? 0 : sizeof(uint64_t) - sizeof(t))
#endif
#if BYTE_ORDER == LITTLE_ENDIAN
#define    PADL_(t)    0
#define    PADR_(t)    PAD_(t)
#else
#define    PADL_(t)    PAD_(t)
#define    PADR_(t)    0
#endif

typedef struct dispatch_thread_event_s {
#if HAVE_UL_COMPARE_AND_WAIT || HAVE_FUTEX
    // 1 means signalled but not waited on yet
    // UINT32_MAX means waited on, but not signalled yet
    // 0 is the initial and final state
    uint32_t dte_value;
#else
    _hmd_dispatch_sema4_t dte_sema;
#endif
} dispatch_thread_event_s, *dispatch_thread_event_t;

typedef struct {
    char operation_l_[PADL_(uint32_t)]; uint32_t operation; char operation_r_[PADR_(uint32_t)];
    char addr_l_[PADL_(user_addr_t)]; user_addr_t addr; char addr_r_[PADR_(user_addr_t)];
    char value_l_[PADL_(uint64_t)]; uint64_t value; char value_r_[PADR_(uint64_t)];
    char timeout_l_[PADL_(uint32_t)]; uint32_t timeout; char timeout_r_[PADR_(uint32_t)];
} hmd_ulock_wait_args;


#pragma mark - GCD

typedef struct {
    const void *isa;
    int ref_cnt;
    int xref_cnt;
    
    const struct dispatch_queue_vtable_s *do_vtable;
    struct dispatch_queue_s *volatile do_next;
    struct dispatch_queue_s *do_targetq;
    void *do_ctxt;
    void *do_finalizer;

    uint64_t volatile dq_state;
    // queue的首元素
    struct dispatch_object_s *volatile dq_items_head;
    // queue编号
    unsigned long dq_serialnum;
    // queue名称
    const char *dq_label;
} hmd_dispatch_queue_s;

#endif /* HMDLockHeader_h */
