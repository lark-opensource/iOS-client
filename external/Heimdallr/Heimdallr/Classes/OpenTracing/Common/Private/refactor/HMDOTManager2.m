//
//  HMDOTManager2.m
//  Heimdallr-8bda3036
//
//  Created by liuhan on 2022/4/18.
//


#import "HMDOTManager2.h"
#import "HMDOTTrace.h"
#import "HMDOTSpan.h"
#import "Heimdallr+Private.h"
#import "HMDOTConfig.h"
#import "Heimdallr+Private.h"
#import "Heimdallr+ModuleCallback.h"
#import "HMDOTTrace+Private.h"
#import "hmd_debug.h"
#import "HMDGCD.h"
#import "NSDictionary+HMDSafe.h"
#import "HMDOTTraceConfig.h"
#import "HMDOTTraceConfig+Private.h"
#import "HMDOTSpan+Private.h"
#import "HMDHermasHelper.h"
#import "HMDHermasManager.h"
#import "HMDHermasHelper.h"
#import "HMDMacro.h"
CLANG_DIAGNOSTIC_PUSH
CLANG_DIAGNOSTIC_IGNORE_STRICT_PROTOTYPES
#import <Hermas/Hermas.h>
CLANG_DIAGNOSTIC_POP
// Utility
#import "HMDMacroManager.h"
#include "pthread_extended.h"
#import "HMDDynamicCall.h"
// PrivateServices
#import "HMDURLSettings.h"

const NSUInteger kHMDMaxTraceCacheSize2 = 100;
static BOOL kHMDEnableDebugUpload2 = NO;

@interface HMDOTManager2 ()

@property (nonatomic, strong, readwrite) dispatch_queue_t spanIOQueue;
@property (atomic, strong, readwrite) HMDOTConfig *enternalConfig;
@property (atomic, assign, readwrite) BOOL hasStopped;
@property (nonatomic, strong, readwrite) NSMutableArray <HMDOTTrace *>*cachedTraces; // 存储未拉取配置时创建的trace
@property (nonatomic, strong) HMInstance *traceInstance;
@property (nonatomic, strong) NSMutableDictionary <NSString*, HMDOTTrace*> *cachedUnHitTraces; // 存储未命中采样的动线trace

@end

@implementation HMDOTManager2

// 获取单例
+ (instancetype)sharedInstance {
    static HMDOTManager2 *sharedTracker = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedTracker = [[HMDOTManager2 alloc] init];
    });
    return sharedTracker;
}

- (instancetype)init {
    if (self = [super init]) {
        _spanIOQueue = dispatch_queue_create("com.heimdallr.spanioqueue", DISPATCH_QUEUE_SERIAL);
        _cachedTraces = [NSMutableArray array];
        _cachedUnHitTraces = [NSMutableDictionary dictionary];
        
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
    
    hmd_safe_dispatch_async(self.spanIOQueue, ^{
        [HMDHermasManager defaultManager];
        HMInstanceConfig *config = [[HMInstanceConfig alloc] initWithModuleId:kModuleOpenTraceName aid:[HMDInjectedInfo defaultInfo].appID];
        config.enableSemiFinished = YES;
        self.traceInstance = [[HMEngine sharedEngine] instanceWithConfig:config];
        [self insertAllCachedTracesWhenValid];
    });
    
    return self;
}

// 师傅需要同步启动
- (BOOL)needSyncStart {
    return YES;
}

// 模块启动
- (void)start {
    [super start];
}

// 模块停滞
- (void)stop {
    [super stop];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

// 更新配置
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

// 启动并且已经获取到采样率 && 非debug返回真
- (BOOL)isValid {
    static BOOL isDebugging = NO;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        isDebugging = HMD_IS_DEBUG || hmddebug_isBeingTraced();
    });
    
    //debug模式下默认不写日志，防止因为打断点等操作导致上报脏数据
    if(isDebugging && !kHMDEnableDebugUpload2) {
        return NO;
    }
    return self.heimdallr && self.enternalConfig;
}

- (void)startTrace:(HMDOTTrace *)trace {
    if(!trace) return;
    hmd_safe_dispatch_async(self.spanIOQueue, ^{
        if (trace.needCache) {
            return;
        }
        
        if ([trace needCacheUnHit]) {
            [self.cachedUnHitTraces hmd_setObject:trace forKey:trace.traceID];
        }
        
        if (trace.hitRules > 0) {
            [self.traceInstance startSemiTraceRecord:[trace reportDictionary]];
        }
    });
}

