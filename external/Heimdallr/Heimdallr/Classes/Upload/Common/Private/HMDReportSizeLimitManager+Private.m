//
//  HMDReportSizeLimitManager+Private.m
//  Heimdallr-8bda3036
//
//  Created by liuhan on 2022/7/28.
//

#import "HMDReportSizeLimitManager+Private.h"
#include "pthread_extended.h"
#import "HMDMacro.h"
CLANG_DIAGNOSTIC_PUSH
CLANG_DIAGNOSTIC_IGNORE_STRICT_PROTOTYPES
#import <Hermas/Hermas.h>
CLANG_DIAGNOSTIC_POP

static pthread_mutex_t operationLock = PTHREAD_MUTEX_INITIALIZER;
static pthread_rwlock_t _rwLock = PTHREAD_RWLOCK_INITIALIZER;
static pthread_rwlock_t _rwSizeLock = PTHREAD_RWLOCK_INITIALIZER;

@interface HMDReportSizeLimitManager ()
@property (nonatomic, assign, readwrite) BOOL isRunning;
@property (nonatomic, assign, readwrite) NSUInteger thresholdSize; // byte
@property (nonatomic, strong, readwrite) NSMutableSet *tools;
@property (nonatomic, assign, readwrite) long long currentDataSize;
@property (nonatomic, assign, readwrite) long long currentDataSize2;
@end

@implementation HMDReportSizeLimitManager (Private)

- (void)startSizeLimit {
    pthread_mutex_lock(&operationLock);
    if (self.isRunning) {
        pthread_mutex_unlock(&operationLock);
        return;
    }
    if (hermas_enabled()) {
        [[HMEngine sharedEngine] updateFlowControlStrategy:HMFlowControlStrategyLimited];
        self.isRunning = YES;
        pthread_mutex_unlock(&operationLock);
        return;
    }
    self.isRunning = YES;
    if (self.tools.count > 0) {
        [self.tools enumerateObjectsUsingBlock:^(id <HMDReportSizeLimitManagerDelegate>  _Nonnull obj, BOOL * _Nonnull stop) {
            if ([obj respondsToSelector:@selector(hmdReportSizeLimitManagerStart)]) {
                [obj hmdReportSizeLimitManagerStart];
            }
        }];
    }
    pthread_mutex_unlock(&operationLock);
}

- (void)stopSizeLimit {
    pthread_mutex_lock(&operationLock);
    if (!self.isRunning) {
        pthread_mutex_unlock(&operationLock);
        return;
    }
    if (hermas_enabled()) {
        [[HMEngine sharedEngine] updateFlowControlStrategy:HMFlowControlStrategyNormal];
        pthread_mutex_unlock(&operationLock);
        return;
    }
    self.isRunning = NO;
    if (self.tools.count > 0) {
        [self.tools enumerateObjectsUsingBlock:^(id <HMDReportSizeLimitManagerDelegate>  _Nonnull obj, BOOL * _Nonnull stop) {
            if ([obj respondsToSelector:@selector(hmdReportSizeLimitManagerStop)]) {
                [obj hmdReportSizeLimitManagerStop];
            }
        }];
    }
    pthread_mutex_unlock(&operationLock);
}

- (void)setDataSizeThreshold:(NSUInteger)thresholdSize {
    pthread_rwlock_wrlock(&_rwSizeLock);
    self.thresholdSize = thresholdSize;
    pthread_rwlock_unlock(&_rwSizeLock);
}

- (void)addSizeLimitTool:(id<HMDReportSizeLimitManagerDelegate>)tool {
    if (tool) {
        pthread_rwlock_wrlock(&_rwLock);
        [self.tools addObject:tool];
        if (self.isRunning && [tool respondsToSelector:@selector(hmdReportSizeLimitManagerStart)]) {
            [tool hmdReportSizeLimitManagerStart];
        }
        pthread_rwlock_unlock(&_rwLock);
    }
}

- (void)removeSizeLimitTool:(id<HMDReportSizeLimitManagerDelegate>)tool {
    if (tool) {
        pthread_rwlock_wrlock(&_rwLock);
        [self.tools removeObject:tool];
        pthread_rwlock_unlock(&_rwLock);
    }
}

- (BOOL)increaseDataLength:(NSUInteger)dataLength {
    BOOL isThreshold = NO;
    pthread_rwlock_rdlock(&_rwSizeLock);
    self.currentDataSize += dataLength;
    isThreshold = self.currentDataSize > self.thresholdSize;
    pthread_rwlock_unlock(&_rwSizeLock);
    if (isThreshold) {
        pthread_rwlock_rdlock(&_rwLock);
        [self.tools enumerateObjectsUsingBlock:^(id  _Nonnull obj, BOOL * _Nonnull stop) {
            id <HMDReportSizeLimitManagerDelegate> tool = obj;
            if ([tool respondsToSelector:@selector(currentSizeOutOfThreshold)]) {
                [tool currentSizeOutOfThreshold];
            }
        }];
        self.currentDataSize = 0;
        pthread_rwlock_unlock(&_rwLock);
        return YES;
    }
    return NO;
}

@end
