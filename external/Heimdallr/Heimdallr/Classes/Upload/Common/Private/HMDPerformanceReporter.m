//
//  HMDPerformanceReporter.m
//  Heimdallr
//
//  Created by fengyadong on 2018/3/29.
//

#import "HMDPerformanceReporter.h"
#import "HeimdallrUtilities.h"
#include "pthread_extended.h"
#import "HMDFileUploader.h"
#import "HMDHeimdallrConfig.h"
#import "HMDGeneralAPISettings.h"
#import "HMDReportLimitSizeTool.h"
#include <stdatomic.h>
#import "HMDPerformanceReporter+SizeLimitedReport.h"
#import "HMDReportSizeLimitManager+Private.h"

@interface HMDPerformanceReporter()<HMDLimitReportDataSizeToolDelegate>
{
    atomic_uint _pendingCount;
    pthread_mutex_t _mutexLock;
    pthread_rwlock_t _rwLock;
}

@property (nonatomic, strong) NSMutableOrderedSet <id<HMDPerformanceReporterDataSource>> *performanceModules;
@property (nonatomic, strong) HMDReportLimitSizeTool *reporSizeLimitTool;
@property (atomic, assign) NSTimeInterval sizeLimitAvailableTime;
@property (nonatomic, strong) id<HMDNetworkProvider> provider;

@end

@implementation HMDPerformanceReporter

- (instancetype)initWithProvider:(id<HMDNetworkProvider>)provider {
    if (self = [super init]) {
        pthread_mutex_init(&_mutexLock, NULL);
        rwlock_init_private(_rwLock);
        _performanceModules = [NSMutableOrderedSet orderedSet];
        self.reporSizeLimitTool = [[HMDReportLimitSizeTool alloc] init];
        self.reporSizeLimitTool.delegate = self;
        self.sizeLimitAvailableTime = 0;
        _enableTimeStamp = DBL_MIN;
        _provider = provider;
        [[HMDReportSizeLimitManager defaultControlManager] addSizeLimitTool:self.reporSizeLimitTool];
    }
    return self;
}

- (void)dealloc {
    if (self.sizeLimitedReportTimer && [self.sizeLimitedReportTimer isValid]) {
        [self.sizeLimitedReportTimer invalidate];
    }
    if (self.reporSizeLimitTool) {
        [[HMDReportSizeLimitManager defaultControlManager] removeSizeLimitTool:self.reporSizeLimitTool];
    }
}

- (void)addReportModuleSafe:(id<HMDPerformanceReporterDataSource>)module {
    if (module) {
        pthread_mutex_lock(&_mutexLock);
        if (![module respondsToSelector:@selector(reporterPriority)]) {
            [self.performanceModules addObject:module];
        }
        else {
            __block NSUInteger insertIdx = self.performanceModules.array.count;
            [self.performanceModules enumerateObjectsUsingBlock:^(id<HMDPerformanceReporterDataSource>  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                if ([obj respondsToSelector:@selector(reporterPriority)]) {
                    if ([module reporterPriority] >= [obj reporterPriority]) {
                        insertIdx = idx;
                        *stop = YES;
                    }
                }
                else {
                    insertIdx = idx;
                    *stop = YES;
                }
            }];
            [self.performanceModules insertObject:module atIndex:insertIdx];
        }
        [self.reporSizeLimitTool addNeedLimitReportSizeRecordClass:module];
        pthread_mutex_unlock(&_mutexLock);
    }
}

- (void)removeReportModuleSafe:(id<HMDPerformanceReporterDataSource>)module {
    if(module) {
        pthread_mutex_lock(&_mutexLock);
        [self.performanceModules removeObject:module];
        [self.reporSizeLimitTool removeReportSizeRecordClass:module];
        pthread_mutex_unlock(&_mutexLock);
    }
}

- (NSArray *)allReportingModules {
    NSArray *allModules;
    pthread_mutex_lock(&_mutexLock);
    allModules = [[self.performanceModules array] copy];
    pthread_mutex_unlock(&_mutexLock);
    return allModules;
}

- (void)updateConfig:(HMDHeimdallrConfig *)config {    
    self.reportPollingInterval = config.apiSettings.performanceAPISetting.uploadInterval;
    self.reportMaxLogCount = config.apiSettings.performanceAPISetting.onceMaxCount;
}

- (BOOL)ifNeedReportAfterUpdatingRecordCount:(NSInteger)count {
#if !RANGERSAPM
    atomic_fetch_add_explicit(&_pendingCount, (unsigned int)count, memory_order_acq_rel);
    if (self.reportMaxLogCount > 0) {
        if (_pendingCount > self.reportMaxLogCount) {
            return YES;
        }
    }
#endif

    return NO;
}

- (void)clearRecordCountAfterReportingSuccessfully {
    atomic_store_explicit(&_pendingCount, 0, memory_order_release);
}

- (void)cleanupWithConfigUnsafe:(HMDDebugRealConfig *)config {
    NSArray<id<HMDPerformanceReporterDataSource>> *modules = [self.performanceModules array];

    for (id<HMDPerformanceReporterDataSource> module in modules) {
        if ([module respondsToSelector:@selector(cleanupPerformanceDataWithConfig:)]) {
            [module cleanupPerformanceDataWithConfig:config];
        }
    }
}

- (void)updateEnableTimeStampAfterReporting {
    NSTimeInterval currentTime = [[NSDate date] timeIntervalSince1970];
    NSTimeInterval newEnableTime = currentTime + self.reportPollingInterval;
    pthread_rwlock_wrlock(&_rwLock);
    _enableTimeStamp = newEnableTime;
    pthread_rwlock_unlock(&_rwLock);
}

- (NSTimeInterval)enableTimeStamp {
    pthread_rwlock_rdlock(&_rwLock);
    NSTimeInterval enableTimeStamp = _enableTimeStamp;
    pthread_rwlock_unlock(&_rwLock);
    return enableTimeStamp;
}

#pragma - mark Size limited tool
- (void)performanceSizeLimitReportStart {
    pthread_mutex_lock(&_mutexLock);
    [self startSizeLimitedReportTimer];
    pthread_mutex_unlock(&_mutexLock);
}

- (void)performanceSizeLimitReportStop {
    pthread_mutex_lock(&_mutexLock);
    [self stopSizeLimitedReportTimer];
    pthread_mutex_unlock(&_mutexLock);
}

- (void)performanceDataSizeOutOfThreshold {
    [self reportPerformanceDataAsyncWithSizeLimited];
}

@end
