//
//  HMDDartTracker.m
//  Heimdallr
//
//  Created by joy on 2018/10/24.
//

#include <stdatomic.h>
#import "HMDDartTracker.h"
#import "HMDDartRecord.h"
#import "HMDSessionTracker.h"
#import "HMDDiskUsage+Private.h"
#import "HMDMemoryUsage.h"
#import "HMDMacro.h"
#import "HMDStoreCondition.h"
#import "Heimdallr.h"
#import "Heimdallr+Private.h"
#import "HMDStoreIMP.h"
#import "HMDUploadHelper.h"
#if RANGERSAPM
#import "RangersAPMUploadHelper.h"
#endif
#import "HMDNetworkManager.h"
#import "NSDictionary+HMDSafe.h"
#import "NSDictionary+HMDHTTPQuery.h"
#import "NSDictionary+HMDJSON.h"
#import "HMDInjectedInfo+UniqueKey.h"
#import "HMDDartTrackerConfig.h"
#import "HMDDynamicCall.h"
#import "HMDNetworkReqModel.h"
#import "HMDGeneralAPISettings.h"
#import "HMDInfo+AppInfo.h"
#if RANGERSAPM
#import "RangersAPMDartURLProvider.h"
#else
#import "HMDDartURLProvider.h"
#endif

#import "HMDMacro.h"
CLANG_DIAGNOSTIC_PUSH
CLANG_DIAGNOSTIC_IGNORE_STRICT_PROTOTYPES
#import <Hermas/Hermas.h>
CLANG_DIAGNOSTIC_POP
#import "HMDHermasHelper.h"
// PrivateServices
#import "HMDURLManager.h"

#define DEFAULT_DART_UPLOAD_LIMIT 5

NSString *const kEnableDartMonitor = @"enable_dart_monitor";
static NSString *const kHMDDartEventType = @"dart";

@interface HMDDartTracker () {
    dispatch_queue_t _operationQueue;
    _Atomic(unsigned int) _uploadingCount;
}

@property(nonatomic, assign) BOOL uploadAlog;
@property(nonatomic, strong) HMInstance *instance;
@end

@implementation HMDDartTracker
SHAREDTRACKER(HMDDartTracker)

- (instancetype)init {
    if (self = [super init]) {
        _operationQueue = dispatch_queue_create("com.heimdallr.game.uploading", DISPATCH_QUEUE_SERIAL);
        atomic_store_explicit(&_uploadingCount, 0u, memory_order_release);
    }
    
    return self;
}

- (HMInstance *)instance {
    if (!_instance) {
        _instance = [[HMEngine sharedEngine] instanceWithModuleId:kModuleExceptionName aid:[HMDInjectedInfo defaultInfo].appID];
    }
    return _instance;
}

- (void)start {
    [super start];
    if (!hermas_enabled()) {
        [self uploadDartLogIfNeeded];
    }
}

- (void)stop {
    [super stop];
}

- (void)updateConfig:(HMDDartTrackerConfig *)config {
    [super updateConfig:config];
    self.uploadAlog = config.uploadAlog;
}

- (void)recordDartErrorWithTraceStack:(NSString *)stack customData:(NSDictionary *)customData customLog:(NSString *)customLog filters:(NSDictionary *)filters{
    if (!self.isRunning) return;
    
    HMDDartRecord *record = [HMDDartRecord newRecord];
    record.inAppTime = [HMDSessionTracker currentSession].timeInSession;
    record.backTrace = [stack copy];
    record.isBackground = HMDSessionTracker.currentSession.backgroundStatus;
    hmd_MemoryBytes memoryBytes = hmd_getMemoryBytes();
    record.memoryUsage = memoryBytes.appMemory/HMD_MB;
    record.freeMemoryUsage = memoryBytes.availabelMemory/HMD_MB;
#if RANGERSAPM
    record.freeDiskUsage = [HMDDiskUsage getFreeDiskSpace]/HMD_MB;
    record.operationTrace = [HMDTracker getOperationTraceIfAvailable];
#endif
    record.freeDiskBlockSize = [HMDDiskUsage getFreeDisk300MBlockSizeWithWaitTime:1.0];
    record.commitID = [HMDInfo defaultInfo].commitID;
    
    // 异常前的百行日志
    record.customLog = customLog;
    
    // 添加自定义信息
    // - pageRoute: 路由信息
    // - exception: 异常名
    // - widgetChain: 异常 Widget 的构建链
    // - timeStamp: 异常发生的时间戳
    // - isContinuous: 是否为连续异常
    //
    // 这里不使用  [HMDInjectedInfo defaultInfo] 避免污染其它上报信息
    record.injectedInfo = customData;
    
    record.filters = filters;
       
    if (hermas_enabled()) {
        // update record
        [self updateRecordWithConfig:record];
        
        // write record
        BOOL recordImmediately = [HMDHermasHelper recordImmediately];
        HMRecordPriority priority = recordImmediately ? HMRecordPriorityRealTime : HMRecordPriorityHigh;
        [self.instance recordData:record.reportDictionary priority:priority];
        
        // upload alog
        if ([HMDDartTracker sharedTracker].uploadAlog) {
            DC_OB(DC_CL(HMDLogUploader, sharedInstance), uploadLastAlogBeforeTime:, record.timestamp);
        }
    } else {
        [self didCollectOneRecord:record trackerBlock:^(BOOL isFlushed) {
            if (isFlushed) {
                [self uploadDartLogIfNeeded];
            }
        }];
    }
}

