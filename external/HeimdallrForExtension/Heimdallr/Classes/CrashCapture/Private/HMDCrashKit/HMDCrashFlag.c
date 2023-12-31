//
//  HMDCrashFlag.c
//  Pods
//
//  Created by yuanzhangjing on 2019/12/30.
//

#include "HMDCrashFlag.h"
#include "hmd_memory.h"
static bool *_flag;
void HMDCrashInjectFlag(bool * _Nullable flag) {
    _flag = flag;
}

void HMDCrashMarkFlag(void) {
    bool *flag = _flag;
    if (flag) {
        bool expect = true;
        hmd_async_read_memory((hmd_vm_address_t)&expect, flag, sizeof(bool));
    }
}
