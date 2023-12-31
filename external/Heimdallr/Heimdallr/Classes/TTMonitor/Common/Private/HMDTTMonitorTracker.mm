//
//  HMDTTMonitorTracker.m
//  Heimdallr
//
//  Created by joy on 2018/3/26.
//

#import "HMDTTMonitorTracker.h"
#import "HMDRecordStore.h"
#import "HMDDebugRealConfig.h"
#import "HMDMacro.h"
#import "HMDStoreIMP.h"
#import "HMDHeimdallrConfig.h"
#import "HMDALogProtocol.h"
#import "HMDNetworkHelper.h"
#import "HMDSimpleBackgroundTask.h"
#import "NSObject+HMDValidate.h"
#include <stdatomic.h>
#import "HMDRecordStore+DeleteRecord.h"
#import "HMDReportLimitSizeTool.h"
#import "HMDMonitorDataManager.h"
#import "NSDictionary+HMDJSON.h"
#import "NSData+HMDJSON.h"
#import "Heimdallr+Private.h"
#import "NSArray+HMDJSON.h"
#import "HMDGCD.h"
#import "HMDTTMonitorCounter.h"
#import "HMDGCDTimer.h"
#import "HMDWeakProxy.h"
#import "HMDPerformanceReporterManager.h"
#import "HMDStoreMemoryDB.h"
#import "NSArray+HMDSafe.h"
#import "HMDDynamicCall.h"
#import "HMDTTMonitorHelper.h"
#import "HMDTTMonitorRecord.h"
#import "HMDTTMonitorMetricRecord.h"
#import "HMDTTMonitor.h"
#import "HMDMonitorDataManager.h"
#import "HMDPerformanceReporter.h"
#import "NSDictionary+HMDSafe.h"
#import "NSArray+HMDSafe.h"
#import "HMDReportDowngrador.h"
#import "HMDTTMonitorTagHelper.h"
#import "HMDInjectedInfo+LegacyDBOptimize.h"
#import "HMDInjectedInfo+PerfOptSwitch.h"
#import "HMDTTMonitorInterceptorParam.h"
#import "HMDHeimdallrConfig+Private.h"

// PrivateServices
#import "HMDDebugLogger.h"
#import "HMDServerStateService.h"

#define kMaxMetricsRecordCount 5000
#define kMaxServiceRecordCount 30000
#define kTrackFlushCount 10
#define kHMDTTMonitorMetricLimit 50
#define kMaxRecordCacheCount 1000 //1000条打点日志大约占内存1Mb
#define kEventBackupToDiskInterval 30.f
#define kTrackMinCacheCount 100
#define kTrackMaxCacheCount 10000


using namespace std;
static NSString *const kHMDTTMonitorBackgroundTask = @"com.heimdallr.backgroundTask.hmdttmonitor.saveTrackerData";
static BOOL globalUseQueueShareStrategy = NO;

@interface HMDTTMonitorTracker()<HMDPerformanceReporterDataSource, HMDTTMonitorOfflineCheckPointProtocol, HMDTTMonitorTraceProtocol> {
    CFTimeInterval _startTimestamp;
}
@property (nonatomic, strong) NSMutableArray<HMDTTMonitorRecord *> *trackersArray;
@property (nonatomic, strong) NSMutableArray<HMDTTMonitorMetricRecord *> *metricsArray;
@property (nonatomic, strong) NSMutableArray<HMDTTMonitorRecord *> *trackersCacheArray;
@property (nonatomic, strong) dispatch_queue_t syncQueue;

@property (nonatomic, assign) HMDRecordLocalIDRange uploadingRange;
@property (nonatomic, assign) HMDRecordLocalIDRange metricCountRange;
@property (nonatomic, assign) HMDRecordLocalIDRange metricTimerRange;
@property (nonatomic, assign) NSInteger hmdCountLimit;
@property (atomic, strong) NSArray<HMDStoreCondition *> *normalCondition;
@property (atomic, strong) NSArray<HMDStoreCondition *> *metricCountCondition;
@property (atomic, strong) NSArray<HMDStoreCondition *> *metricTimerCondition;
@property (nonatomic, strong) HMDReportLimitSizeTool *sizeLimitTool;
@property (nonatomic, strong) NSMutableArray<HMDTTMonitorRecord *> *recordCache; // 未获取到采样率时，埋点数据的缓存
@property (nonatomic, strong) HMDTTMonitorCounter *counter;
@property (nonatomic, strong) HMDGCDTimer *GCDTimer;
@property (nonatomic, assign) BOOL needStopRepeating;

@property (nonatomic, assign) BOOL needDeleteRecordsFromDB;
@property (nonatomic, assign) NSUInteger uploadingCountFromMemory;

@property (nonatomic, assign) NSUInteger insertIndex;
@property (nonatomic, assign) BOOL hasNewData;
@property (nonatomic, strong) NSLock *lock;

@end

@implementation HMDTTMonitorTracker
#if RANGERSAPM
@synthesize dropData;
#endif

@synthesize ignoreLogType;

+ (void)setUseShareQueueStrategy:(BOOL)on {
    globalUseQueueShareStrategy = on;
}

+ (dispatch_queue_t)globalSyncQueue {
    static dispatch_queue_t queue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        queue = dispatch_queue_create("com.heimdallr.hmdttmonitor.syncQueue", DISPATCH_QUEUE_SERIAL);
    });
    return queue;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    if (self.GCDTimer && [self.GCDTimer existTimer]) {
        [self.GCDTimer cancelTimer];
    }
    HMDALOG_PROTOCOL_INFO_TAG(@"HMDEventTrace", @"HMDTTMonitorTracker dealloc");
}

- (instancetype)initMonitorWithAppID:(NSString *)appID injectedInfo:(HMDTTMonitorUserInfo *)info {
    self = [super init];
    if (self) {
        
        self.lock = [[NSLock alloc] init];
        self.insertIndex = 0;
        self.hasNewData = YES;
        
        self.dataManager = [[HMDMonitorDataManager alloc] initMonitorWithAppID:appID injectedInfo:info];
        
        // 固化队列共享逻辑
        self.syncQueue = [self.class globalSyncQueue];
        
        self.trackersArray = [NSMutableArray new];
        self.metricsArray = [NSMutableArray new];
        self.trackersCacheArray = [NSMutableArray new];
        self.recordCache = [NSMutableArray new];
        if (!_startTimestamp) {
            _startTimestamp = [[NSDate date] timeIntervalSince1970];
        }
        self.counter = [[HMDTTMonitorCounter alloc] initCounterWithAppID:self.dataManager.appID];
        
        if ([HMDInjectedInfo defaultInfo].ttMonitorSampleOptEnable) {
            [HMDTTMonitorHelper registerCrashCallbackToLog];
        }
        
        __weak typeof(self) weakSelf = self;
        self.dataManager.stopCacheBlock = ^() {
            // 将缓存数据存入数据库
            hmd_safe_dispatch_async(weakSelf.syncQueue, ^{
                [weakSelf insertRecordCacheIntoTrackersArrayIfNeeded];
                [weakSelf tracksCountChangedWithSyncWrite:YES];
            });
        };
        [[HMDPerformanceReporterManager sharedInstance] addReportModule:(id<HMDPerformanceReporterDataSource>)[HMDWeakProxy proxyWithTarget:self] withAppID:self.dataManager.appID];
        
        // 添加定时器，30s一次，尝试将内存中的缓存落盘
        self.GCDTimer = [HMDGCDTimer new];
        [self.GCDTimer scheduledDispatchTimerWithInterval:kEventBackupToDiskInterval queue:self.syncQueue repeats:YES action:^{
            if (weakSelf.trackersArray.count) {
                [weakSelf tracksCountChangedWithSyncWrite:YES];
            }
        }];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(willResignActive:)
                                                     name:UIApplicationWillResignActiveNotification
                                                   object:nil];
        
        HMDALOG_PROTOCOL_INFO_TAG(@"HMDEventTrace", @"HMDTTMonitorTracker initialize with manager : %@", self.dataManager ? self.dataManager.appID : @"nil");
    }
    return self;
}

