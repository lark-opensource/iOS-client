//
//  UITrackerManager.m
//  Heimdallr
//
//  Created by joy on 2018/4/25.
//

#import "HMDUITrackerManager.h"
#import "HMDRecordStore.h"
#import "Heimdallr.h"
#import "Heimdallr+Private.h"
#import "Heimdallr+Cleanup.h"
#include "pthread_extended.h"
#import "HMDStoreCondition.h"
#import "HMDUITracker.h"
#import "UINavigationController+HMDUITracker.h"
#import "UITabBarController+HMDUITracker.h"
#import "UIViewController+HMDUITracker.h"
#import "HMDMacro.h"
#import "HeimdallrUtilities.h"
#import "HMDUploadHelper.h"
#import "HMDNetworkManager.h"
#import "HMDDebugRealConfig.h"
#import "HMDStoreIMP.h"
#import "HMDALogProtocol.h"
#import "HMDInfo+SystemInfo.h"
#import "HMDUITrackerConfig.h"
#import "HMDDynamicCall.h"
#import "HMDVCFinder.h"
#import "NSArray+HMDJSON.h"
#import "HMDRecordStore+DeleteRecord.h"
#import "HMDGCD.h"
#import "HMDUITrackRecord.h"
#import "HMDPerformanceReporter.h"
#import "NSDictionary+HMDJSON.h"
#import "HMDUIViewHierarchy.h"
#include "pthread_extended.h"
#import "HMDMacro.h"
#import "HMDUITrackerTool.h"
#import "HMDReportDowngrador.h"
#include "HMDISAHookOptimization.h"


#import "HMDHermasCounter.h"
#import "HMDHermasManager.h"
#import "HMDMacro.h"
CLANG_DIAGNOSTIC_PUSH
CLANG_DIAGNOSTIC_IGNORE_STRICT_PROTOTYPES
#import <Hermas/Hermas.h>
CLANG_DIAGNOSTIC_POP
// PrivateServices
#import "HMDServerStateService.h"

NSString *const kHMDUITrackerSceneDidChangeNotification = @"kHMDUITrackerSceneDidChangeNotification";
static NSString *const kEnableUIMonitor = @"enable_ui_monitor"; //只有云控回捞时用

@interface HMDUITrackerManager ()<HMDPerformanceReporterDataSource, HMDUITrackerDelegate>
{
    pthread_mutex_t _mutex;
    pthread_rwlock_t _recentScenesLock;
}
@property (nonatomic, assign, readwrite) CFTimeInterval lastFlushTimestamp;
@property (nonatomic, assign, readwrite) CFTimeInterval startTimestamp;
@property (atomic, copy, readwrite) NSString *scene;
@property (atomic, copy, readwrite) NSString *lastScene;
@property (atomic, strong) dispatch_queue_t syncQueue;
@property (atomic, strong, readwrite) NSNumber *sceneInPushing; // 场景正在切换
@property (atomic, assign) BOOL newVCPushing;
@property (nonatomic, assign) BOOL isNeedSaveEventsInBackground;
@property (nonatomic, strong, readwrite) NSMutableArray<NSDictionary *> *recentScenes;
@property (nonatomic, assign) HMDRecordLocalIDRange uploadingRange;
@property (nonatomic, assign) NSInteger hmdCountLimit;
@property (nonatomic, strong) NSArray<HMDStoreCondition *> *andConditions;
@property (nonatomic, strong) HMInstance *instance;
@end
@implementation HMDUITrackerManager

+ (instancetype)sharedManager
{
    static HMDUITrackerManager *tracker = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        tracker = [[HMDUITrackerManager alloc] init];
    });
    return tracker;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _events = [NSMutableArray array];
        _recentScenes = [NSMutableArray array];
        
        rwlock_init_private(_recentScenesLock);
        mutex_init_recursive(_mutex);
        
        self.scene = @"unknown";
        self.lastScene = @"unknown";
        self.sceneInPushing = @(NO);
        self.flushCount = 60;
        self.flushInterval = 60;
        self.syncQueue = dispatch_queue_create("com.heimdallr.UITracker.syncQueue", DISPATCH_QUEUE_SERIAL);
        self.isNeedSaveEventsInBackground = NO;

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillEnterForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];
        
        [HMDVCFinder.finder addObserver:self forKeyPath:@"scene" options:0 context:NULL];
        [HMDVCFinder.finder triggerUpdateImmediately];
    }
    return self;
}

