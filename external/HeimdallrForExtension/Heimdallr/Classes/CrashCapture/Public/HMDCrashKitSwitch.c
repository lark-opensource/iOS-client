//
//  HMDCrashKitSwitch.c
//  Pods
//
//  Created by yuanzhangjing on 2019/12/1.
//

#include "HMDCrashKitSwitch.h"

static uint64_t _switch;

void hmd_crash_switch_update(unsigned int option, bool value) {
    if (option < 64) {
        uint64_t n = 1;
        if (value) {
            _switch |= (n<<option);
        } else {
            _switch &= ~(n<<option);
        }
    }
}

bool hmd_crash_switch_state(unsigned int option) {
    if (option < 64) {
        uint64_t n = 1;
        return (_switch & (n<<option)) != 0;
    }
    return false;
}

#define HMDMaxStackTraceCount 16384 //(128k)

static uint32_t stack_trace_count;

void hmd_crash_update_stack_trace_count(uint32_t count)
{
    stack_trace_count = (count < HMDMaxStackTraceCount) ? count : HMDMaxStackTraceCount;
}

uint32_t hmd_crash_stack_trace_count(void)
{
    return stack_trace_count;
}

static int crash_max_vmmap;

void hmd_crash_update_max_vmmap(int max_vmmap)
{
    crash_max_vmmap = max_vmmap;
}

int hmd_crash_max_vmmap(void)
{
    return crash_max_vmmap;
}
