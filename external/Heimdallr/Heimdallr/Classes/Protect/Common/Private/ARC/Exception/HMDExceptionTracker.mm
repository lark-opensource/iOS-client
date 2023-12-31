//
//  HMDProtector.m
//  Heimdallr
//
//  Created by fengyadong on 2018/4/9.
//

#define HMD_USE_DEBUG_ONCE

#include <mach/mach.h>
#include <pthread.h>
#import "HMDExceptionTracker.h"
#import "Heimdallr.h"
#import "Heimdallr+Private.h"
#import "HMDRecordStore.h"
#import "HMDExceptionRecord.h"
#import "HMDSessionTracker.h"
#import "HMDExceptionReporter.h"
#import "HeimdallrUtilities.h"
#import "HMDProtector.h"
#import "HMDProtect_Private.h"
#import "HMDStoreIMP.h"
#import "HMDAppleBacktracesLog.h"
#import "HMDDiskUsage.h"
#import "HMDMemoryUsage.h"
#import "HMDMacro.h"
#import "HMDExceptionRecord.h"
#import "HMDDebugRealConfig.h"
#import "HMDExceptionTrackerConfig.h"
#import "NSDictionary+HMDSafe.h"
#import "HMDInjectedInfo+UniqueKey.h"
#import "HMDALogProtocol.h"
#import "HMDDynamicCall.h"
#import "HMDServiceContextMainThreadDispatch.h"
#include "pthread_extended.h"

#import "HMDHermasHelper.h"
#import "HMDMacro.h"
CLANG_DIAGNOSTIC_PUSH
CLANG_DIAGNOSTIC_IGNORE_STRICT_PROTOTYPES
#import <Hermas/Hermas.h>
CLANG_DIAGNOSTIC_POP
// Utility
#import "HMDMacroManager.h"
// PrivateServices
#import "HMDDebugLogger.h"
#import "HMDServerStateService.h"

static NSString *const kEnableExceptionMonitor = @"enable_exception_monitor";

static NSString *const kHMDExceptionTrackerProtectionBlockRegisterKey = @"HMDExceptionTrackerProtectionBlockRegisterKey";
static NSString *const HMDDispatchMainThreadCustomContextAndFilterKey = @"slardar_dispatch_main_thread_protect";

#define DEFAULT_EXCEPTION_UPLOAD_LIMIT 5

@interface HMDExceptionTracker() <HMDExceptionReporterDataProvider> {
    NSArray<HMDStoreCondition *> *_andConditions;
   
    // Pending Records
    NSMutableArray<HMDExceptionRecord *> *_pendingRecords; // should be access within _pendingMutex
    pthread_mutex_t _pendingMutex;
    BOOL _onceStarted;              // require atomic access
}

@property (nonatomic, strong) HMInstance *instance;

@end

@protocol HMDCrashPreventMethod <NSObject>

+ (void)switchNSExceptionOption:(BOOL)shouldOpen;

+ (void)scopePrefix:(NSString * _Nonnull)prefix;

+ (void)scopeWhiteList:(NSArray<NSString *> * _Nonnull)whiteList;

+ (void)scopeBlackList:(NSArray<NSString *> * _Nonnull)blackList;

+ (void)switchMachExceptionOption:(BOOL)shouldOpen;

+ (void)updateMachExceptionCloudControl:(NSArray<NSString *> * _Nonnull)settings;

@end

@implementation HMDExceptionTracker

+ (instancetype)sharedTracker{
    static HMDExceptionTracker *sharedTracker = nullptr;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedTracker = [[HMDExceptionTracker alloc] init];
    });
    return sharedTracker;
}

- (HMInstance *)instance {
    if (_instance == nil) {
        _instance = [[HMEngine sharedEngine] instanceWithModuleId:kModuleExceptionName aid:HMDInjectedInfo.defaultInfo.appID];
    }
    return _instance;
}

