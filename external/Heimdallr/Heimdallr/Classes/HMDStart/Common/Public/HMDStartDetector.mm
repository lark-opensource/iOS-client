//
//  HMDStartDetector.m
//  Heimdallr
//
//  Created by 谢俊逸 on 22/2/2018.
//

#import "HMDStartDetector.h"
#import "Heimdallr.h"
#import "Heimdallr+Private.h"
#import "Heimdallr+Cleanup.h"
#import "HMDStartRecord.h"
#import "HMDMacro.h"
#import "HMDStoreIMP.h"
#import "HMDDebugRealConfig.h"
#import "HMDStartDetectorConfig.h"
#import "HMDPerformanceReportRequest.h"
#import "NSArray+HMDSafe.h"
#import "HMDALogProtocol.h"
#import "HMDPerformanceReporter.h"
#import "AppStartTracker.h"
#include <atomic>
#import "NSDate+HMDAccurate.h"
#import "NSDictionary+HMDSafe.h"

#import "HMDHermasCounter.h"
#import "HMDHermasManager.h"
#import "HMDMacro.h"
CLANG_DIAGNOSTIC_PUSH
CLANG_DIAGNOSTIC_IGNORE_STRICT_PROTOTYPES
#import <Hermas/Hermas.h>
CLANG_DIAGNOSTIC_POP
// PrivateServices
#import "HMDServerStateService.h"

extern start_time_log_t *start_time_log;
extern "C"
{
  void monitorAppStartTime(void);
}

CFTimeInterval hmd_load_start_timestamp;

@interface HMDStartDetector()<HMDPerformanceReporterDataSource> {
    
}
@property (nonatomic, strong)HMDPerformanceReportRequest *reportingRequest;
@property (nonatomic, assign) BOOL hasStartLaunch;
@property (nonatomic, strong) HMInstance *instance;

@end

@implementation HMDStartDetector


void addInfo(HMDStartRecord *record) {
    record.enableUpload = [HMDStartDetector share].config.enableUpload ? 1 : 0;
    record.sequenceCode = record.enableUpload ? [[HMDHermasCounter shared] generateSequenceCode:@"HMDStartRecord"] : -1;
}

+ (instancetype)share {
  static dispatch_once_t onceToken;
  static HMDStartDetector *share = nil;
  dispatch_once(&onceToken, ^{
    share = [HMDStartDetector new];
  });
  return share;
}

- (HMInstance *)instance {
    if (!_instance) {
        _instance = [HMDHermasManager sharedPerformanceInstance];
    }
    return _instance;
}

- (NSTimeInterval)didFnishConcurrentRendering {
    NSTimeInterval interval = [[NSDate date] timeIntervalSince1970] - hmd_load_start_timestamp;
    
    HMDStartRecord *record = [HMDStartRecord new];
    record.timestamp = [[NSDate date] timeIntervalSince1970];
    record.timeType = @"load_to_render_time";
    record.timeInterval = interval;
    record.sessionID = [HMDSessionTracker currentSession].sessionID;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        record.enableUpload = self.config.enableUpload ? 1 : 0;
        if (hermas_enabled()) {
            addInfo(record);
            [self.instance recordData:record.reportDictionary];
        } else {
            [self.heimdallr.database insertObject:(id)record
                                             into:[self.storeClass tableName]];
        }
    });
    
    return interval ?: 0.0;
}

+ (void)markWillFinishingLaunchDate {
    static std::atomic_flag onceToken = ATOMIC_FLAG_INIT;
    if(!atomic_flag_test_and_set(&onceToken)) {
        HMDWillFinishLaunchingDate = [NSDate date];
        HMDWillFinishLaunchingAccurateDate = [NSDate hmd_accurateDate];
    }
}

+ (void)markMainDate {
    static std::atomic_flag onceToken = ATOMIC_FLAG_INIT;
    if(!atomic_flag_test_and_set(&onceToken)) {
        HMDMainDate = [NSDate date];
    }
}

#pragma - mark drop data

- (void)dropAllDataForServerState {
    [[Heimdallr shared].store.database deleteAllObjectsFromTable:[self.storeClass tableName]];
}

