//
//  HMDOTSpan.m
//  Pods
//
//  Created by fengyadong on 2019/12/11.
//

#import "HMDOTSpan.h"
#import "HMDOTTrace.h"
#include <pthread.h>
#import "HMDMacro.h"
#import "HMDOTManager.h"
#import "HMDInfo+AppInfo.h"
#import "HMDInfo+SystemInfo.h"
#import "HMDOTTrace+Private.h"
#import "HMDOTTraceDefine.h"
#import "NSDate+HMDAccurate.h"
#import "HMDALogProtocol.h"
#import "HMDOTTraceConfig.h"
#import "HMDOTSpanConfig.h"
#import "HMDOTTraceConfig+Tools.h"
#import "NSDictionary+HMDSafe.h"

#import "HMDOTTraceConfig+Tools.h"
#import "HMDMacro.h"
CLANG_DIAGNOSTIC_PUSH
CLANG_DIAGNOSTIC_IGNORE_STRICT_PROTOTYPES
#import <Hermas/Hermas.h>
CLANG_DIAGNOSTIC_POP
#import "HMDOTManager2.h"

static const int globalTraceVersion = 3;

@interface HMDOTSpan ()<HMDRecordStoreObject>

@property (nonatomic, assign) NSUInteger localID;
@property (nonatomic, assign) NSUInteger sequenceCode;
@property (nonatomic, copy, readwrite) NSString *traceID;//一次完整场景的id，在所有span之间共享
@property (nonatomic, assign) __uint64_t threadID;
@property (nonatomic, copy) NSString *serviceName;//监控的场景名称
@property (nonatomic, copy) NSString *operationName;//一次span的名称，多个span之间可以重复
@property (nonatomic, copy, readwrite) NSString *spanID;//唯一的id，随机数
@property (nonatomic, weak, readwrite) HMDOTTrace *trace;
@property (nonatomic, copy) NSString *parentID;//多层次之间的父节点的spanID，根节点为空
@property (nonatomic, copy) NSString *referenceID;//表示当前span逻辑上的前序span的spanID
@property (nonatomic, assign) long long startTimestamp;
@property (nonatomic, assign) long long finishTimestamp;
@property (atomic, copy) NSArray<NSDictionary *> *logs;
@property (atomic, copy) NSDictionary<NSString*, NSString*> *tags;
@property (nonatomic, assign, readwrite) NSUInteger isFinished;
@property (nonatomic, assign, readwrite) BOOL isInstant;
@property (nonatomic, assign) NSUInteger category;
@property (nonatomic, assign) NSUInteger type;
@property (nonatomic, copy) NSDictionary *data;
@property (nonatomic, copy) NSDictionary *extra;
@property (nonatomic, assign, readwrite) BOOL isMovingLine;
@property (nonatomic, copy) NSString *traceParent;
@property (nonatomic, assign) NSUInteger needReferenceOtherLog;

@end

@implementation HMDOTSpan

+ (instancetype)newRecord {
    HMDOTSpan *span = [self new];
    span.threadID = [[self class] currentThreadID];
    span.startTimestamp = MilliSecond([[NSDate hmd_accurateDate] timeIntervalSince1970]);
    span.logs = [NSArray array];
    span.tags = [NSDictionary dictionary];
    span.isInstant = NO;
    span.category = 10000;
    span.type = 10000;
    span.data = [NSDictionary dictionary];
    span.extra = [NSDictionary dictionary];
    span.isMovingLine = NO;
    span.needReferenceOtherLog = 1;
    
#ifdef DEBUG
    __weak typeof(span) weakSpan = span;
    __block int index = 0;
    dispatch_source_t timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_global_queue(0, 0));
    dispatch_source_set_timer(timer, DISPATCH_TIME_NOW, 1.0 * NSEC_PER_SEC, 0.0 * NSEC_PER_SEC);
    dispatch_source_set_event_handler(timer, ^{
        index++;
        if(index == 120) {
            dispatch_suspend(timer);
            __strong typeof(weakSpan) strongSpan = weakSpan;
            if (strongSpan) {
                NSAssert(strongSpan.isFinished == 1, @"span:%@ did not finish after it is started more than 120 seconds，please make sure call the finish method if it is already finished", strongSpan.operationName);
            }
        }
    });
    dispatch_resume(timer);