- (void)dealloc
{
    [HMDVCFinder.finder removeObserver:self forKeyPath:@"scene"];
    mutex_destroy(_mutex);
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (HMInstance *)instance {
    if (!_instance) {
        _instance = [HMDHermasManager sharedPerformanceInstance];
    }
    return _instance;
}

#pragma mark - KVO VC Finder

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    self.scene = HMDVCFinder.finder.scene;
    self.lastScene = HMDVCFinder.finder.previousScene ?: @"unkown";
    if (!self.newVCPushing) {
        self.sceneInPushing = @(NO);
    }
    
    [self updateOperationTrace];
    
    if(hmd_log_enable()) {
        HMDALOG_PROTOCOL_INFO_TAG(@"heimdallr", @"[HMDUITrackerManager] Leaving scene %@ Enter scene %@", self.lastScene, self.scene);
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kHMDUITrackerSceneDidChangeNotification object:nil];
}

- (void)updateOperationTrace {
    //0表示关闭此功能
    NSUInteger threshold = ((HMDUITrackerConfig *)self.config).recentAccessScenesLimit;
    if(threshold == 0) return;
    
    NSString *scene = self.scene;
    if (scene && ![scene hasPrefix:@"UI"]) {
        pthread_rwlock_wrlock(&_recentScenesLock);
        NSMutableDictionary *sceneInfo = [NSMutableDictionary dictionary];
        [sceneInfo setValue:scene forKey:@"scene"];
        [sceneInfo setValue:@(MilliSecond([[NSDate date] timeIntervalSince1970]))forKey:@"timestamp"];
        if (sceneInfo) {
            [self.recentScenes addObject:sceneInfo];
        }
        if (self.recentScenes.count > threshold) {
            [self.recentScenes removeObjectAtIndex:0];
        }

        NSAssert([NSThread isMainThread] && self.recentScenes.count <= threshold, @"The method must be called on the main thread and should keep the amount of the last visited pages up to threshold!");
        pthread_rwlock_unlock(&_recentScenesLock);
    }
}

- (long long)dbMaxSize {
    return 10000;
}

- (NSArray<HMDUITrackRecord*>*)ui_actionRecordsInAppTimeFrom:(CFTimeInterval)fromTime to:(CFTimeInterval)toTime sessionID:(NSString *)sessionID recordClass:(Class)recordClass {
    HMDStoreCondition *condition1 = [[HMDStoreCondition alloc] init];
    condition1.key = @"inAppTime";
    condition1.threshold = fromTime;
    condition1.judgeType = HMDConditionJudgeGreater;
    
    HMDStoreCondition *condition2 = [[HMDStoreCondition alloc] init];
    condition2.key = @"inAppTime";
    condition2.threshold = toTime;
    condition2.judgeType = HMDConditionJudgeLess;
    
    HMDStoreCondition *condition3 = [[HMDStoreCondition alloc] init];
    condition2.key = @"sessionID";
    condition2.stringValue = sessionID;
    condition2.judgeType = HMDConditionJudgeEqual;
    
    self.andConditions = @[condition1,condition2,condition3];
    
    
    return [[Heimdallr shared].database getObjectsWithTableName:[self.storeClass tableName] class:self.storeClass andConditions:self.andConditions orConditions:nil];
}


#pragma mark -- receiveNotification
- (void)applicationDidEnterBackground:(NSNotification *)notification {
    if (hermas_enabled()) return;
    
    hmd_safe_dispatch_async(self.syncQueue, ^{
        // 这边的events写入到了数据库, 从这个节点往后的events 都应该写入数据库, 防止后台 crash 的时候,events 丢失
        self.isNeedSaveEventsInBackground = YES;
        if (self.events.count > 0) {
            if ([self.heimdallr.database insertObjects:self.events
                                                        into:[self.storeClass tableName]]) {
             
                [self.heimdallr updateRecordCount:self.events.count];
                [self.events removeAllObjects];
            }
        }
    });
}

- (void)applicationWillEnterForeground:(NSNotification *)notification {
    if (hermas_enabled()) return;
    
    pthread_mutex_lock(&_mutex);
    self.isNeedSaveEventsInBackground = NO;
    pthread_mutex_unlock(&_mutex);
}
#pragma mark - HeimdallrModule

