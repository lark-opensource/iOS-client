//
//  HMDReportConfig.m
//  Heimdallr-8bda3036
//
//  Created by liuhan on 2022/7/25.
//

#import <Foundation/Foundation.h>
#import "HMDCustomReportConfig.h"
#include "pthread_extended.h"
#import "HMDCustomReportManager.h"

#define MAXTHRESHOLDSIZE 2 * 1024 * 1024
#define MINTHRESHOLDSIZE 100
#define MAXUPLOADINTERVAL 10 * 60
#define MINUPLOLADINTERVAL 5

@interface HMDCustomReportConfig() {
    pthread_rwlock_t intervalLock;
    pthread_rwlock_t sizeLock;
}

@property (atomic, assign, readwrite) HMDCustomReportMode customReportMode;


@end

@implementation HMDCustomReportConfig

@synthesize thresholdSize = _thresholdSize, uploadInterval = _uploadInterval;

- (instancetype)initConfigWithMode:(HMDCustomReportMode)mode {
    if (self = [super init]) {
        pthread_rwlock_init(&intervalLock, NULL);
        pthread_rwlock_init(&sizeLock, NULL);
        self.customReportMode = mode;
        if (mode == HMDCustomReportModeSizeLimit) {
            _thresholdSize = MINTHRESHOLDSIZE;
            _uploadInterval = MINUPLOLADINTERVAL;
        } else {
            _uploadInterval = [[HMDCustomReportManager defaultManager] getReportIntervalOfSetting];
        }
    }
    return self;
}

- (void)setThresholdSize:(NSInteger)thresholdSize {
    NSInteger size = thresholdSize;
    switch (self.customReportMode) {
        case HMDCustomReportModeSizeLimit:
            if (thresholdSize > MAXTHRESHOLDSIZE) {
                size = MAXTHRESHOLDSIZE;
            } else if (thresholdSize < MINTHRESHOLDSIZE) {
                size = MINTHRESHOLDSIZE;
            }
            pthread_rwlock_wrlock(&sizeLock);
            _thresholdSize = size;
            pthread_rwlock_unlock(&sizeLock);
            break;
        case HMDCustomReportModeActivelyTrigger:
            pthread_rwlock_wrlock(&sizeLock);
            _thresholdSize = MINTHRESHOLDSIZE;
            pthread_rwlock_unlock(&sizeLock);
            break;
        default:
            break;
    }
}

- (NSInteger)thresholdSize {
    pthread_rwlock_wrlock(&sizeLock);
    NSInteger size = _thresholdSize;
    pthread_rwlock_unlock(&sizeLock);
    return size;
}

- (void)setUploadInterval:(NSInteger)uploadInterval {
    NSInteger interval = uploadInterval < MINUPLOLADINTERVAL ? MINUPLOLADINTERVAL : uploadInterval;
    pthread_rwlock_wrlock(&intervalLock);
    _uploadInterval = interval;
    pthread_rwlock_unlock(&intervalLock);
    
}

- (NSInteger)uploadInterval {
    pthread_rwlock_wrlock(&intervalLock);
    NSInteger interval = _uploadInterval;
    pthread_rwlock_unlock(&intervalLock);
    return interval;
}

@end