#endif
    
    return span;
}

- (void)dealloc {
#ifdef DEBUG
    if (hermas_enabled()) {
        if (self.trace && !self.trace.isAbandoned) {
            NSAssert(self.isFinished == 1, @"span:%@ did not finish when deallocating，please make sure call the finish method if it is already finished!", self.operationName);
        }
    } else {
        if (!self.isReporting && self.trace && !self.trace.isAbandoned) {
            NSAssert(self.isFinished == 1, @"span:%@ did not finish when deallocating，please make sure call the finish method if it is already finished!", self.operationName);
        }
    }
#endif
}

+ (instancetype)startSpanOfTrace:(HMDOTTrace *)trace
                       operationName:(NSString*)operationName {
    HMDOTSpan *span = [self startSpanOfTrace:trace operationName:operationName spanStartDate:[NSDate hmd_accurateDate]];
    return span;
}

+ (instancetype)startSpanOfTrace:(HMDOTTrace *)trace
                   operationName:(NSString *)operationName
                   spanStartDate:(NSDate *)startDate {
    HMDOTSpanConfig *config = [[HMDOTSpanConfig alloc] initWithOperationName:operationName];
    config.startDate = startDate;
    HMDOTSpan *span = [self startSpanOfTrace:trace WithConfig:config];
    return span;
}

+ (instancetype)startSpan:(NSString *)operationName
                  childOf:(HMDOTSpan *)parent {
    HMDOTSpan *span = [self startSpan:operationName childOf:parent spanStartDate:[NSDate hmd_accurateDate]];
    return span;
}

+ (instancetype)startSpan:(NSString *)operationName
                  childOf:(HMDOTSpan *)parent
            spanStartDate:(NSDate *)startDate {
    HMDOTSpanConfig *config = [[HMDOTSpanConfig alloc] initWithOperationName:operationName];
    config.startDate = startDate;
    HMDOTSpan *span = [self startSpanOfParentSpan:parent WithConfig:config];
    return span;
}

+ (instancetype)startSpan:(NSString *)operationName
              referenceOf:(HMDOTSpan *)reference {
    HMDOTSpanConfig *config = [[HMDOTSpanConfig alloc] initWithOperationName:operationName];
    HMDOTSpan *span = [self startSpanOfReferance:reference SpanWithConfig:config];
    return span;
}

- (void)insertPlaceHolderIfNeeded {
    if (hermas_enabled()) {
        [self.trace addOneSpanID:self.spanID];
        [[HMDOTManager2 sharedInstance] startSpan:self];
    } else {
        if (!self.trace.needCache && self.trace.insertMode == HMDOTTraceInsertModeEverySpanStart) {
            [[HMDOTManager sharedInstance] insertSpan:self];
        }
    }
}

- (void)logMessage:(NSString *)message fields:(NSDictionary<NSString*, NSString*>*)fields {
    if(!message && !fields) return;
    
    __block BOOL isFiledsValid = YES;
    [fields enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull obj, BOOL * _Nonnull stop) {
        if (![key isKindOfClass:[NSString class]] || ![obj isKindOfClass:[NSString class]]) {
            isFiledsValid = NO;
            *stop = YES;
        }
    }];
    
    NSAssert(isFiledsValid, @"key and value in parameter fields only support string type, invalid data will be ignored!  the span is: %@ .", self.operationName);
    
    NSMutableDictionary *logItem = [NSMutableDictionary dictionary];
    
    long long timestamp = MilliSecond([[NSDate hmd_accurateDate] timeIntervalSince1970]);
    [logItem setValue:@(timestamp) forKey:@"timestamp"];
    [logItem setValue:message forKey:@"message"];
    if (isFiledsValid) {
        [logItem setValue:fields forKey:@"fields"];
    }
    
    NSMutableArray<NSDictionary *> *mutableLogs = [NSMutableArray arrayWithArray:self.logs];
    [mutableLogs addObject:[logItem copy]];
    self.logs = mutableLogs;
}

