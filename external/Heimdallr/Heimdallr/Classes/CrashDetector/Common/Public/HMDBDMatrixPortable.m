//
//  HMDBDMatrixPortable.c
//  Pods
//
//  Created by bytedance on 2023/4/12.
//

#if !SIMPLIFYEXTENSION

#include "HMDExcludeModuleHelper.h"
#include "HMDCrashKit+Internal.h"

#define HMD_THIS_IS_BD_MATRIX_FILE
#include "HMDBDMatrixPortable.h"

// 该文件仅限 BDMatrix 使用
bool HMDBDMatrixPortable_lastTimeCrash(void) {
    return HMDCrashKit.sharedInstance.lastTimeCrash;
}

bool HMDBDMatrixPortable_crashTrackerFinishedDetection(void) {
    id<HMDExcludeModule> crashModule = [HMDExcludeModuleHelper excludeModuleForRuntimeClassName:@"HMDCrashTracker"];
    return crashModule.finishDetection;
}

uint64_t HMDBDMatrixPortable_lastCrashUsedVM(void) {
    return HMDCrashKit.sharedInstance.lastCrashUsedVM;
}

uint64_t HMDBDMatrixPortable_lastCrashTotalVM(void) {
    return HMDCrashKit.sharedInstance.lastCrashTotalVM;
}

#endif