- (instancetype)init {
    if(self = [super init]) {
        pthread_mutex_init(&_pendingMutex, NULL);
    }
    return self;
}

- (void)recordCapture:(HMDProtectCapture * _Nonnull)capture {
    BOOL needDrop = hermas_enabled() ? hermas_drop_data(kModuleExceptionName) : hmd_drop_data(HMDReporterException);
    if (needDrop) return;
    
    HMDExceptionRecord *record = [HMDExceptionRecord newRecord];
    @autoreleasepool {
        record.errorType = capture.protectType;
        record.protectTypeString = capture.protectTypeString;
        record.reason = capture.reason;
        record.exceptionLogStr = capture.log;
        
        id crashKey = capture.crashKey;
        if([crashKey isKindOfClass:NSString.class])
            record.crashKey = capture.crashKey;
        
        record.crashKeyList = capture.crashKeyList;
        hmd_MemoryBytes memoryBytes = hmd_getMemoryBytes();
        record.memoryUsage = memoryBytes.appMemory/HMD_MB;
        record.freeMemoryUsage = memoryBytes.availabelMemory/HMD_MB;
        record.freeDiskBlockSize = [HMDDiskUsage getFreeDisk300MBlockSize];
        record.lastScene = [HMDTracker getLastSceneIfAvailable];
        record.operationTrace = [HMDTracker getOperationTraceIfAvailable];
        record.inAppTime = [HMDSessionTracker currentSession].timeInSession;
        NSMutableDictionary *custom = [NSMutableDictionary dictionaryWithCapacity:3];
        [custom setValue:[HMDInjectedInfo defaultInfo].userID forKey:@"user_id"];
        if ([HMDInjectedInfo defaultInfo].scopedUserID) {
            [custom setValue:[HMDInjectedInfo defaultInfo].scopedUserID forKey:@"scoped_user_id"];
        }
        [custom setValue:[HMDInjectedInfo defaultInfo].userName forKey:@"user_name"];
        [custom setValue:[HMDInjectedInfo defaultInfo].email forKey:@"email"];
        [custom addEntriesFromDictionary:[HMDInjectedInfo defaultInfo].customContext];
        if(capture.customDictionary != nil) [custom addEntriesFromDictionary:capture.customDictionary];
        record.customParams = [custom copy];
        
        NSMutableDictionary *filterDict = [NSMutableDictionary dictionary];
        NSDictionary *filterInfo = [HMDInjectedInfo defaultInfo].filters;
        if (filterInfo.count) {
            [filterDict addEntriesFromDictionary:filterInfo];
        }
        if(capture.customFilter != nil) [filterDict addEntriesFromDictionary:capture.customFilter];
        
        if (capture.protectTypeString && capture.protectTypeString.length > 0) {
            [filterDict hmd_setObject:capture.protectTypeString forKey:@"type"];
        }
        record.filterParams = filterDict;
        
        NSMutableDictionary *settings = [NSMutableDictionary new];
        HMDExceptionTrackerConfig *config = (HMDExceptionTrackerConfig *)self.config;
        HMDProtector *shared = [HMDProtector sharedProtector];
        [settings setValue:@(shared.currentProtectionCollection) forKey:@"options"];
        [settings setValue:shared.ignoreDuplicate ? @"1" : @"0" forKey:@"ignore_duplicate"];
        [settings setValue:shared.ignoreTryCatch ? @"1" : @"0" forKey:@"ignore_try_catch"];
        [settings setValue:config.catchMethodList forKey:@"custom_catch"];
        [settings setValue:config.systemProtectList forKey:@"system_protect"];
        record.settings = [settings copy];
    }
    
    // 安全气垫为了支持某些防护发生的时刻
    // 其模块并未启动 (数据库无法访问)
    BOOL onceStarted = __atomic_load_n(&_onceStarted, __ATOMIC_ACQUIRE);

    if(onceStarted) [self collectRecordToHermasOrDB:record];
    else [self pendingRecord:record];
    
}
    
