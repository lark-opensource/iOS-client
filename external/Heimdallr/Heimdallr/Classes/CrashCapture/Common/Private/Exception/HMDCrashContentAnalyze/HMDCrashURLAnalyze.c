//
//  HMDCrashURLAnalyze.c
//  Heimdallr
//
//  Created by bytedance on 2020/4/14.
//

#include "HMDCrashURLAnalyze.h"
#include "HMDCrashFileBuffer.h"
#include "hmd_objc_apple.h"
#include "hmd_memory.h"
#include "HMDCrashContentAnalyze.h"

int HMDAnalyzeNSURLContent(int fd, HMDCrashObjectInfo *object, char *buffer, int length) {
    struct HMDURL cls = {0};
    if (hmd_async_read_memory((hmd_vm_address_t)object->addr, &cls, sizeof(cls)) != HMD_ESUCCESS) {
        return 0;
    }
    return HMDCrashWriteClassInfoWithAddress(fd, (void *)cls._string, buffer, length);
}
