//
//  BDPAppPreloadInfo.m
//  Timor
//
//  Created by 傅翔 on 2019/7/5.
//

#import "BDPAppPreloadInfo.h"

@implementation BDPAppPreloadInfo

+ (instancetype)preloadInfoWithUniqueID:(BDPUniqueID *)uniqueID priority:(BDPPkgLoadPriority)priority preloadMode:(BDPPreloadMode)mode {
    if (!uniqueID) {
        return nil;
    }
    BDPAppPreloadInfo *info = [[BDPAppPreloadInfo alloc] init];
    info.uniqueID = uniqueID;
    info.priority = priority;
    info.preloadMode = mode;
    return info;
}

+ (instancetype)preloadInfoWithUniqueID:(BDPUniqueID *)uniqueID priority:(BDPPkgLoadPriority)priority {
    return [BDPAppPreloadInfo preloadInfoWithUniqueID:uniqueID priority:priority preloadMode:-1];
}

- (instancetype)init {
    if (self = [super init]) {
        _preloadMode = -1;
    }
    return self;
}

- (void)setPriority:(BDPPkgLoadPriority)priority {
    _priority = priority >= BDPAppLoadPriorityNormal && priority <= BDPAppLoadPriorityHighest ? priority : BDPAppLoadPriorityNormal;
}

- (void)setPreloadMode:(BDPPreloadMode)preloadMode {
    _preloadMode = preloadMode >= BDPPreloadModeLazy && preloadMode <= BDPPreloadModeLatest ? preloadMode : -1;
}

@end
