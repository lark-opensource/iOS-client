//
//  HMDOTManager.m
//  Pods
//
//  Created by fengyadong on 2019/12/12.
//

#import "HMDOTManager.h"
#import "HMDOTTrace.h"
#import "HMDOTSpan.h"
#import "Heimdallr+Private.h"
#import "HMDOTConfig.h"
#import "HMDPerformanceReporterManager.h"
#import "HMDWeakProxy.h"
#import "Heimdallr+Private.h"
#import "HMDUploadHelper.h"
#import "Heimdallr+ModuleCallback.h"
#import "HMDOTTrace+Private.h"
#import "hmd_debug.h"
#import "HMDGCD.h"

#import "HMDMacro.h"
CLANG_DIAGNOSTIC_PUSH
CLANG_DIAGNOSTIC_IGNORE_STRICT_PROTOTYPES
#import <Hermas/Hermas.h>
CLANG_DIAGNOSTIC_POP
#import "HMDHermasHelper.h"
// Utility
#import "HMDMacroManager.h"
// PrivateServices
#import "HMDServerStateService.h"
#import "HMDURLSettings.h"

static BOOL needDropOpenTraceData(void) {
    BOOL needDrop = hermas_enabled() ? hermas_drop_data(kModuleOpenTraceName) : hmd_drop_data(HMDReporterOpenTrace);
    return needDrop;
}

const NSUInteger kHMDMaxTraceCacheSize = 100;
static BOOL kHMDEnableDebugUpload = NO;

@interface HMDOTManager ()<HMDNetworkProvider, HMDPerformanceReporterDataSource>

@property (nonatomic, strong, readwrite) dispatch_queue_t spanIOQueue;
@property (nonatomic, strong, readwrite) HMDPerformanceReporter *tracingReporter;
@property (atomic, strong, readwrite) HMDOTConfig *enternalConfig;
@property (atomic, assign, readwrite) BOOL hasStopped;
@property (nonatomic, strong, readwrite) NSMutableArray <HMDOTTrace *>*cachedTraces;

@end

@implementation HMDOTManager

+ (instancetype)sharedInstance {
    static HMDOTManager *sharedTracker = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedTracker = [[HMDOTManager alloc] init];
    });
    return sharedTracker;
}

- (instancetype)init {
    if (self = [super init]) {
        _spanIOQueue = dispatch_queue_create("com.heimdallr.spanioqueue", DISPATCH_QUEUE_SERIAL);
        _cachedTraces = [NSMutableArray array];
        //如果此时还没拉到远程配置，需要监听时机，判断此模块到底需不需要开启
        if (![Heimdallr shared].isRemoteReady) {
            [[Heimdallr shared] addObserver:self forKeyPath:NSStringFromSelector(@selector(isRemoteReady)) options:NSKeyValueObservingOptionNew|
            NSKeyValueObservingOptionOld context:nil];
        } else {
            [[Heimdallr shared] addObserverForModule:kHMDModuleOpenTracingTracker usingBlock:^(id<HeimdallrModule>  _Nullable module, BOOL isWorking) {
                self.hasStopped = !isWorking;
                if(self.hasStopped) {
                    [self cleanupCachedTraces];
                }
            }];
        }
    }
    
    return self;
}

- (Class<HMDRecordStoreObject>)storeClass {
    return [HMDOTSpan class];
}

- (BOOL)needSyncStart {
    return YES;
}

- (void)start {
    [super start];
    self.tracingReporter = [[HMDPerformanceReporter alloc] initWithProvider:(id<HMDNetworkProvider>)[HMDWeakProxy proxyWithTarget:self]];
    [self.tracingReporter addReportModuleSafe:(id<HMDPerformanceReporterDataSource>)[HMDWeakProxy proxyWithTarget:self]];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(performanceReportSuccessed:) name:HMDPerformanceReportSuccessNotification object:nil];
    [self insertAllCachedTracesWhenValid];
}

- (void)stop {
    [super stop];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)updateConfig:(HMDModuleConfig *)config {
    [super updateConfig:config];
    static dispatch_once_t onceToken;
    if ([config isKindOfClass:[HMDOTConfig class]]) {
        dispatch_once(&onceToken, ^{
            self.enternalConfig = (HMDOTConfig *)config;
        });
    }
    [self insertAllCachedTracesWhenValid];
}

- (BOOL)isValid {
    static BOOL isDebugging = NO;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        isDebugging = HMD_IS_DEBUG || hmddebug_isBeingTraced();
    });
    
    //debug模式下不写日志，防止因为打断点等操作导致上报脏数据
    if(isDebugging && !kHMDEnableDebugUpload) {
        return NO;
    }
    return self.heimdallr && self.enternalConfig;
}