- (void)logError:(NSError *)error {
    if (!error) return;
    NSString *errorMsg = [NSString stringWithFormat:@"error_code:%ld, error_message:%@", (long)error.code, error.description];
    [self logErrorWithMessage:errorMsg];
}

- (void)logErrorWithMessage:(NSString *)message {
    if(!message) return;
    [self setTag:@"error" value:message];
}

- (void)setTag:(NSString *)key value:(id)value {
#ifdef DEBUG
    NSDictionary<NSString*, NSString*> * traceTags = [self.trace obtainTraceTags];
    if (traceTags && [traceTags objectForKey:key]) {
        NSAssert(NO, @"Detect the span's tag conflicts with the trace's tags. Please make sure they are identical!, the span is: %@", self.operationName);
    }
#endif
    if (!key || !value)  {
        return;
    }
    
    if (![value isKindOfClass:[NSString class]]) {
        return;
    }
    
    if ([key isEqualToString:@"error"]) {
        self.trace.hasError = 1;
    }
    
    NSMutableDictionary <NSString*, NSString*> *mutableTags = [NSMutableDictionary dictionaryWithDictionary:self.tags];
    [mutableTags setValue:value forKey:key];
    self.tags = mutableTags;
}

- (void)resetSpanStartDate:(NSDate *)startDate {
    if (!startDate) { return; }
    if (self.isFinished) { return; }
    self.startTimestamp = MilliSecond([startDate timeIntervalSince1970]);
}

- (void)finish {
    [self finishWithEndDate:nil];
}

- (void)finishWithEndDate:(NSDate *_Nullable)endDate {
    // span finish请务必在trace finish之前调用，否则可能无法上报
    if (self.trace.isFinished == 1) {
        NSAssert(NO, @"Please call span finish before trace finish!, the span is: %@, the trace is: %@", self.operationName, self.trace.serviceName);
        if (hmd_log_enable()) {
            HMDALOG_PROTOCOL_ERROR_TAG(@"Heimdallr", @"HMDOTSpan Error:span name:%@  Please call span finish before trace finish!", self.operationName);
        }
        return;
    }
    
    // 如果trace已经abandon了，也不能再次调用了
    if (self.trace && self.trace.isAbandoned == 1) {
        NSAssert(NO, @"Please not call span finish after trace abandon!, the span is: %@, the trace is: %@", self.operationName, self.trace.serviceName);
        if (hmd_log_enable()) {
            HMDALOG_PROTOCOL_ERROR_TAG(@"Heimdallr", @"HMDOTSpan Error:span name:%@  Please not call span finish after trace abandon!", self.operationName);
        }
        return;
    }
    
    // 如果已经结束了 就不能再次调用结束了
    if (self.isFinished == 1) {
        if (hmd_log_enable()) {
            HMDALOG_PROTOCOL_ERROR_TAG(@"Heimdallr", @"HMDOTSpan Error:span name:%@  Method named finish can be invoked once only!", self.operationName);
        }
        return;
    }
    
    self.traceParent = [self getTraceParent];
    endDate = endDate ?: [NSDate hmd_accurateDate];
    self.finishTimestamp = MilliSecond([endDate timeIntervalSince1970]);
    NSAssert((self.finishTimestamp >= self.startTimestamp), @"Finish time can not be less than the start time. The span is: %@ and the trace is: %@", self.operationName, self.trace.serviceName);
    
    self.isFinished = 1;

    if (hermas_enabled()) {
        [[HMDOTManager2 sharedInstance] finishSpan:self];
    } else {
        [self writeSpanIfNeedWithNeedReplace:NO];
    }
}

- (void)writeSpanIfNeedWithNeedReplace:(BOOL)needReplace{
    if (self.trace.needCache) {
        [self.trace cacheOneSpan:self];
    } else if (self.trace.insertMode == HMDOTTraceInsertModeEverySpanStart) {
        if (self.isInstant && !needReplace) {
            [[HMDOTManager sharedInstance] insertSpan:self];
        } else {
            [[HMDOTManager sharedInstance] replaceSpan:self];
        }
    } else if (self.trace.insertMode == HMDOTTraceInsertModeEverySpanFinish) {
        [[HMDOTManager sharedInstance] insertSpan:self];
    }
        
}

