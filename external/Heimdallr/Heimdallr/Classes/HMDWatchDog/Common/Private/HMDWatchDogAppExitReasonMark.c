//
//  HMDWatchDogAppExitReasonMark.c
//  Heimdallr
//
//  Created by ByteDance on 2023/9/18.
//

#include "HMDWatchDogAppExitReasonMark.h"

static bool * appStateIsWatchDogAddress;
static bool * appStateIsWeakWatchDogAddress;

void HMDWatchDog_registerAppExitReasonMark(bool * _Nullable flag) {
    appStateIsWatchDogAddress = flag;
}

void HMDWatchDog_markAppExitReasonWatchDog(bool isWatchDog) {
    if (appStateIsWatchDogAddress) {
        *appStateIsWatchDogAddress = isWatchDog;
    }
}

void HMDWeakWatchDog_registerAppExitReasonMark(bool * _Nullable flag) {
    appStateIsWeakWatchDogAddress = flag;
}

void HMDWeakWatchDog_markAppExitReasonWatchDog(bool isWeakWatchdog) {
    if (appStateIsWeakWatchDogAddress) {
        *appStateIsWeakWatchDogAddress = isWeakWatchdog;
    }
}
