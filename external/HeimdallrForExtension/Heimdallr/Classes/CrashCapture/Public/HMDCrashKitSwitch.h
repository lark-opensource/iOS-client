//
//  HMDCrashKitSwitch.h
//  Pods
//
//  Created by yuanzhangjing on 2019/12/1.
//

#ifndef HMDCrashKitSwitch_h
#define HMDCrashKitSwitch_h

#include <stdio.h>
#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

    enum {
        HMDCrashSwitchRegisterAnalysis = 0,
        HMDCrashSwitchStackAnalysis,
        HMDCrashSwitchVMMap,
        HMDCrashSwitchCPPBacktrace,
        HMDCrashSwitchContentAnalysis,
        HMDCrashSwitchIgnoreExitByUser,
        HMDCrashSwitchWriteImageOnCrash,
        HMDCrashSwitchExtendFD
    };

    void hmd_crash_switch_update(unsigned int option, bool value);

    bool hmd_crash_switch_state(unsigned int option);

    void hmd_crash_update_stack_trace_count(uint32_t count);

    uint32_t hmd_crash_stack_trace_count(void);

    void hmd_crash_update_max_vmmap(int max_vmmap);
    
    int hmd_crash_max_vmmap(void);

#ifdef __cplusplus
} // extern "C"
#endif

#endif /* HMDCrashKitSwitch_h */