- (void)finishWithError:(NSError *)error {
    [self logError:error];
    [self finish];
}

- (void)finishWithErrorMsg:(NSString *)message {
    [self logErrorWithMessage:message];
    [self finish];
}

+ (__uint64_t)currentThreadID {
    pthread_t thread = pthread_self();
    __uint64_t thread_id = 0;
    pthread_threadid_np(thread,&thread_id);
    
    //主线程threadID固定是0
    if ([NSThread isMainThread]) {
        thread_id = 0;
    }
    
    return thread_id;
}

#pragma mark - new api for movingline

+ (nullable instancetype)createSpanWithConfig:(HMDOTSpanConfig *)spanConfig {
    
    if (hermas_enabled()) {
        if ([HMDOTManager2 sharedInstance].hasStopped) return nil;
    } else {
        if ([HMDOTManager sharedInstance].hasStopped) return nil;
    }
    
    NSAssert(spanConfig, @"span config cannot be nil");
    NSAssert(spanConfig.trace, @"trace cannot be nil, the current span is: %@ .", spanConfig.operationName);
    NSAssert(!spanConfig.trace.isFinished, @"please call this method before trace finish, the trace is:%@, the span is:%@ .", spanConfig.trace.serviceName, spanConfig.operationName);
    
    if(!spanConfig) {
        if (hmd_log_enable()) {
            HMDALOG_PROTOCOL_ERROR_TAG(@"Heimdallr", @"HMDOTSpan Error: create span failed; reason = spanConfig is nil!");
        }
        return nil;
    }
    if(!spanConfig.trace) {
        if (hmd_log_enable()) {
            HMDALOG_PROTOCOL_ERROR_TAG(@"Heimdallr", @"HMDOTSpan Error: create span failed; reason = spanConfig.tracce is nil; spanName = %@", spanConfig.operationName);
        }
        return nil;
    }
    if(spanConfig.trace.isFinished) {
        if (hmd_log_enable()) {
            HMDALOG_PROTOCOL_ERROR_TAG(@"Heimdallr", @"HMDOTSpan Error: create span failed; reason = spanConfig.trace is finish; spanName = %@, traceName = %@", spanConfig.operationName, spanConfig.trace.serviceName);
        }
        return nil;
    }
    
    HMDOTSpan *span = [self newRecord];
    span.traceID = spanConfig.trace.traceID;
    span.operationName = spanConfig.operationName;
    span.serviceName = spanConfig.trace.serviceName;
    span.spanID = [HMDOTTraceConfig generateRandom16LengthString];
    span.referenceID = spanConfig.trace.latestSpanID;
    span.trace = spanConfig.trace;
    spanConfig.trace.latestSpanID = span.spanID;
    span.isInstant = YES;
    if (spanConfig.startDate) {
        span.startTimestamp = MilliSecond([spanConfig.startDate timeIntervalSince1970]);
    }
    if (spanConfig.error) {
        [span logError:spanConfig.error];
    }
    if (spanConfig.errMsg) {
        [span logErrorWithMessage:spanConfig.errMsg];
    }
    if (spanConfig.tags) {
        [spanConfig.tags enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull value, BOOL * _Nonnull stop) {
            [span setTag:key value:value];
        }];
    }
    if (spanConfig.logs) {
        [spanConfig.logs enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull log, NSUInteger idx, BOOL * _Nonnull stop) {
            @autoreleasepool {
                NSString *logMsg = log.allKeys.firstObject;
                NSDictionary *fields = [log valueForKey:logMsg];
                [span logMessage:logMsg fields:fields];
            }
        }];
    }
    
    [span finish];
    
    return span;
}

- (NSString *)getTraceParent {
    int flags = self.trace.hitRules ? 1 : 0;
    NSString *traceParent = [NSString stringWithFormat:@"%@", [[NSString alloc] initWithFormat:@"%02x-%@-%@-%02x", globalTraceVersion, self.trace.traceID, self.spanID, flags]];
    if (!traceParent || [traceParent isKindOfClass:[NSNull class]] || !traceParent.length) {
        if (hmd_log_enable()) {
            HMDALOG_PROTOCOL_ERROR_TAG(@"Heimdallr", @"HMDOTSpan Error: spanParent is nil; traceName = %@, spanName = %@, traceID = %@, spanID = %@, globalTraceVersion = %d, flags = %d", self.trace.serviceName, self.operationName, self.trace.traceID, self.spanID, globalTraceVersion, flags);
        }
    }
    return traceParent ?: @"";
}

