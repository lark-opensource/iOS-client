//
//  HMDOTTrace.m
//  Pods
//
//  Created by fengyadong on 2019/12/11.
//

#import "HMDOTTrace.h"
#import "HMDOTSpan.h"
#import "HMDOTTraceConfig.h"
#import "HMDMacro.h"
#import "HMDOTManager.h"
#import "Heimdallr+Private.h"
#import "HMDInfo+AppInfo.h"
#import "HMDInfo+SystemInfo.h"
#import "HMDSessionTracker.h"
#import "HMDOTConfig.h"
#import "NSDate+HMDAccurate.h"
#import "HMDALogProtocol.h"
#import "HMDOTBridge.h"
#import "HMDOTTraceConfig+Tools.h"
#import "HMDMacro.h"
CLANG_DIAGNOSTIC_PUSH
CLANG_DIAGNOSTIC_IGNORE_STRICT_PROTOTYPES
#import <Hermas/Hermas.h>
CLANG_DIAGNOSTIC_POP
#import "HMDOTManager2.h"
#import "HMDHermasManager.h"

#include "pthread_extended.h"

NSUInteger hmd_hit_rules_all = 0x01;
NSUInteger hmd_hit_rules_error = 0x10;

static BOOL kHMDIgnoreUnfinishedAssert = NO;

@interface HMDOTTrace ()

@property (nonatomic, assign, readwrite) NSUInteger localID;
@property (nonatomic, assign) NSUInteger sequenceCode;
@property (nonatomic, copy, readwrite) NSString *serviceName;
@property (nonatomic, copy, readwrite) NSString *traceID;
@property (nonatomic, assign, readwrite) long long startTimestamp;
@property (nonatomic, assign, readwrite) long long finishTimestamp;
@property (nonatomic, copy, readwrite) NSString *appVersion;
@property (nonatomic, copy, readwrite) NSString *updateVersionCode;
@property (nonatomic, copy, readwrite) NSString *osVersion;
@property (nonatomic, copy, readwrite) NSString *sessionID;
@property (nonatomic, assign, readwrite) NSUInteger isFinished;//trace是否结束，默认0
@property (nonatomic, assign, readwrite) NSUInteger hitRules;
@property (nonatomic, strong, readwrite) NSNumber *sampleRate;
@property (atomic, assign, readwrite) BOOL isForcedUpload; /*当前trace是否是强制命中采样并上报*/
@property (atomic, copy, readwrite) NSDictionary<NSString*, NSString*> *tags;
@property (atomic, assign, readwrite) BOOL needCache;/*是否发生在HMDOTManager启动之前*/
@property (atomic, assign, readwrite) BOOL isAbandoned; /*当前的 Trace 是否无效了*/
@property (nonatomic, strong, readwrite) NSMutableArray <HMDOTSpan *>*cachedSpans;
@property (nonatomic, strong, readwrite) NSMutableArray <NSString *>*spanIdList;
@property (nonatomic, strong, readwrite) NSLock *cacheLock;
@property (nonatomic, strong, readwrite) NSLock *idListLock;
@property (nonatomic, assign, readwrite) HMDOTTraceInsertMode insertMode;/*写入模式*/
@property (nonatomic, assign, readwrite) BOOL isMovingLine;
@property (nonatomic, copy, readwrite) NSString *traceType;

// 未命中采样动线日志的缓存
@property (nonatomic, strong) NSMutableArray <HMDOTSpan *> *cacheUnHitSpans;

#ifdef DEBUG
@property (nonatomic, assign) BOOL ignoreAssert;
#endif
@end

@implementation HMDOTTrace {
    pthread_rwlock_t _cacheUnHitLock;
}

+ (void)ignoreUnfinishedTraceAssert {
    kHMDIgnoreUnfinishedAssert = YES;
}

+ (void)enableDebugUpload {
    if (hermas_enabled()) {
        [[HMDOTManager2 sharedInstance] enableDebugUpload];
    } else {
        [[HMDOTManager sharedInstance] enableDebugUpload];
    }
}

