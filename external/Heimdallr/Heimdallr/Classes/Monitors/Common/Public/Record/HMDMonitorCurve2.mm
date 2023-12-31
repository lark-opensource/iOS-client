//
//  HMDMonitorCurve2.m
//  Heimdallr-8bda3036
//
//  Created by 崔晓兵 on 17/3/2022.
//

#import "HMDMonitorCurve2.h"
#import "Heimdallr.h"
#import "Heimdallr+Private.h"
#import "HMDStoreIMP.h"
#import "HMDCPUMonitorRecord.h"
#import "HMDMemoryMonitorRecord.h"
#import "HMDFPSMonitorRecord.h"
#import "HMDALogProtocol.h"
#import "pthread_extended.h"
#import "HMDReportLimitSizeTool.h"
#import "HMDGCD.h"
#import "HMDMonitorRecord.h"
#import "HMDReportDowngrador.h"
#import "HMDHermasCounter.h"
#import "HMDHermasManager.h"
#import "HMDMacro.h"
CLANG_DIAGNOSTIC_PUSH
CLANG_DIAGNOSTIC_IGNORE_STRICT_PROTOTYPES
#import <Hermas/Hermas.h>
CLANG_DIAGNOSTIC_POP
// PrivateServices
#import "HMDServerStateService.h"

@interface HMDMonitorCurve()
@property (nonatomic, strong) dispatch_queue_t syncQueue;
@end


@interface HMDMonitorCurve2()
@property (nonatomic, strong) HMInstance *instance;
@end

@implementation HMDMonitorCurve2

- (instancetype)initWithCurveName:(NSString *)name recordClass:(Class)recordClass {
    self = [super initWithCurveName:name recordClass:recordClass];
    return self;
}

- (HMInstance *)instance {
    if (!_instance) {
        _instance = [HMDHermasManager sharedPerformanceInstance];
    }
    return _instance;
}


- (void)pushRecord:(HMDMonitorRecord *)record {
    hmd_safe_dispatch_async(self.syncQueue, ^{
        if (self.instance.isDropData) return;
        if (hmd_downgrade_performance(@"performance_monitor")) return;
        [self.storageDelegate updateRecordWithConfig:record];
        [record addInfo];
        if ([record needAggregate]) {
            [self.instance aggregateData:record.reportDictionary];
        } else {
            [self.instance recordData:record.reportDictionary];
        }
    });
}

- (void)pushRecordToDBImmediately:(HMDMonitorRecord *)record {
    hmd_safe_dispatch_async(self.syncQueue, ^{
        if (self.instance.isDropData) return;
        if (hmd_downgrade_performance(@"performance_monitor")) return;
        [self.storageDelegate updateRecordWithConfig:record];
        [record addInfo];
        if ([record needAggregate]) {
            [self.instance aggregateData:record.reportDictionary];
        } else {
            [self.instance recordData:record.reportDictionary priority:HMRecordPriorityHigh];
        }
    });
}


#pragma mark -- receiveNotification

- (void)applicationEnterBackground:(NSNotification *)notification {
    // do nothing
}

#pragma - mark drop data

- (void)dropAllDataForServerState {
    // do nothing
}

- (void)recordDataDirectly:(NSDictionary *_Nonnull)dic {
    if (self.instance.isDropData) return;
    
    BOOL enableUpload = [self.storageDelegate enableUpload];
    NSMutableDictionary *mutabldDic = [NSMutableDictionary dictionaryWithDictionary:dic];
    [mutabldDic setValue:@(enableUpload) forKey:@"enable_upload"];
    [self.instance recordData:mutabldDic.copy];
}

@end