+ (instancetype)startSpanOfTrace:(HMDOTTrace *)trace WithConfig:(HMDOTSpanConfig *)config {
    
    if (hermas_enabled()) {
        if ([HMDOTManager2 sharedInstance].hasStopped) return nil;
    } else {
        if ([HMDOTManager sharedInstance].hasStopped) return nil;
    }
    
    NSAssert(config, @"[HMDOTSpan startSpanWithConfig:] Span config cannot be nil!");
    NSAssert(config.operationName, @"[HMDOTSpan startSpanWithConfig:] The operationName of span can not be nil.");
    if (!config) {
        if (hmd_log_enable()) {
            HMDALOG_PROTOCOL_ERROR_TAG(@"Heimdallr", @"HMDOTSpan Error: creat span failed; reason = span config is nil;");
        }
        return nil;
    }
    if (!config.operationName) {
        if (hmd_log_enable()) {
            HMDALOG_PROTOCOL_ERROR_TAG(@"Heimdallr", @"HMDOTSpan Error: creat span failed; reason = span.operation name is nil;");
        }
        return nil;
    }
    
    if (!trace) trace = config.trace;
    NSAssert(trace, @"trace cannot be nil, the current span is: %@ .", config.operationName);
    NSAssert(!trace.isFinished, @"please call this method before trace finish, the trace is:%@, the span is:%@ .", trace.serviceName, config.operationName);
    
    if(!trace) {
        if (hmd_log_enable()) {
            HMDALOG_PROTOCOL_ERROR_TAG(@"Heimdallr", @"HMDOTSpan Error: creat span failed; reason = span.trace is nil; spanName = %@", config.operationName);
        }
        return nil;
    }
    
    if(trace.isFinished) {
        if (hmd_log_enable()) {
            HMDALOG_PROTOCOL_ERROR_TAG(@"Heimdallr", @"HMDOTSpan Error: creat span failed; reason = span.trace is finish; spanName = %@, traceName = %@", config.operationName, trace.serviceName);
        }
        return nil;
    }
    
    HMDOTSpan *span = [self newRecord];
    span.traceID = trace.traceID;
    span.operationName = config.operationName;
    span.serviceName = trace.serviceName;
    span.spanID = [HMDOTTraceConfig generateRandom16LengthString];
    span.referenceID = trace.latestSpanID;
    span.trace = trace;
    trace.latestSpanID = span.spanID;
    if (config.startDate) {
        span.startTimestamp = MilliSecond([config.startDate timeIntervalSince1970]);
    }
    
    span.isInstant = config.isInstant;
    span.category = config.category;
    span.type = config.type;
    span.data = [config.data generateMovinglineData];
    span.extra = config.extra;
    span.isMovingLine = trace.isMovingLine;
    span.needReferenceOtherLog = config.needReferenceOtherLog ? 1 : 0;

    if (config.error) {
        [span logError:config.error];
    }
    if (config.errMsg) {
        [span logErrorWithMessage:config.errMsg];
    }
    if (config.tags) {
        [config.tags enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull value, BOOL * _Nonnull stop) {
            [span setTag:key value:value];
        }];
    }
    if (config.logs) {
        [config.logs enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull log, NSUInteger idx, BOOL * _Nonnull stop) {
            @autoreleasepool {
                NSString *logMsg = log.allKeys.firstObject;
                NSDictionary *fields = [log valueForKey:logMsg];
                [span logMessage:logMsg fields:fields];
            }
        }];
    }
    
    if (span.isInstant) {
        [span finish];
    } else {
        [span insertPlaceHolderIfNeeded];
    }
    return span;
}

