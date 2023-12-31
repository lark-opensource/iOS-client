//
//  HMDMonitor.m
//  Heimdallr
//
//  Created by 刘诗彬 on 2017/12/11.
//

#import "HMDMonitor.h"
#import "Heimdallr.h"
#import "Heimdallr+Private.h"
#import "HMDMonitor+Private.h"
#import "HMDStoreIMP.h"
#import "Heimdallr+Cleanup.h"
#import "HMDMonitor+Report.h"
#import "HMDDynamicCall.h"
#import "NSArray+HMDSafe.h"
#import "HMDReportLimitSizeTool.h"
#import "HMDGCD.h"
#import "HMDStoreMemoryDB.h"
#import "HMDMonitorCurve2.h"
#import "HMDMacro.h"
CLANG_DIAGNOSTIC_PUSH
CLANG_DIAGNOSTIC_IGNORE_STRICT_PROTOTYPES
#import <Hermas/Hermas.h>
CLANG_DIAGNOSTIC_POP
#import "HMDMacro.h"
#import "HMDReportDowngrador.h"
#import "HMDMonitorCurve+Private.h"
#import "NSDictionary+HMDSafe.h"

static void *monitor_queue_key = &monitor_queue_key;
static void *monitor_queue_context = &monitor_queue_context;

dispatch_queue_t hmd_get_monitor_queue(void)
{
    static dispatch_queue_t monitor_queue = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        monitor_queue = dispatch_queue_create("com.hmd.heimdallr.monitor", DISPATCH_QUEUE_SERIAL);
        dispatch_queue_set_specific(monitor_queue, monitor_queue_key, monitor_queue_context, 0);
    });
    return monitor_queue;
}

void dispatch_on_monitor_queue(dispatch_block_t block)
{
    if (block == NULL) {
        return;
    }
    if (dispatch_get_specific(monitor_queue_key) == monitor_queue_context) {
        block();
    } else {
        hmd_safe_dispatch_async(hmd_get_monitor_queue(), block);
    }
}

@interface HMDMonitor ()<HMDMonitorStorageDelegate>
{
    dispatch_source_t _timer;
    HMDMonitorCurve *_curve;
    NSMutableArray * _monitorCallbacks;
    NSLock *_monitorLock;
}

@property (nonatomic, strong) HMDPerformanceReportRequest *reportingRequest;
@property (nonatomic, strong, readwrite) NSDictionary *customUploadDic;
@property (nonatomic, strong) NSMutableArray *customScenes;
@property (nonatomic, copy) NSString *customSceneStr;
@property (nonatomic, assign) BOOL hasRegisterKVO;

@property (nonatomic, assign) BOOL inSpecialSceneListening;
@property (nonatomic, strong) NSString *lastSpecialScene;

@end

@implementation HMDMonitor
@synthesize reportingRequest = _reportingRequest;

+ (instancetype)sharedMonitor
{
    return nil;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _refreshInterval = 1;
        _monitorCallbacks = [NSMutableArray new];
        _curve = hermas_enabled() ? [[HMDMonitorCurve2 alloc] init] : [[HMDMonitorCurve alloc] init];
        _monitorLock  = [NSLock new];
        _customUploadDic = [NSDictionary dictionary];
        _customScenes = [NSMutableArray array];
    }
    return self;
}

- (void)registerKVO {
    if(!self.hasRegisterKVO) {
        DC_OB(DC_CL(HMDUITrackerManager, sharedManager), addObserver:forKeyPath:options:context:, self, @"scene",
              (NSKeyValueObservingOptions)NSKeyValueObservingOptionOld|NSKeyValueObservingOptionNew|NSKeyValueObservingOptionInitial, nil);
        
        DC_OB(DC_CL(HMDUITrackerManager, sharedManager), addObserver:forKeyPath:options:context:, self, @"lastScene",
              (NSKeyValueObservingOptions)NSKeyValueObservingOptionOld|NSKeyValueObservingOptionNew|NSKeyValueObservingOptionInitial, nil);
        self.hasRegisterKVO = YES;
    }
}

- (void)removeKVO {
    if(self.hasRegisterKVO) {
        @try {
            DC_OB(DC_CL(HMDUITrackerManager, sharedManager), removeObserver:forKeyPath:, self, @"scene");
            DC_OB(DC_CL(HMDUITrackerManager, sharedManager), removeObserver:forKeyPath:, self, @"lastScene");
            self.hasRegisterKVO = NO;
        } @catch (NSException *exception) {
        
        }
    }
}


- (HMDMonitorRecord *)refresh {
    return nil;
}

