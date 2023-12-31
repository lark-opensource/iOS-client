//
//  HMDMetricKitMonitor.m
//  Heimdallr
//
//  Created by maniackk on 2021/4/21.
//

#include <pthread.h>
#include <mach/vm_prot.h>
#import <MetricKit/MetricKit.h>

#import "HMDMetricKitTracker.h"
#import "HMDBinaryImage.h"
#import "HMDMetrickitConfig.h"
#import "HMDExceptionReporter.h"
#import "HMDInfo+AppInfo.h"
#import "HeimdallrUtilities.h"
#import "HMDALogProtocol.h"
#import "NSDictionary+HMDSafe.h"
#import "HMDCompactUnwind.hpp"
#import "HMDUserDefaults.h"
#import "hmd_thread_backtrace.h"
#import "HMDMacro.h"
#import "HMDServiceContext.h"
#import "HMDMacroManager.h"

#import "HMDHermasHelper.h"
#import "HMDInjectedInfo.h"
#import "HMDMacro.h"
CLANG_DIAGNOSTIC_PUSH
CLANG_DIAGNOSTIC_IGNORE_STRICT_PROTOTYPES
#import <Hermas/Hermas.h>
CLANG_DIAGNOSTIC_POP
#import "HMDHermasCounter.h"
#import "HMDMetricKitRecord.h"
#import "HMDStoreCondition.h"
#import "Heimdallr+Private.h"
#import "Heimdallr.h"
#import "HMDMetricKitSegmentRenameFix.h"

// PrivateServices
#import "HMDServerStateService.h"

static NSString *const HMDMetricKitEventType = @"HMDMetricKit";

@interface HMDMetricKitTracker()<MXMetricManagerSubscriber>

@property(nonatomic, strong) NSMutableArray<MXDiagnosticPayload *> *payloads API_AVAILABLE(ios(14.0));

@property(nonatomic, strong) HMInstance *instance;

@property(nonatomic, strong) NSMutableArray<MXMetricPayload *> *metricPayloads API_AVAILABLE(ios(13.0));

@property(nonatomic, assign) BOOL isUploadMetric;

@property(nonatomic, assign) BOOL isFixSegmentRename;

@property(nonatomic, strong) NSString *expandDir API_AVAILABLE(ios(14.0));

@property(nonatomic, strong) NSString *appImagesTextSegmentInfoFilePath API_AVAILABLE(ios(14.0));

@property(nonatomic, strong) NSArray<HMDStoreCondition *> *andConditions;

@end

@implementation HMDMetricKitTracker

+ (instancetype)sharedTracker {
    static HMDMetricKitTracker *monitor = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        monitor = [[HMDMetricKitTracker alloc] init];
    });
    return monitor;
}

- (HMInstance *)instance {
    if (!_instance) {
        _instance = [[HMEngine sharedEngine] instanceWithModuleId:kModuleExceptionName aid:[HMDInjectedInfo defaultInfo].appID];
    }
    return _instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        if (@available(iOS 13.0, *)) {
            _metricPayloads = [[NSMutableArray alloc] init];
            _isUploadMetric = NO;
        }
    }
    return self;
}

- (void)start{
    if (@available(iOS 13.0, *)) {
        [super start];
        MXMetricManager *shared = [MXMetricManager sharedManager];
        [shared addSubscriber:self];
        if (@available(iOS 14.0, *)) {
            if(_isFixSegmentRename) {
                [[HMDMetricKitSegmentRenameFix shared] fetchRecentAppVersionMainOffset];
                [[HMDMetricKitSegmentRenameFix shared] asyncRecordRecordAppImagesTextSegmentInfo];
            } else {
                [[HMDMetricKitSegmentRenameFix shared] removeExpendDir];
            }
        }
    }
}

- (void)stop{
    if (@available(iOS 13.0, *)) {
        [super stop];
        MXMetricManager *shared = [MXMetricManager sharedManager];
        [shared removeSubscriber:self];
    }
}