+ (instancetype)startSpanOfParentSpan:(HMDOTSpan *)parent WithConfig:(HMDOTSpanConfig *)config {
    
    if (hermas_enabled()) {
        if ([HMDOTManager2 sharedInstance].hasStopped) return nil;
    } else {
        if ([HMDOTManager sharedInstance].hasStopped) return nil;
    }
    
    NSAssert(config, @"[HMDOTSpan startSpanWithConfig:] Span config cannot be nil!");
    NSAssert(config.operationName, @"[HMDOTSpan startSpanWithConfig:] The operationName of span can not be nil.");
    if (!config) {
        if (hmd_log_enable()) {
            HMDALOG_PROTOCOL_ERROR_TAG(@"Heimdallr", @"HMDOTSpan Error: creat span failed; reason = span config is nil;");
        }
        return nil;
    }
    if (!config.operationName) {
        if (hmd_log_enable()) {
            HMDALOG_PROTOCOL_ERROR_TAG(@"Heimdallr", @"HMDOTSpan Error: creat span failed; reason = span.operation name is nil;");
        }
        return nil;
    }
    
    NSAssert(parent, @"parent cannot be nil, the current span is: %@ .", config.operationName);
//    NSAssert(!parent.isFinished, @"please call this method before parent span is finished. the current span is: %@, the parent span is %@ .", config.operationName, parent.operationName);
    NSAssert(!parent.trace.isFinished, @"please call this method before parent's trace finish, the span is: %@, the parentSpan is: %@ .", config.operationName, parent.operationName);
    
    if(!parent) {
        if (hmd_log_enable()) {
            HMDALOG_PROTOCOL_ERROR_TAG(@"Heimdallr", @"HMDOTSpan Error: creat span failed; reason = parent is nil; spanName = %@", config.operationName);
        }
        return nil;
    }
    
    if(parent.isFinished) {
        if (hmd_log_enable()) {
            HMDALOG_PROTOCOL_ERROR_TAG(@"Heimdallr", @"HMDOTSpan Error: creat span failed; reason = parent is finish; spanName = %@, parentName = %@", config.operationName, parent.serviceName);
        }
        return nil;
    }
    
    if(!parent.trace) {
        if (hmd_log_enable()) {
            HMDALOG_PROTOCOL_ERROR_TAG(@"Heimdallr", @"HMDOTSpan Error: creat span failed; reason = parent.trace is nil; spanName = %@, parentName = %@", config.operationName, parent.serviceName);
        }
        return nil;
    }
    
    if(parent.trace.isFinished) {
        if (hmd_log_enable()) {
            HMDALOG_PROTOCOL_ERROR_TAG(@"Heimdallr", @"HMDOTSpan Error: creat span failed; reason = parent.trace is finish; spanName = %@, parentName = %@, parentTraceName = %@", config.operationName, parent.serviceName, parent.trace.serviceName);
        }
        return nil;
    }
    
    HMDOTSpan *span = [self newRecord];
    span.traceID = parent.traceID;
    span.operationName = config.operationName;
    span.serviceName = parent.serviceName;
    span.spanID = [HMDOTTraceConfig generateRandom16LengthString];
    span.parentID = parent.spanID;
    span.referenceID = parent.latestChildSpanID;
    span.trace = parent.trace;
    span.parentSpan = parent;
    parent.latestChildSpanID = span.spanID;
    
    if (config.startDate) {
        span.startTimestamp = MilliSecond([config.startDate timeIntervalSince1970]);
    }
    
    span.isInstant = config.isInstant;
    span.category = config.category;
    span.type = config.type;
    span.data = [config.data generateMovinglineData];
    span.extra = config.extra;
    span.isMovingLine = parent.trace.isMovingLine;
    span.needReferenceOtherLog = config.needReferenceOtherLog ? 1 : 0;
    
    if (config.error) {
        [span logError:config.error];
    }
    if (config.errMsg) {
        [span logErrorWithMessage:config.errMsg];
    }
    if (config.tags) {
        [config.tags enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull value, BOOL * _Nonnull stop) {
            [span setTag:key value:value];
        }];
    }
    if (config.logs) {
        [config.logs enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull log, NSUInteger idx, BOOL * _Nonnull stop) {
            @autoreleasepool {
                NSString *logMsg = log.allKeys.firstObject;
                NSDictionary *fields = [log valueForKey:logMsg];
                [span logMessage:logMsg fields:fields];
            }
        }];
    }
    
    if (span.isInstant) {
        [span finish];
    } else {
        [span insertPlaceHolderIfNeeded];
    }
    
    return span;
}