- (void)setTimerRefresh:(NSTimeInterval)refreshInterval {  // NO LOCK ⚠️
    if(refreshInterval == 0) {  // request to cancel the timer
        if(_timer != nil) {
            dispatch_source_cancel(_timer);
            _timer = nil;
        }
    }
    else {
        if(_timer == nil) {     // request to start new timer
            _timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, hmd_get_monitor_queue());
            dispatch_source_set_timer(_timer, DISPATCH_TIME_NOW, refreshInterval * NSEC_PER_SEC, 0 * NSEC_PER_SEC);
            __weak typeof(self) wself = self;
            dispatch_source_set_event_handler(_timer, ^{
                __strong typeof(wself) sself = wself;
                HMDMonitorRecord *record = [sself refresh];
                for (HMDMonitorCallback callback in sself->_monitorCallbacks) {
                    callback(record);
                }
            });
            dispatch_resume(_timer);
        }
        // if timer started check if need modify callback interval
        else if(refreshInterval != _refreshInterval) {
            dispatch_source_set_timer(_timer, DISPATCH_TIME_NOW, refreshInterval * NSEC_PER_SEC, 0 * NSEC_PER_SEC);
        }
    }
    _refreshInterval = refreshInterval;
}


- (void)setRefreshInterval:(double)refreshInterval {
    [_monitorLock lock];
    [self setTimerRefresh:refreshInterval];
    [_monitorLock unlock];
}

- (void)startWithInterval:(CFTimeInterval)interval {
    [self setTimerRefresh:interval];
}

- (long long)dbMaxSize {
    return 30000;
}


-(void)addMonitorCallbacks:(HMDMonitorCallback)callback
{
    __weak HMDMonitor *weakSelf = self;
    dispatch_sync(hmd_get_monitor_queue(), ^{
        __strong HMDMonitor *strongSelf = weakSelf;
        if(strongSelf != nil)
            [strongSelf->_monitorCallbacks addObject:callback];
    });
}

- (void)removeMonitorCallbacks:(HMDMonitorCallback)callback
{
    __weak HMDMonitor *weakSelf = self;
    dispatch_sync(hmd_get_monitor_queue(), ^{
        __strong HMDMonitor *strongSelf = weakSelf;
        if(strongSelf != nil)
            [strongSelf->_monitorCallbacks removeObject:callback];
    });
}

- (void)didEnterScene:(NSString *)scene {
}

- (void)willLeaveScene:(NSString *)scene {
}

- (void)enterCustomScene:(NSString *)scene {
    if(HMDIsEmptyString(scene)) {
        return ;
    }
    hmd_safe_dispatch_async(hmd_get_monitor_queue(), ^{
        NSString *lastScene = [self.customScenes lastObject];
        // 去重逻辑 如果传入的 scene 当前 栈顶的一个 scene 是重复的那么不传入;
        if (![lastScene isEqualToString:scene]) {
            [self.customScenes addObject:scene];
            self.customSceneStr = [self.customScenes componentsJoinedByString:@","];
        }
    });
}

- (void)leaveCustomScene:(NSString *)scene {
    if(HMDIsEmptyString(scene)) {
        return ;
    }
    hmd_safe_dispatch_async(hmd_get_monitor_queue(), ^{
        [self.customScenes removeObject:scene];
        if (self.customScenes.count == 0) {
            self.customSceneStr = nil;
        } else {
            self.customSceneStr = [self.customScenes componentsJoinedByString:@","];
        }
    });
}

- (BOOL)enableUpload {
    return self.config.enableUpload;
}

- (BOOL)monitorCurve:(HMDMonitorCurve *)monitorCurve willSaveRecords:(NSArray <HMDMonitorRecord *>*)records
{
    if (records.count == 0) {
        return NO;
    }
    
    BOOL result = [self.heimdallr.database insertObjects:records
                                                          into:[[[records firstObject] class] tableName]];
    if (!result) {
        result = [self.heimdallr.store.memoryDB insertObjects:records into:[[[records firstObject] class] tableName] appID:self.heimdallr.userInfo.appID];
    }
    
    if (result) {
        [self.heimdallr updateRecordCount:records.count];
    }
    return result;
}

- (void)recordSizeCalculationWithRecord:(HMDMonitorRecord *)record {
    if (!self.config.enableUpload) { return; }
    if (self.sizeLimitTool && [self.sizeLimitTool shouldSizeLimit]) {
        [self.sizeLimitTool estimateSizeWithMonitorRecords:self.curve.records recordClass:[self storeClass] module:self];
    }
}

- (void)dropAllMonitorRecords {
    [self.heimdallr.database deleteAllObjectsFromTable:[self.storeClass tableName]];
}

- (void)performanceDataSaveImmediately {
    [self.curve pushRecordImmediately];
}

#pragma mark - HeimdallrModule