- (BOOL)needSyncStart {
    return NO;
}

- (BOOL)performanceDataSource {
    return NO;
}

- (BOOL)exceptionDataSource {
    return YES;
}

- (void)updateConfig:(HMDMetrickitConfig *)config {
    [super updateConfig:config];
    _isUploadMetric = config.isUploadMetric;
    _isFixSegmentRename = config.isFixSegmentRename;
}

- (Class<HMDRecordStoreObject>)storeClass {
    return [HMDMetricKitRecord class];
}

- (void)uploadMetricKitLogIfNeeded {
    HMDStopUpload exceptionStopUpload = [HMDInjectedInfo defaultInfo].exceptionStopUpload;
    if (exceptionStopUpload && exceptionStopUpload()) {
        return;
    }
    [[HMDExceptionReporter sharedInstance] reportExceptionDataWithExceptionTypes:@[@(HMDMetricKitExceptionType)]];
}

#pragma mark --- exception report ---

- (HMDExceptionType)exceptionType {
    return HMDMetricKitExceptionType;
}

- (NSArray *)pendingExceptionData {
    if (hermas_enabled()) return nil;
    
    NSMutableArray *reportData = [NSMutableArray new];
    
    HMDStoreCondition *condition1 = [[HMDStoreCondition alloc] init];
    condition1.key                = @"timestamp";
    condition1.threshold          = 0;
    condition1.judgeType          = HMDConditionJudgeGreater;

    HMDStoreCondition *condition2 = [[HMDStoreCondition alloc] init];
    condition2.key                = @"timestamp";
    condition2.threshold          = [[NSDate date] timeIntervalSince1970];
    condition2.judgeType          = HMDConditionJudgeLess;

    _andConditions = @[ condition1, condition2 ];
    
    //In order to prevent the reported message from being too large, we only report one piece of data at a time
    NSArray<HMDMetricKitRecord *> *diagnosticRecords =
        [[Heimdallr shared].database getObjectsWithTableName: [HMDMetricKitRecord tableName]
                                                       class: [HMDMetricKitRecord class]
                                               andConditions:_andConditions
                                                orConditions:nil
                                                       limit:1];

    if (diagnosticRecords.count > 0) {
        [diagnosticRecords enumerateObjectsUsingBlock:^(HMDMetricKitRecord * _Nonnull record, NSUInteger idx, BOOL * _Nonnull stop) {
            [reportData addObject:record.reportDictionary];
        }];
    }
    
    return reportData;
}

- (void)exceptionReporterDidReceiveResponse:(BOOL)isSuccess{
    if (hermas_enabled()) {
        return;
    }
    
    if (!isSuccess) {
        NSDictionary *uploadFailData = [[self pendingExceptionData] firstObject];
        if (uploadFailData) {
            id<HMDTTMonitorServiceProtocol> ttmonitor = hmd_get_heimdallr_ttmonitor();
            [ttmonitor hmdTrackService:@"hmd_metrickit_upload_fail" metric:nil category:nil extra:uploadFailData];
        }
    }
    
    [[Heimdallr shared].database deleteObjectsFromTable:[[self storeClass] tableName]
                                          andConditions:_andConditions
                                           orConditions:nil
                                                  limit:1];
    
    
    long long count = [[Heimdallr shared].database recordCountForTable:[[self storeClass] tableName]];
    if (count > 0) {
        [self uploadMetricKitLogIfNeeded];
    }
}

-(void)dropExceptionData {

    if (hermas_enabled()) {
        return;
    }
    
    [[Heimdallr shared].database deleteAllObjectsFromTable:[[self storeClass] tableName]];
}

#pragma mark - MXMetricManagerSubscriber

