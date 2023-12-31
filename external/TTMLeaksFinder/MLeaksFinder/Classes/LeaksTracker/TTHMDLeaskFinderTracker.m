//
//  HMDTTLeaskFinderTracker.m
//  Heimdallr_Example
//
//  Created by bytedance on 2020/5/29.
//  Copyright © 2020 ghlsb@hotmail.com. All rights reserved.
//

#import "TTHMDLeaskFinderTracker.h"
#import "TTHMDLeaksFinderRecord.h"
#import "TTHMDLeaksFinderDetector.h"
#import <BDALogProtocol/BDAlogProtocol.h>
#import <Heimdallr/HMDUserExceptionTracker.h>
#import <TTMacroManager/TTMacroManager.h>

#include <pthread.h>

#ifndef PTHREAD_MUTEX_SAFE_CHECK_TYPE
#ifdef DEBUG
#define PTHREAD_MUTEX_SAFE_CHECK_TYPE PTHREAD_MUTEX_ERRORCHECK
#else
#define PTHREAD_MUTEX_SAFE_CHECK_TYPE PTHREAD_MUTEX_DEFAULT
#endif
#endif

#ifndef mutex_init_normal
#define mutex_init_normal(mtx) {                                                                  \
     pthread_mutexattr_t attr;                                                                    \
    (pthread_mutexattr_init)(&attr);                                                              \
    (pthread_mutexattr_settype)(&attr, PTHREAD_MUTEX_SAFE_CHECK_TYPE);                            \
    (pthread_mutex_init)(&(mtx), &attr);                                                          \
    (pthread_mutexattr_destroy)(&attr);                                                           \
}
#endif

static NSString *const HMDLeaksFinderTitle = @"HMDLeaksFinderException";
static NSString *const HMDLeaksFinderExceptionType = @"Leaks";

@interface TTHMDLeaskFinderTracker () <TTHMDLeaksFinderDetectorDelegate>

@property(nonatomic, strong) NSArray<HMDStoreCondition *> *andConditions;
@property (nonatomic, assign) pthread_mutex_t startMutex;
@property (nonatomic, assign) BOOL isStart;

@end

@implementation TTHMDLeaskFinderTracker

+ (instancetype)sharedTracker {
    static TTHMDLeaskFinderTracker *sharedTracker = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedTracker = [[self alloc] init];
    });
    return sharedTracker;
}

#pragma mark - override
- (instancetype)init {
    if (self = [super init]) {
        mutex_init_normal(_startMutex);
    }
    return self;
}

- (BOOL)isDebug{
    if ([TTMacroManager isDebug]) {
        return YES;
    }
    return  NO;
}

- (void)start {
    if ([self isDebug]) {
        return;
    }
    
    pthread_mutex_lock(&_startMutex);
    if (self.isStart) {
        pthread_mutex_unlock(&_startMutex);
        return;
    }
    [super start];
    self.isStart = YES;
    [[TTHMDLeaksFinderDetector shareInstance] start];
    [TTHMDLeaksFinderDetector shareInstance].delegate = self;
    pthread_mutex_unlock(&_startMutex);

}

- (void)stop {
    pthread_mutex_lock(&_startMutex);
    if (!self.isStart) {
        pthread_mutex_unlock(&_startMutex);
        return;
    }
    [super stop];
    self.isStart = NO;
    [[TTHMDLeaksFinderDetector shareInstance] stop];
    pthread_mutex_unlock(&_startMutex);
}

- (void)updateConfig:(HMDModuleConfig *)config {
    [super updateConfig:config];
    [[TTHMDLeaksFinderDetector shareInstance] updateConfig:config];
}

#pragma mark - HMDLeaksFinderDetectorDelegate
//上报自定义异常
- (void)detector:(TTHMDLeaskFinderTracker *)detector didDetectData:(TTHMDLeaksFinderRecord *)data {
    NSMutableDictionary *filter = [[NSMutableDictionary alloc] init];
    if (data.leaksId.length > 0) {
        [filter setValue:data.leaksId forKey:@"leaks_id"];
    }
    //Leaks size round filters
    if (data.leakSizeRound.length > 0) {
        [filter setValue:data.leakSizeRound forKey:@"leaks_size_round"];
    }
    
    [[HMDUserExceptionTracker sharedTracker] trackUserExceptionWithExceptionType:HMDLeaksFinderExceptionType title:HMDLeaksFinderTitle subTitle:data.retainCycle?:@"unknown" addressList:data.addressList customParams:[data customData] filters:filter callback:^(NSError * _Nullable error) {
        if (error) {
            BDALOG_PROTOCOL_ERROR_TAG(@"Heimdallr", @"[TTHMDLeaksFinder] upload user exception failed with error %@", error);
        }
    }];
    BDALOG_PROTOCOL_WARN_TAG(@"Heimdallr", @"[TTHMDLeaksFinder] Found leaks");
}

@end