- (void)collectRecordToHermasOrDB:(HMDExceptionRecord *)record {
    if (hermas_enabled()) {
        // update record
        [self updateRecordWithConfig:record];
        
        // write record
        [self.instance recordData:record.reportDictionary];
        
        // upload alog
        HMDExceptionTrackerConfig *config = (HMDExceptionTrackerConfig *)self.config;
        if (config.uploadAlog) {
            DC_OB(DC_CL(HMDLogUploader, sharedInstance), exceptionALogUploadWithEndTime:, record.timestamp);
        }
        
        return;
    }
#if RANGERSAPM
    [self didCollectOneRecord:record trackerBlock:^(BOOL isFlushed) {
        if (isFlushed) {
            [self uploadProtectLogIfNeeded];
        }
    }];
#else
    [self didCollectOneRecord:record];
#endif
}

- (void)updateConfig:(HMDExceptionTrackerConfig *)config
{
    [super updateConfig:config];
    
    if (HMDProtectIgnoreCloudSettings) {
        HMDALOG_PROTOCOL_INFO_TAG(@"Heimdallr", @"%@ module ignore update config", [self moduleName]);
        return;
    }
    
    HMDProtector *sharedInstance = [HMDProtector sharedProtector];
    sharedInstance.ignoreDuplicate = config.ignoreDuplicate;
    sharedInstance.ignoreTryCatch = config.ignoreTryCatch;
#if RANGERSAPM
    sharedInstance.protectorUpload = config.protectorUpload;
    sharedInstance.arrayCreateMode = config.arrayCreateMode;
#endif
    
    if(!self.isRunning) return;
    
    [sharedInstance switchProtection:config.openOptions];
    
    // custom catch受总开关控制
    [self enableCustomCatchWithMethodDict:config.catchMethodList];
    
    // system protect受总开关控制
    [self enableSystemProtectWithKeyList:config.systemProtectList];
    
    Class<HMDCrashPreventMethod> _Nullable crashPreventClass = objc_getClass("HMDCrashPrevent");
    if(crashPreventClass != nil) {
        [crashPreventClass switchNSExceptionOption:config.enableNSException];
        
        NSString * _Nullable prefix = config.machExceptionPrefix;
        if(prefix != nil && prefix.length > 0) [crashPreventClass scopePrefix:config.machExceptionPrefix];
        
        NSMutableArray<NSString *> *whileListArray = NSMutableArray.array;
        NSMutableArray<NSString *> *blackListArray = NSMutableArray.array;
        
        NSDictionary<NSString *, NSNumber *> *machExceptionList = config.machExceptionList;
        if(machExceptionList != nil) {
            [machExceptionList enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull maybeStringKey,
                                                                   NSNumber * _Nonnull maybeNumberValue,
                                                                   BOOL * _Nonnull stop) {
                if(![maybeStringKey   isKindOfClass:NSString.class] ||
                   ![maybeNumberValue isKindOfClass:NSNumber.class]) {
                    stop[0] = YES;
                    DEBUG_RETURN_NONE;
                }
                BOOL value = maybeNumberValue.boolValue;
                if(value) [whileListArray addObject:maybeStringKey];
                else      [blackListArray addObject:maybeStringKey];
            }];
        }
        
        [crashPreventClass scopeWhiteList:whileListArray];
        [crashPreventClass scopeBlackList:blackListArray];
        
        NSDictionary<NSString *, NSString *> *machExceptionCloud = config.machExceptionCloud;
        
        NSMutableArray<NSString *> *cloudControl = NSMutableArray.array;
        
        if(machExceptionCloud != nil) {
            [machExceptionCloud enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull maybeStringKey,
                                                                    NSString * _Nonnull maybeStringValue,
                                                                   BOOL * _Nonnull stop) {
                if(![maybeStringKey   isKindOfClass:NSString.class] ||
                   ![maybeStringValue isKindOfClass:NSString.class]) {
                    stop[0] = YES;
                    DEBUG_RETURN_NONE;
                }
                [cloudControl addObject:maybeStringValue];
            }];
        }
        
        [crashPreventClass updateMachExceptionCloudControl:cloudControl];
        
        [crashPreventClass switchMachExceptionOption:config.enableMachException];
    }
    
    id<HMDMainThreadDispatchProtocol> _Nullable mainThreadDispatch =
        HMDServiceContext_getMainThreadDispatch();
    
    if(mainThreadDispatch != nil) {
        NSDictionary<NSString *, NSNumber *> *methodsCollection = config.dispatchMainThread;
        NSMutableArray<NSString *> *methods = [NSMutableArray arrayWithCapacity:methodsCollection.count];
        
        if(methodsCollection.count > 0) {
            [methodsCollection enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull maybeStringKey,
                                                                   NSNumber * _Nonnull maybeNumberValue,
                                                                   BOOL * _Nonnull stop) {
                if(![maybeStringKey   isKindOfClass:NSString.class] ||
                   ![maybeNumberValue isKindOfClass:NSNumber.class]) {
                    stop[0] = YES;
                    DEBUG_RETURN_NONE;
                }
                BOOL value = maybeNumberValue.boolValue;
                if(value) [methods addObject:maybeStringKey];
            }];
        }
        
        if(methods.count > 0) {
            [mainThreadDispatch dispatchMainThreadMethods:methods];
            mainThreadDispatch.enable = YES;
            
            NSString *contextString = [methods componentsJoinedByString:@","];
            [[HMDInjectedInfo defaultInfo] setCustomContextValue:contextString forKey:HMDDispatchMainThreadCustomContextAndFilterKey];
            [[HMDInjectedInfo defaultInfo] setCustomFilterValue:contextString forKey:HMDDispatchMainThreadCustomContextAndFilterKey];
            
        } else {
            [[HMDInjectedInfo defaultInfo] removeCustomContextKey:HMDDispatchMainThreadCustomContextAndFilterKey];
            [[HMDInjectedInfo defaultInfo] removeCustomFilterKey:HMDDispatchMainThreadCustomContextAndFilterKey];
            
            mainThreadDispatch.enable = NO;
        }
    }
}

