//
//  HMDReportSizeControl.m
//  AFgzipRequestSerializer-iOS13.0
//
//  Created by zhangxiao on 2019/12/16.
//

#import "HMDReportLimitSizeTool.h"
#include "pthread_extended.h"
#import "HMDALogProtocol.h"
#import "HMDDynamicCall.h"
#import "HMDGCD.h"
#import "HMDWeakProxy.h"
#import "HMDCustomReportManager.h"
#import "HMDReportSizeLimitManager+Private.h"

@interface HMDReportLimitSizeTool ()

@property (nonatomic, strong) dispatch_queue_t calculationQueue;
@property (nonatomic, strong) NSMutableDictionary *visitorTimeRangeDict;
@property (nonatomic, strong) NSMutableSet *muduleSet;

@end


@implementation HMDReportLimitSizeTool

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.calculationQueue = dispatch_queue_create("com.heimdallr.report.size.control", DISPATCH_QUEUE_SERIAL);
        self.muduleSet = [NSMutableSet set];
    }
    return self;
}

- (void)addNeedLimitReportSizeRecordClass:(id)recordModule {
    if (!recordModule) {return;}
    hmd_safe_dispatch_async(self.calculationQueue, ^{
        [self.muduleSet addObject:recordModule];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
        if ([recordModule isKindOfClass:NSClassFromString(@"HeimdallrModule")]) {
            DC_OB(recordModule,setupWithHeimdallrReportSizeLimit:, self);
        } else if ([recordModule respondsToSelector:@selector(setupWithHeimdallrReportSizeLimit:)]) {
            if ([object_getClass(recordModule) isKindOfClass: object_getClass([HMDWeakProxy class])]) {
                [((HMDWeakProxy *)recordModule) retainTarget];
                [recordModule performSelector:@selector(setupWithHeimdallrReportSizeLimit:) withObject:self];
                [((HMDWeakProxy *)recordModule) releaseTarget];
            } else {
                [recordModule performSelector:@selector(setupWithHeimdallrReportSizeLimit:) withObject:self];
            }

        }
#pragma clang diagnostic pop
    });
}

- (void)addNeedLimitReportSizeRecordClasses:(NSSet *)recordModules {
    hmd_safe_dispatch_async(self.calculationQueue, ^{
        for (id recordModule in recordModules) {
            [self.muduleSet addObject:recordModule];

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
            if ([recordModule isKindOfClass:NSClassFromString(@"HeimdallrModule")]) {
                DC_OB(recordModule,setupWithHeimdallrReportSizeLimit:, self);
            } else if ([recordModule respondsToSelector:@selector(setupWithHeimdallrReportSizeLimit:)]) {
                [recordModule performSelector:@selector(setupWithHeimdallrReportSizeLimit:) withObject:self];
            }
#pragma clang diagnostic pop
        }
    });
}

- (void)removeReportSizeRecordClass:(id)recordModule {
    if (!recordModule) {return;}
    hmd_safe_dispatch_async(self.calculationQueue, ^{
        [self.muduleSet removeObject:recordModule];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
        if ([recordModule isKindOfClass:NSClassFromString(@"HeimdallrModule")]) {
            DC_OB(recordModule,setupWithHeimdallrReportSizeLimit:, nil);
        } else if ([recordModule respondsToSelector:@selector(setupWithHeimdallrReportSizeLimit:)]) {
            [recordModule performSelector:@selector(setupWithHeimdallrReportSizeLimit:) withObject:nil];
        }
#pragma clang diagnostic pop
    });
}

- (void)hmdReportSizeLimitManagerStart {
    hmd_safe_dispatch_async(self.calculationQueue, ^{
        if (self.delegate && [self.delegate respondsToSelector:@selector(performanceSizeLimitReportStart)]) {
            [self.delegate performanceSizeLimitReportStart];
        }
    });
}

- (void)hmdReportSizeLimitManagerStop {
    hmd_safe_dispatch_async(self.calculationQueue, ^{
        if (self.delegate && [self.delegate respondsToSelector:@selector(performanceSizeLimitReportStop)]) {
            [self.delegate performanceSizeLimitReportStop];
        }
    });
}

- (BOOL)shouldSizeLimit {
    BOOL isSizeLimit = [HMDCustomReportManager defaultManager].currentConfig.customReportMode == HMDCustomReportModeSizeLimit;
    return isSizeLimit;
}

