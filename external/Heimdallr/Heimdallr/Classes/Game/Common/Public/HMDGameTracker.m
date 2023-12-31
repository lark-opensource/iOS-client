//  Heimdallr
//
//  Created by 谢俊逸 on 2019/06/13.
//

#import <stdatomic.h>
#import "HMDGameTracker.h"
#import "HMDGameRecord.h"
#import "HMDSessionTracker.h"
#import "HMDDiskUsage+Private.h"
#import "HMDMemoryUsage.h"
#import "HMDMacro.h"
#import "HMDStoreCondition.h"
#import "Heimdallr.h"
#import "Heimdallr+Private.h"
#import "HMDStoreIMP.h"
#import "HMDUploadHelper.h"
#import "HMDNetworkManager.h"
#import "NSDictionary+HMDHTTPQuery.h"
#import "NSDictionary+HMDSafe.h"
#import "HMDInjectedInfo+UniqueKey.h"
#import "NSDictionary+HMDSafe.h"
#import "HMDNetworkReqModel.h"
#import "HMDGeneralAPISettings.h"
#import "HMDJSON.h"
#if !RANGERSAPM
#import "HMDGameURLProvider.h"
#endif

#import "HMDMacro.h"
CLANG_DIAGNOSTIC_PUSH
CLANG_DIAGNOSTIC_IGNORE_STRICT_PROTOTYPES
#import <Hermas/Hermas.h>
CLANG_DIAGNOSTIC_POP
#import "HMDHermasHelper.h"
// PrivateServices
#import "HMDURLManager.h"

#define DEFAULT_GAME_UPLOAD_LIMIT 5

NSString *const kEnableGameMonitor = @"enable_game_monitor";
static NSString *const kHMDGameEventType = @"game";

@interface HMDGameTracker () {
    dispatch_queue_t _operationQueue;
    _Atomic(unsigned int) _uploadingCount;
    HMInstance *_instance;
}
@end

@implementation HMDGameTracker
SHAREDTRACKER(HMDGameTracker)

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
        [self uploadGameLogIfNeeded];
    }
}

- (void)stop {
    [super stop];
}

-(void)__attribute__((annotate("oclint:suppress[block captured instance self]")))recordGameErrorWithTraceStack:(NSString *)stack name:(NSString *)name reason:(NSString *)reason asyncLogging:(BOOL)asyncLogging filters:(NSDictionary<NSString *,NSString *> *)filters context:(NSDictionary<NSString *,NSString *> *)context{
    if (self.isRunning) {
        HMDGameRecord *record = [HMDGameRecord newRecord];
        record.backTrace = [stack copy];
        record.name = [name copy];
        record.reason = [reason copy];
        record.isBackground = HMDSessionTracker.currentSession.backgroundStatus;
        hmd_MemoryBytes memoryBytes = hmd_getMemoryBytes();
        record.memoryUsage = memoryBytes.appMemory/HMD_MB;
        record.freeMemoryUsage = memoryBytes.availabelMemory/HMD_MB;
        record.freeDiskBlockSize = [HMDDiskUsage getFreeDisk300MBlockSizeWithWaitTime:1.0];
        NSMutableDictionary *custom = [NSMutableDictionary dictionaryWithCapacity:3];
        [custom setValue:[HMDInjectedInfo defaultInfo].userID forKey:@"user_id"];
        if ([HMDInjectedInfo defaultInfo].scopedUserID) {
            [custom setValue:[HMDInjectedInfo defaultInfo].scopedUserID forKey:@"scoped_user_id"];
        }
        [custom setValue:[HMDInjectedInfo defaultInfo].userName forKey:@"user_name"];
        [custom setValue:[HMDInjectedInfo defaultInfo].email forKey:@"email"];
        [custom addEntriesFromDictionary:[HMDInjectedInfo defaultInfo].customContext];
        record.customParams = [custom copy];
        if(context != nil){
            record.customParams = [self combineRecord:record.customParams withOthers:context];
        }
        
        record.filters = [HMDInjectedInfo defaultInfo].filters;
        if(filters != nil ){
            record.filters = [self combineRecord:record.filters withOthers:filters];
        }
        
        if (hermas_enabled()) {
            // update record
            [self updateRecordWithConfig:record];
            
            // write record
            BOOL recordImmediately = [HMDHermasHelper recordImmediately];
            HMRecordPriority priority = recordImmediately ? HMRecordPriorityRealTime : HMRecordPriorityHigh;
            [self.instance recordData:record.reportDictionary priority:priority];
            
        } else {
            [self didCollectOneRecord:record async:asyncLogging trackerBlock:^(BOOL isFlushed) {
                if (isFlushed) {
                    [self uploadGameLogIfNeeded];
                }
            }];
        }
    }
}