#pragma mark HeimdallrModule
- (void)cleanupWithConfig:(HMDCleanupConfig *)cleanConfig {
    [self.heimdallr cleanupDatabaseWithConfig:cleanConfig tableName:[self.storeClass tableName]];
}

- (void)setupWithHeimdallr:(Heimdallr *)heimdallr { 
    [super setupWithHeimdallr:heimdallr];
}

- (void)start {
    [super start];
    start_time_log = startlog;

    if (self.hasStartLaunch) { return; }
    self.hasStartLaunch = YES;

    if ([NSThread isMainThread]) {
        [self startLaunchDetection];
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self startLaunchDetection];
        });
    }
}

- (void)startLaunchDetection {
    //后台启动之后会挂起，耗时不准确，忽略
    BOOL isBackgroundLaunch = [UIApplication sharedApplication].applicationState == UIApplicationStateBackground;
    if (!isUIScene() && isBackgroundLaunch) {
        HMDALOG_PROTOCOL_ERROR_TAG(@"Heimdallr", @"start detector is skipped because of background launch");
        return;
    }
    
    //因为目前启动时间从load开始计算，因此启动时间监控首次生效时候拿不到准确的数据，因为从第二次再开始上报
    //如果 start 模块没有加入 defaultSetupModules，那么首次启动会在拉到配置后才调用 start，导致误把拉到配置的时间当作 didFinishLaunching 时间，所以需要判断 appStartTrackerEnabled
    if (appStartTrackerEnabled()) {
        monitorAppStartTime();
    }
}

- (void)stop { 
    [super stop];
}

- (BOOL)needSyncStart {
    return YES;
}

- (void)prepareForDefaultStart {
    self.config.enableUpload = YES;
}

- (BOOL)performanceDataSource
{
    return YES;
}

- (Class<HMDRecordStoreObject>)storeClass { 
    return [HMDStartRecord class];
}

- (void)updateConfig:(HMDStartDetectorConfig *)config
{
    [super updateConfig:config];
}

#pragma mark helper

