//
//  HMDNetQualityManager.m
//  Heimdallr
//
//  Created by zhangxiao on 2021/3/4.
//

#import "HMDNetQualityTracker.h"
#import "HMDDynamicCall.h"
#include "pthread_extended.h"

NSString *const kHMDNetQualityDidChange = @"kHMDCurrentNetworkQualityDidChange";
NSString *const kHMDNetQualityDidChangeUserInfoQualityKey = @"network_quality";

@interface HMDNetQualityTracker ()

@property (atomic, assign) BOOL isRunning;
@property (nonatomic, assign, readwrite) NSInteger currentNetQuality;


@end

@implementation HMDNetQualityTracker {
    pthread_rwlock_t _qualityTypeLock;
}

#pragma mark --- life cycle
+ (instancetype)sharedTracker {
    static HMDNetQualityTracker *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[HMDNetQualityTracker alloc] init];
    });
    return instance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _currentNetQuality = -1;
        pthread_rwlock_init(&_qualityTypeLock, NULL);
    }
    return self;
}

- (void)switchNetQualityTrackerStatus:(BOOL)isOn {
    if (isOn == self.isRunning) { return; }
    if (isOn) {
        [self startNetQualityMonitor];
    } else {
        [self stopNetQualityMonitor];
    }
}

- (void)startNetQualityMonitor {
    if (!self.isRunning) {
        self.isRunning = YES;
        id monitor = DC_CL(HMDTTNetQualityHelper, sharedInstance);
        if(monitor) {
            DC_OB(monitor, start);
            DC_OB(monitor, registerQualityDelegate:, self);
        }
    }
}

- (void)stopNetQualityMonitor {
    if (self.isRunning) {
        self.isRunning = NO;
        id monitor = DC_CL(HMDTTNetQualityHelper, sharedInstance);
        if(monitor) {
            DC_OB(monitor, stop);
        }
    }
}

- (void)dealloc {
    if (self.isRunning) {
        [self stopNetQualityMonitor];
    }
}

#pragma mark --- override
- (NSInteger)currentNetQuality {
    NSInteger qualityCode = -1;
    pthread_rwlock_rdlock(&_qualityTypeLock);
    qualityCode = _currentNetQuality;
    pthread_rwlock_unlock(&_qualityTypeLock);
    return qualityCode;
}

#pragma mark --- protocol
- (void)hmdCurrentNetQualityDidChange:(NSInteger)netQualityType {
    pthread_rwlock_wrlock(&_qualityTypeLock);
    _currentNetQuality = netQualityType;
    pthread_rwlock_unlock(&_qualityTypeLock);
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kHMDNetQualityDidChange object:@{kHMDNetQualityDidChangeUserInfoQualityKey: @(netQualityType)}];
}

@end