+ (void)initialize {
    if (self == [HMDOTTrace class]) {
        [HMDHermasManager defaultManager];
    }
}

+ (instancetype)startTrace:(NSString *)serviceName
                 startDate:(NSDate *)startDate
                insertMode:(HMDOTTraceInsertMode)insertMode {
    
    if (hermas_enabled()) {
        if ([HMDOTManager2 sharedInstance].hasStopped) return nil;
    } else {
        if ([HMDOTManager sharedInstance].hasStopped) return nil;
    }
    
    NSAssert(serviceName, @"serviceName cannot be nil.");
    if (!serviceName) {
        if (hmd_log_enable()) {
           HMDALOG_PROTOCOL_ERROR_TAG(@"Heimdallr", @"HMDOTTrace Error: serviceName can not be nil.");
        }
        return nil;
    }
    HMDOTTraceConfig *traceConfig = [[HMDOTTraceConfig alloc] initWithServiceName:serviceName];
    traceConfig.startDate = startDate;
    traceConfig.insertMode = insertMode;
    HMDOTTrace *trace = [self startTraceWithConfig:traceConfig];
    return trace;
}

+ (instancetype)startTrace:(NSString *)serviceName startDate:(NSDate *)startDate {
    return [self startTrace:serviceName startDate:startDate insertMode:HMDOTTraceInsertModeEverySpanStart];
}

+ (instancetype)startTrace:(NSString *)serviceName {
    HMDOTTrace *trace = [self startTrace:serviceName startDate:[NSDate hmd_accurateDate]];
    return trace;
}

+ (instancetype)startTraceWithConfig:(HMDOTTraceConfig *)traceConfig {
    if (hermas_enabled()) {
        if ([HMDOTManager2 sharedInstance].hasStopped) return nil;
    } else {
        if ([HMDOTManager sharedInstance].hasStopped) return nil;
    }
    
    NSAssert(traceConfig, @"trace config cannot be nil.");
    if (!traceConfig) {
        if (hmd_log_enable()) {
           HMDALOG_PROTOCOL_ERROR_TAG(@"Heimdallr", @"HMDOTTrace Error: trace config can not be nil.");
        }
        return nil;
    }
    
    HMDOTTrace *trace = [[HMDOTTrace alloc] initWithTraceConfig:traceConfig];
    [trace updateHitRules];
    
    if (hermas_enabled()) {
        [trace decideInsertPolicy];
    } else {
        [trace decideInsertPolicyWithMode:traceConfig.insertMode];
    }

  
    
    [[HMDOTBridge sharedInstance] registerTrace:trace forTraceID:trace.traceID];
    
#ifdef DEBUG
    __weak typeof(trace) weakTrace = trace;
    __block int index = 0;
    dispatch_source_t timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_global_queue(0, 0));
    dispatch_source_set_timer(timer, DISPATCH_TIME_NOW, 1.0 * NSEC_PER_SEC, 0.0 * NSEC_PER_SEC);
    dispatch_source_set_event_handler(timer, ^{
        index++;
        if(index == 120) {
            dispatch_suspend(timer);
            __strong typeof(weakTrace) strongTrace = weakTrace;
            if (strongTrace && !strongTrace.ignoreAssert && !kHMDIgnoreUnfinishedAssert) {
                NSAssert(strongTrace.isFinished == 1 || strongTrace.isAbandoned == 1, @"trace:%@ did not finish after it is started more than 120 seconds，please make sure call the finish method if it is already finished", strongTrace.serviceName);
            }
        }
    });
    dispatch_resume(timer);
#endif
    
    return trace;
}

