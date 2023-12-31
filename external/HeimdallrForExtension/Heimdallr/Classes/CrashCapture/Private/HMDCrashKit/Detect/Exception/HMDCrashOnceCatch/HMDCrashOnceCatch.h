//
//  HMDCrashOnceCatch.h
//  CaptainAllred
//
//  Created by sunrunwang on 2019/8/2.
//  Copyright © 2019 sunrunwang. All rights reserved.
//

#ifndef HMDCrashOnceCatch_h
#define HMDCrashOnceCatch_h

#include <stdbool.h>
#include "HMDCrashHeader.h"
#include "HMDAsyncThread.h"
#include <mach/mach_types.h>

#define once_catch   HMDCrashOnceCatch
#define catch_finish HMDCrashCatchFinish
#define catch_thread HMDCrashCatchThread
#define wait_catch   HMDCrashWaitCatch

EXTERN_C

thread_t catch_thread(void);

bool once_catch(void);

void wait_catch(void);

void catch_finish(void);

EXTERN_C_END

#endif /* HMDCrashOnceCatch_h */