- (Class<HMDRecordStoreObject>)metricStoreClass {
    return [HMDTTMonitorMetricRecord class];
}

- (Class<HMDRecordStoreObject>)trackerStoreClass {
    return [HMDTTMonitorRecord class];
}

- (void)setupWithHeimdallrReportSizeLimit:(HMDReportLimitSizeTool *)sizeLimitTool {
    self.sizeLimitTool = sizeLimitTool;
}

- (BOOL)performanceDataSource {
    return YES;
}

- (HMDHeimdallrConfig *)customConfig {
    return self.dataManager.config;
}

- (void)trackDataWithParam:(HMDTTMonitorInterceptorParam *)params {
    // 排查问题临时将事件的 serviceName、logType、appId 写入Alog或者Crash追踪数据
    if ([HMDInjectedInfo defaultInfo].ttMonitorSampleOptEnable) {
        [HMDTTMonitorHelper saveLatestLogWithServiceName:params.serviceName logType:params.logType appID:params.appID];
    } else {
        HMDALOG_PROTOCOL_INFO_TAG(@"HMDEventTrace_ServiceName", @"HMDTTMonitorTracker（serviceName、logType、appID) write to alog : serviceName = %@, logType = %@, appID = %@", params.serviceName, params.logType, params.appID);
    }
    
#if RANGERSAPM
    BOOL rangersAPMNeedUpload = [self needUploadWithlogTypeStr:params.logType serviceType:params.serviceName];
    if (!rangersAPMNeedUpload && !self.dataManager.needCache) {
        return;
    }
#endif
    
    if ([self respondsToSelector:@selector(recordDataGeneratedCheckPointWithServiceName:logType:data:)]) {
        [self recordDataGeneratedCheckPointWithServiceName:params.serviceName logType:params.logType data:params.wrapData];
    }
    
    NSInteger uniqueCode = [self.counter generateUniqueCode];
    if ([self respondsToSelector:@selector(recordGeneratedCheckPointWithlogType:serviceType:appID:actionType:uniqueCode:)]) {
        [self recordGeneratedCheckPointWithlogType:params.logType serviceType:params.serviceName appID:params.appID actionType:params.storeType uniqueCode:uniqueCode];
    }
    
    NSAssert(params.appID != nil,@"The appID cannot be nil! logType = %@, serviceType = %@", params.logType ?: @"", params.serviceName ?: @"");
    // 当 service 有值的时候, 才去判断是否覆盖了
    if (params.serviceName && params.serviceName.length > 0) {
        params.wrapData = [HMDTTMonitorHelper filterTrackerReservedKeysWithDataDict:params.wrapData];
    }
    
#ifdef DEBUG
    NSMutableString *str = [NSMutableString string];
    if(![params.wrapData hmd_performValidate:(CAValidateType)(CAValidateTypeJSON | CAValidateTypeImmutable) saveResult:str prefixBlank:0 increaseblank:4]) {
        const char *warningStringBegin =
        " -------------------------------------------------------------------------------------- \n"
        "          HMDTTMonitor customizes types of incoming records   Check report\n"
        " -------------------------------------------------------------------------------------- \n";
        const char *warningStringEnd =
        " -------------------------------------------------------------------------------------- \n"
        "     Immutable incoming type - JSON detection failed, which may result in online CRASH  \n"
        " -------------------------------------------------------------------------------------- \n";
        NSString *serviceInfo =
        [NSString stringWithFormat:@"logType: %@; serviceName: %@;\n",params.logType, params.serviceName];
        HMDPrint("%s%s%s%s", warningStringBegin, serviceInfo.UTF8String, str.UTF8String, warningStringEnd);
    }
#endif

    BOOL isConfirmCoding = NO;
    if ([HMDInjectedInfo defaultInfo].ttmonitorCodingProtocolOptEnabled) {
        isConfirmCoding = [HMDTTMonitorHelper fastCheckDictionaryDataFormat:params.wrapData];
    } else {
        isConfirmCoding = [HMDTTMonitorHelper checkDictionaryDataFormat:params.wrapData];
    }
    // 判断打点数据是否都满足实现 NSCoding 协议
    if (!isConfirmCoding) {
        HMDALOG_PROTOCOL_ERROR_TAG(@"HMDEventTrace", @"HMDTTMonitorTracker : Service(%@) is not response NSCoding protocol, appid : %@", params.serviceName, params.appID ?: @"");
        return;
    }

    // 判断一个对象能否转换成JSON对象，如果不能则不往数据库存储
    BOOL isValidJson = NO;
    try {
        isValidJson = [NSJSONSerialization isValidJSONObject:params.wrapData];
    } catch (NSException *exception) {
        isValidJson = NO;
    }
    if (!isValidJson) {
        HMDALOG_PROTOCOL_ERROR_TAG(@"HMDEventTrace", @"HMDTTMonitorTracker : Service(%@) is valid json object, appid : %@, log_type : %@", params.serviceName, params.appID ?: @"", params.logType ?: @"");
        
        NSAssert(false,@"TTMonitor - The data of the event tracing cannot satisfy isValidJSONObject. appid = %@, log_type = %@, service_name = %@", params.appID ?: @"", params.logType ?: @"", params.serviceName ?: @"");
        return;
    }
    
    if (![HMDInjectedInfo defaultInfo].ttMonitorSampleOptEnable) {
#if RANGERSAPM
        if (self.dropData || hmd_drop_data_sdk(HMDReporterPerformance, params.appID)) {
#else
        if (hmd_drop_data_sdk(HMDReporterPerformance, params.appID)) {
#endif
            HMDALOG_PROTOCOL_INFO_TAG(@"HMDEventTrace", @"HMDTTMonitorTracker eventData write to alog after dropdata : serviceName = %@, logType = %@, data = %@", params.serviceName, params.logType, params.wrapData);
            
            return;
        }
        
        // check if the data hit downgrade rule (the priority of downgrade is greater than the sampling ratio)
        BOOL isDownGrade = [[HMDReportDowngrador sharedInstance] needUploadWithLogType:params.logType serviceName:params.serviceName aid:params.appID];
        if (!isDownGrade) {
            return;
        }
    }
    
    NSMutableDictionary *tmpData = [[NSMutableDictionary alloc] initWithDictionary:params.wrapData];
    if (![tmpData objectForKey:@"network_type"]) {
        [tmpData setValue:@([HMDNetworkHelper connectTypeCode]) forKey:@"network_type"];
    }

    HMDTTMonitorRecord *record = [HMDTTMonitorRecord newRecord];
    if (self.dataManager.injectedInfo) {
        record.sdkVersion = self.dataManager.injectedInfo.sdkVersion;
    }
    record.extra_values = tmpData;
    record.log_type = params.logType;
    record.service = params.serviceName;
    record.log_id = [HMDTTMonitorHelper generateLogID];  // 暂时不知道有啥用
    record.appID = params.appID;
    record.uniqueCode = uniqueCode;
    record.customTag = [HMDTTMonitorTagHelper getMonitorTag];
    
    if ([HMDInjectedInfo defaultInfo].ttMonitorSampleOptEnable) {
        record.needUpload = params.needUpload;
        record.traceParent = params.traceParent;
        record.singlePointOnly = params.singlePointOnly;
    } else {
        [self setMovingLineAndNeedUploadForRecord:record];
        if ([HMDInjectedInfo defaultInfo].stopWriteToDiskWhenUnhit && !record.needUpload && params.storeType != HMDTTmonitorStoreActionUploadImmediately) {
            return;
        }
    }
    hmd_safe_dispatch_async(self.syncQueue, ^{
        BOOL badTracker = NO;
        @try {
            switch (params.storeType) {
                case HMDTTmonitorStoreActionNormal:
                case HMDTTmonitorStoreActionStoreImmediately: {
                    // 未获得采样率前，先缓存数据，等待获取到采样率后，再更新needupload
                    if (self.dataManager.needCache) {
                        [self.recordCache addObject:record];
                        if (self.recordCache.count > kMaxRecordCacheCount) {
                            [self.recordCache removeObjectAtIndex:0];
                        }
                    }
                    else {
                        // 确保缓存有机会更新，且存入数据库
                        [self insertRecordCacheIntoTrackersArrayIfNeeded];
                        BOOL isStoreNow = params.storeType == HMDTTmonitorStoreActionStoreImmediately;
                        if (record.needUpload) {
                            record.sequenceNumber = [self.counter generateSequenceNumber];
                        }
                        badTracker = YES;
                        [self cleanupTrackersArrayToThreshold];
                        [self.trackersArray addObject:record];
                        if ([self respondsToSelector:@selector(recordCachedCheckPointWithServiceName:data:)]) {
                            [self recordCachedCheckPointWithServiceName:record.service data:record.extra_values];
                        }
                        [self tracksCountChangedWithSyncWrite: isStoreNow];
                    }
                    break;
                }
                
                case HMDTTmonitorStoreActionUploadImmediatelyIfNeed:{
                    if (!self.dataManager.needCache && !record.needUpload) break;
                }
                case HMDTTmonitorStoreActionUploadImmediately:{
                    record.sequenceNumber = [self.counter generateSequenceNumber];
                    [self.trackersCacheArray addObject:record];
                    [self hmd_uploadMonitorDataImmediatelyWithRetryCount:0];
                    break;
                }
                
                default:
                    break;
            }
            [HMDDebugLogger printLog:[NSString stringWithFormat:@"Record an event-log successfully, name: %@", params.serviceName]];
        }
        @catch (NSException *exception) {
            // 检测是否是trackersArray数据发生的异常
            if (badTracker) {
                HMDALOG_PROTOCOL_ERROR_TAG(@"HMDEventTrace", @"HMDTTMonitorTracker : try catch exception with records form %ld to %ld, appid : %@", [self.trackersArray.firstObject uniqueCode], [self.trackersArray.lastObject uniqueCode], params.appID ?: @"");
                [self.trackersArray removeAllObjects];
            }
        }
        @finally {
            
        }
    });
}

#pragma - mark - track

// 如果TrackersArray缓存数量超过kTrackMaxCacheCount，触发清理策略
- (void)cleanupTrackersArrayToThreshold {
    NSMutableDictionary *recordIdxDic = [NSMutableDictionary dictionary];
    NSMutableIndexSet *notNeedUploadIdxSet = [[NSMutableIndexSet alloc] init];
    if (self.trackersArray.count >= kTrackMaxCacheCount) {
        // 清理占比最多且占比大于kTrackMaxCacheCount * 20%的某类埋点
        __block int maxCount = 0;
        __block NSString *maxKey = @"";
        [self.trackersArray enumerateObjectsUsingBlock:^(HMDTTMonitorRecord * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            @autoreleasepool {
                // 统计所有埋点类型对应的下标
                NSString *key = [NSString stringWithFormat:@"%@_%@", obj.log_type, obj.service];
                NSMutableIndexSet *key_set = [recordIdxDic objectForKey:key];
                
                if ([recordIdxDic hmd_hasKey:key]) {
                    [key_set addIndex:idx];
                    [recordIdxDic hmd_setObject:key_set forKey:key];
                    
                    if (key_set.count > maxCount) {
                        maxCount = (int)key_set.count;
                        maxKey = key;
                    }
                } else {
                    NSMutableIndexSet *new_set = [[NSMutableIndexSet alloc] init];
                    [new_set addIndex:idx];
                    [recordIdxDic hmd_setObject:new_set forKey:key];
                }
                // 统计不需要上报record的下标
                if (!obj.needUpload) {
                    [notNeedUploadIdxSet addIndex:idx];
                }
            }
        }];
        
        if ([recordIdxDic hmd_hasKey:maxKey] && maxCount >= (kTrackMaxCacheCount * 0.2)) {
            NSMutableIndexSet *maxCountSet = [recordIdxDic objectForKey:maxKey];
            [self.trackersArray removeObjectsAtIndexes:maxCountSet];
            
            HMDALOG_PROTOCOL_WARN_TAG(@"HMDEventTrace", @"HMDTTMonitorTracker - Drop events for avoiding oom, logType_serviceName = %@, count = %d, appid = %@, strategy = largest proportion.", maxKey, maxCount, self.dataManager.appID);
        }else {
            
            // 清理不需要上报的数据
            [self.trackersArray removeObjectsAtIndexes:notNeedUploadIdxSet];
            
            if (self.trackersArray.count < kTrackMaxCacheCount) {
                HMDALOG_PROTOCOL_WARN_TAG(@"HMDEventTrace", @"HMDTTMonitorTracker - Drop not need upload events for avoiding oom, appid = %@", self.dataManager.appID);
            } else {
                // 清理最老的数据
                [self.trackersArray removeObjectAtIndex:0];
                HMDALOG_PROTOCOL_WARN_TAG(@"HMDEventTrace", @"HMDTTMonitorTracker - Drop oldest events for avoiding oom");
            }
        }
    }
}

#pragma - mark - cache

// 如果有缓存，更新needupload，再插入TrackersArray中
- (void)insertRecordCacheIntoTrackersArrayIfNeeded {
    if (self.recordCache.count) {
        NSMutableArray *missSampling = [NSMutableArray new];
        for (HMDTTMonitorRecord *record in self.recordCache) {
            [self setMovingLineAndNeedUploadForRecord:record];
            if (record.needUpload) {
                record.sequenceNumber = [self.counter generateSequenceNumber];
            }
            else {
                [missSampling addObject:@(record.uniqueCode)];
            }
        }
        [self.trackersArray addObjectsFromArray:self.recordCache];
        if ([self respondsToSelector:@selector(recordCachedCheckPointWithServiceName:data:)]) {
            for (HMDTTMonitorRecord *record in self.recordCache) {
                [self recordCachedCheckPointWithServiceName:record.service data:record.extra_values];
            }
        }
        HMDALOG_PROTOCOL_INFO_TAG(@"HMDEventTrace", @"HMDTTMonitorTracker save cache records from %ld to %ld, total count : %ld, miss sampling : %@, appID : %@", [self.recordCache.firstObject uniqueCode], [self.recordCache.lastObject uniqueCode], self.recordCache.count, [missSampling copy], self.dataManager.appID);
        [self.recordCache removeAllObjects];
    }
}

#pragma mark -- metric

- (void)countEvent:(NSString *)type label:(NSString *)label value:(float)value needAggregate:(BOOL)needAggr appID:(NSString *)appID {
#if RANGERSAPM
    if (self.dropData) return;
#endif
    if (hmd_drop_data_sdk(HMDReporterPerformance, appID)) return;
    
    NSAssert(appID != nil,@"The appID cannot be nil!");
    
    if (![self.customConfig metricTypeEnabled:type]) {
        return;
    }
    
    HMDTTMonitorMetricRecord *metricRecord = [HMDTTMonitorMetricRecord newRecord];
    metricRecord.key = label;
    metricRecord.value = value;
    metricRecord.type = type;
    metricRecord.needAggr = needAggr;
    metricRecord.metricType = TTMonitorMetricItemTypeCount;
    metricRecord.appID = appID;
    
    hmd_safe_dispatch_async(self.syncQueue, ^{
        [self.metricsArray addObject:metricRecord];
    });
}

- (void)timerEvent:(NSString *)type label:(NSString *)label value:(float)value needAggregate:(BOOL)needAggr appID:(NSString *)appID {
#if RANGERSAPM
    if (self.dropData) return;
#endif
    if (hmd_drop_data_sdk(HMDReporterPerformance, appID)) return;
    
    NSAssert(appID != nil,@"The appID cannot be nil!");
    
    if (![self.customConfig metricTypeEnabled:type]) {
        return;
    }
    
    HMDTTMonitorMetricRecord *metricRecord = [HMDTTMonitorMetricRecord newRecord];
    metricRecord.key = label;
    metricRecord.value = value;
    metricRecord.type = type;
    metricRecord.needAggr = needAggr;
    metricRecord.metricType = TTMonitorMetricItemTypeTime;
    metricRecord.appID = appID;
    
    hmd_safe_dispatch_async(self.syncQueue, ^{
        [self.metricsArray addObject:metricRecord];
    });
}
#pragma mark -- util

- (void)tracksCountChangedWithSyncWrite:(BOOL)syncWrite {
    NSUInteger flushCount = kTrackFlushCount;
    if ([self.dataManager isMainAppMonitor]) {
        if([HMDInjectedInfo defaultInfo].monitorFlushCount > 0){
            flushCount = [HMDInjectedInfo defaultInfo].monitorFlushCount;
        }
    } else {
        if (self.dataManager.injectedInfo.flushCount > 0) {
            flushCount = self.dataManager.injectedInfo.flushCount;
        }
    }
    if (self.trackersArray.count >= flushCount || syncWrite) {
        BOOL result = [self.dataManager.store.database insertObjects:self.trackersArray
                                                                into:[[[self.trackersArray firstObject] class] tableName]];
        
        NSArray *records = [self.trackersArray copy];
        NSMutableArray *needUploadRecords = [NSMutableArray array];
        BOOL memoryResult = NO;
        for (HMDTTMonitorRecord *record in records) {
            if ([record isKindOfClass:[HMDTTMonitorRecord class]] && record.needUpload) {
                [needUploadRecords hmd_addObject:record];
            }
        }
        
        // memory database
        if (!result) {
            memoryResult = [self.dataManager.store.memoryDB insertObjects:needUploadRecords.copy into:[[[self.trackersArray firstObject] class] tableName] appID:self.dataManager.appID];
        }
        
        if (result || memoryResult) {
            // 改为只在写入数据库的时候 评估数据写入的量
            if (self.sizeLimitTool && [self.sizeLimitTool shouldSizeLimit]) {
                if (needUploadRecords.count > 0) {
                    [self.sizeLimitTool estimateSizeWithDictArray:[self getTracksDataWithRecords:needUploadRecords] module:self];
                }
            }
            
            if ([HMDInjectedInfo defaultInfo].enableLegacyDBOptimize) {
                if (needUploadRecords.count > 0) {
                    [self.lock lock];
                    self.insertIndex += 1;
                    self.hasNewData = YES;
                    [self.lock unlock];
                }
            }
            
            [[HMDPerformanceReporterManager sharedInstance] updateRecordCount:self.trackersArray.count withAppID:self.dataManager.appID];
            if ([self respondsToSelector:@selector(recordSavedCheckPointWithServiceName:data:)]) {
                for (HMDTTMonitorRecord *record in self.trackersArray) {
                    [self recordSavedCheckPointWithServiceName:record.service data:record.extra_values];
                }
            }
            [self.trackersArray removeAllObjects];
        }
        
        if ([self respondsToSelector:@selector(recordSavedCheckPointWithRecords:success:memoryDB:appID:)]) {
            [self recordSavedCheckPointWithRecords:records success:result memoryDB:memoryResult appID:self.dataManager.appID];
        }
        
        result = [self.dataManager.store.database insertObjects:self.metricsArray
                                                                into:[[[self.metricsArray firstObject] class] tableName]];
        if (result) {
            [[HMDPerformanceReporterManager sharedInstance] updateRecordCount:self.trackersArray.count withAppID:self.dataManager.appID];
            [self.metricsArray removeAllObjects];
        }
    }
    
    // avoid oom
    NSInteger limit = MAX((flushCount * 2), (kTrackMinCacheCount));
    if (self.trackersArray.count > limit) {
        [self.trackersArray removeObjectsInRange:NSMakeRange(0, flushCount)];
        HMDALOG_PROTOCOL_WARN_TAG(@"HMDEventTrace", @"Drop event for avoiding oom, count : %ld, appid : %@", limit, self.dataManager.appID);
    }
}
    
- (BOOL)isHighPriorityWithLogType:(NSString *)logTypeStr serviceType:(NSString *)serviceType {
    return NO;
}

- (BOOL)needUploadWithlogTypeStr:(NSString *)logTypeStr serviceType:(NSString *)serviceType {
    return [self needUploadWithLogTypeStr:logTypeStr serviceType:serviceType data:nil];
}

- (BOOL)needUploadWithLogTypeStr:(NSString *)logTypeStr serviceType:(NSString *)serviceType data:(NSDictionary *)data {
    BOOL needUpload = NO;
    if ([logTypeStr isEqualToString:kHMDTTMonitorServiceLogTypeStr] && serviceType) {
        // fixme : For MT's ttlive events only
        if (self.ignoreLogType && [serviceType hasPrefix:@"ttlive_"]) {
            needUpload = [self serviceTypeEnabled:serviceType];
        }
        else {
            needUpload = [self logTypeEnabled:logTypeStr] && [self serviceTypeEnabled:serviceType];
        }
    } else {
        needUpload = [self logTypeEnabled:logTypeStr];
        if (needUpload && data) {
            needUpload = [self.customConfig customLogTypeEnable:logTypeStr withMonitorData:data];
        }
    }
    
    return needUpload;
}
    
- (BOOL)logTypeEnabled:(NSString *)logType {
    return [self.customConfig logTypeEnabled:logType];
}

- (BOOL)serviceTypeEnabled:(NSString *)serviceType {
    return [self.customConfig serviceTypeEnabled:serviceType];
}

- (BOOL)ttmonitorConfigurationAvailable {
    return self.customConfig.configurationAvailable;
}


#pragma mark -- upload
- (NSArray *)getTracksDataWithRecords:(NSArray<HMDTTMonitorRecord *> *)records {
    if (records.count < 1) {
        return nil;
    }
    NSMutableArray *dataArray = [NSMutableArray array];
    
    for (HMDTTMonitorRecord *record in records) {
#if !RANGERSAPM
        if (![HMDTTMonitorTagHelper verifyMonitorTag:record.customTag]) {
            continue;
        }
#endif
        NSMutableDictionary *dataValue = [NSMutableDictionary dictionary];
#if RANGERSAPM
        if ([record.log_type isEqualToString:kHMDTTMonitorServiceLogTypeStr]) {
            [dataValue setValue:@"event_log" forKey:@"log_type"];
        } else {
            [dataValue setValue:record.log_type forKey:@"log_type"];
        }
#else
        [dataValue setValue:@"event" forKey:@"module"];
        [dataValue setValue:record.log_type forKey:@"log_type"];
        [dataValue setValue:@(record.netQualityType) forKey:@"network_quality"];
#endif
        long long time = MilliSecond(record.timestamp);
        [dataValue setValue:@(time) forKey:@"timestamp"];
        [dataValue setValue:record.sessionID forKey:@"session_id"];
        [dataValue setValue:@(record.inAppTime) forKey:@"inapp_time"];

        if (record.service) {
#if !RANGERSAPM
            [dataValue setValue:record.service forKey:@"service"];
#else
            [dataValue setValue:record.service forKey:@"event_name"];
#endif
        }
        if (record.appID) {
            [dataValue setValue:record.appID forKey:@"aid"];
        }
        [dataValue setValue:record.log_id forKey:@"insert_id"];
        [dataValue setValue:[HMDTTMonitorHelper generateUploadID] forKey:@"upload_id"];
        [dataValue setValue:@(record.localID) forKey:@"log_id"];
        
        if ([record.extra_values isKindOfClass:[NSDictionary class]]) {
            [dataValue addEntriesFromDictionary:record.extra_values];
        }
        if (record.sdkVersion) {
            [dataValue setValue:record.sdkVersion forKey:@"sdk_version"];
        }
        if (record.appVersion) {
            [dataValue setValue:record.appVersion forKey:@"app_version"];
        }
        if (record.osVersion) {
            [dataValue setValue:record.osVersion forKey:@"os_version"];
        }
        if (record.updateVersionCode) {
            [dataValue setValue:record.updateVersionCode forKey:@"update_version_code"];
        }
        if (record.sequenceNumber > 0) {
            [dataValue setValue:@(record.sequenceNumber) forKey:@"seq_no_type"];
        }
        
        [dataValue setValue:record.traceParent forKey:@"traceparent"];
        [dataValue setValue:@(record.singlePointOnly) forKey:@"single_point_only"];
        
#if RANGERSAPM
        [dataArray addObject:[NSDictionary dictionaryWithObject:[dataValue copy] forKey:@"payload"]];
#else
        [dataArray addObject:[dataValue copy]];
#endif
    }
    
    NSArray *datas = [dataArray copy];
    if ([self respondsToSelector:@selector(recordFetchedCheckPointWithRecords:appID:)]) {
        [self recordFetchedCheckPointWithRecords:datas appID:self.dataManager.appID];
    }
    
    return datas;
}

- (NSArray *)getMetricDataWithRecords:(NSArray<HMDTTMonitorMetricRecord *> *)records {
    NSMutableArray *dataArray = [NSMutableArray array];
    
    for (HMDTTMonitorMetricRecord *record in records) {
        NSMutableDictionary *dataValue = [NSMutableDictionary dictionary];
        
        long long time = MilliSecond(record.timestamp);
        
        [dataValue setValue:@(time) forKey:@"timestamp"];
        [dataValue setValue:record.sessionID forKey:@"session_id"];
        [dataValue setValue:@(record.inAppTime) forKey:@"inapp_time"];
        [dataValue setValue:record.key forKey:@"key"];
        [dataValue setValue:@(record.value) forKey:@"value"];
        [dataValue setValue:record.type forKey:@"type"];

        [dataArray addObject:dataValue];
    }
    
    return [dataArray copy];
}

- (void)hmd_uploadMonitorDataImmediatelyWithRetryCount:(NSInteger)retryCount {
    [[HMDPerformanceReporterManager sharedInstance] reportImmediatelyPerformanceCacheDataWithAppID:self.dataManager.appID block:^(BOOL success) {
        if (success) {
            hmd_safe_dispatch_async(self.syncQueue, ^{
                [self.trackersCacheArray removeAllObjects];
            });
        } else if(retryCount < 3) {
            hmd_safe_dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), self.syncQueue, ^{
                [self hmd_uploadMonitorDataImmediatelyWithRetryCount:(retryCount + 1)];
            });
        }
    }];
}