- (void)start {
#if !RANGERSAPM
    if (HMD_IS_DEBUG) return;
#endif
    
    [super start];
    
    if (HMDProtectIgnoreCloudSettings) {
        HMDALOG_PROTOCOL_INFO_TAG(@"Heimdallr", @"%@ module ignore start", [self moduleName]);
        return;
    }
    
    HMDExceptionTrackerConfig *config = (__kindof HMDExceptionTrackerConfig *)self.config;
    HMDProtector *sharedInstance = [HMDProtector sharedProtector];
    sharedInstance.ignoreDuplicate = config.ignoreDuplicate;
    sharedInstance.ignoreTryCatch = config.ignoreTryCatch;
#if RANGERSAPM
    sharedInstance.protectorUpload = config.protectorUpload;
    sharedInstance.arrayCreateMode = config.arrayCreateMode;
#endif
    HMDExceptionTracker_connectWithProtector_if_need();
    
    [sharedInstance switchProtection:config.openOptions];
    [self enableCustomCatchWithMethodDict:config.catchMethodList];
    [self enableSystemProtectWithKeyList:config.systemProtectList];
    
    [self savePendingRecordToDatabase];
    
    Class<HMDCrashPreventMethod> _Nullable crashPreventClass = objc_getClass("HMDCrashPrevent");
    if(crashPreventClass != nil) {
        [crashPreventClass switchNSExceptionOption:config.enableNSException];
        [crashPreventClass switchMachExceptionOption:config.enableMachException];
        
        NSString * _Nullable prefix = config.machExceptionPrefix;
        if(prefix != nil && prefix.length > 0) [crashPreventClass scopePrefix:config.machExceptionPrefix];
        
        NSMutableArray<NSString *> *whileListArray = NSMutableArray.array;
        NSMutableArray<NSString *> *blackListArray = NSMutableArray.array;
        
        NSDictionary<NSString *, NSNumber *> *machExceptionList = config.machExceptionList;
        if(machExceptionList != nil) {
            [machExceptionList enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull maybeStringKey,
                                                                   NSNumber * _Nonnull maybeNumberValue,
                                                                   BOOL * _Nonnull stop) {
                if(![maybeStringKey   isKindOfClass:NSString.class] ||
                   ![maybeNumberValue isKindOfClass:NSNumber.class]) {
                    stop[0] = YES;
                    DEBUG_RETURN_NONE;
                }
                BOOL value = maybeNumberValue.boolValue;
                if(value) [whileListArray addObject:maybeStringKey];
                else      [blackListArray addObject:maybeStringKey];
            }];
        }
        
        [crashPreventClass scopeWhiteList:whileListArray];
        [crashPreventClass scopeBlackList:blackListArray];
        
        NSDictionary<NSString *, NSString *> *machExceptionCloud = config.machExceptionCloud;
        
        NSMutableArray<NSString *> *cloudControl = NSMutableArray.array;
        
        if(machExceptionCloud != nil) {
            [machExceptionCloud enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull maybeStringKey,
                                                                    NSString * _Nonnull maybeStringValue,
                                                                   BOOL * _Nonnull stop) {
                if(![maybeStringKey   isKindOfClass:NSString.class] ||
                   ![maybeStringValue isKindOfClass:NSString.class]) {
                    stop[0] = YES;
                    DEBUG_RETURN_NONE;
                }
                [cloudControl addObject:maybeStringValue];
            }];
        }
        
        [crashPreventClass updateMachExceptionCloudControl:cloudControl];
    }
    
    id<HMDMainThreadDispatchProtocol> _Nullable mainThreadDispatch =
        HMDServiceContext_getMainThreadDispatch();
    
    if(mainThreadDispatch != nil) {
        NSDictionary<NSString *, NSNumber *> *methodsCollection = config.dispatchMainThread;
        NSMutableArray<NSString *> *methods = [NSMutableArray arrayWithCapacity:methodsCollection.count];
        
        if(methodsCollection.count > 0) {
            [methodsCollection enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull maybeStringKey,
                                                                   NSNumber * _Nonnull maybeNumberValue,
                                                                   BOOL * _Nonnull stop) {
                if(![maybeStringKey   isKindOfClass:NSString.class] ||
                   ![maybeNumberValue isKindOfClass:NSNumber.class]) {
                    stop[0] = YES;
                    DEBUG_RETURN_NONE;
                }
                BOOL value = maybeNumberValue.boolValue;
                if(value) [methods addObject:maybeStringKey];
            }];
        }
        
        if(methods.count > 0) {
            [mainThreadDispatch dispatchMainThreadMethods:methods];
            mainThreadDispatch.enable = YES;
            
            NSString *contextString = [methods componentsJoinedByString:@","];
            [[HMDInjectedInfo defaultInfo] setCustomContextValue:contextString forKey:HMDDispatchMainThreadCustomContextAndFilterKey];
            [[HMDInjectedInfo defaultInfo] setCustomFilterValue:contextString forKey:HMDDispatchMainThreadCustomContextAndFilterKey];
            
        } else {
            [[HMDInjectedInfo defaultInfo] removeCustomContextKey:HMDDispatchMainThreadCustomContextAndFilterKey];
            [[HMDInjectedInfo defaultInfo] removeCustomFilterKey:HMDDispatchMainThreadCustomContextAndFilterKey];
            
            mainThreadDispatch.enable = NO;
        }
    }
}