- (void)start {
    if ([HMDInfo defaultInfo].systemVersion.doubleValue < 9.0) {
        return;
    }
    [super start];
    _startTimestamp = [[NSDate date] timeIntervalSince1970];

    HMDUITracker *tracker = HMDUITracker.sharedInstance;
    tracker.delegate = self;
    [tracker start];
}

- (void)stop {
    [super stop];
}

- (void)setupWithHeimdallr:(Heimdallr *)heimdallr {
    [super setupWithHeimdallr:heimdallr];
}
- (void)cleanupWithConfig:(HMDCleanupConfig *)cleanConfig {
    [self.heimdallr cleanupDatabaseWithConfig:cleanConfig tableName:[self.storeClass tableName]];
    [self.heimdallr cleanupDatabase:[self.storeClass tableName] limitSize:[self dbMaxSize]];
}
- (void)updateConfig:(HMDUITrackerConfig *)config {
    [super updateConfig:config];
    if (config.flushCount > 0) {
        self.flushCount = config.flushCount;
    }
    
    if (config.flushInterval > 0) {
        self.flushInterval = config.flushInterval;
    }
    
    self.uploadCount = config.maxUploadCount ?: 1;
    
    bool ISASwizzleOptimization = config.ISASwizzleOptimization;
    
    if  (ISASwizzleOptimization) {
        HMDISAHookOptimization_initialization();
        HMDUITracker_viewController_enable_ISA_swizzle_optimization(true);
    } else {
        HMDUITracker_viewController_enable_ISA_swizzle_optimization(false);
    }
}

- (Class<HMDRecordStoreObject>)storeClass {
    return [HMDUITrackRecord class];
}

- (BOOL)performanceDataSource {
    return YES;
}

#pragma mark - HMDUITrackerDelegate

- (void)hmdTrackableContext:(HMDUITrackableContext *)context eventWithName:(NSString *)event parameters:(NSDictionary *)parameters {
    BOOL needDrop = hermas_enabled() ? self.instance.isDropData : hmd_drop_data(HMDReporterPerformance);
    if (needDrop) return;

    if (hmd_downgrade_performance(@"ui_action")) return;

    
    pthread_mutex_lock(&_mutex);
    
    HMDUITrackRecord *record = [HMDUITrackRecord newRecord];
    record.name = context.trackName;
    record.event = event;
    record.context = context;
    record.extraInfo = parameters;
    record.enableUpload = self.config.enableUpload ? 1 : 0;
    if (hermas_enabled()) {
        record.sequenceCode = record.enableUpload ? [[HMDHermasCounter shared] generateSequenceCode:@"HMDUITrackRecord"] : -1;
    }
    
    hmd_safe_dispatch_async(self.syncQueue, ^{
        [self hmdTrackWithRecord:record];
    });
    
    pthread_mutex_unlock(&_mutex);
}
- (void)hmdTrackWithName:(NSString *)name event:(NSString *)event parameters:(NSDictionary *)parameters {
    BOOL needDrop = hermas_enabled() ? self.instance.isDropData : hmd_drop_data(HMDReporterPerformance);
    if (needDrop) return;

    if (hmd_downgrade_performance(@"ui_action")) return;
    
    pthread_mutex_lock(&_mutex);

    HMDUITrackRecord *record = [HMDUITrackRecord newRecord];
    record.name = name;
    record.event = event;
    record.extraInfo = parameters;
    record.enableUpload = self.config.enableUpload ? 1 : 0;
    if (hermas_enabled()) {
        record.sequenceCode = record.enableUpload ? [[HMDHermasCounter shared] generateSequenceCode:@"HMDUITrackRecord"] : -1;
    }
    
    hmd_safe_dispatch_async(self.syncQueue, ^{
        [self hmdTrackWithRecord:record];
    });
    
    pthread_mutex_unlock(&_mutex);
}