#pragma mark - DataReporterDelegate
- (NSUInteger)reporterPriority {
    return HMDReporterPriorityTTMonitorTracker;
}

- (NSArray *)metricCountPerformanceData {
    NSMutableArray *dataArray = [NSMutableArray array];
    NSTimeInterval ignoreTime = [[HMDInjectedInfo defaultInfo] getIgnorePerformanceDataTimeInterval];
    
    HMDStoreCondition *condition1 = [[HMDStoreCondition alloc] init];
    condition1.key = @"appID";
    condition1.stringValue = self.dataManager.appID;
    condition1.judgeType = HMDConditionJudgeEqual;
    
    HMDStoreCondition *condition2 = [[HMDStoreCondition alloc] init];
    condition2.key = @"metricType";
    condition2.threshold = TTMonitorMetricItemTypeCount;
    condition2.judgeType = HMDConditionJudgeEqual;
    
    NSArray<HMDStoreCondition *> *metricCountCondition = nil;
    if (ignoreTime) {
        HMDStoreCondition *condition3 = [[HMDStoreCondition alloc] init];
        condition3.key = @"timestamp";
        condition3.threshold = ignoreTime;
        condition3.judgeType = HMDConditionJudgeGreater;
        
        metricCountCondition = @[condition1,condition2,condition3];
    }
    else {
        metricCountCondition = @[condition1,condition2];
    }
    
    NSArray<HMDTTMonitorMetricRecord *> *metricRecords = [self.dataManager.store.database getObjectsWithTableName:[[self metricStoreClass] tableName] class:[self metricStoreClass] andConditions:metricCountCondition orConditions:nil limit:kHMDTTMonitorMetricLimit];
    
    self.metricCountRange = [HMDRecordStore localIDRange:metricRecords];
    self.metricCountCondition = metricCountCondition;
    
    NSArray *metricResult = [self getMetricDataWithRecords:metricRecords];
    if (metricResult) {
        [dataArray addObjectsFromArray:metricResult];
    }

    return [dataArray copy];
}