- (void)insertTrace:(HMDOTTrace *)trace {
    if(!trace) return;
    if (needDropOpenTraceData()) {
        [trace abandonCurrentTrace];
        return;
    }
    hmd_safe_dispatch_async(self.spanIOQueue, ^{
        if (trace.needCache) {
            [self.cachedTraces addObject:trace];
            //限制缓存数量，防止极端情况下内存无限增长
            if(self.cachedTraces.count > kHMDMaxTraceCacheSize) {
                [self.cachedTraces removeObjectAtIndex:0];
            }
            //每次缓存的trace结束的时候也尝试写入，否则仅依赖配置更新的时机可能导致缓存的trace一直没有机会写入
            [self insertAllCachedTracesWhenValid];
        }else if (trace.hitRules > 0) {
            [self.heimdallr.database insertObject:trace into:[HMDOTTrace tableName]];
        }
    });
}

- (void)replaceTrace:(HMDOTTrace *)trace {
    if(!trace) return;
    NSAssert(!trace.needCache, @"It can only be replaced after starting the HMDOTManager module and hits reported fully, otherwise it can only be inserted!");
    if(trace.needCache) return;
    if (needDropOpenTraceData()) {
        [trace abandonCurrentTrace];
        return;
    }
    
    if ((trace.hitRules == hmd_hit_rules_error && !trace.hasError) || trace.hitRules == 0) {
        [self cleanupPlaceholderForTrace:trace];
    } else {
        hmd_safe_dispatch_async(self.spanIOQueue, ^{
            HMDStoreCondition *condition = [[HMDStoreCondition alloc] init];
            condition.stringValue = trace.traceID;
            condition.judgeType = HMDConditionJudgeEqual;
            condition.key = @"traceID";
            
            [self.heimdallr.database deleteObjectsFromTable:[HMDOTTrace tableName] andConditions:@[condition] orConditions:nil];
            [self.heimdallr.database insertObject:trace into:[HMDOTTrace tableName]];
            
        });
    }
}

- (void)insertSpan:(HMDOTSpan *)span {
    if(!span) return;
    if (needDropOpenTraceData()) {
        [span.trace abandonCurrentTrace];
        return;
    }
    hmd_safe_dispatch_async(self.spanIOQueue, ^{
        if (span.trace.needCache) {
            [span.trace cacheOneSpan:span];
        } else if (span.trace.hitRules > 0) {
            [self.heimdallr.database insertObject:span into:[self.storeClass tableName]];
        }
    });
}

- (void)replaceSpan:(HMDOTSpan *)span {
    if(!span) return;
    if(span.trace.needCache) return;
    if(span.trace.hitRules == 0) return;
    if (needDropOpenTraceData()) {
        [span.trace abandonCurrentTrace];
        return;
    }
    NSAssert(!span.trace.needCache, @"It can only be replaced after starting the HMDOTManager module and hits reported fully, otherwise it can only be inserted!");
    hmd_safe_dispatch_async(self.spanIOQueue, ^{
        NSMutableArray *conditions = [NSMutableArray array];
        HMDStoreCondition *traceCondtion = [[HMDStoreCondition alloc] init];
        traceCondtion.stringValue = span.traceID;
        traceCondtion.key = @"traceID";
        traceCondtion.judgeType = HMDConditionJudgeEqual;
        [conditions addObject:traceCondtion];
        
        HMDStoreCondition *spanCondtion = [[HMDStoreCondition alloc] init];
        spanCondtion.stringValue = span.spanID;
        spanCondtion.key = @"spanID";
        spanCondtion.judgeType = HMDConditionJudgeEqual;
        [conditions addObject:spanCondtion];
        
        [self.heimdallr.database deleteObjectsFromTable:[self.storeClass tableName] andConditions:conditions orConditions:nil];
        [self.heimdallr.database insertObject:span into:[self.storeClass tableName]];
    });
}

- (void)insertCallbackSpans:(NSArray<HMDOTSpan *> *)spans forTrace:(HMDOTTrace *)trace {
    if(spans.count == 0) return;
    if (needDropOpenTraceData()) {
        [trace abandonCurrentTrace];
        return;
    }
    hmd_safe_dispatch_async(self.spanIOQueue, ^{
        if (trace.needCache) {
            [trace cacheCallbackSpans:spans];
        } else {
            [self.heimdallr.database insertObjects:spans into:[self.storeClass tableName]];
        }
    });
}

- (BOOL)insertCachedTrace:(HMDOTTrace *)trace {
    NSAssert(trace.needCache, @"Only traces already cached can invoke this method!");
    if (trace.needCache && trace.isFinished == 0)  return NO;
    if(trace.hitRules == 0) return NO;
    BOOL traceInsertSuccess = [self.heimdallr.database insertObject:trace into:[HMDOTTrace tableName]];
    BOOL spansInsertSuccess = [self.heimdallr.database insertObjects:trace.allCachedSpans into:[self.storeClass tableName]];
    return traceInsertSuccess && spansInsertSuccess;
}