void startlog(CFTimeInterval from_load_to_first_render_time,
              CFTimeInterval from_didFinshedLaunching_to_first_render_time,
              CFTimeInterval from_load_to_didFinshedLaunching_time,
              CFTimeInterval hmd_load_timestamp,
              bool prewarm,
              NSMutableArray *objc_load_infos,
              NSMutableArray *cpp_init_infos
              ) {
#ifdef DEBUG
    NSLog(@"StartTimeLog:\nfrom_didFinshedLaunching_to_first_render_time %f", from_didFinshedLaunching_to_first_render_time);
#else
  
#endif
    hmd_load_start_timestamp = hmd_load_timestamp;
    
    NSMutableArray *recordArray = [NSMutableArray new];
    
    if (from_didFinshedLaunching_to_first_render_time > 0 && from_didFinshedLaunching_to_first_render_time < 20) {
        // didFinshedLaunching_to_first_render_time
        HMDStartRecord *record = [HMDStartRecord new];
        record.timestamp = [[NSDate date] timeIntervalSince1970];
        record.timeType = @"didFinshedLaunching_to_first_render_time";
        record.timeInterval = from_didFinshedLaunching_to_first_render_time * 1000;
        record.sessionID = [HMDSessionTracker currentSession].sessionID;
        record.prewarm = prewarm;
        [recordArray addObject:record];
    }
    
    if (from_load_to_first_render_time > 0 && from_load_to_first_render_time < 20) {
        // from_load_to_first_render_time
        HMDStartRecord *from_load_to_first_render_time_record = [HMDStartRecord new];
        from_load_to_first_render_time_record.timeType = @"from_load_to_first_render_time";
        from_load_to_first_render_time_record.timeInterval = from_load_to_first_render_time * 1000;
        from_load_to_first_render_time_record.timestamp = [[NSDate date] timeIntervalSince1970];
        from_load_to_first_render_time_record.sessionID = [HMDSessionTracker currentSession].sessionID;
        from_load_to_first_render_time_record.prewarm = prewarm;
        [recordArray hmd_addObject:from_load_to_first_render_time_record];
    }

    if (from_load_to_didFinshedLaunching_time > 0 && from_load_to_didFinshedLaunching_time < 20) {
        // from_load_to_didFinshedLaunching_time
        HMDStartRecord *from_load_to_didFinshedLaunching_time_record = [HMDStartRecord new];
        from_load_to_didFinshedLaunching_time_record.timeType = @"from_load_to_didFinshedLaunching_time";
        from_load_to_didFinshedLaunching_time_record.timeInterval = from_load_to_didFinshedLaunching_time * 1000;
        from_load_to_didFinshedLaunching_time_record.timestamp = [[NSDate date] timeIntervalSince1970];
        from_load_to_didFinshedLaunching_time_record.sessionID = [HMDSessionTracker currentSession].sessionID;
        from_load_to_didFinshedLaunching_time_record.prewarm = prewarm;
        [recordArray addObject:from_load_to_didFinshedLaunching_time_record];
    }
    
    BOOL needDrop = hermas_enabled() ? [HMDHermasManager sharedPerformanceInstance].isDropData : hmd_drop_data(HMDReporterPerformance);
    if (needDrop) return;
    
    if (recordArray && recordArray.count > 0) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSUInteger enableUpload = [HMDStartDetector share].config.enableUpload ? 1 : 0;
            [recordArray hmd_enumerateObjectsUsingBlock:^(HMDStartRecord * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                obj.enableUpload = enableUpload;
            } class:[HMDStartRecord class]];
            
            if (hermas_enabled()) {
                static HMInstance *instance = [HMDHermasManager sharedPerformanceInstance];
                [recordArray enumerateObjectsUsingBlock:^(HMDStartRecord * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                    addInfo(obj);
                    [instance recordData:obj.reportDictionary];
                }];
                
            } else {
                if ([[HMDStartDetector share].heimdallr.database insertObjects:recordArray into:[HMDStartRecord tableName]]) {
                    [[HMDStartDetector share].heimdallr updateRecordCount:recordArray.count];
                }
            }
            
        });
    }
}

- (NSArray<HMDStartRecord *> *)records {
    return [[Heimdallr shared].database getAllObjectsWithTableName:[HMDStartRecord tableName]
                                                                   class:[HMDStartRecord class]];
}

#pragma mark -- upload
- (NSUInteger)reporterPriority {
    return HMDReporterPriorityStartDetector;
}

- (NSArray *)getDataWithRecords:(NSArray<HMDStartRecord *> *)records isDebugReal:(BOOL)isDebugReal {
    NSMutableArray *dataArray = [NSMutableArray array];
    for (HMDStartRecord *record in records) {
        BOOL storeTag = NO;
        
        for (NSMutableDictionary *dict in dataArray) {
            if ([[dict valueForKey:@"session_id"] isEqualToString:record.sessionID]) {
                NSMutableDictionary *extraDic = [dict valueForKey:@"extra_values"];
                NSString *type = record.timeType;
                if (type) {
                    [extraDic setValue:@(record.timeInterval) forKey:type];
                }
                storeTag = YES;
            }
        }
        if (storeTag) {
            continue;
        }
        NSMutableDictionary *dataValue = [NSMutableDictionary dictionary];
        
        long long time = MilliSecond(record.timestamp);
        [dataValue setValue:@(time) forKey:@"timestamp"];
        [dataValue setValue:record.sessionID forKey:@"session_id"];
        [dataValue setValue:@"start" forKey:@"service"];
        [dataValue setValue:@(record.localID) forKey:@"log_id"];
        [dataValue setValue:@(record.netQualityType) forKey:@"network_quality"];
        [dataValue setValue:@(record.prewarm) forKey:@"prewarm"];

        if (isDebugReal) {
            [dataValue setValue:@"performance_monitor_debug" forKey:@"log_type"];
        } else {
            [dataValue setValue:@"performance_monitor" forKey:@"log_type"];
        }
        
        NSMutableDictionary *extraValue = [NSMutableDictionary dictionary];
        NSString *type = record.timeType;
        if (type) {
            [extraValue setValue:@(record.timeInterval) forKey:type];
        }
        [dataValue setValue:extraValue forKey:@"extra_values"];

        [dataArray addObject:dataValue];
    }
    return [dataArray copy];
}