- (NSArray *)metricTimerPerformanceData {
    NSMutableArray *dataArray = [NSMutableArray array];
    NSTimeInterval ignoreTime = [[HMDInjectedInfo defaultInfo] getIgnorePerformanceDataTimeInterval];
    
    HMDStoreCondition *condition1 = [[HMDStoreCondition alloc] init];
    condition1.key = @"appID";
    condition1.stringValue = self.dataManager.appID;
    condition1.judgeType = HMDConditionJudgeEqual;
    
    HMDStoreCondition *condition2 = [[HMDStoreCondition alloc] init];
    condition2.key = @"metricType";
    condition2.threshold = TTMonitorMetricItemTypeTime;
    condition2.judgeType = HMDConditionJudgeEqual;
    
    NSArray<HMDStoreCondition *> *metricTimerCondition = nil;
    if (ignoreTime) {
        HMDStoreCondition *condition3 = [[HMDStoreCondition alloc] init];
        condition3.key = @"timestamp";
        condition3.threshold = [[HMDInjectedInfo defaultInfo] getIgnorePerformanceDataTimeInterval];
        condition3.judgeType = HMDConditionJudgeGreater;
        
        metricTimerCondition = @[condition1,condition2,condition3];
    }
    else {
        metricTimerCondition = @[condition1,condition2];
    }
        
    NSArray<HMDTTMonitorMetricRecord *> *metricRecords = [self.dataManager.store.database getObjectsWithTableName:[[self metricStoreClass] tableName] class:[self metricStoreClass] andConditions:metricTimerCondition orConditions:nil limit:kHMDTTMonitorMetricLimit];
    
    self.metricTimerRange = [HMDRecordStore localIDRange:metricRecords];
    self.metricTimerCondition = metricTimerCondition;

    NSArray *metricResult = [self getMetricDataWithRecords:metricRecords];
    if (metricResult) {
        [dataArray addObjectsFromArray:metricResult];
    }
    
    return [dataArray copy];
}