+ (instancetype)startSpanOfReferance:(HMDOTSpan *)reference SpanWithConfig:(HMDOTSpanConfig *)config {
    if (hermas_enabled()) {
        if ([HMDOTManager2 sharedInstance].hasStopped) return nil;
    } else {
        if ([HMDOTManager sharedInstance].hasStopped) return nil;
    }
    
    NSAssert(config, @"[HMDOTSpan startSpanWithConfig:] Span config cannot be nil!");
    NSAssert(config.operationName, @"[HMDOTSpan startSpanWithConfig:] The operationName of span can not be nil.");
    if (!config) {
        if (hmd_log_enable()) {
            HMDALOG_PROTOCOL_ERROR_TAG(@"Heimdallr", @"HMDOTSpan Error: creat span failed; reason = span config is nil;");
        }
        return nil;
    }
    if (!config.operationName) {
        if (hmd_log_enable()) {
            HMDALOG_PROTOCOL_ERROR_TAG(@"Heimdallr", @"HMDOTSpan Error: creat span failed; reason = span.operation name is nil;");
        }
        return nil;
    }
    
    NSAssert(reference, @"reference cannot be nil, the span is:%@ .", config.operationName);
    NSAssert(!reference.trace.isFinished, @"please call this method before reference's trace finish, the span is: %@, the referenced of span is: %@", config.operationName, reference.operationName);
    
    if(!reference) {
        if (hmd_log_enable()) {
            HMDALOG_PROTOCOL_ERROR_TAG(@"Heimdallr", @"HMDOTSpan Error: creat span failed; reason = reference is nil; spanName = %@, referenceName = %@", config.operationName, reference.operationName);
        }
        return nil;
    }
    
    if(!reference.trace) {
        if (hmd_log_enable()) {
            HMDALOG_PROTOCOL_ERROR_TAG(@"Heimdallr", @"HMDOTSpan Error: creat span failed; reason = reference.trace is nil; spanName = %@, referenceName = %@", config.operationName, reference.operationName);
        }
        return nil;
    }
    
    if(reference.trace.isFinished) {
        if (hmd_log_enable()) {
            HMDALOG_PROTOCOL_ERROR_TAG(@"Heimdallr", @"HMDOTSpan Error: creat span failed; reason = reference.trace is finish; spanName = %@, referenceName = %@, referenceTraceName = %@", config.operationName, reference.operationName, reference.trace.serviceName);
        }
        return nil;
    }
    
    HMDOTSpan *span = [self newRecord];
    span.traceID = reference.traceID;
    span.operationName = config.operationName;
    span.serviceName = reference.serviceName;
    span.spanID = [HMDOTTraceConfig generateRandom16LengthString];
    span.parentID = reference.parentID;
    span.referenceID = reference.spanID;
    span.trace = reference.trace;
    span.parentSpan = reference.parentSpan;
    span.parentSpan.latestChildSpanID = span.spanID;
    
    if (config.startDate) {
        span.startTimestamp = MilliSecond([config.startDate timeIntervalSince1970]);
    }
    
    span.isInstant = config.isInstant;
    span.category = config.category;
    span.type = config.type;
    span.data = [config.data generateMovinglineData];
    span.extra = config.extra;
    span.isMovingLine = reference.trace.isMovingLine;
    span.needReferenceOtherLog = config.needReferenceOtherLog ? 1 : 0;
    
    if (config.error) {
        [span logError:config.error];
    }
    if (config.errMsg) {
        [span logErrorWithMessage:config.errMsg];
    }
    if (config.tags) {
        [config.tags enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull value, BOOL * _Nonnull stop) {
            [span setTag:key value:value];
        }];
    }
    if (config.logs) {
        [config.logs enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull log, NSUInteger idx, BOOL * _Nonnull stop) {
            @autoreleasepool {
                NSString *logMsg = log.allKeys.firstObject;
                NSDictionary *fields = [log valueForKey:logMsg];
                [span logMessage:logMsg fields:fields];
            }
        }];
    }
    
    if (span.isInstant) {
        [span finish];
    } else {
        [span insertPlaceHolderIfNeeded];
    }
    
    return span;
}

