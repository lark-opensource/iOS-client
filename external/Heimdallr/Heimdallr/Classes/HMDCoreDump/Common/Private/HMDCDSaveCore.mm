//
//  HMDCDSaveCore.cpp
//  Heimdallr
//
//  Created by maniackk on 2020/10/14.
//

#import <atomic>
#import <unistd.h>
#import <string.h>
#import <stdlib.h>
#import <mach/mach.h>
#import <sys/mount.h>
#import <pthread/pthread.h>

#import "HMDCDMachO.hpp"
#import "HMDCDSaveCore.h"
#import "HMDCDUploader.h"
#import "HMDCrashSDKLog.h"
#import "HMDCDGenerator.h"
#import "HMDCDConfig+Private.h"
#import "HMDCrashDeadLockMonitor.h"

// 引入tmppath,是防止coredump没有写入完整，第二次启动时候，上传不完整的数据，没有意义。
static char* kBasePath = NULL;
static char* kTmpBasePath = NULL;
static unsigned long kMinFreeDiskUsageMB = HMD_CD_DEFAULT_minFreeDiskUsageMB;
static unsigned long    kMaxCDFileSizeMB = HMD_CD_DEFAULT_maxCDFileSizeMB;
static BOOL             kdumpNSException = HMD_CD_DEFAULT_dumpNSException;
static BOOL            kdumpCPPException = HMD_CD_DEFAULT_dumpCPPException;
static bool kIsOpen = false;
static bool kIsReady = NO;

extern char hmd_home_path[];

static unsigned long long freeDiskSpace(void) {
    struct statfs s;
    const char *path = hmd_home_path;
    if (path) {
        int ret = statfs(path, &s);
        if (ret == 0) {
            return s.f_bavail * s.f_bsize;
        }
    }
    return 0;
}

//static mach_vm_size_t getResidentSize() {
//    task_vm_info_data_t vmInfo;
//    mach_msg_type_number_t count = TASK_VM_INFO_COUNT;
//    kern_return_t ret = task_info(mach_task_self(), TASK_VM_INFO, (task_info_t)&vmInfo, &count);
//    if (ret != KERN_SUCCESS) {
//        return 0;
//    }
//    return vmInfo.phys_footprint;
//}

void hmd_handle_coredump(struct hmdcrash_detector_context *crash_detector_context, 
                         struct hmd_crash_env_context *envContextPointer,
                         bool force) {
    if(!kIsReady) return;
    if(force) goto Flag_force;
    
    if (!kIsOpen) return;
    if ((crash_detector_context->crash_type == HMDCrashTypeNSException) && !kdumpNSException) {
        SDKLog("coredump: crash type nsexception exception, not open dump nsexception");
        return;
    }
    
    if ((crash_detector_context->crash_type == HMDCrashTypeCPlusPlus) && !kdumpCPPException) {
        SDKLog("coredump: crash type cpp exception, not open dump cpp exception");
        return;
    }
    
Flag_force:
    
    kIsReady = false; //only dump once
    
    if (kTmpBasePath == NULL || kBasePath == NULL) {
        SDKLog("coredump: path is null");
        return;
    }
    
    if (kMaxCDFileSizeMB >1000) {
        return;
    }
    
    if (access(kBasePath, F_OK) == 0 || access(kTmpBasePath, F_OK) == 0)
    {
        SDKLog("coredump: coredump file is exist");
        return;
    }
    
    unsigned long long freeSize = freeDiskSpace();
    if (freeSize < kMinFreeDiskUsageMB * 1024 * 1024) {
        SDKLog("coredump: device free disk size is less than min_free_disk_usage_mb");
        return;
    }
    
//    mach_vm_size_t residentSize = getResidentSize();
//    if (residentSize <= 0 || residentSize > kMaxCDFileSizeMB * 1024 * 1024) {
//        SDKLog("coredump: resident memory is bigger than max_cdfile_size_mb");
//        return;
//    }
    
    // delay deadlock
    hmd_crash_start_coredump();
    bool isSucceed = saveCore(kMaxCDFileSizeMB * 1024 * 1024 , kTmpBasePath, envContextPointer, crash_detector_context->crash_time);
    if (isSucceed) {
        if (rename(kTmpBasePath, kBasePath) == 0) {
            SDKLog("coredump: rename coredump file from tmp");
        }
    }
}

void hmd_cd_set_basePath(const char *path) {
    // 多线程竞争会有内存泄漏问题, atomic 防范一下
    static std::atomic_flag onceToken = ATOMIC_FLAG_INIT;
    if(onceToken.test_and_set()) return;
    
    kBasePath = (char *)malloc(strlen(path) + 1);
    strcpy(kBasePath, path);
    //kBasePath + .tmp
    kTmpBasePath = (char *)malloc(strlen(path) + 5);
    snprintf(kTmpBasePath, strlen(path) + 5, "%s.tmp", path);
}

void hmd_cd_set_minFreeDiskUsageMB(unsigned long minFreeDiskUsageMB) {
    kMinFreeDiskUsageMB = minFreeDiskUsageMB;
}

void hmd_cd_set_maxCDFileSizeMB(unsigned long maxCDFileSizeMB) {
    kMaxCDFileSizeMB = maxCDFileSizeMB;
}

void hmd_cd_set_isOpen(bool isOpen) {
#if !__has_feature(address_sanitizer)
    kIsOpen = isOpen;
#endif
}

void hmd_cd_set_dumpNSException(BOOL isDump) {
    kdumpNSException = isDump;
}

void hmd_cd_set_dumpCPPException(BOOL isDump) {
    kdumpCPPException = isDump;
}

void hmd_cd_markReady(void) {
    kIsReady = true;
}