- (void)setupWithHeimdallr:(Heimdallr *)heimdallr {
    [super setupWithHeimdallr:heimdallr];
    self.curve.storageDelegate = self;
}

- (void)start {
    [_monitorLock lock];
    
    // 命中了 通过场景来打开监控的功能
    if(!self.config.enableOpen && [self customSceneListenEnabled]) {
        [self startWithListenSpecialScene];
        [_monitorLock unlock];
        return;
    }
    
    if(self.isRunningWithSpecialScene) {
        [self leaveSpecialScene];
        self.inSpecialSceneListening = NO;
    }
    
    if (!self.isRunning) {
        [super start];
        [self startWithInterval:_refreshInterval];
        [self registerKVO];
    }
    [_monitorLock unlock];
}

- (void)stop {
    [_monitorLock lock];
    
    if(self.inSpecialSceneListening) {
        [self stopWithListenSpecialScene];
        [_monitorLock unlock];
        return;
    }
    
    if (self.isRunning) {
        [super stop];
        [self setTimerRefresh:0.0];  // zero means stop the timer
        [self removeKVO];
    }
    
    [_monitorLock unlock];
}
    
- (Class<HMDRecordStoreObject>)storeClass {
    return [HMDMonitorRecord class];
}

- (void)cleanupWithConfig:(HMDCleanupConfig *)cleanConfig {
    [self.heimdallr cleanupDatabaseWithConfig:cleanConfig tableName:[[self storeClass] tableName]];
    [self.heimdallr cleanupDatabase:[self.storeClass tableName] limitSize:[self dbMaxSize]];
}

- (void)updateConfig:(HMDMonitorConfig *)config {
    [super updateConfig:config];
    self.refreshInterval = config.refreshInterval;
    self.curve.flushCount = config.flushCount;
    self.curve.flushInterval = config.flushInterval;
    self.curve.performanceReportEnable = config.enableUpload;
    [self.curve asyncActionOnCurveQueue:^{
        self.customUploadDic = config.customEnableUpload;
    }];
}

- (BOOL)needSyncStart {
    return NO;
}

- (BOOL)performanceDataSource
{
    return YES;
}

- (void)prepareForDefaultStart {
    self.config.enableUpload = YES;
}

#pragma mark - KVO
- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary<NSKeyValueChangeKey,id> *)change
                       context:(void *)context
{
    id newValue = [change objectForKey:NSKeyValueChangeNewKey];
    hmd_safe_dispatch_async(hmd_get_monitor_queue(), ^{
        if ([keyPath isEqualToString:@"scene"] && [newValue isKindOfClass:[NSString class]]) {
            [self kvoDidEnterNewScene:newValue];
        } else if ([keyPath isEqualToString:@"lastScene"]  && [newValue isKindOfClass:[NSString class]]) {
            [self kvoWillLeaveNewScene:newValue];
        }
    });
}

- (void)kvoDidEnterNewScene:(NSString *)newValue {
    [self didEnterScene:newValue];
    [self listenEnterSpecialSceneToOpenMonitor:newValue];
}

- (void)kvoWillLeaveNewScene:(NSString *)newValue {
    [self willLeaveScene:newValue];
    [self listenLeaveSpecialSceneToOpenMonitor:newValue];
}

#pragma mark - records
- (NSArray *)fetchUploadRecords {
    NSMutableArray<HMDMonitorRecord *> *records = [NSMutableArray new];
    
    // data from memory database
    NSArray<HMDMonitorRecord *> *tmpMemoryRecords = [self.heimdallr.store.memoryDB getObjectsWithTableName:[[self storeClass] tableName] appID:self.heimdallr.userInfo.appID limit:self.reportingRequest.limitCount];
    
    if (tmpMemoryRecords && tmpMemoryRecords.count) {
        self.reportingRequest.limitCount -= tmpMemoryRecords.count;
        self.reportingRequest.limitCountFromMemory = tmpMemoryRecords.count;
        [records addObjectsFromArray:tmpMemoryRecords];
    }
    
    // data from FMDB
    NSTimeInterval ignoreTime = [[HMDInjectedInfo defaultInfo] getIgnorePerformanceDataTimeInterval];

    HMDStoreCondition *condition0 = [[HMDStoreCondition alloc] init];
    condition0.key = @"enableUpload";
    condition0.threshold = 0;
    condition0.judgeType = HMDConditionJudgeGreater;

    HMDStoreCondition *condition1 = [[HMDStoreCondition alloc] init];
    condition1.key = @"timestamp";
    condition1.threshold = [[NSDate date] timeIntervalSince1970];
    condition1.judgeType = HMDConditionJudgeLess;

    HMDStoreCondition *condition2 = [[HMDStoreCondition alloc] init];
    condition2.key = @"isReported";
    condition2.threshold = 0;
    condition2.judgeType = HMDConditionJudgeEqual;
    
    HMDStoreCondition *condition3 = [[HMDStoreCondition alloc] init];
    condition3.key = @"timestamp";
    condition3.threshold = ignoreTime;
    condition3.judgeType = HMDConditionJudgeGreater;

    self.reportingRequest.dataAndConditions = @[condition0, condition1, condition2, condition3];

    NSArray<HMDMonitorRecord *> *tmpDiskRecords =
    [self.heimdallr.database getObjectsWithTableName:[[self storeClass] tableName]
                                              class:[self storeClass]
                                      andConditions:self.reportingRequest.dataAndConditions
                                       orConditions:nil
                                              limit:self.reportingRequest.limitCount];
    if (tmpDiskRecords.count) {
        [records addObjectsFromArray:tmpDiskRecords];
    }
    return records.copy;
}