-(void)__attribute__((annotate("oclint:suppress[block captured instance self]")))recordGameErrorWithTraceStack:(NSString *)stack name:(NSString *)name reason:(NSString *)reason asyncLogging:(BOOL)asyncLogging filters:(NSDictionary<NSString *,NSString *> *)filters{
    [self recordGameErrorWithTraceStack:stack name:name reason:reason asyncLogging:asyncLogging filters:filters context:nil];
}

- (void)__attribute__((annotate("oclint:suppress[block captured instance self]"))) recordGameErrorWithTraceStack:(NSString *)stack name:(NSString *)name reason:(NSString *)reason asyncLogging:(BOOL)asyncLogging {
    [self recordGameErrorWithTraceStack:stack name:name reason:reason asyncLogging:asyncLogging filters:nil];
}

- (void)recordGameErrorWithTraceStack:(NSString *)stack name:(NSString *)name reason:(NSString *)reason {
    [self recordGameErrorWithTraceStack:stack name:name reason:reason asyncLogging:YES];
}

- (Class<HMDRecordStoreObject>)storeClass {
    return [HMDGameRecord class];
}

- (void)uploadGameLogIfNeeded {
    // 如果有正在上传的就不触发了
    // 如果没有上传的就放置一个设置位 + 1 [ 虽然还不清楚是否有上传的 ]
    unsigned int expected = 0;
    if(!atomic_compare_exchange_strong_explicit(&self->_uploadingCount, &expected, 1, memory_order_acq_rel, memory_order_acquire))
        return;
    
    // Explicit capture [ SELF ] for stand alone object, this is always safe and sound
    dispatch_async(_operationQueue, ^{
        NSArray<HMDGameRecord *> *records = [self fetchUploadRecords];
        if (records.count == 0) {
            atomic_fetch_sub_explicit(&self->_uploadingCount, 1, memory_order_release);
            return;
        } else if(records.count > 1)
            atomic_fetch_add_explicit(&self->_uploadingCount, (unsigned int)(records.count - 1), memory_order_release);
        
        for (HMDGameRecord *record in records) {
            NSDictionary *data = [HMDGameTracker getGameDataWithRecord:record];
            [self uploadGameLogWithData:data recordID:record.localID];
        }
    });
}

- (NSArray<HMDGameRecord *> *)fetchUploadRecords {
    Class<HMDRecordStoreObject> storeClass = self.storeClass;
    NSString *tableName = [storeClass tableName];
    
    HMDStoreCondition *condition1 = [[HMDStoreCondition alloc] init];
    condition1.key = @"enableUpload";
    condition1.threshold = 0;
    condition1.judgeType = HMDConditionJudgeGreater;

    HMDStoreCondition *condition2 = [[HMDStoreCondition alloc] init];
    condition2.key = @"timestamp";
    condition2.threshold = [[NSDate date] timeIntervalSince1970];
    condition2.judgeType = HMDConditionJudgeLess;

    NSArray<HMDStoreCondition *> *andConditions = @[condition1,condition2];

    NSArray<HMDGameRecord *> *records = [[Heimdallr shared].database getObjectsWithTableName:tableName
                                                                                       class:storeClass
                                                                               andConditions:andConditions
                                                                                orConditions:nil
                                                                                       limit:DEFAULT_GAME_UPLOAD_LIMIT];
    return records;
}