- (void)finishTrace:(HMDOTTrace *)trace {
    if (!trace) {
        return;
    }
    if(trace.needCache) {
        [self.cachedTraces addObject:trace];
        //限制缓存数量，防止极端情况下内存无限增长
        if(self.cachedTraces.count > kHMDMaxTraceCacheSize2) {
            [self.cachedTraces removeObjectAtIndex:0];
        }
        //每次缓存的trace结束的时候也尝试写入，否则仅依赖配置更新的时机可能导致缓存的trace一直没有机会写入
        [self insertAllCachedTracesWhenValid];
        return;
    };
    if ([trace needCacheUnHit]) {
        // 将trace和所有span落盘
        [self.traceInstance recordLocal:[trace reportDictionary] forceSave:YES];
        NSArray *cacheSpansUnHit = [trace obtainSpansUnHit];
        [cacheSpansUnHit enumerateObjectsUsingBlock:^(HMDOTSpan *  _Nonnull span, NSUInteger idx, BOOL * _Nonnull stop) {
            [self.traceInstance recordLocal:[span reportDictionary] forceSave:YES];
        }];
        
        [self.cachedUnHitTraces removeObjectForKey:trace.traceID ?: @""];
        
    } else if ((trace.hitRules == hmd_hit_rules_error && !trace.hasError)) {
        // 命中了error_rule的trace在start时会落盘，如果没有发生error，应该在finish清理
        [self cleanupPlaceholderForTrace:trace];
    } else {
        hmd_safe_dispatch_async(self.spanIOQueue, ^{
            [self.traceInstance finishSemiTraceRecord:[trace reportDictionary] WithSpanIdList:[trace obtainSpanIDList]];
        });
    }
}

- (void)startSpan:(HMDOTSpan *)span {
    if(!span) return;
    hmd_safe_dispatch_async(self.spanIOQueue, ^{
        if (span.trace.needCache) {
            [span.trace cacheOneSpan:span];
        } else if ([span.trace needCacheUnHit]) {
            [span.trace cacheOneSpanUnHit:span];
            [self checkCacheUnHitSpansCount];
        } else if (span.trace.hitRules > 0) {
            [self.traceInstance startSemiSpanRecord:[span reportDictionary]];
        }
    });
}

- (void)finishSpan:(HMDOTSpan *)span {
    if(!span) return;
    if(span.trace.needCache) {
        [span.trace cacheOneSpan:span];
    } else if (span.isInstant && [span.trace needCacheUnHit]) {
        [span.trace cacheOneSpanUnHit:span];
        [self checkCacheUnHitSpansCount];
    }
    if(span.trace.hitRules == 0) return;
    if (span.isInstant) {
        [span.trace addOneSpanID:span.spanID];
    }
    hmd_safe_dispatch_async(self.spanIOQueue, ^{
        [self.traceInstance finishSemiSpanRecord:[span reportDictionary]];
    });
    
}

- (void)checkCacheUnHitSpansCount {
    hmd_safe_dispatch_async(self.spanIOQueue, ^{
        __block NSInteger count = 0;
        [self.cachedUnHitTraces enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull traceID, HMDOTTrace * _Nonnull trace, BOOL * _Nonnull stop) {
            count = count + [trace obtainSpansUnHit].count;
            if (count >= HMDOTManagerConfig.defaultConfig.maxMemoryCacheCount){
                [[HMDOTManagerConfig defaultConfig] invokeMemoryCacheCallback];
                *stop = YES;
            }
        }];
        
    });
}

// 写入cached trace
- (BOOL)insertCachedTrace:(HMDOTTrace *)trace {
    NSAssert(trace.needCache, @"Only traces already cached can invoke this method!");
    if (trace.needCache && trace.isFinished == 0)  return NO;
    if(trace.hitRules == 0) return NO;
    BOOL result = NO;
    for (HMDOTSpan *span in trace.allCachedSpans) {
        [self.traceInstance finishSemiSpanRecord:[span reportDictionary]];
    }
    [self.traceInstance finishSemiTraceRecord:[trace reportDictionary] WithSpanIdList:[trace obtainSpanIDList]];
    result = true;
    return result;
}

// cachedTraces落盘
- (void)insertAllCachedTracesWhenValid {
    //还没有拉到配置时采样率不确定，需要等待下一个时机
    if (![self isValid]) return;
    hmd_safe_dispatch_async(self.spanIOQueue, ^{
        for(NSInteger i = 0; i < self.cachedTraces.count; i++) {
            HMDOTTrace *trace = self.cachedTraces[i];
            //缓存起来的trace需要挨个更新是否采样命中的标志
            [trace updateHitRules];
            
            if(trace.hitRules > 0) {
                //缓存起来需要上报的，上报完成之后清理
                BOOL isSccess = [self insertCachedTrace:trace];
                if (isSccess) {
                    [self.cachedTraces removeObject:trace];
                }
            } else if (trace.needCacheUnHit) {
                [self.cachedUnHitTraces hmd_setObject:trace forKey:trace.traceID];
                [self.cachedTraces removeObject:trace];
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

- (void)cleanupTrace:(HMDOTTrace *)trace {
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
        [self.traceInstance deleteSemifinishedRecords:trace.traceID WithSpanIdList:[trace obtainSpanIDList]];
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

- (void)enableDebugUpload {
    kHMDEnableDebugUpload2 = YES;
}

- (void)uploadCache {
    hmd_safe_dispatch_async(self.spanIOQueue, ^{
        [self.traceInstance UploadLocalData];
        [[HMEngine sharedEngine] uploadLocalDataWithModuleId:kModulePerformaceName];
    });
}

@end