- (void)setMovingLineCategory:(NSUInteger)category type:(NSUInteger)type data:(nullable id<HMDOTSpanMovinglineDataProtocol>)data  extra:(nullable NSDictionary*)extra AndEndDate:(nullable NSDate *)endDate {
    BOOL isReWrite = NO;
    
    if (category != self.category) {
        isReWrite = YES;
        self.category = category;
    }
    
    if (type != self.type) {
        isReWrite = YES;
        self.type = type;
    }
    
    if (data) {
        isReWrite = YES;
        self.data = [data generateMovinglineData];
    }
    
    if (extra) {
        isReWrite = YES;
        self.extra = extra;
    }
    
    if (endDate) {
        isReWrite = YES;
        self.finishTimestamp = MilliSecond([endDate timeIntervalSince1970]);
        NSAssert(self.finishTimestamp >= self.startTimestamp, @"Finish time can not be less than the start time. The span is: %@ and the trace is: %@", self.operationName, self.trace.serviceName);
    }
    
    if (self.isFinished && !self.trace.isFinished && isReWrite) {
        if (hermas_enabled()) {
            [[HMDOTManager2 sharedInstance] finishSpan:self];
        } else {
            [self writeSpanIfNeedWithNeedReplace:YES];
        }
    }
}

- (NSDictionary *)reportDictionary {
#ifdef DEBUG
    if (!hermas_enabled()) {
        self.isReporting = YES;
    }
#endif
    NSMutableDictionary *dataValue = [NSMutableDictionary dictionary];
    [dataValue setValue:@"tracer_span" forKey:@"log_type"];
    [dataValue setValue:self.operationName forKey:@"operation_name"];
    [dataValue setValue:self.serviceName forKey:@"service"];
    [dataValue setValue:self.traceID forKey:@"trace_id"];
    [dataValue setValue:self.spanID forKey:@"span_id"];
    [dataValue setValue:self.parentID forKey:@"parent_id"];
    [dataValue setValue:self.referenceID forKey:@"reference_id"];
    [dataValue setValue:@(self.startTimestamp) forKey:@"start_timestamp"];
    [dataValue setValue:@(self.finishTimestamp) forKey:@"finish_timestamp"];
    [dataValue setValue:self.logs forKey:@"logs"];
    [dataValue setValue:self.tags forKey:@"tags"];
    [dataValue setValue:[NSString stringWithFormat:@"%lld", self.threadID] forKey:@"thread_id"];
    [dataValue setValue:@(self.isFinished) forKey:@"is_finished"];
    if (hermas_enabled() && self.sequenceCode >= 0) {
        [dataValue setValue:@(self.sequenceCode) forKey:@"sequence_code"];
    }
    
    if (self.isMovingLine) {
        NSMutableDictionary *movingLine = [NSMutableDictionary dictionary];
        [movingLine setValue:self.traceParent forKey:@"traceparent"];
        [movingLine setValue:@(self.type) forKey:@"type"];
        [movingLine setValue:@(self.category) forKey:@"category"];
        [movingLine setValue:self.data forKey:@"data"];
        [movingLine setValue:self.extra forKey:@"extra"];
        [movingLine hmd_setObject:@(self.needReferenceOtherLog) forKey:@"ref_log"];
        [dataValue setValue:[movingLine copy] forKey:@"movingline"];
    }

    return dataValue;
}

# pragma todo deprecated
+ (NSArray *)bg_ignoreKeys {
    return @[@"trace",@"latestChildSpanID",@"parentSpan"];
}

+ (NSString *)tableName {
    return NSStringFromClass(self);
}

+ (NSUInteger)cleanupWeight {
    return 0;
}

+ (NSArray <NSDictionary *>*)reportDataForRecords:(NSArray *)records {
    NSMutableArray *dataArray = [NSMutableArray array];
    
    for (HMDOTSpan *record in records) {
        NSDictionary *dataValue = [record reportDictionary];
        if (dataValue) {
            [dataArray addObject:dataValue];
        }
    }
    
    return [dataArray copy];
}

@end
