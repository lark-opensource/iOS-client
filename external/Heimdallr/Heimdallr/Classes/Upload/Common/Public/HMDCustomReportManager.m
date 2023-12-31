//
//  HMDReportManager.m
//  Heimdallr-8bda3036
//
//  Created by liuhan on 2022/7/25.
//

#import "HMDCustomReportManager.h"
#include "pthread_extended.h"
#import "HMDReportSizeLimitManager+Private.h"
#import "HMDPerformanceReporterManager.h"
#import "HMDHeimdallrConfig.h"
#import "HMDGeneralAPISettings.h"
#import "NSDate+HMDAccurate.h"

#import "HMDMacro.h"
CLANG_DIAGNOSTIC_PUSH
CLANG_DIAGNOSTIC_IGNORE_STRICT_PROTOTYPES
#import <Hermas/Hermas.h>
CLANG_DIAGNOSTIC_POP

static pthread_mutex_t customOperationLock = PTHREAD_MUTEX_INITIALIZER;

NSString * const kHMDCustomReportPerformaceModueName = @"batch";


@interface HMDPerformanceReporterManager ()

@property (nonatomic, strong) NSMutableDictionary<NSString *,HMDPerformanceReporter *> *reporters;

@end


@interface HMDCustomReportManager ()

@property (atomic, assign, readwrite) NSUInteger thresholdSize;
@property (atomic, assign, readwrite) NSUInteger uploadIntervalSec;
@property (atomic, assign, readwrite) HMDCustomReportMode customReportMode;

@property (nonatomic, strong, readwrite) NSMutableArray<HMDCustomReportConfig *>*cachedCustomConfigs;

@property (atomic, strong, readwrite) HMDCustomReportConfig *currentConfig;

@property (nonatomic, strong, readwrite) HMDHeimdallrConfig *heimdallrConfig;

@end

@implementation HMDCustomReportManager {
    pthread_rwlock_t _rwCurrentLock;
    pthread_rwlock_t _rwCacheLock;
    pthread_rwlock_t _rwIntervalLock;
    NSTimeInterval _lastReportTime;
}

+ (instancetype)defaultManager {
    static HMDCustomReportManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[HMDCustomReportManager alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        pthread_rwlock_init(&_rwCacheLock, NULL);
        pthread_rwlock_init(&_rwCurrentLock, NULL);
        pthread_rwlock_init(&_rwIntervalLock, NULL);
        _lastReportTime = -1;
        self.cachedCustomConfigs = [NSMutableArray array];
    }
    return self;
}

- (void)startWithConfig:(HMDCustomReportConfig *)config {
    pthread_mutex_lock(&customOperationLock);
    // 缓存配置
    [self cacheOneConfig:config];
    
    // 如该配置优先级高于或等于当前优先级，切换上报模式
    pthread_rwlock_wrlock(&_rwCurrentLock);
    if (config.customReportMode <= self.currentConfig.customReportMode || self.currentConfig == NULL) {
        [self switchCurrentReportMode];
    }
    pthread_rwlock_unlock(&_rwCurrentLock);
    
    pthread_mutex_unlock(&customOperationLock);
}


- (void)stopWithCustomMode:(HMDCustomReportMode)mode {
    pthread_mutex_lock(&customOperationLock);
    [self removeOneConfigWithMode:mode];
    
    // 如果该配置优先级和当前生效配置优先级一致，切换上报模式
    pthread_rwlock_wrlock(&_rwCurrentLock);
    if (mode == self.currentConfig.customReportMode) {
        [self switchCurrentReportMode];
    }
    
    // 如果没有缓存配置，开启常规上报
    if (self.cachedCustomConfigs.count < 1) {
        pthread_rwlock_unlock(&_rwCurrentLock);
        pthread_mutex_unlock(&customOperationLock);
        [self startNormalUpload];
        return;
    }
    
    pthread_rwlock_unlock(&_rwCurrentLock);
    
    pthread_mutex_unlock(&customOperationLock);
}