- (void)updateRecordWithConfig:(HMDMonitorRecord *)record {
    if(!HMDIsEmptyDictionary(self.customUploadDic)) {
        [self.customUploadDic enumerateKeysAndObjectsUsingBlock:^(NSString *_Nonnull key, NSNumber* _Nonnull obj, BOOL * _Nonnull stop) {
            // 多个业务传入的 custom_scene 用 “，”相连。这里用 custom_scene 是否包含下发场景来判断是否要上报
            if(!HMDIsEmptyString(record.customScene) && [record.customScene containsString:key] && [obj intValue]) {
                record.enableUpload = 1;
                *stop = YES;
            }
            else if(!HMDIsEmptyString(record.scene) && [record.scene isEqualToString:key] && [obj intValue]) {
                record.enableUpload = 1;
                *stop = YES;
            }
        }];
    }
    
    if(self.config.enableUpload) {
        record.enableUpload = 1;
        record.baseSample = YES;
    }
    
    if(self.isRunningWithSpecialScene) {
        record.isSpecialSceneOpenRecord = YES;
    }
}

#pragma mark - listen and start with scene
- (BOOL)customSceneListenEnabled {
    HMDMonitorConfig *monitorConfig = (HMDMonitorConfig *)self.config;
    return monitorConfig.customOpenEnabled && monitorConfig.customOpenScene.count > 0;
}

- (void)startWithListenSpecialScene {
    if (!self.isRunning && !self.inSpecialSceneListening) {
        self.inSpecialSceneListening = YES;
        [self registerKVO];
    }
}
    
- (void)stopWithListenSpecialScene {
    if(self.inSpecialSceneListening) {
        if(self.isRunningWithSpecialScene) {
            [self leaveSpecialScene];
        }
        [self removeKVO];
        self.inSpecialSceneListening = NO;
    }
}

// start or stop when enter special scene
- (void)enterSpecialScene {
    if (!self.isRunning && !self.isRunningWithSpecialScene) {
        [super start];
        self.isRunningWithSpecialScene = YES;
        [self monitorRunWithSpecialScene];
    }
}
    
- (void)leaveSpecialScene {
    if (self.isRunning && self.isRunningWithSpecialScene) {
        [super stop];
        self.isRunningWithSpecialScene = NO;
        self.lastSpecialScene = nil;
        [self monitorStopWithSpecialScene];
    }
}

- (void)monitorRunWithSpecialScene {
    [self startWithInterval:_refreshInterval];
}
    
- (void)monitorStopWithSpecialScene {
    [self setTimerRefresh:0.0];  // zero means stop the timer
}

// special scene listen
- (void)listenEnterSpecialSceneToOpenMonitor:(NSString *)scene {
    if(!scene || ! self.inSpecialSceneListening) {
        return;
    }
    
    BOOL isSpecialScene = [((HMDMonitorConfig *)self.config).customOpenScene hmd_boolForKey:scene];
    // 监控没有开启 触发开启
    if(!self.isRunningWithSpecialScene && isSpecialScene) {
        [self enterSpecialScene];
        self.lastSpecialScene = scene;
        return;
    }
    
    if(self.isRunningWithSpecialScene && !isSpecialScene) {
        [self leaveSpecialScene];
    }
}

- (void)listenLeaveSpecialSceneToOpenMonitor:(NSString *)scene {
    if(!scene || !self.inSpecialSceneListening) {
        return;
    }
    
    BOOL isSpecialScene = [((HMDMonitorConfig *)self.config).customOpenScene hmd_boolForKey:scene];
    if(isSpecialScene &&
       self.isRunningWithSpecialScene &&
       self.lastSpecialScene &&
       [self.lastSpecialScene isEqualToString:scene]) {
        [self leaveSpecialScene];
    }
}

@end