- (NSArray *)performanceDataWithCountLimit:(NSInteger)limitCount {
    if (hermas_enabled()) {
        return nil;
    }
    
    NSArray<HMDStartRecord *> *records = [self fetchUploadRecordsWithLimit:limitCount];
    if(records == nil) return nil;
    
    NSArray *result = [self getDataWithRecords:records isDebugReal:NO];
    
    return [result copy];
}

- (NSArray<HMDStartRecord *> *)fetchUploadRecordsWithLimit:(NSInteger)limitCount {
    HMDStoreCondition *condition1 = [[HMDStoreCondition alloc] init];
    condition1.key = @"enableUpload";
    condition1.threshold = 0;
    condition1.judgeType = HMDConditionJudgeGreater;

    HMDStoreCondition *condition2 = [[HMDStoreCondition alloc] init];
    condition2.key = @"timestamp";
    condition2.threshold = [[NSDate date] timeIntervalSince1970];
    condition2.judgeType = HMDConditionJudgeLess;
    
    NSArray<HMDStoreCondition *> *dataAddCondtion = @[condition1, condition2];
    
    NSArray<HMDStartRecord *> *records =
    [[Heimdallr shared].store.database getObjectsWithTableName:[[self storeClass] tableName]
                                                         class:[self storeClass]
                                                 andConditions:dataAddCondtion
                                                  orConditions:nil
                                                         limit:limitCount];
    if (records) {
        self.reportingRequest = [[HMDPerformanceReportRequest alloc] init];
        self.reportingRequest.limitCount = limitCount;
        self.reportingRequest.dataAndConditions = dataAddCondtion;
    }
    return records;
}

- (NSArray *)debugRealPerformanceDataWithConfig:(HMDDebugRealConfig *)config {
    if (![config checkIfAllowedDebugRealUploadWithType:kEnablePerformanceMonitor] &&
        ![config checkIfAllowedDebugRealUploadWithType:kHMDModuleStartDetector]) {
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
    
    NSArray<HMDStoreCondition *> *debugRealConditions = @[condition1,condition2];
    
    NSArray<HMDStartRecord *> *records =
    [[Heimdallr shared].store.database getObjectsWithTableName:[[self storeClass] tableName]
                                                         class:[self storeClass]
                                                 andConditions:debugRealConditions
                                                  orConditions:nil
                                                         limit:config.limitCnt];
    
    NSArray *result = [self getDataWithRecords:records isDebugReal:YES];
    
    return [result copy];
}

- (void)cleanupPerformanceDataWithConfig:(HMDDebugRealConfig *)config {
    if (hermas_enabled()) {
        return;
    }
    
    HMDStoreCondition *condition1 = [[HMDStoreCondition alloc] init];
    condition1.key = @"timestamp";
    condition1.threshold = config.fetchStartTime;
    condition1.judgeType = HMDConditionJudgeGreater;
    
    HMDStoreCondition *condition2 = [[HMDStoreCondition alloc] init];
    condition2.key = @"timestamp";
    condition2.threshold = config.fetchEndTime;
    condition2.judgeType = HMDConditionJudgeLess;
    
    NSArray<HMDStoreCondition *> *debugRealConditions = @[condition1,condition2];
    
    [[Heimdallr shared].store.database deleteObjectsFromTable:[[self storeClass] tableName]
                                                andConditions:debugRealConditions
                                                 orConditions:nil
                                                        limit:config.limitCnt];
}

- (void)performanceDataDidReportSuccess:(BOOL)isSuccess {
    if (hermas_enabled()) {
        return;
    }
    
    if (isSuccess) {
        [self.heimdallr.database deleteObjectsFromTable:[[self storeClass] tableName]
                                          andConditions:self.reportingRequest.dataAndConditions
                                           orConditions:nil
                                                  limit:self.reportingRequest.limitCount];
    }
    self.reportingRequest = nil;
}

@end