- (void)recordDartErrorWithTraceStack:(NSString *)stack
                           customData:(NSDictionary *)customData
                            customLog:(NSString *)customLog {
    [self recordDartErrorWithTraceStack:stack customData:customData customLog:customLog filters:nil];
}

- (void)recordDartErrorWithTraceStack:(NSString *)stack {
    [self recordDartErrorWithTraceStack:stack customData:@{} customLog:@""];
}

- (Class<HMDRecordStoreObject>)storeClass {
    return [HMDDartRecord class];
}

- (void)uploadDartLogIfNeeded {
    // 如果有正在上传的就不触发了
    // 如果没有上传的就放置一个设置位 + 1 [ 虽然还不清楚是否有上传的 ]
    unsigned int expected = 0;
    if(!atomic_compare_exchange_strong_explicit(&self->_uploadingCount, &expected, 1, memory_order_acq_rel, memory_order_acquire))
        return;
    
    // Explicit capture [ SELF ] for stand alone object, this is always safe and sound
    _Atomic(unsigned int) *uploadingCount = &_uploadingCount;
    dispatch_async(_operationQueue, ^{
        NSArray<HMDDartRecord *> *records = [self fetchUploadRecords];
        
        if (records.count == 0) {
            atomic_fetch_sub_explicit(uploadingCount, 1, memory_order_release);
            return;
        } else if(records.count > 1) {
            atomic_fetch_add_explicit(uploadingCount, (unsigned int)(records.count - 1), memory_order_release);
        }
        
        NSTimeInterval lastTimestamp = 0;
        for (HMDDartRecord *record in records) {
            if (record.timestamp > lastTimestamp) {
                lastTimestamp = record.timestamp;
            }
            NSDictionary *data = [HMDDartTracker getDartDataWithRecord:record];
            [self uploadDartLogWithData:data recordID:record.localID];
        }
        
        //上传Alog日志
        if (lastTimestamp > 0 && [HMDDartTracker sharedTracker].uploadAlog) {
            DC_OB(DC_CL(HMDLogUploader, sharedInstance), uploadLastAlogBeforeTime:, lastTimestamp);
        }
    });
}

- (NSArray<HMDDartRecord *> *)fetchUploadRecords {
    HMDStoreCondition *condition1 = [[HMDStoreCondition alloc] init];
    condition1.key = @"enableUpload";
    condition1.threshold = 0;
    condition1.judgeType = HMDConditionJudgeGreater;
    
    HMDStoreCondition *condition2 = [[HMDStoreCondition alloc] init];
    condition2.key = @"timestamp";
    condition2.threshold = [[NSDate date] timeIntervalSince1970];
    condition2.judgeType = HMDConditionJudgeLess;
    
    NSArray<HMDStoreCondition *> *andConditions = @[condition1,condition2];
    
    NSArray<HMDDartRecord *> *records = [[Heimdallr shared].database getObjectsWithTableName:[[self storeClass] tableName] class:[self storeClass] andConditions:andConditions orConditions:nil limit:DEFAULT_DART_UPLOAD_LIMIT];
    return records;
}

- (void)__attribute__((annotate("oclint:suppress[block captured instance self]"))) uploadDartLogWithData:(NSDictionary *)postData recordID:(NSUInteger)recordID {
    NSString *dartReportURL = [HMDURLManager URLWithProvider:self forAppID:[HMDInjectedInfo defaultInfo].appID];
    if (dartReportURL == nil) {
        return;
    }
    
    if (!HMDIsEmptyDictionary([HMDInjectedInfo defaultInfo].commonParams)) {
        NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithDictionary:[HMDUploadHelper sharedInstance].headerInfo];
        [dic addEntriesFromDictionary:[HMDInjectedInfo defaultInfo].commonParams];
        NSString *queryString = [dic hmd_queryString];
        dartReportURL = [NSString stringWithFormat:@"%@?%@", dartReportURL, queryString];
    } else {
        NSString *queryString = [[HMDUploadHelper sharedInstance].headerInfo hmd_queryString];
        
        dartReportURL = [NSString stringWithFormat:@"%@?%@", dartReportURL, queryString];
    }
    
    NSMutableDictionary * headerDict = [NSMutableDictionary dictionaryWithCapacity:2];
    [headerDict setValue:@"application/json; encoding=utf-8" forKey:@"Content-Type"];
    [headerDict setValue:@"application/json" forKey:@"Accept"];