- (NSArray *)performanceDataWithCountLimit:(NSInteger)limitCount {
    
    NSUInteger index = 0;
    if ([HMDInjectedInfo defaultInfo].enableLegacyDBOptimize) {
        [self.lock lock];
        index = self.insertIndex;
        BOOL hasNewData = self.hasNewData;
        [self.lock unlock];
        
        if (!hasNewData) {
            return nil;
        }
    }
    
    if (self.needStopRepeating) {
        BOOL success = [self cleanupRecords:self.uploadingRange andConditions:self.normalCondition storeClass:[self trackerStoreClass]];
        if (success) {
            self.needStopRepeating = NO;
            [self.dataManager.store saveStoreErrorCode:0];
        }
    }
    
    self.hmdCountLimit = limitCount ?: 0;
    NSArray *records = [self fetchTTMonitorRecordsStartTime:0
                                                    endTime:[[NSDate date] timeIntervalSince1970]
                                                 limitCount:self.hmdCountLimit];
    if (records.count && [self respondsToSelector:@selector(recordsFetchedCheckPointWithReporter:datas:)]) {
        [self recordsFetchedCheckPointWithReporter:[NSString stringWithFormat:@"%p", self.dataManager.reporter] datas:[records mutableCopy]];
    }
    
    if ([HMDInjectedInfo defaultInfo].enableLegacyDBOptimize) {
        if (records.count == 0) {
            [self.lock lock];
            if (index == self.insertIndex) {
                self.hasNewData = NO;
            }
            [self.lock unlock];
        }
    }
    
    return records;
}