- (void)stop {
    [super stop];
    [[HMDProtector sharedProtector] turnProtectionOff:HMDProtectionTypeAll];
    [self enableCustomCatchWithMethodDict:@{}];
    
    Class<HMDCrashPreventMethod> _Nullable crashPreventClass = objc_getClass("HMDCrashPrevent");
    if(crashPreventClass != nil) {
        [crashPreventClass switchNSExceptionOption:NO];
        [crashPreventClass switchMachExceptionOption:NO];
    }
}

- (Class<HMDRecordStoreObject>)storeClass {
    return [HMDExceptionRecord class];
}

- (BOOL)exceptionDataSource {
    return YES;
}

- (NSArray *)getExceptionDataWithRecords:(NSArray<HMDExceptionRecord *> *)records {
    NSMutableArray *dataArray = [NSMutableArray array];
    
    for (HMDExceptionRecord *record in records) {
        NSMutableDictionary *dataValue = [NSMutableDictionary dictionary];
        
        long long timestamp = MilliSecond(record.timestamp);
        
        [dataValue setValue:@(timestamp) forKey:@"timestamp"];
        [dataValue setValue:kHMDExceptionEventType forKey:@"event_type"];
        [dataValue setValue:record.sessionID forKey:@"session_id"];
        [dataValue setValue:@(record.errorType) forKey:@"error_type"];
        [dataValue setValue:record.protectTypeString forKey:@"protect_type_string"];
        [dataValue setValue:record.reason forKey:@"reason"];
        [dataValue setValue:record.crashKey forKey:@"crashKey"];
        [dataValue setValue:record.crashKeyList forKey:@"crashKeyList"];
        [dataValue setValue:record.exceptionLogStr forKey:@"stack"];
        [dataValue setValue:@(record.memoryUsage) forKey:@"memory_usage"];
        [dataValue setValue:@(record.freeDiskBlockSize) forKey:@"d_zoom_free"];
        [dataValue setValue:@(hmd_calculateMemorySizeLevel(((uint64_t)record.freeMemoryUsage)*HMD_MEMORY_MB)) forKey:HMD_Free_Memory_Key];
        [dataValue setValue:record.lastScene forKey:@"last_scene"];
        [dataValue setValue:record.operationTrace forKey:@"operation_trace"];
        [dataValue setValue:@(record.inAppTime) forKey:@"inapp_time"];
        if (record.customParams.count > 0) {
            [dataValue setValue:record.customParams forKey:@"custom"];
        }
        
        if (record.filterParams.count > 0) {
            [dataValue setValue:record.filterParams forKey:@"filters"];
        }
        if (record.settings.count > 0) {
            [dataValue setValue:record.settings forKey:@"settings"];
        }
        
        [dataValue addEntriesFromDictionary:record.environmentInfo];
        
        [[HMDInjectedInfo defaultInfo] confUniqueKeyForData:dataValue timestamp:timestamp eventType:kHMDExceptionEventType];
        
        [dataArray addObject:dataValue];
        
        HMDExceptionTrackerConfig *config = (HMDExceptionTrackerConfig *)self.config;
        if (config.uploadAlog) {
            DC_OB(DC_CL(HMDLogUploader, sharedInstance), exceptionALogUploadWithEndTime:, record.timestamp);
        }
    }
    
    return [dataArray copy];
}