- (void) __attribute__((annotate("oclint:suppress[block captured instance self]"))) uploadGameLogWithData:(NSDictionary *)postData recordID:(NSUInteger)recordID {
    NSString *gameReportURL = [HMDURLManager URLWithProvider:self forAppID:[HMDInjectedInfo defaultInfo].appID];
    if (gameReportURL == nil) {
        return;
    }
    
    if (!HMDIsEmptyDictionary([HMDInjectedInfo defaultInfo].commonParams)) {
        NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithDictionary:[HMDUploadHelper sharedInstance].headerInfo];
        [dic addEntriesFromDictionary:[HMDInjectedInfo defaultInfo].commonParams];
        NSString *queryString = [dic hmd_queryString];
        gameReportURL = [NSString stringWithFormat:@"%@?%@", gameReportURL, queryString];
    } else {
        NSString *queryString = [[HMDUploadHelper sharedInstance].headerInfo hmd_queryString];
        
        gameReportURL = [NSString stringWithFormat:@"%@?%@", gameReportURL, queryString];
    }
    
    NSMutableDictionary * headerDict = [NSMutableDictionary dictionaryWithCapacity:2];
    [headerDict setValue:@"application/json; encoding=utf-8" forKey:@"Content-Type"];
    [headerDict setValue:@"application/json" forKey:@"Accept"];
    
    HMDNetworkReqModel *reqModel = [HMDNetworkReqModel new];
    reqModel.requestURL = gameReportURL;
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

+ (NSDictionary *)getGameDataWithRecord:(HMDGameRecord *)record {

    NSMutableDictionary *dataValue = [NSMutableDictionary dictionary];
    
    long long timestamp = MilliSecond(record.timestamp);
    
    [dataValue setValue:@(timestamp) forKey:@"timestamp"];
    [dataValue setValue:kHMDGameEventType forKey:@"event_type"];
    
    [dataValue setValue:record.backTrace forKey:@"data"];
    [dataValue setValue:record.name forKey:@"crash_name"];
    [dataValue setValue:record.reason forKey:@"crash_reason"];
    
    [dataValue setValue:record.sessionID forKey:@"session_id"];
    [dataValue setValue:@(record.memoryUsage) forKey:@"memory_usage"];
    [dataValue setValue:@(record.freeDiskBlockSize) forKey:@"d_zoom_free"];
    [dataValue setValue:@(hmd_calculateMemorySizeLevel(record.freeMemoryUsage*HMD_MB)) forKey:HMD_Free_Memory_Key];
    [dataValue setValue:@(record.isBackground) forKey:@"is_background"];
    
    [dataValue addEntriesFromDictionary:record.environmentInfo];
    
    NSMutableDictionary *header = [NSMutableDictionary dictionaryWithDictionary:[HMDUploadHelper sharedInstance].headerInfo];
    [[HMDInjectedInfo defaultInfo] confUniqueKeyForData:header timestamp:timestamp eventType:kHMDGameEventType];
    [dataValue setValue:[header copy] forKey:@"header"];
    
    if (record.customParams.count > 0) {
        [dataValue setValue:record.customParams forKey:@"custom"];
    }
    
    if (record.filters.count > 0) {
        [dataValue setValue:record.filters forKey:@"filters"];
    }
    
    return [dataValue copy];
}


- (NSDictionary<NSString *,NSString *>*)combineRecord:(NSDictionary<NSString *,NSString *> *)dicOfRecord withOthers:(NSDictionary<NSString *,NSString *> *)others {
    NSMutableDictionary *mergedDic = [NSMutableDictionary dictionary];
    if (dicOfRecord != nil) {
        [mergedDic addEntriesFromDictionary:dicOfRecord];
    }
    
    [others enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull obj, BOOL * _Nonnull stop) {
        if (!HMDIsEmptyString(key) && obj !=nil) {
            NSString *strVal = nil;
            if ([obj isKindOfClass:NSNumber.class]) {
                strVal = [(NSNumber *)obj stringValue];
            } else if ([obj isKindOfClass:NSString.class]) {
                strVal = [obj copy];
            } else {
                if ([obj respondsToSelector:@selector(description)]) {
                    strVal = [obj description];
                }
            }
            [mergedDic hmd_setSafeObject:strVal forKey:key];
        }
    }];
    
    return mergedDic;
}

@end