- (NSArray *)fetchTTMonitorRecordsStartTime:(NSTimeInterval)startTime
                                    endTime:(NSTimeInterval)endTime
                                 limitCount:(NSInteger)limitCount {
    NSMutableArray<HMDTTMonitorRecord *> *trackRecords = [NSMutableArray array];

    // data from memory database
    NSArray<HMDTTMonitorRecord *> *tmpMemoryRecords = [self.dataManager.store.memoryDB getObjectsWithTableName:[[self trackerStoreClass] tableName] appID:self.dataManager.appID limit:limitCount];
    
    if (tmpMemoryRecords && tmpMemoryRecords.count) {
        limitCount -= tmpMemoryRecords.count;
        self.uploadingCountFromMemory = tmpMemoryRecords.count;
        [trackRecords addObjectsFromArray:tmpMemoryRecords];
        HMDALOG_PROTOCOL_INFO_TAG(@"HMDEventTrace", @"HMDTTMonitorTracker : fetch data from memory: %@, count: %zd, appID: %@",[[self trackerStoreClass] tableName], tmpMemoryRecords.count, self.dataManager.appID);
    }
    
    // data from FMDB
    NSArray<HMDTTMonitorRecord *> *tmpDiskRecords = nil;
    if (!self.needStopRepeating) {
        HMDStoreCondition *condition1 = [[HMDStoreCondition alloc] init];
        condition1.key = @"needUpload";
        condition1.threshold = 1;
        condition1.judgeType = HMDConditionJudgeEqual;

        HMDStoreCondition *condition2 = [[HMDStoreCondition alloc] init];
        condition2.key = @"timestamp";
        condition2.threshold = endTime;
        condition2.judgeType = HMDConditionJudgeLess;

        HMDStoreCondition *condition3 = [[HMDStoreCondition alloc] init];
        condition3.key = @"appID";
        condition3.stringValue = self.dataManager.appID;
        condition3.judgeType = HMDConditionJudgeEqual;
        
        NSArray<HMDStoreCondition *> *normalCondition = nil;
        startTime = MAX((startTime),([[HMDInjectedInfo defaultInfo] getIgnorePerformanceDataTimeInterval]));
        if (startTime > 0) {
            HMDStoreCondition *condition4 = [[HMDStoreCondition alloc] init];
            condition4.key = @"timestamp";
            condition4.threshold = startTime;
            condition4.judgeType = HMDConditionJudgeGreater;
            
            normalCondition = @[condition1,condition2,condition3,condition4];
        }
        else {
            normalCondition = @[condition1,condition2,condition3];
        }

        tmpDiskRecords = [self.dataManager.store.database getObjectsWithTableName:[[self trackerStoreClass] tableName] class:[self trackerStoreClass] andConditions:normalCondition orConditions:nil limit:limitCount];

        if (tmpDiskRecords && tmpDiskRecords.count) {
            self.uploadingRange = [HMDRecordStore localIDRange:tmpDiskRecords];
            self.normalCondition = normalCondition;
            [trackRecords addObjectsFromArray:tmpDiskRecords];
            self.needDeleteRecordsFromDB = YES;
            HMDALOG_PROTOCOL_INFO_TAG(@"HMDEventTrace", @"HMDTTMonitorTracker : fetch data from database: %@, count: %zd, appID: %@", [[self trackerStoreClass] tableName], tmpDiskRecords.count, self.dataManager.appID);
            
        }
    }
    
    if (!trackRecords.count) return nil;
    
    NSArray *trackResult = [self getTracksDataWithRecords:trackRecords];

    NSMutableArray *dataArray = [NSMutableArray array];

    if (trackResult) {
       [dataArray addObjectsFromArray:trackResult];
    }

    return [dataArray copy];
}

- (void)performanceDataSaveImmediately {
    hmd_safe_dispatch_async(self.syncQueue, ^{
       [self tracksCountChangedWithSyncWrite:YES];
    });
}

- (NSArray * _Nullable)performanceCacheDataImmediatelyUpload {
    if (!self.trackersCacheArray || self.trackersCacheArray.count == 0) { return nil; }

    NSMutableArray<HMDTTMonitorRecord *> *trackRecords = [NSMutableArray array];
    [self.trackersCacheArray enumerateObjectsUsingBlock:^(HMDTTMonitorRecord * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.timestamp >= [[HMDInjectedInfo defaultInfo] getIgnorePerformanceDataTimeInterval]) {
            [trackRecords addObject:obj];
        }
    }];

    NSArray *trackResult = [self getTracksDataWithRecords:trackRecords];

    NSMutableArray *dataArray = [NSMutableArray array];
    if (trackResult) {
        [dataArray addObjectsFromArray:trackResult];
    }
    
    return [dataArray copy];
}