- (void)switchCurrentReportMode {
    pthread_rwlock_unlock(&_rwCurrentLock);
    // 终止原有模式
    switch (self.currentConfig.customReportMode) {
        case HMDCustomReportModeSizeLimit:
            [[HMDReportSizeLimitManager defaultControlManager] stopSizeLimit];
            break;
        case HMDCustomReportModeActivelyTrigger:
            if (hermas_enabled()) {
                [[HMEngine sharedEngine] startUploadTimerWithModuleId:kHMDCustomReportPerformaceModueName];
            }
            break;
        default:
            break;
    }
    
    self.currentConfig = self.cachedCustomConfigs.firstObject;
    
    // 开启现有模式
    switch (self.currentConfig.customReportMode) {
        case HMDCustomReportModeSizeLimit:
            [[HMDReportSizeLimitManager defaultControlManager] startSizeLimit];
            break;
        case HMDCustomReportModeActivelyTrigger:
            if (hermas_enabled()) {
                [[HMEngine sharedEngine] stopUploadTimerWithModuleId:kHMDCustomReportPerformaceModueName];
            }
        default:
            break;
    }
    pthread_rwlock_unlock(&_rwCurrentLock);
}


- (void)startNormalUpload {
    pthread_mutex_lock(&customOperationLock);
    
    if (self.cachedCustomConfigs.count < 1) {
        pthread_mutex_unlock(&customOperationLock);
        return;
    }
    
    [self removeAllConfigs];
    
    pthread_rwlock_unlock(&_rwCurrentLock);
    if (self.currentConfig.customReportMode == HMDCustomReportModeSizeLimit) {
        [[HMDReportSizeLimitManager defaultControlManager] stopSizeLimit];
    }
    
    self.currentConfig = NULL;
    pthread_rwlock_unlock(&_rwCurrentLock);
    
    pthread_mutex_unlock(&customOperationLock);
}


- (void)triggerReport {
    pthread_rwlock_wrlock(&_rwCurrentLock);
    HMDCustomReportMode mode = self.currentConfig.customReportMode;
    pthread_rwlock_unlock(&_rwCurrentLock);
    
    if (mode != HMDCustomReportModeActivelyTrigger) {
        return;
    } else {
        pthread_rwlock_wrlock(&_rwIntervalLock);
        NSTimeInterval currentTime = [[NSDate date] timeIntervalSince1970];
        BOOL allowReport = (currentTime - _lastReportTime) >= [self getReportIntervalOfSetting];
        if (_lastReportTime == -1 || allowReport) {
            _lastReportTime = currentTime;
            pthread_rwlock_unlock(&_rwIntervalLock);
            if (hermas_enabled()) {
                [[HMEngine sharedEngine] triggerUploadManuallyWithModuleId:kHMDCustomReportPerformaceModueName];
            } else {
                [[HMDPerformanceReporterManager sharedInstance] triggerAllReporterUpload];
            }
            
            return;
        }
        pthread_rwlock_unlock(&_rwIntervalLock);
    }
}


- (void)cacheOneConfig:(HMDCustomReportConfig *)config {
    if (config) {
        pthread_rwlock_wrlock(&_rwCacheLock);
        if (self.cachedCustomConfigs.count == 0) {
            [self.cachedCustomConfigs addObject:config];
            pthread_rwlock_unlock(&_rwCacheLock);
            return;
        }
        
        if (config.customReportMode > self.cachedCustomConfigs.lastObject.customReportMode) {
            [self.cachedCustomConfigs addObject:config];
            pthread_rwlock_unlock(&_rwCacheLock);
            return;
        }
        
        for (int i = 0; i < (int)self.cachedCustomConfigs.count; i++) {
            if (config.customReportMode == self.cachedCustomConfigs[i].customReportMode) {
                [self.cachedCustomConfigs replaceObjectAtIndex:i withObject:config];
                break;
            } else if (config.customReportMode < self.cachedCustomConfigs[i].customReportMode) {
                int index = i ? i - 1 : i;
                [self.cachedCustomConfigs insertObject:config atIndex:index];
                break;
            }
        }
        pthread_rwlock_unlock(&_rwCacheLock);
    }
}


- (void)removeOneConfigWithMode:(HMDCustomReportMode)mode {
    if (mode) {
        pthread_rwlock_wrlock(&_rwCacheLock);
        for (int i = 0; i < (int)self.cachedCustomConfigs.count; i++) {
            if (mode == self.cachedCustomConfigs[i].customReportMode) {
                [self.cachedCustomConfigs removeObjectAtIndex:i];
                break;
            }
        }
        pthread_rwlock_unlock(&_rwCacheLock);
    }
}


- (void)removeAllConfigs {
    pthread_rwlock_wrlock(&_rwCacheLock);
    [self.cachedCustomConfigs removeAllObjects];
    pthread_rwlock_unlock(&_rwCacheLock);
}

- (void)updateConfig:(HMDHeimdallrConfig *)config {
    self.heimdallrConfig = config;
}

- (NSInteger) getReportIntervalOfSetting {
    return 5;
//    return self.heimdallrConfig.apiSettings.performanceAPISetting.uploadInterval;
}

@end