#pragma mark --- record
- (void)estimateSizeWithStoreObjectRecord:(NSArray *)records recordClass:(nonnull Class<HMDRecordStoreObject>)recordClass module:(nonnull id)reportMoudle {
    if (![self shouldSizeLimit]) { return; }
    if (!records || records.count == 0 ) { return; }
    if (![recordClass respondsToSelector:@selector(reportDataForRecords:)]) { return;}
    NSArray <NSDictionary *> *dictArray = [recordClass reportDataForRecords:records];
    hmd_safe_dispatch_async(self.calculationQueue, ^{
        if ([recordClass respondsToSelector:@selector(reportDataForRecords:)]) {
            @try {
                if (dictArray) {
                    NSData *data = [NSJSONSerialization dataWithJSONObject:dictArray options:NSJSONWritingPrettyPrinted error:NULL];
                    [self accumulationDataLengthWithData:data];
                    if (hmd_log_enable()) {
                        if (data.length > [HMDCustomReportManager defaultManager].currentConfig.thresholdSize) {
                            HMDALOG_PROTOCOL_INFO_TAG(@"Heimdallr", @"Heimdallr report data out of threhold size: %ld, recordDict: %@", data.length, dictArray);
                        }
                    }
                }
            } @catch (NSException *exception) {
                if (hmd_log_enable()) {
                     HMDALOG_PROTOCOL_ERROR_TAG(@"Heimdallr", @"Heimdallr report data size record covert to data failed with exception %@", exception.description);
                }
            }
        }
    });
}

- (void)estimateSizeWithMonitorRecords:(NSArray *)needAggregateRecords recordClass:(Class<HMDRecordStoreObject>)recordClass module:(nonnull id)reportMoudle{
    if (![self shouldSizeLimit]) { return; }
    NSArray *aggregateDictArray = nil;
    if ([recordClass respondsToSelector:@selector(aggregateDataWithRecords:)]) {
        aggregateDictArray = [recordClass aggregateDataWithRecords:[needAggregateRecords copy]];
    }
    hmd_safe_dispatch_async(self.calculationQueue, ^{
        @try {
            if (aggregateDictArray) {
                NSData *data = [NSJSONSerialization dataWithJSONObject:aggregateDictArray options:NSJSONWritingPrettyPrinted error:NULL];
                [self accumulationDataLengthWithData:data];
                if (hmd_log_enable()) {
                    if (data.length > [HMDCustomReportManager defaultManager].currentConfig.thresholdSize) {
                        HMDALOG_PROTOCOL_INFO_TAG(@"Heimdallr", @"Heimdallr report data out of threhold size: %ld, recordDict: %@", data.length, aggregateDictArray);
                    }
                }
            }
        } @catch (NSException *exception) {
            if (hmd_log_enable()) {
                 HMDALOG_PROTOCOL_ERROR_TAG(@"Heimdallr", @"Heimdallr report data size record covert to data failed with exception %@", exception.description);
            }
        }
    });
}

- (void)estimateSizeWithDictArray:(NSArray<NSDictionary *> *)aggregateDictArray module:(id)reportMoudle {
    if (!aggregateDictArray || ![self shouldSizeLimit]) { return; }
    hmd_safe_dispatch_async(self.calculationQueue, ^{
        @try {
            if (aggregateDictArray) {
                NSData *data = [NSJSONSerialization dataWithJSONObject:aggregateDictArray options:NSJSONWritingPrettyPrinted error:NULL];
                [self accumulationDataLengthWithData:data];
                if (hmd_log_enable()) {
                    if (data.length > [HMDCustomReportManager defaultManager].currentConfig.thresholdSize) {
                        HMDALOG_PROTOCOL_INFO_TAG(@"Heimdallr", @"Heimdallr report data out of threhold size: %ld, recordDict: %@", data.length, aggregateDictArray);
                    }
                }
            }
        } @catch (NSException *exception) {
            if (hmd_log_enable()) {
                 HMDALOG_PROTOCOL_ERROR_TAG(@"Heimdallr", @"Heimdallr report data size record covert to data failed with exception %@", exception.description);
            }
        }
    });
}

- (BOOL)accumulationDataLengthWithData:(NSData *)data {
    NSUInteger length = [data length];
    return [[HMDReportSizeLimitManager defaultControlManager] increaseDataLength:length];
}

- (void)currentSizeOutOfThreshold {
    hmd_safe_dispatch_async(self.calculationQueue, ^{
        if (![self shouldSizeLimit]) { return; }
        if ([self.delegate respondsToSelector:@selector(performanceDataSizeOutOfThreshold)]) {
           [self.delegate performanceDataSizeOutOfThreshold];
        }
    });
}


@end