- (NSArray *)debugRealPerformanceDataWithConfig:(HMDDebugRealConfig *)config {
    NSMutableArray<HMDTTMonitorRecord *> *trackRecords;
    
    if (![config checkIfAllowedDebugRealUploadWithType:kHMDTTMonitorServiceLogTypeStr]) {
        return nil;
    }
    
    HMDStoreCondition *condition1 = [[HMDStoreCondition alloc] init];
    condition1.key = @"timestamp";
    condition1.threshold = config.fetchStartTime;
    condition1.judgeType = HMDConditionJudgeGreater;
    
    HMDStoreCondition *condition2 = [[HMDStoreCondition alloc] init];
    condition2.key = @"timestamp";
    condition2.threshold = config.fetchEndTime;
    condition2.judgeType = HMDConditionJudgeLess;
    
   NSArray<HMDStoreCondition *> *debugRealCondition = @[condition1,condition2];
    
    NSArray<HMDTTMonitorRecord *> *tmpRecords = [self.dataManager.store.database getObjectsWithTableName:[[self trackerStoreClass] tableName] class:[self trackerStoreClass] andConditions:debugRealCondition orConditions:nil limit:config.limitCnt];
    
    trackRecords = [NSMutableArray arrayWithArray:tmpRecords];
    
    self.uploadingRange = [HMDRecordStore localIDRange:trackRecords];
    self.normalCondition = debugRealCondition;
    
    NSArray *trackResult = [self getTracksDataWithRecords:trackRecords];
    
    NSMutableArray *dataArray = [NSMutableArray array];
    
    if (trackResult) {
        [dataArray addObjectsFromArray:trackResult];
    }
    
    return [dataArray copy];
}

- (void)cleanupPerformanceDataWithConfig:(HMDDebugRealConfig *)config {
    HMDStoreCondition *condition1 = [[HMDStoreCondition alloc] init];
    condition1.key = @"timestamp";
    condition1.threshold = config.fetchStartTime;
    condition1.judgeType = HMDConditionJudgeGreater;
    
    HMDStoreCondition *condition2 = [[HMDStoreCondition alloc] init];
    condition2.key = @"timestamp";
    condition2.threshold = config.fetchEndTime;
    condition2.judgeType = HMDConditionJudgeLess;
    
    NSArray<HMDStoreCondition *> *debugRealConditions = @[condition1,condition2];

    [self cleanupRecords:self.uploadingRange andConditions:debugRealConditions storeClass:[self trackerStoreClass]];
}

- (void)cleanupNotUploadAndReportedPerformanceData {
    HMDStoreCondition *condition1 = [[HMDStoreCondition alloc] init];
    condition1.key = @"needUpload";
    condition1.threshold = 0;
    condition1.judgeType = HMDConditionJudgeEqual;

    NSArray<HMDStoreCondition *> *cleanCondition = @[condition1];
    [self.dataManager.store.database deleteObjectsFromTable:[[self trackerStoreClass] tableName]
                                              andConditions:cleanCondition
                                               orConditions:nil];
}

- (void)performanceDataDidReportSuccess:(BOOL)isSuccess {
    if (!isSuccess) return;
    
    // clean data from memory database
    if (self.uploadingCountFromMemory) {
        [self.dataManager.store.memoryDB deleteObjectsFromTable:[[self trackerStoreClass] tableName] appID:self.dataManager.appID count:self.uploadingCountFromMemory];
    }
    
    // clean data from FMDB
    if (!self.needStopRepeating && self.needDeleteRecordsFromDB) {
        [self cleanupRecords:self.uploadingRange andConditions:self.normalCondition storeClass:[self trackerStoreClass]];
        self.needDeleteRecordsFromDB = NO;
    }
}

- (BOOL)cleanupRecords:(HMDRecordLocalIDRange)range
         andConditions:(NSArray *)andConditionss
            storeClass:(Class<HMDRecordStoreObject>)storeClass
{
    BOOL success = [self.dataManager.store cleanupRecordsWithRange:range andConditions:andConditionss storeClass:storeClass];
    
    if (!success) {
        HMDALOG_PROTOCOL_ERROR_TAG(@"HMDEventTrace", @"HMDTTMonitorTracker : Delete event failed, store class : %@, appID : %@, errorCode : %ld", storeClass, self.dataManager.appID, [self.dataManager.store.database deleteErrorCode]);
    }
    
    // 事件埋点需删除失败后，做逻辑删除
    if ([storeClass isEqual:[self trackerStoreClass]] && success == NO) {
        HMDTTMonitorRecord *record = [HMDTTMonitorRecord newRecord];
        success = [self.dataManager.store logicalCleanupRecordsWithRange:range andConditions:andConditionss storeClass:storeClass object:record];
        HMDALOG_PROTOCOL_ERROR_TAG(@"HMDEventTrace", @"HMDTTMonitorTracker : Delete event failed and then update success : %d, appID : %@", success, self.dataManager.appID);
    }
    
    // stop repeating
    if ([storeClass isEqual:[self trackerStoreClass]] && success == NO) {
        self.needStopRepeating = YES;
        [self.dataManager.store saveStoreErrorCode:[self.dataManager.store.database deleteErrorCode]];
        HMDALOG_PROTOCOL_ERROR_TAG(@"HMDEventTrace", @"HMDTTMonitorTracker : Delete event failed and then stop reporting, appID : %@", self.dataManager.appID);
    }
    
    return success;
}

- (void)saveEventDataToDiskWhenEnterBackground {
    // 需落盘数据，同步阻塞
    if (self.trackersArray.count || self.metricsArray.count) {
        dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
        NSString *taskName = [kHMDTTMonitorBackgroundTask stringByAppendingFormat:@"%@", self.dataManager.appID];
        [HMDSimpleBackgroundTask
        detachBackgroundTaskWithName:taskName
        task:^(void (^ _Nonnull completeHandle)()) {
            hmd_safe_dispatch_async(self.syncQueue, ^{
                if (self.trackersArray.count > 0) {
                    BOOL result = [self.dataManager.store.database insertObjects:self.trackersArray
                                                                            into:[[[self.trackersArray firstObject] class] tableName]];
                    if (result) {
                        [[HMDPerformanceReporterManager sharedInstance] updateRecordCount:self.trackersArray.count withAppID:self.dataManager.appID];
                        [self.trackersArray removeAllObjects];
                    }
                }
                if (self.metricsArray.count > 0) {
                    BOOL result = [self.dataManager.store.database insertObjects:self.metricsArray
                                                                            into:[[[self.metricsArray firstObject] class] tableName]];
                    if (result) {
                        [[HMDPerformanceReporterManager sharedInstance] updateRecordCount:self.metricsArray.count withAppID:self.dataManager.appID];
                        [self.metricsArray removeAllObjects];
                    }
                }
                dispatch_semaphore_signal(semaphore);
                if(completeHandle) completeHandle();
            });
        }];
        
        dispatch_semaphore_wait(semaphore, dispatch_time(DISPATCH_TIME_NOW, 5.f));
    }
}

#pragma - mark HMDTTMonitorTraceProtocol

- (void)recordGeneratedCheckPointWithlogType:(NSString *)logTypeStr
                                 serviceType:(NSString*)serviceType
                                       appID:(NSString *)appID
                                  actionType:(HMDTTMonitorStoreActionType)actionType
                                  uniqueCode:(int64_t)uniqueCode
{
    if (!self.customConfig.enableEventTrace) return;
    
    HMDALOG_PROTOCOL_INFO_TAG(@"HMDEventTrace", @"HMDTTMonitorTracker event log type : %@, service type : %@, app id : %@, action type : %ld, unique code : %lld", logTypeStr, serviceType ?: @"", appID ?: @"", actionType, uniqueCode);
}