- (void)didReceiveMetricPayloads:(NSArray<MXMetricPayload *> *)payloads  API_AVAILABLE(ios(13.0)){
    if (!_isUploadMetric) {
        return;
    }
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        [payloads enumerateObjectsUsingBlock:^(MXMetricPayload * _Nonnull payload, NSUInteger idx, BOOL * _Nonnull stop) {
            HMDMetricKitRecord *record = [HMDMetricKitRecord newRecord];
            record.eventType = HMDMetricKitEventTypeMetric;
            if (@available(iOS 14.0, *)) {
                record.metric = payload.dictionaryRepresentation;
            } else {
                record.metric = payload.DictionaryRepresentation;
            }
            if (hermas_enabled()) {
                // update record
                [self updateRecordWithConfig:record];
                
                BOOL recordImmediately = [HMDHermasHelper recordImmediately];
                HMRecordPriority priority = recordImmediately ? HMRecordPriorityRealTime : HMRecordPriorityHigh;
                [self.instance recordData:record.reportDictionary priority:priority];
            }else {
                [self didCollectOneRecord:record trackerBlock:^(BOOL flag) {
                    if(flag) {
                        [self uploadMetricKitLogIfNeeded];
                    }else {
                        HMDLog(@"[MetricKit]save metric payload to db error");
                    }
                }];
            }
        }];
    });
}

- (void)didReceiveDiagnosticPayloads:(NSArray<MXDiagnosticPayload *> *)payloads  API_AVAILABLE(ios(14.0)) {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        if (payloads && payloads.count > 0){
            NSDictionary *binaryImage;
            NSDictionary *recentVersionImage;
            NSDictionary *historyAppImageTextSegmentInfo;
            NSDictionary *historyPreAppImageTextSegmentInfo;
            if (self.isFixSegmentRename) {
                // contain app recent version's main function offset
                recentVersionImage = [[HMDMetricKitSegmentRenameFix shared] fetchRecentAppVersionMainOffset];
                // contain app recent version's app image load address
                historyAppImageTextSegmentInfo = [[HMDMetricKitSegmentRenameFix shared] historyAppImageTextSegmentMap];
                // clean the expired App image load address recodes
                [[HMDMetricKitSegmentRenameFix shared] resetAppImagesTextSegmentRangeFile];
                // contain app recent version's app image load address(recode when app load)
                historyPreAppImageTextSegmentInfo = [[HMDMetricKitSegmentRenameFix shared] historyPreAppImageTextSegmentMap];
            }
            //app image info list which is used to determine system symbol.
            binaryImage = [[HMDMetricKitSegmentRenameFix shared] fetchCurrentImageNameUUIDMap];
            
            [payloads enumerateObjectsUsingBlock:^(MXDiagnosticPayload * _Nonnull payload, NSUInteger idx, BOOL * _Nonnull stop) {
                HMDMetricKitRecord *record = [HMDMetricKitRecord newRecord];
                record.eventType = HMDMetricKitEventTypeDiagnostic;
                record.diagnostic = [payload dictionaryRepresentation];
                record.binaryImages = binaryImage;
                record.recentAppImages = recentVersionImage;
                record.historyAppImageInfo = historyAppImageTextSegmentInfo;
                record.historyPreAppImageInfo = historyPreAppImageTextSegmentInfo;
                if (hermas_enabled()) {
                    // update record
                    [self updateRecordWithConfig:record];
                    
                    BOOL recordImmediately = [HMDHermasHelper recordImmediately];
                    HMRecordPriority priority = recordImmediately ? HMRecordPriorityRealTime : HMRecordPriorityHigh;
                    [self.instance recordData:record.reportDictionary priority:priority];
                }else {
                    [self didCollectOneRecord:record trackerBlock:^(BOOL flag) {
                        if(flag) {
                            [self uploadMetricKitLogIfNeeded];
                        }else {
                            HMDLog(@"[MetricKit]save diagnostic payload to db error");
                        }
                    }];
                }
            }];
        }
    });
}

@end