- (instancetype)initWithTraceConfig:(HMDOTTraceConfig *)traceConfig {
    self = [super init];
    if (self) {
        pthread_rwlock_init(&_cacheUnHitLock, NULL);
        self.serviceName = traceConfig.serviceName;
        self.traceID = [traceConfig generateTraceID];
        
        self.isForcedUpload = traceConfig.isForcedUplaod;
        
        self.isMovingLine = traceConfig.isMovingLine;
        self.traceType = traceConfig.type;
        
        if (traceConfig.startDate) {
            self.startTimestamp = MilliSecond([traceConfig.startDate timeIntervalSince1970]);
        } else {
            self.startTimestamp = MilliSecond([[NSDate hmd_accurateDate] timeIntervalSince1970]);
        }
        self.appVersion = [HMDInfo defaultInfo].shortVersion;
        self.updateVersionCode = [HMDInfo defaultInfo].buildVersion;
        self.osVersion = [HMDInfo defaultInfo].systemVersion;
        self.sessionID = [HMDSessionTracker sharedInstance].eternalSessionID;
        self.tags = [NSDictionary dictionary];
        self.cachedSpans = [NSMutableArray array];
        self.spanIdList = [NSMutableArray array];
        self.cacheLock = [[NSLock alloc] init];
        self.idListLock = [[NSLock alloc] init];
        
        self.cacheUnHitSpans = [NSMutableArray array];
    }
    return self;
}

- (void)decideInsertPolicyWithMode:(HMDOTTraceInsertMode)insertMode {
    BOOL modeValid = insertMode <=2;
    NSAssert(modeValid, @"Value of insertMode is in the range from 0 to 2. The trace is: %@", self.serviceName);
    self.insertMode = insertMode;
    if (![HMDOTManager sharedInstance].isValid || insertMode == HMDOTTraceInsertModeAllSpanBatch || !modeValid) {
        self.needCache = YES;
    } else {
        //只有在HMDOTManager模块启动之后且插入模式是spanstart或者是everySpanFinish才需要插入一个占位的trace
        [[HMDOTManager sharedInstance] insertTrace:self];
    }
}

- (void)dealloc {
#ifdef DEBUG
    if (!self.isReporting && !self.isAbandoned) {
        NSAssert(self.isFinished == 1, @"Trace:%@ hasn't finished yet when it is destroyed. Please confirm that you will manually invoke finish method after the trace finishes.", self.serviceName);
    }
#endif
}


- (void)updateHitRules {
    if (self.isForcedUpload) {
        self.hitRules = 1;
        self.sampleRate = @(1);
        return;
    }
    NSInteger hitRules = 0;
    
    HMDOTConfig *config;
    if (hermas_enabled()) {
        config = [HMDOTManager2 sharedInstance].enternalConfig;
    } else {
        config = [HMDOTManager sharedInstance].enternalConfig;
    }
    
    NSNumber *sampleRate = [config.allowServiceList objectForKey:self.serviceName];
    //没有该serviceName时sampleRate为nil
    if (![sampleRate isKindOfClass:[NSNumber class]]) {
        sampleRate = [NSNumber numberWithInteger:0];
    }
    
    NSDecimalNumber *zeroDecimal = [[NSDecimalNumber alloc] initWithDouble:0.0];
    NSDecimalNumber *sampleDemical = [NSDecimalNumber decimalNumberWithDecimal:[sampleRate decimalValue]];
    
    if(sampleRate && [sampleRate isKindOfClass:[NSNumber class]] && [zeroDecimal compare:sampleDemical] ==  NSOrderedAscending) {
        hitRules |= hmd_hit_rules_all;
    }
    
    NSNumber *errorRate = [config.allowErrorList objectForKey:self.serviceName];
    if (![errorRate isKindOfClass:[NSNumber class]]) {
        errorRate = [NSNumber numberWithInteger:0];
    }
    NSDecimalNumber *errorDecimal = [NSDecimalNumber decimalNumberWithDecimal:[errorRate decimalValue]];
    
    if(self.hasError && (!errorRate || ([errorRate isKindOfClass:[NSNumber class]] && [zeroDecimal compare:errorDecimal] ==  NSOrderedAscending))) {
        hitRules |= hmd_hit_rules_error;
    }
    
    self.hitRules = hitRules;
    self.sampleRate = sampleRate;
}