- (void)recordSavedCheckPointWithRecords:(NSArray *)records
                                 success:(BOOL)success
                                memoryDB:(BOOL)memoryDB
                                   appID:(NSString *)appID
{
    if (!self.customConfig.enableEventTrace) return;
    
    if (success || memoryDB) {
        NSMutableArray *uniqueCodes = [NSMutableArray new];
        NSMutableArray *seqenceNumbers = [NSMutableArray new];
        for (HMDTTMonitorRecord *record in records) {
            if (record.needUpload) {
                [uniqueCodes addObject:@(record.uniqueCode)];
                [seqenceNumbers addObject:@(record.sequenceNumber)];
            }
        }
        HMDALOG_PROTOCOL_INFO_TAG(@"HMDEventTrace", @"HMDTTMonitorTracker save records successed : %d, memoryDB : %d, from %ld to %ld, count : %ld, appID : %@, need upload unique code : %@, seq_no : %@", success, memoryDB, [(HMDTTMonitorRecord*)records.firstObject uniqueCode], [(HMDTTMonitorRecord*)records.lastObject uniqueCode], records.count, appID, [uniqueCodes copy], [seqenceNumbers copy]);
    }
    else {
        HMDALOG_PROTOCOL_ERROR_TAG(@"HMDEventTrace", @"HMDTTMonitorTracker save records successed : %d, memoryDB : %d, from %ld to %ld, count : %ld, appID : %@", success, memoryDB, [(HMDTTMonitorRecord*)records.firstObject uniqueCode], [(HMDTTMonitorRecord*)records.lastObject uniqueCode], records.count, appID);
    }
}

- (void)recordFetchedCheckPointWithRecords:(NSArray<NSDictionary *> *)records
                                     appID:(NSString *)appID
{
    if (!self.customConfig.enableEventTrace) return;
    
    NSNumber *firstSeqenceNumber = [records.firstObject objectForKey:@"seq_no_type"];
    NSNumber *lastSeqenceNumber = [records.lastObject objectForKey:@"seq_no_type"];
    HMDALOG_PROTOCOL_INFO_TAG(@"HMDEventTrace", @"HMDTTMonitorTracker fetch records from %ld to %ld, count : %ld, appID : %@", firstSeqenceNumber ? [firstSeqenceNumber integerValue] : -2, lastSeqenceNumber ? [lastSeqenceNumber integerValue] : -2, records.count, appID);
}

#pragma - mark drop data

- (void)removebjects:(NSMutableArray *)array WithAid:(NSString *)aid {
    if ([array isKindOfClass:[NSArray class]]) {
        [array enumerateObjectsUsingBlock:^(HMDTTMonitorRecord*  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj isKindOfClass:[HMDTTMonitorRecord class]] && [obj.appID isEqualToString:aid]) {
                [array removeObject:obj];
            }
        }];
    }
}

- (void)dropAllDataForServerStateWithAid:(NSString *)aid {
    hmd_safe_dispatch_async(self.syncQueue, ^{
        [self removebjects:self.recordCache WithAid:aid];
        [self removebjects:self.trackersArray WithAid:aid];
        [self removebjects:self.trackersCacheArray WithAid:aid];
        //metricsArray已废弃，不做额外的以Aid为维度删除策略
        [self.metricsArray removeAllObjects];
        
        HMDStoreCondition *aidCondition = [[HMDStoreCondition alloc] init];
        aidCondition.key = @"appID";
        aidCondition.stringValue = aid;
        aidCondition.judgeType = HMDConditionJudgeEqual;
        
        NSArray<HMDStoreCondition *> *cleanCondition = @[aidCondition];
        [self.dataManager.store.database deleteObjectsFromTable:[[self trackerStoreClass] tableName] andConditions:cleanCondition orConditions:nil];
        [self.dataManager.store.database deleteObjectsFromTable:[[self metricStoreClass] tableName] andConditions:cleanCondition orConditions:nil];
    });
}

- (void)dropAllDataForServerState {
//    hmd_safe_dispatch_async(self.syncQueue, ^{
//        [self.recordCache removeAllObjects];
//        [self.trackersArray removeAllObjects];
//        [self.trackersCacheArray removeAllObjects];
//        [self.metricsArray removeAllObjects];
//
//        [self.dataManager.store.database deleteAllObjectsFromTable:[[self trackerStoreClass] tableName]];
//        [self.dataManager.store.database deleteAllObjectsFromTable:[[self metricStoreClass] tableName]];
//    });
}

#pragma mark -- receiveNotification
- (void)willResignActive:(NSNotification *)notification {
    hmd_safe_dispatch_async(self.syncQueue, ^{
        [self cleanupWithConfig:self.customConfig.cleanupConfig];
    });
}

#pragma mark - cleanup
- (void)cleanupWithConfig:(HMDCleanupConfig *)cleanConfig {
    HMDStoreCondition *aidCondition = [[HMDStoreCondition alloc] init];
    aidCondition.judgeType = HMDConditionJudgeEqual;
    aidCondition.stringValue = self.dataManager.appID;
    aidCondition.key = @"appID";
    
    NSArray *andConditions = [NSArray arrayWithObjects:aidCondition, nil];
    
    // 当第一次 Heimdallr 拉不到配置时 会在 HMDConfigManager.config 就为空了
    // 所以 HMDConfigManager.config.cleanupConfig 就是空的
    if (cleanConfig.andConditions.count > 0) {
        andConditions = [andConditions arrayByAddingObjectsFromArray:cleanConfig.andConditions];
        
        NSString *tableName = [[self trackerStoreClass] tableName];
        [self.dataManager.store.database deleteObjectsFromTable:tableName
                                                                 andConditions:andConditions
                                                                  orConditions:nil];
        if ([self.dataManager.store.database recordCountForTable:tableName] >= kMaxServiceRecordCount) {
            [self cleanupNotUploadAndReportedPerformanceData];
        }
        [self.dataManager.store.database deleteObjectsFromTable:tableName limitToMaxSize:kMaxServiceRecordCount];
        
        
        tableName = [[self metricStoreClass] tableName];
        [self.dataManager.store.database deleteObjectsFromTable:tableName
                                                            andConditions:andConditions
                                                             orConditions:nil];
        [self.dataManager.store.database deleteObjectsFromTable:tableName limitToMaxSize:kMaxMetricsRecordCount];
    } else {
        HMDALOG_PROTOCOL_ERROR_TAG(@"Heimdallr", @"%@", @"cleanupconditions cannot be nil!");
    }
}

# pragma mark - movingline
- (void) setMovingLineAndNeedUploadForRecord:(HMDTTMonitorRecord *)record {
    // movingline
    NSDictionary *extra = [NSDictionary dictionary];
    NSString *traceParent;
    BOOL isTraceParentHit = NO;
    
    if (record.extra_values) {
        extra = [record.extra_values hmd_dictForKey:@"extra"];
    }
     
    if (extra && extra.count > 0) {
        traceParent = [extra hmd_stringForKey:@"traceparent"];
    }
    
    if (traceParent && traceParent.length == 55) {
        NSString *flag = [traceParent substringFromIndex:traceParent.length - 2];
        if ([flag isEqualToString:@"01"]) {
            isTraceParentHit = YES;
        }
    }
    
    BOOL needUpload = [self needUploadWithLogTypeStr:record.log_type serviceType:record.service data:record.extra_values];
    
    NSInteger singlePointOnly = 0;
    if (!needUpload && isTraceParentHit) {
        singlePointOnly = 1;
    }
    
    record.needUpload = needUpload || isTraceParentHit;
    record.traceParent = traceParent;
    record.singlePointOnly = singlePointOnly;
}

@end