- (NSArray *)dealNotDebugRealPerformanceData {
    NSArray<HMDExceptionRecord *> *records = [self fetchUploadRecordsWithLimitCount:DEFAULT_EXCEPTION_UPLOAD_LIMIT];
    if (records.count == 0) return nil;
    
    NSArray *result = [self getExceptionDataWithRecords:records];
    return [result copy];
}

- (NSArray *)fetchUploadRecordsWithLimitCount:(NSInteger)limitCount {
    if (!self.config.enableUpload) {
        return nil;
    }
    
    HMDStoreCondition *condition1 = [[HMDStoreCondition alloc] init];
    condition1.key = @"enableUpload";
    condition1.threshold = 0;
    condition1.judgeType = HMDConditionJudgeGreater;

    HMDStoreCondition *condition2 = [[HMDStoreCondition alloc] init];
    condition2.key = @"timestamp";
    condition2.threshold = [[NSDate date] timeIntervalSince1970];
    condition2.judgeType = HMDConditionJudgeLess;
    
    _andConditions = @[condition1,condition2];
    
    NSArray<HMDExceptionRecord *> *records = [[Heimdallr shared].store.database getObjectsWithTableName:[[self storeClass] tableName] class:[self storeClass] andConditions:_andConditions orConditions:nil limit:limitCount];
    return records;
}

