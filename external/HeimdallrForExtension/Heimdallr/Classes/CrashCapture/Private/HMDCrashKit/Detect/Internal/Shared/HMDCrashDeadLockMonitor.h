//
//  HMDCrashDeadLockMonitor.h
//  Heimdallr
//
//  Created by yuanzhangjing on 2019/9/23.
//

#ifndef HMDCrashDeadLockMonitor_h
#define HMDCrashDeadLockMonitor_h

#include <stdio.h>
#include <stdbool.h>

bool hmd_crash_init_detect_deadlock(void);

void hmd_crash_start_detect_deadlock(void);

void hmd_crash_stop_detect_deadlock(void);

#ifdef __cplusplus
extern "C" {
#endif

void hmd_crash_start_coredump(void);

#ifdef __cplusplus
} // extern "C"
#endif

#endif /* HMDCrashDeadLockMonitor_h */