#if RANGERSAPM
    headerDict = [NSMutableDictionary dictionaryWithDictionary:[RangersAPMUploadHelper headerFieldsForAppID:[HMDInjectedInfo defaultInfo].appID withCustomHeaderFields:headerDict]];
#endif
    
    HMDNetworkReqModel *reqModel = [HMDNetworkReqModel new];
    reqModel.requestURL = dartReportURL;
    reqModel.method = @"POST";
    reqModel.params = postData;
    reqModel.headerField = [headerDict copy];
    reqModel.needEcrypt = [self shouldEncrypt];
    
    [[HMDNetworkManager sharedInstance] asyncRequestWithModel:reqModel callback:^(NSError *error, id jsonObj) {
        BOOL isSuccess = NO;
        if ([jsonObj isKindOfClass:NSDictionary.class]) {
            NSDictionary *result = [jsonObj hmd_dictForKey:@"result"];
            NSString *message = [result hmd_stringForKey:@"message"];
            if ([message isEqualToString:@"success"]) {
                isSuccess = YES;
            }
        }
        
        if (isSuccess) {
            // Explicit capture [ SELF ] for stand alone object, this is always safe and sound
            dispatch_async(self->_operationQueue, ^{
                HMDStoreCondition *condition = [[HMDStoreCondition alloc] init];
                condition.threshold = recordID;
                condition.judgeType = HMDConditionJudgeEqual;
                condition.key = @"localID";
                
                [[Heimdallr shared].database deleteObjectsFromTable:[[self storeClass] tableName] andConditions:@[condition] orConditions:nil];
                
                atomic_fetch_sub_explicit(&self->_uploadingCount, 1, memory_order_release);
            });
        } else atomic_fetch_sub_explicit(&self->_uploadingCount, 1, memory_order_release);
    }];
}

+ (NSDictionary *)getDartDataWithRecord:(HMDDartRecord *)record {

    NSMutableDictionary *dataValue = [NSMutableDictionary dictionary];
    
    long long timestamp = MilliSecond(record.timestamp);
    
    [dataValue setValue:@(timestamp) forKey:@"timestamp"];
    [dataValue setValue:kHMDDartEventType forKey:@"event_type"];
    [dataValue setValue:record.backTrace forKey:@"data"];
    [dataValue setValue:record.sessionID forKey:@"session_id"];
    [dataValue setValue:@(record.memoryUsage) forKey:@"memory_usage"];
    [dataValue setValue:@(record.freeDiskBlockSize) forKey:@"d_zoom_free"];
    [dataValue setValue:@(hmd_calculateMemorySizeLevel(((uint64_t)record.freeMemoryUsage)*HMD_MEMORY_MB)) forKey:HMD_Free_Memory_Key];
    [dataValue setValue:@(record.isBackground) forKey:@"is_background"];
#if RANGERSAPM
    [dataValue setValue:@(record.inAppTime) forKey:@"inapp_time"];
    [dataValue setValue:record.operationTrace forKey:@"operation_trace"];
#endif
    
    [dataValue addEntriesFromDictionary:record.environmentInfo];

    // 存到 Event 信息中供下载
    [dataValue setValue:record.customLog forKey:@"custom_log"];
    
    NSMutableDictionary *header = [NSMutableDictionary dictionaryWithDictionary:[HMDUploadHelper sharedInstance].headerInfo];
    [[HMDInjectedInfo defaultInfo] confUniqueKeyForData:header timestamp:timestamp eventType:kHMDDartEventType];
#if RANGERSAPM
    [header hmd_setObject:record.appVersion forKey:@"app_version"];
    [header hmd_setObject:record.buildVersion forKey:@"update_version_code"];
    [header hmd_setObject:record.osVersion forKey:@"os_version"];
#endif
    [header setValue:record.commitID forKey:@"release_build"];
    [dataValue setValue:[header copy] forKey:@"header"];

    // 注入自定义信息
    [dataValue setValue:[record.injectedInfo copy] forKey:@"custom"];
    
    if ([record.filters count] > 0) {
        [dataValue setValue:[record.filters copy] forKey:@"filters"];
    }
    
    return [dataValue copy];
}

@end