#pragma mark - DataReporterDelegate
- (NSArray *)pendingExceptionData {
    if (hermas_enabled()) {
        return nil;
    }
    
    return [self dealNotDebugRealPerformanceData];
}

- (void) dropExceptionData {
    if (hermas_enabled()) {
        return;
    }
    
    [[Heimdallr shared].store.database deleteAllObjectsFromTable:[[self storeClass] tableName]];
}

- (NSArray *)pendingDebugRealExceptionDataWithConfig:(HMDDebugRealConfig *)config {
    if (![config checkIfAllowedDebugRealUploadWithType:kEnableExceptionMonitor]) {
        return nil;
    }
    
    NSArray<HMDExceptionRecord *> *records = [self fetchUploadRecordsWithLimitCount:config.limitCnt];
    NSArray *result = [self getExceptionDataWithRecords:records];
    return [result copy];
}

- (void)cleanupExceptionDataWithConfig:(HMDDebugRealConfig *)config {
    HMDStoreCondition *condition1 = [[HMDStoreCondition alloc] init];
    condition1.key = @"enableUpload";
    condition1.threshold = 0;
    condition1.judgeType = HMDConditionJudgeGreater;
    
    HMDStoreCondition *condition2 = [[HMDStoreCondition alloc] init];
    condition2.key = @"timestamp";
    condition2.threshold = [[NSDate date] timeIntervalSince1970];
    condition2.judgeType = HMDConditionJudgeLess;
    
    NSArray<HMDStoreCondition *> *debugRealConditions = @[condition1,condition2];
    // 清空数据库
    [[Heimdallr shared].store.database deleteObjectsFromTable:[[self storeClass] tableName] andConditions:debugRealConditions orConditions:nil limit:config.limitCnt];
}

- (void)exceptionReporterDidReceiveResponse:(BOOL)isSuccess {
    if (hermas_enabled()) {
        return;
    }
    
    if(isSuccess)
        [[Heimdallr shared].store.database  deleteObjectsFromTable:[[self storeClass] tableName] andConditions:_andConditions orConditions:nil limit:DEFAULT_EXCEPTION_UPLOAD_LIMIT];
}

#if RANGERSAPM

#pragma mark - Upload
- (void)uploadProtectLogIfNeeded {
    [[HMDExceptionReporter sharedInstance] reportAllExceptionData];
    [HMDDebugLogger printLog:@"Protect log is uploading..."];
}
#endif

#pragma - Private

- (void)enableCustomCatchWithMethodDict:(NSDictionary *)methodDict {
    NSMutableArray *catchMethods = [[NSMutableArray alloc] init];
    [methodDict enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull methodName, NSNumber * _Nonnull obj, BOOL * _Nonnull stop) {
        if ([obj isKindOfClass:[NSNumber class]] && [obj boolValue]) {
            [catchMethods addObject:methodName];
        }
    }];
    [[HMDProtector sharedProtector] catchMethodsWithNames:catchMethods];
}