- (void)insertAllCachedTracesWhenValid {
    //还没有拉到配置时采样率不确定，需要等待下一个时机
    if (![self isValid]) return;
    hmd_safe_dispatch_async(self.spanIOQueue, ^{
        for(NSInteger i = 0;i < self.cachedTraces.count;i++) {
            HMDOTTrace *trace = self.cachedTraces[i];
            //缓存起来的trace需要挨个更新是否采样命中的标志
            [trace updateHitRules];
            
            if(trace.hitRules > 0) {
                //缓存起来需要上报的，上报完成之后清理
                BOOL isSccess = [self insertCachedTrace:trace];
                if (isSccess) {
                    [self.cachedTraces removeObject:trace];
                }
            } else {
                //不需要上报的，也需要清理
                [self.cachedTraces removeObject:trace];
            }
        }
    });
}

- (void)cleanupCachedTraces {
    hmd_safe_dispatch_async(self.spanIOQueue, ^{
        [self.cachedTraces removeAllObjects];
    });
}

- (void)cleanupCachedTrace:(HMDOTTrace *)trace {
    if (!trace) { return;}
    hmd_safe_dispatch_async(self.spanIOQueue, ^{
        [self.cachedTraces removeObject:trace];
        
        if(!trace.needCache) {
            [self cleanupPlaceholderForTrace:trace];
        }
    });
}

- (void)cleanupPlaceholderForTrace:(HMDOTTrace *)trace {
    hmd_safe_dispatch_async(self.spanIOQueue, ^{
        [self.heimdallr.database inTransaction:^BOOL{
            HMDStoreCondition *condition = [[HMDStoreCondition alloc] init];
            condition.stringValue = trace.traceID;
            condition.judgeType = HMDConditionJudgeEqual;
            condition.key = @"traceID";
            
            BOOL deleteTraceSuccess = [self.heimdallr.database deleteObjectsFromTable:[HMDOTTrace tableName] andConditions:@[condition] orConditions:nil];
            BOOL deleteSpanSuccess = [self.heimdallr.database deleteObjectsFromTable:[self.storeClass tableName] andConditions:@[condition] orConditions:nil];
            
            return deleteTraceSuccess && deleteSpanSuccess;
        }];
    });
}
//观察Heimdallr.isRemoteReady是否变更0->1
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if ([keyPath isEqualToString:NSStringFromSelector(@selector(isRemoteReady))]) {
        NSNumber *new = change[NSKeyValueChangeNewKey];
        NSNumber *old = change[NSKeyValueChangeOldKey];
        if (new.boolValue && !old.boolValue) {
            //一次性的监听，后面的变化通过HMDModuleCallback实现
            [[Heimdallr shared] removeObserver:self forKeyPath:NSStringFromSelector(@selector(isRemoteReady))];
            [[Heimdallr shared] addObserverForModule:kHMDModuleOpenTracingTracker usingBlock:^(id<HeimdallrModule>  _Nullable module, BOOL isWorking) {
                self.hasStopped = !isWorking;
                if(self.hasStopped) {
                    [self cleanupCachedTraces];
                }
            }];
        }
    }
}

- (void)prepareForDefaultStart {
    self.config.enableOpen = YES;
}

- (void)performanceReportSuccessed:(NSNotification *)notification {
    if ([notification.object isKindOfClass:NSArray.class]) {
        NSArray *reporterArray = (NSArray *)notification.object;
        if (![reporterArray containsObject:self.tracingReporter] && [reporterArray containsObject:[Heimdallr shared].reporter]) {
            [[HMDPerformanceReporterManager sharedInstance] reportOTDataWithReporter:self.tracingReporter block:NULL];
        }
    }
}

#pragma - mark drop data

- (void)dropAllDataForServerState {
    hmd_safe_dispatch_async(self.spanIOQueue, ^{
        [self.cachedTraces removeAllObjects];
        [self.heimdallr.database deleteAllObjectsFromTable:[HMDOTTrace tableName]];
        [self.heimdallr.database deleteAllObjectsFromTable:[self.storeClass tableName]];
    });
}

#pragma mark HMDNetworkProvider method

- (NSDictionary *)reportHeaderParams {
    return [HMDUploadHelper sharedInstance].headerInfo;
}

- (NSDictionary *)reportCommonParams {
    return [HMDInjectedInfo defaultInfo].commonParams;
}

- (NSString *)reportPerformanceURLPath {
    return @"/monitor/collect/c/trace_collect";
}

- (BOOL)enableBackgroundUpload {
    return YES;
}

- (void)enableDebugUpload {
    kHMDEnableDebugUpload = YES;
}

@end
