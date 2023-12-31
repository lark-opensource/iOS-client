//
//  HMDCrashDebugAssert.h
//  TEST
//
//  Created by sunrunwang on 2019/4/8.
//  Copyright © 2019 Bill Sun. All rights reserved.
//

#ifndef HMDCrashDebugAssert_h
#define HMDCrashDebugAssert_h

#ifndef DEBUG_ELSE
#ifdef DEBUG
#define DEBUG_ELSE
#else
#define DEBUG_ELSE
#endif
#endif

#ifndef DEBUG_POINT
#ifdef DEBUG
#define DEBUG_POINT __builtin_trap();
#else
#define DEBUG_POINT
#endif
#endif

#ifndef DEBUG_ASSERT
#ifdef DEBUG
#define DEBUG_ASSERT(x) if(!(x)) DEBUG_POINT
#else
#define DEBUG_ASSERT(x)
#endif
#endif

#ifndef DEBUG_ACTION
#ifdef DEBUG
#define DEBUG_ACTION(x) do { (x); } while(0)
#else
#define DEBUG_ACTION(x)
#endif
#endif


#ifndef DEBUG_ONCE
#ifdef DEBUG
#ifdef CFDebugAssert_DEBUG_ONCE_CPP
#define DEBUG_ONCE ({                                                       \
static std::atomic_flag onceToken = ATOMIC_FLAG_INIT;                       \
if(onceToken.test_and_set(std::memory_order_acq_rel)) __builtin_trap();     \
});
#elif defined CFDebugAssert_DEBUG_ONCE_C
#define DEBUG_ONCE ({                                                       \
static atomic_flag onceToken = ATOMIC_FLAG_INIT;                            \
if(atomic_flag_test_and_set_explicit(&onceToken, memory_order_acq_rel))     \
__builtin_trap();                                                           \
});
#else
#define DEBUG_ONCE
#warning DEBUG_ONCE not available
#endif
#else
#define DEBUG_ONCE
#endif
#endif

#ifndef HMDCRASH_PROCESS_ONLY
#ifdef DEBUG
#define HMDCRASH_PROCESS_ONLY DEBUG_ASSERT(dispatch_get_specific((void *)0xABCDEF) == (void *)0xABCDEF);
#else
#define HMDCRASH_PROCESS_ONLY
#endif
#endif

#endif /* HMDCrashDebugAssert_h */
