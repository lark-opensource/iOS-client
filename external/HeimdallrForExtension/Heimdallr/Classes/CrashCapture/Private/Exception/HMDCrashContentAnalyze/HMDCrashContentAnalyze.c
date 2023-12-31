//
//  HMDCrashContentAnalyze.c
//  Heimdallr
//
//  Created by bytedance on 2020/4/14.
//

#include "HMDCrashContentAnalyze.h"

#define kHMDBufferLength 100

static _Atomic(HMDObjCClassType) analyzeTypes = HMDObjCClassTypeAll;

HMDObjCClassType HMDFetchAnalyzeTypes() {
    return analyzeTypes;
}

void HMDInitWriteContentTypes(HMDObjCClassType types) {
    analyzeTypes = types;
}

int HMDCrashWriteClassInfo(int fd, HMDCrashObjectInfo *info) {
    HMDClassData *data = HMDFetchObjectClassData(info);
    char buffer[kHMDBufferLength];
    if (analyzeTypes & data->type) {
        return data->writeObject(fd, info, buffer, kHMDBufferLength);
    }
    return HMDWriteObjectDescription(fd, info, buffer, kHMDBufferLength);
}

int HMDCrashWriteClassInfoWithAddress(int fd, void *object, char *buffer, int length) {
    HMDCrashObjectInfo info = {0};
    if (HMDCrashGetObjectInfo(object, &info)) {
        HMDClassData *data = HMDFetchObjectClassData(&info);
        if (analyzeTypes & data->type) {
            return data->writeObject(fd, &info, buffer, length);
        }
        return HMDWriteObjectDescription(fd, &info, buffer, length);
    }
    return 0;
}
