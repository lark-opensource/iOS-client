//
//  HMDCrashKitSwitch.h
//  Pods
//
//  Created by yuanzhangjing on 2019/12/1.
//

#ifndef HMDCrashKitSwitch_h
#define HMDCrashKitSwitch_h

#include <stdbool.h>
#include "HMDPublicMacro.h"

HMD_EXTERN_SCOPE_BEGIN

enum {
    HMDCrashSwitchRegisterAnalysis = 0,
    HMDCrashSwitchStackAnalysis,
    HMDCrashSwitchVMMap,
    HMDCrashSwitchCPPBacktrace,
    HMDCrashSwitchContentAnalysis,
    HMDCrashSwitchIgnoreExitByUser,
    HMDCrashSwitchWriteImageOnCrash,
    HMDCrashSwitchExtendFD,
    HMDCrashSwitchCoreDumpIfAsan,   // 如果发生 Asan 是否进行 CoreDump
};

void hmd_crash_switch_update(unsigned int option, bool value);

bool hmd_crash_switch_state(unsigned int option);

void hmd_crash_update_stack_trace_count(uint32_t count);

uint32_t hmd_crash_stack_trace_count(void);

void hmd_crash_update_max_vmmap(int max_vmmap);

int hmd_crash_max_vmmap(void);

HMD_EXTERN_SCOPE_END

#endif /* HMDCrashKitSwitch_h */
