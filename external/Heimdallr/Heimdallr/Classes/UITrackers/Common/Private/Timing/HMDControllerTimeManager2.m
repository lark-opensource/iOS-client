//
//  HMDControllerTimeManager2.m
//  Heimdallr-8bda3036
//
//  Created by 崔晓兵 on 13/4/2022.
//

#import "HMDControllerTimeManager2.h"
#import "HMDInjectedInfo.h"
#import "HMDDebugRealConfig.h"
#import "HMDControllerTimingConfig.h"
#import "HMDGCD.h"
#import "HMDReportDowngrador.h"
#import "HMDHermasHelper.h"
#import "HMDHermasManager.h"
#import "HMDMacro.h"
CLANG_DIAGNOSTIC_PUSH
CLANG_DIAGNOSTIC_IGNORE_STRICT_PROTOTYPES
#import <Hermas/Hermas.h>
CLANG_DIAGNOSTIC_POP

@interface HMDControllerTimeManager()
@property (nonatomic, strong) dispatch_queue_t syncQueue;
@end

@interface HMDControllerTimeManager2()
@property (nonatomic, strong) HMInstance *instance;
@end

@implementation HMDControllerTimeManager2

- (HMInstance *)instance {
    if (!_instance) {
        _instance = [HMDHermasManager sharedPerformanceInstance];
    }
    return _instance;
}

- (void)clearRecordsArray {
    // do nothing
}

#pragma mark -- receiveNotification
- (void)applicationWillEnterBackground:(NSNotification *)notification {
   // do nothing
}
#pragma mark - delegate
- (void)hmdControllerName:(NSString *)pageName typeName:(NSString *)typeName timeInterval:(NSTimeInterval)interval isFirstOpen:(NSInteger)isFirstOpen {
    if (!self.isRunning || hermas_drop_data(kModulePerformaceName) || hmd_downgrade_performance(@"performance_monitor")) {
        return;
    }
    HMDControllerTimeRecord *record = [HMDControllerTimeRecord newRecord];
    record.timeInterval = interval;
    record.pageName = pageName;
    record.typeName = typeName;
    record.isFirstOpen = isFirstOpen;
    record.enableUpload = self.config.enableUpload ? 1 : 0;
    hmd_safe_dispatch_async(self.syncQueue, ^{
        // need aggregate
        [self.instance aggregateData:record.reportDictionary];
    });
}
#pragma mark -- upload
        
- (NSArray *)performanceDataWithCountLimit:(NSInteger)limitCount {
    return nil;
}


- (void)performanceDataSaveImmediately {
    [self.instance stopAggregate:NO];
}

- (void)performanceDataDidReportSuccess:(BOOL)isSuccess {
    // do nothing
}

- (void)cleanupNotUploadAndReportedPerformanceData {
    // do nothing
}

#pragma - mark drop data

- (void)dropAllDataForServerState {
    // do nothing
}


#pragma mark - SizeLimitedReport Modify

- (NSArray *)performanceDataWithLimitSize:(NSUInteger)limitSize
                               limitCount:(NSInteger)limitCount
                              currentSize:(NSUInteger *)currentSize {

    return nil;
}

- (void)performanceSizeLimitedDataDidReportSuccess:(BOOL)isSuccess {
    // do nothing
}

@end
