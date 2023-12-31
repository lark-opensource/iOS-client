//
//  TSPKDetectConsts.h
//  Pods
//
//  Created by PengYan on 2021/3/27.
//

#ifndef TSPKDetectConsts_h
#define TSPKDetectConsts_h

typedef NS_ENUM(NSUInteger, TSPKDetectTriggerType) {
    TSPKDetectTriggerTypeNone,
    TSPKDetectTriggerTypePageStatus,
    TSPKDetectTriggerTypeAdvanceAppStatus,
};

typedef NS_ENUM(NSUInteger, TSPKDetectTaskType) {
    TSPKDetectTaskTypeNone,
    TSPKDetectTaskTypeDetectReleaseBadCase,
    TSPKDetectTaskTypeDetectReleaseStatus
};


#endif /* TSPKDetectConsts_h */