- (void)hmdTrackWithRecord:(HMDUITrackRecord *)record {
    if (hermas_enabled()) {
        [self.instance recordData:record.reportDictionary];
    } else {
        
        [self.events addObject:record];
        
        if (self.lastFlushTimestamp == 0) {
            self.lastFlushTimestamp = [[NSDate date] timeIntervalSince1970];
        }
        
        CFTimeInterval nowTimeStamp = [[NSDate date] timeIntervalSince1970];
        BOOL isExceedTimeThreshold = nowTimeStamp - self.lastFlushTimestamp > self.flushInterval;
        BOOL isExceedCountThreshold = self.events.count > self.flushCount;
        if (isExceedTimeThreshold || isExceedCountThreshold || self.isNeedSaveEventsInBackground) {
            // 数量控制策略 _flushCount
            // storage in database
            if ([self.heimdallr.store.database insertObjects:self.events into:[self.storeClass tableName]]) {
                [self.heimdallr updateRecordCount:self.events.count];
            }
            // remove memory cache
            [self.events removeAllObjects];
            //update
            self.lastFlushTimestamp = nowTimeStamp;
        }
    }
}

// viewDidAppear
// 目前 appearVC 参数尚未使用, 其原本意图是控制当前 VC 切换到哪里了
// 但是目前切换到哪个 VC 事用 VCFinder 管理, 所以没有传递, 也不用传递
- (void)didAppearViewController:(UIViewController *)appearVC {
    DEBUG_ASSERT(appearVC == nil);
    [HMDVCFinder.finder triggerUpdate];
    self.newVCPushing = NO;
}

// viewDidDisAppear
// 目前 leavingVC 参数尚未使用, 其原本意图是控制当前 VC 切换到哪里了
// 但是目前切换到哪个 VC 事用 VCFinder 管理, 所以没有传递, 也不用传递
- (void)didLeaveViewController:(UIViewController *)leavingVC {
    DEBUG_ASSERT(leavingVC == nil);
    [HMDVCFinder.finder triggerUpdate];
}

// presentviewcontroller & pushViewcontroller
// 目前 fromVC 和 toVC 参数尚未使用, 其原本意图是控制当前 VC 切换到哪里了
// 但是目前切换到哪个 VC 事用 VCFinder 管理, 所以没有传递, 也不用传递
- (void)hmdSwitchToNewVCFrom:(UIViewController *)fromVC
                          to:(UIViewController *)toVC {
    DEBUG_ASSERT(fromVC == nil && toVC == nil);
    self.sceneInPushing = @(YES);
    self.newVCPushing = YES;
}

#pragma mark - upload

- (NSUInteger)reporterPriority {
    return HMDReporterPriorityUITrackerManager;
}

- (NSArray *)getUITrackerDataWithRecords:(NSArray<HMDUITrackRecord *> *)records {
    NSMutableArray *dataArray = [NSMutableArray array];
    
    for (HMDUITrackRecord *record in records) {
        NSMutableDictionary *dataValue = [NSMutableDictionary dictionary];
        
        // 上传统一使用毫秒
        long long timestamp = MilliSecond(record.timestamp);
        
        [dataValue setValue:@(timestamp) forKey:@"timestamp"];
        [dataValue setValue:@"ui_action" forKey:@"log_type"];
        [dataValue setValue:record.sessionID forKey:@"session_id"];
        [dataValue setValue:@(record.inAppTime) forKey:@"inapp_time"];
        [dataValue setValue:record.name forKey:@"page"];
        [dataValue setValue:record.event forKey:@"action"];
        [dataValue setValue:@(record.localID) forKey:@"log_id"];

        if (record.extraInfo) {
            NSDictionary *contextDict = record.extraInfo;
            [dataValue setValue:contextDict forKey:@"context"];
        }
        [dataArray addObject:dataValue];
    }
    
    return [dataArray copy];
}