- (void)resetTraceStartDate:(NSDate *)startDate {
    if (!startDate) { return; }
    if (self.isFinished == 1) { return; }
    self.startTimestamp = MilliSecond([startDate timeIntervalSince1970]);
}

- (void)finish {
    [self finishWithDate:nil];
}

-(void)finishWithDate:(NSDate *_Nullable)finishDate {
    if (self.isFinished == 1) { // 只调用一次结束 第二次调用无效
        if (hmd_log_enable()) {
           HMDALOG_PROTOCOL_ERROR_TAG(@"Heimdallr", @"HMDOTTrace Error: trace name:%@, Call finish method once only!!!", self.serviceName);
        }
        return;
    }
    
    finishDate = finishDate ?: [NSDate hmd_accurateDate];
    self.finishTimestamp = MilliSecond([finishDate timeIntervalSince1970]);
    NSAssert((self.finishTimestamp >= self.startTimestamp), @"Finish time can not be less than the start time. The trace is: %@", self.serviceName);
    
    self.isFinished = 1;
    //trace中间任意一个span可能发生error，所以hit_rules要更新
    [self updateHitRules];
    if (self.isAbandoned) { return; }
    if (hermas_enabled()) {
        [[HMDOTManager2 sharedInstance] finishTrace:self];
    } else {
        if (self.needCache) {
            [[HMDOTManager sharedInstance] insertTrace:self];
        } else {
            [[HMDOTManager sharedInstance] replaceTrace:self];
        }
    }

    [[HMDOTBridge sharedInstance] removeTraceID:self.traceID];
}

- (void)finishAfterDelay:(NSTimeInterval)delay {
    dispatch_time_t time = dispatch_time(DISPATCH_TIME_NOW, delay * NSEC_PER_SEC);
    dispatch_after(time, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self finish];
    });
}

- (void)setTag:(NSString *)key value:(NSString *)value {
    if (!key || !value)  {
        return;
    }
    
    if (![value isKindOfClass:[NSString class]]) {
        return;
    }
    
    NSMutableDictionary <NSString*, NSString*> *mutableTags = [NSMutableDictionary dictionaryWithDictionary:self.tags];
    [mutableTags setValue:value forKey:key];
    self.tags = mutableTags;
}

- (NSDictionary *)reportDictionary {
    NSMutableDictionary *dataValue = [NSMutableDictionary dictionary];
    [dataValue setValue:@"tracer" forKey:@"log_type"];
    [dataValue setValue:self.serviceName forKey:@"service"];
    [dataValue setValue:self.traceID forKey:@"trace_id"];
    [dataValue setValue:@(self.startTimestamp) forKey:@"start_timestamp"];
    [dataValue setValue:@(self.finishTimestamp) forKey:@"finish_timestamp"];
    [dataValue setValue:self.appVersion forKey:@"app_version"];
    [dataValue setValue:self.updateVersionCode forKey:@"update_version_code"];
    [dataValue setValue:self.osVersion forKey:@"os_version"];
    [dataValue setValue:@(1) forKey:@"report_mode"];
    [dataValue setValue:self.sampleRate forKey:@"sample_rate"];
    [dataValue setValue:@(self.hitRules) forKey:@"hit_rules"];
    [dataValue setValue:self.tags forKey:@"tags"];
    [dataValue setValue:@(self.isFinished) forKey:@"is_finished"];
    [dataValue setValue:@(self.insertMode) forKey:@"insert_mode"];
    
    if (hermas_enabled() && self.sequenceCode >= 0) {
        [dataValue setValue:@(self.sequenceCode) forKey:@"sequence_code"];
    }
    
    if (self.isMovingLine) {
        NSMutableDictionary *movingLine = [NSMutableDictionary dictionary];
        [movingLine setValue:self.traceType forKey:@"trace_type"];
        [dataValue setValue:[movingLine copy] forKey:@"movingline"];
    }
    
    return [dataValue copy];
}