- (void)enableSystemProtectWithKeyList:(NSArray <NSString *>*)keyList {
    if (keyList && [keyList isKindOfClass:[NSArray class]] && keyList.count > 0) {
        BOOL isThereNSAssert = NO;
        BOOL isThereWeakRetainDeallocating = NO;
        
        for (NSString *protect_type in keyList) {
            if ([protect_type isKindOfClass:[NSString class]] && protect_type.length > 0) {
                if ([protect_type isEqualToString:@"nano"]) {
                    [[HMDProtector sharedProtector] enableNanoCrashProtect];
                }
                else if ([protect_type isEqualToString:@"NSAssert"]) {
                    isThereNSAssert = YES;
                } else if ([protect_type isEqualToString:@"weakRetainDeallocating"]) {
                    isThereWeakRetainDeallocating = YES;
                }
            }
        }
        
        if(isThereNSAssert)
             [[HMDProtector sharedProtector] enableAssertProtect];
        else [[HMDProtector sharedProtector] disableAssertProtect];
        
        if(isThereWeakRetainDeallocating)
             [[HMDProtector sharedProtector] enableWeakRetainDeallocating];
        else [[HMDProtector sharedProtector] disableWeakRetainDeallocating];
    }
}

#pragma mark - Pending Record

- (void)pendingRecord:(HMDExceptionRecord *)record {
    pthread_mutex_lock(&_pendingMutex);
    BOOL onceStarted = __atomic_load_n(&_onceStarted, __ATOMIC_ACQUIRE);
    
    if(onceStarted) {
        pthread_mutex_unlock(&_pendingMutex);
        [self collectRecordToHermasOrDB:record];
        return;
    }
    
    if(_pendingRecords == nil)
       _pendingRecords = [NSMutableArray arrayWithCapacity:4];
    
    [_pendingRecords addObject:record];
    
    pthread_mutex_unlock(&_pendingMutex);
}

- (void)savePendingRecordToDatabase {
    // 是否曾经启动过
    BOOL onceStarted = __atomic_load_n(&_onceStarted, __ATOMIC_ACQUIRE);
    
    // 如果曾经启动过，那么无需将 pending records 再存回数据库 (因为之前搞过咯)
    if(onceStarted) return;
    
    // 标记曾经启动过 (意味着数据库连接; 与 Heimdallr 通信可行)
    __atomic_store_n(&_onceStarted, YES, __ATOMIC_RELEASE);
    
    // 从 mutex 保护区域读取数据
    NSArray<HMDExceptionRecord *> * _Nullable pendingRecordsArray = nil;
    
    // 读取保护区域数据 (without actually Locked this is really fast)
    pthread_mutex_lock(&_pendingMutex);
    pendingRecordsArray = _pendingRecords;
    _pendingRecords = nil;
    pthread_mutex_unlock(&_pendingMutex);
    
    // 如果没有数据的话
    if(pendingRecordsArray == nil) return;
    
    // 载入 pending 数据
    for(HMDExceptionRecord *eachRecord in pendingRecordsArray) {
        [self collectRecordToHermasOrDB:eachRecord];
    }
}

@end

#pragma mark - Connect With Protector
// 代码是为了链接 HMDException Tracker 和 Protector
// 注意链接过后 HMDExceptionTracker 并没有启动
// 它与 Heimdallr 主模块的数据库连接也没有完成

static void HMDExceptionTracker_connectWithProtector_once(void);

void HMDExceptionTracker_connectWithProtector_if_need(void) {
    static pthread_once_t onceToken = PTHREAD_ONCE_INIT;
    pthread_once(&onceToken, HMDExceptionTracker_connectWithProtector_once);
}

static void HMDExceptionTracker_connectWithProtector_once(void) {
    DEBUG_ONCE
    
    HMDExceptionTracker *exceptionTracker = HMDExceptionTracker.sharedTracker;
    HMDProtector *protector = HMDProtector.sharedProtector;
    
    [protector registerIdentifier:kHMDExceptionTrackerProtectionBlockRegisterKey withBlock:^(HMDProtectCapture * _Nonnull capture) {
        [exceptionTracker recordCapture:capture];
    }];
}