- (NSArray *)debugRealPerformanceDataWithConfig:(HMDDebugRealConfig *)config {
    if (hermas_enabled()) {
        return nil;
    }
    
    if (![config checkIfAllowedDebugRealUploadWithType:kEnablePerformanceMonitor] && ![config checkIfAllowedDebugRealUploadWithType:kEnableUIMonitor]) {
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
    
    NSArray<HMDUITrackRecord *> *records = [[Heimdallr shared].database getObjectsWithTableName:[[self storeClass] tableName] class:[self storeClass] andConditions:debugRealConditions orConditions:nil limit:config.limitCnt];
    NSArray *result = [self getUITrackerDataWithRecords:records];
    
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
    
    [[Heimdallr shared].database deleteObjectsFromTable:[[self storeClass] tableName]
                                          andConditions:debugRealConditions
                                           orConditions:nil
                                                  limit:config.limitCnt];
}

- (NSArray *)performanceDataWithCountLimit:(NSInteger)limitCount {
    if (hermas_enabled()) {
        return nil;
    }
    
    self.hmdCountLimit = limitCount ?: 0;
    NSArray<HMDUITrackRecord *> *records = [self fetchUploadRecords];

    if (records.count < self.uploadCount) { return nil; }
    return [self getUITrackerDataWithRecords:records];
}

- (NSArray *)fetchUploadRecords {
    HMDStoreCondition *condition0 = [[HMDStoreCondition alloc] init];
    condition0.key = @"enableUpload";
    condition0.threshold = 0;
    condition0.judgeType = HMDConditionJudgeGreater;

    HMDStoreCondition *condition1 = [[HMDStoreCondition alloc] init];
    condition1.key = @"timestamp";
    condition1.threshold = [[NSDate date] timeIntervalSince1970];
    condition1.judgeType = HMDConditionJudgeLess;

    self.andConditions = @[condition0, condition1];

    NSArray<HMDUITrackRecord *> *records = [[Heimdallr shared].database getObjectsWithTableName:[[self storeClass] tableName]
                                                                                          class:[self storeClass]
                                                                                  andConditions:self.andConditions
                                                                                   orConditions:nil
                                                                                          limit:self.hmdCountLimit];
    return records;
}

- (UIWindow *)getKeyWindow {
    return [HMDUITrackerTool keyWindow];
}

// Response 之后数据清除等工作
- (void)performanceDataDidReportSuccess:(BOOL)isSuccess {
    if (hermas_enabled()) return;
    
    if (isSuccess) {
        [[Heimdallr shared].database deleteObjectsFromTable:[[self storeClass] tableName]
                                              andConditions:self.andConditions
                                               orConditions:nil
                                                      limit:self.hmdCountLimit];
    }
}

#pragma - mark drop data

- (void)dropAllDataForServerState {
    if (hermas_enabled()) return;
    
    hmd_safe_dispatch_async(self.syncQueue, ^{
        [self.events removeAllObjects];
        [[Heimdallr shared].database deleteAllObjectsFromTable:[[self storeClass] tableName]];
    });
}

//返回当前用户最近10个进入的页面
- (NSDictionary *)sharedOperationTrace {
    //0表示关闭此功能
    NSUInteger threshold = ((HMDUITrackerConfig *)self.config).recentAccessScenesLimit;
    if(threshold == 0) return nil;
    
    NSMutableDictionary *operationTrace = [NSMutableDictionary dictionary];
    pthread_rwlock_rdlock(&_recentScenesLock);
    NSArray<NSDictionary *> *recentScenes = [self.recentScenes copy];
    pthread_rwlock_unlock(&_recentScenesLock);

    [operationTrace setValue:recentScenes forKey:@"recent_access_scenes"];
    
    return [operationTrace copy];
}

// #warning 这里是自定义异常数据，需要进一步评估

- (void)recordViewHierarchyForWindow:(UIWindow *)window WithDetail:(BOOL)need{
    if(window == nil) DEBUG_RETURN_NONE;
    
    __block NSDictionary *viewHierarchy = [NSDictionary new];
    hmd_dispatch_main_sync_safe(^{
        viewHierarchy = [[HMDUIViewHierarchy shared] getViewHierarchy:window superView:nil superVC:nil withDetail:need targetView:nil];
    });
    hmd_safe_dispatch_async(self.syncQueue, ^{
        [[HMDUIViewHierarchy shared] recordViewHierarchy:viewHierarchy];
    });
}

- (void)recordViewHierarchyForKeyWindowWithDetail:(BOOL)need{
    __block NSDictionary *viewHierarchy = [NSDictionary new];
    hmd_dispatch_main_sync_safe(^{
        UIWindow *keyWindow = HMDUITrackerTool.keyWindow;
        if (keyWindow == nil) return;
        viewHierarchy = [[HMDUIViewHierarchy shared] getViewHierarchy:keyWindow superView:nil superVC:nil withDetail:need targetView:nil];
    });
    hmd_safe_dispatch_async(self.syncQueue, ^{
        [[HMDUIViewHierarchy shared] recordViewHierarchy:viewHierarchy];
    });
}

- (void)uploadViewHierarchyWithTitle:(NSString *)title subTitle:(NSString *)subTitle {
    hmd_safe_dispatch_async(self.syncQueue, ^{
        [[HMDUIViewHierarchy shared] uploadViewHierarchyIfNeedWithTitle:title subTitle:subTitle];
    });
}


@end