- (NSArray<HMDOTSpan *> *)allCachedSpans {
    [self.cacheLock lock];
    NSArray<HMDOTSpan *> *spans = [self.cachedSpans copy];
    [self.cacheLock unlock];
    
    return spans;
}

- (void)cacheOneSpan:(HMDOTSpan *)span {
    if (self.isAbandoned) { return; }
    [self.cacheLock lock];
    if (span) {
        [self.cachedSpans addObject:span];
    }
    [self.cacheLock unlock];
}

- (void)cacheCallbackSpans:(NSArray<HMDOTSpan *> *)spans {
    if (self.isAbandoned) { return; }
    [self.cacheLock lock];
    if (spans.count > 0) {
        [self.cachedSpans addObjectsFromArray:spans];
    }
    [self.cacheLock unlock];
}

- (NSArray<NSString *> *)obtainSpanIDList {
    [self.idListLock lock];
    NSArray<NSString *> *spanIDList = [self.spanIdList copy];
    [self.idListLock unlock];
    return spanIDList;
}

- (void)addOneSpanID:(NSString *)spanID {
    if (self.isAbandoned) { return; }
    [self.idListLock lock];
    if (spanID) {
        [self.spanIdList addObject:spanID];
    }
    [self.idListLock unlock];
}

- (BOOL)needCacheUnHit {
    BOOL needCacheUnHit = hermas_enabled() && self.isMovingLine && (self.hitRules != hmd_hit_rules_all) && [HMDOTManagerConfig defaultConfig].enableCacheUnHitLog;
    return needCacheUnHit;
}

- (void)cacheOneSpanUnHit:(HMDOTSpan *)span {
    if (![self needCacheUnHit]) return;
    pthread_rwlock_wrlock(&_cacheUnHitLock);
    if (span) {
        [self.cacheUnHitSpans addObject:span];
    }
    pthread_rwlock_unlock(&_cacheUnHitLock);
}

- (NSArray<HMDOTSpan *> *)obtainSpansUnHit {
    NSArray<HMDOTSpan *> *cacheUnHitSpans = [NSArray array];
    if ([self needCacheUnHit]) {
        pthread_rwlock_rdlock(&_cacheUnHitLock);
        cacheUnHitSpans = [self.cacheUnHitSpans copy];
        pthread_rwlock_unlock(&_cacheUnHitLock);
    }
    return cacheUnHitSpans;
}

+ (void)uploadCache {
    if (hermas_enabled()) {
        [[HMDOTManager2 sharedInstance] uploadCache];
    }
}

- (void)abandonCurrentTrace {
    self.isAbandoned = YES;
    
    if (hermas_enabled()) {
        [[HMDOTManager2 sharedInstance] cleanupTrace:self];
    } else {
        [[HMDOTManager sharedInstance] cleanupCachedTrace:self];
    }
    
    [self.cacheLock lock];
    [self.cachedSpans removeAllObjects];
    [self.cacheLock unlock];
}

- (NSDictionary<NSString*, NSString*> *)obtainTraceTags {
    return self.tags;
}

#ifdef DEBUG
- (void)ignoreUnfinishedTraceAssert {
    self.ignoreAssert = YES;
}
#endif

# pragma refactor
- (void)decideInsertPolicy {
    if (![HMDOTManager2 sharedInstance].isValid) {
        self.needCache = YES;
    } else {
        //只有在HMDOTManager模块启动之后且插入模式是spanstart或者是everySpanFinish才需要插入一个占位的trace
        [[HMDOTManager2 sharedInstance] startTrace:self];
    }
}

# pragma todo deprecated
+ (NSArray *)bg_ignoreKeys {
    return @[@"latestSpanID",@"needCache",@"cachedSpans",@"cacheLock",@"isAbandoned",@"idListLock",@"cacheUnHitLock",@"cacheUnHitSpans"];
}

+ (NSString *)tableName {
    return NSStringFromClass(self);
}

@end
