//
//  OPTrace.m
//  ECOProbe
//
//  Created by qsc on 2021/3/30.
//

#import "OPTrace.h"
#import "OPTracingCoreSpan.h"
#import "OPMonitorService.h"
#import "OPTraceService.h"
#import <ECOProbe/ECOProbe-Swift.h>
#import "OPTraceConstants.h"
#import "NSDictionary+ECOExtensions.h"
#import "OPMonitor+Serialize.h"
#import <ECOProbeMeta/ECOProbeMeta-Swift.h>
#import "OPMonitorFlushTask.h"

@interface OPTrace()

@property (nonatomic, strong) OPTracingCoreSpan *tracingSpan;
@property (nonatomic, strong) NSMutableArray<NSString *> *monitorCache;
@property (nonatomic, assign) BOOL traceFinished;
@property (nonatomic, strong) OPTraceBatchConfig *batchConfig;
@property (nonatomic, strong) dispatch_semaphore_t semaphore;
@property (nonatomic, assign) BOOL everSerialized;
@property (nonatomic, strong) NSMutableSet<NSString *> *executedTaskNames;
@property (nonatomic, strong, readwrite) OPMonitorEvent *batchReportMonitor;
@property (nonatomic, assign, readwrite) BOOL batchEnabled;

@end

#define Lock() dispatch_semaphore_wait(_semaphore, DISPATCH_TIME_FOREVER);

#define Unlock() dispatch_semaphore_signal(_semaphore);

#define MAX_CACHE_COUNT 50

@implementation OPTrace

- (instancetype)initWithTraceId:(NSString *)traceId {
    OPTracingCoreSpan *tracingSpan = [[OPTracingCoreSpan alloc] initWithTraceId:traceId];

    return [self initWithTraceSpan:tracingSpan];
}

- (instancetype)initWithTraceId:(NSString *)traceId BizName:(NSString *)bizName {
    OPTrace *trace = [self initWithTraceId:traceId];
    trace.batchEnabled = [self.batchConfig checkBizBatchEnabledWithBizName: bizName] && [self.batchConfig checkApiReportEnabledWithApiName:bizName];
    return trace;
}

- (instancetype)initWithTraceSpan:(OPTracingCoreSpan *)traceSpan {
    self = [super init];
    if (self) {
        _tracingSpan = traceSpan;
        _traceFinished = NO;
        _everSerialized = NO;
        _semaphore = dispatch_semaphore_create(1);
        _batchEnabled = NO;
    }
    return self;
}


- (NSString *)traceId {
    return self.tracingSpan.traceId;
}


- (nonnull instancetype)subTrace {
    OPTrace *subTrace = [[OPTraceService defaultService] generateTraceWithParent:self];
    //派生子级 trace 的批量上报开关跟随父级
    subTrace.batchEnabled = self.batchEnabled;
    return subTrace;
}

- (nonnull instancetype)subTraceWithBizName:(NSString *)bizName {
    OPTrace *subTrace = [[OPTraceService defaultService] generateTraceWithParent:self];
    subTrace.batchEnabled = [self.batchConfig checkBizBatchEnabledWithBizName: bizName] && [self.batchConfig checkApiReportEnabledWithApiName:bizName];
    return subTrace;
}

- (BOOL)shouldExecuteTask:(NSString *) name {
    if (!self.batchEnabled) {
        return NO;
    }
    if (!name) {
        return NO;
    }
    if ([self.executedTaskNames containsObject:name]) {
        return NO;
    } else {
        [self.executedTaskNames addObject:name];
        return YES;
    }
}

- (OPMonitorServiceConfig * _Nonnull)config {
    return [[OPMonitorService defaultService] config];
}

- (BOOL)reportEnabled {
    return self.batchConfig.reportEnabled;
}

- (BOOL)reportEnabledForMonitor:(OPMonitorEvent *)event {

   return [self.batchConfig batchEnabledForEventName:event.name
                                       monitorDomain:event.innerMonitorCode.domain
                                           monitorId:event.innerMonitorCode.ID];
}
- (BOOL)logEnabled {
    return self.batchConfig.logEnabled;
}

#pragma mark OPMonitorServiceProtocol

- (void)flush:(nonnull OPMonitorEvent *)monitor platform:(OPMonitorReportPlatform)platform {
    if (self.monitorCache.count > MAX_CACHE_COUNT) {
        self.batchEnabled = false;
        Lock();
        [self.monitorCache removeAllObjects];
        Unlock();
        self.warn(@"trace receive too many monitors! delete all data and disable batch! last monitor: %@, id: %@", monitor.name, monitor.innerMonitorCode.ID);
        return;
    }
    if(self.batchEnabled && [self reportEnabledForMonitor:monitor]) {
        [monitor removeRedundantData];
        NSString *serialized = [monitor serialize];
        if(serialized) {
            Lock();
            [self.monitorCache addObject: serialized];
            Unlock();
        } else {
            NSAssert(NO, @"opmonitor serialized result is not valid!");
            self.error(@"opmonitor serialized result is not valid!");
        }
    }
}

- (void)log:(nonnull OPMonitorEvent *)monitor {
    if(!self.batchEnabled || ![self logEnabled]) {
        return;
    }
    if (!monitor) {
        return;
    }
    // 若埋点被批量上报，批量上报是会打印一次，此处无需再打印一次日志。故只对不上报的点打日志
    if(![self reportEnabledForMonitor:monitor]) {
        [[OPMonitorService defaultService] log:monitor];
    }
}

# pragma mark trace finish

- (void)finish {
    if(self.traceFinished) {
        NSAssert(NO, @"your trace double finished!");
        self.error(@"call trace finish multi times! drop cache count: %lu", [self.monitorCache count]);
        return;
    }
    self.traceFinished = true;

    if(!self.reportEnabled) {
        self.info(@"report is not enabled! cache size: %lu", [self.monitorCache count]);
        return;
    }

    if([self.monitorCache count] < 1) {
        self.warn(@"monitor cache is empty! skip report");
        return;
    }

    self.batchReportMonitor.tracing(self.tracingSpan);

    if([NSJSONSerialization isValidJSONObject:self.monitorCache]) {
        NSError *serializeError;
        NSData *data = [NSJSONSerialization dataWithJSONObject:self.monitorCache
                                                       options:kNilOptions
                                                         error:&serializeError];

        NSString *jsonString = [[NSString alloc] initWithData:data
                                                     encoding:NSUTF8StringEncoding];
        if(serializeError) {
            self.batchReportMonitor.setError(serializeError)
            .setResultTypeFail()
            .setErrorMessage(@"serialize monitor cache error!");

            self.error(@"convert monitor cache failed! error; %@", serializeError);
        } else {
            self.batchReportMonitor.addCategoryValue(kTraceSerializeKeyMonitorData, jsonString);
        }
    } else {
        self.error(@"convert monitor cache failed! not a valid JSON");
        self.batchReportMonitor.setResultTypeFail().setErrorMessage(@"monitor cache is not valid JSON Object");
    }
    Lock();
    [self.monitorCache removeAllObjects];
    Unlock();
    self.batchReportMonitor.flush();
}

#pragma mark serialize & deserialize

- (NSString * _Nullable)serialize {
    self.everSerialized = YES;
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    NSDictionary *traceDict = [[NSDictionary alloc] initWithObjectsAndKeys:
                               self.traceId, kTraceSerializeKeyTraceId,
                               @(self.tracingSpan.createTime), kTraceSerializeKeyCreateTime,
                               nil];
    [dict setObject:traceDict forKey:kTraceSerializeKeyTrace];
    [dict setObject:self.monitorCache forKey:kTraceSerializeKeyMonitorData];
    [dict setValue:@(self.batchEnabled) forKey:kTraceSerializeKeyBatchEnabled];

    if ([NSJSONSerialization isValidJSONObject:dict]) {
        NSData *data = [NSJSONSerialization dataWithJSONObject:dict options:kNilOptions error:nil];
        return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    } else {
        NSAssert(NO, @"serialize trace failed! not a valid JSON!");
        self.error(@"serialize trace failed! not a valid JSON!");
    }
    return nil;
}

+ (instancetype _Nullable)deserializeFrom:(nonnull NSString *)json {

    NSError *parseError;
    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:[json dataUsingEncoding:NSUTF8StringEncoding]
                                    options:kNilOptions
                                      error:&parseError];
    if(parseError) {
        NSAssert(NO, @"parse OPTrace: parse json error: %@", parseError);
        return nil;
    }

    NSDictionary *traceDict = [dict eco_dictionaryValueForKey:kTraceSerializeKeyTrace];
    if(!traceDict) {
        NSAssert(NO, @"parse OPTrace: trace is not valid!");
        return nil;
    }

    OPTracingCoreSpan *span = [[OPTracingCoreSpan alloc] initWithJSONDict: traceDict];
    NSArray *monitor = [dict eco_arrayValueForKey:kTraceSerializeKeyMonitorData];
    if (span && monitor) {
        OPTrace *trace = [[OPTrace alloc] initWithTraceSpan:span];
        trace.batchEnabled = [dict eco_boolValueForKey:kTraceSerializeKeyBatchEnabled];
        [[trace monitorCache] addObjectsFromArray:monitor];
        return trace;
    } else {
        NSAssert(NO, @"OPTrace parse from json failed! traceId or monitorData is not valid!");
        return nil;
    }
}

#pragma mark Log

- (void (^ _Nonnull)(NSString * message,
                     const char* file,
                     const char* function,
                     int line))_debug {

    __weak typeof(self) weakSelf = self;
    return ^void (NSString * message, const char* file, const char* function, int line) {
        typeof(weakSelf) self = weakSelf;
        if (self) {
            [OPTraceLoggerObjc _debugWithTrace:self
                                      message: message
                                         file: file ? [NSString stringWithUTF8String:file] : @""
                                     function: function ? [NSString stringWithUTF8String:function] : @""
                                         line: line];
        }
    };
}

- (void (^ _Nonnull)(NSString * message,
                     const char* file,
                     const char* function,
                     int line))_info {

    __weak typeof(self) weakSelf = self;
    return ^void (NSString * message, const char* file, const char* function, int line) {
        typeof(weakSelf) self = weakSelf;
        if (self) {
            [OPTraceLoggerObjc _infoWithTrace:self
                                      message: message
                                         file: file ? [NSString stringWithUTF8String:file] : @""
                                     function: function ? [NSString stringWithUTF8String:function] : @""
                                         line: line];
        }
    };
}

- (void (^ _Nonnull)(NSString * message,
                     const char* file,
                     const char* function,
                     int line))_warn {

    __weak typeof(self) weakSelf = self;
    return ^void (NSString * message, const char* file, const char* function, int line) {
        typeof(weakSelf) self = weakSelf;
        if (self) {
            [OPTraceLoggerObjc _warnWithTrace:self
                                      message: message
                                         file: file ? [NSString stringWithUTF8String:file] : @""
                                     function: function ? [NSString stringWithUTF8String:function] : @""
                                         line: line];
        }
    };
}

- (void (^ _Nonnull)(NSString * message,
                     const char* file,
                     const char* function,
                     int line))_error {

    __weak typeof(self) weakSelf = self;
    return ^void (NSString * message, const char* file, const char* function, int line) {
        typeof(weakSelf) self = weakSelf;
        if (self) {
            [OPTraceLoggerObjc _errorWithTrace:self
                                      message: message
                                         file: file ? [NSString stringWithUTF8String:file] : @""
                                     function: function ? [NSString stringWithUTF8String:function] : @""
                                         line: line];
        }
    };
}

#pragma mark Lazy init

- (OPTraceBatchConfig *)batchConfig {
    return [OPTraceBatchConfig shared];
}

- (NSMutableArray<NSString *> *)monitorCache {
    if (!_monitorCache) {
        _monitorCache = [NSMutableArray array];
    }
    return _monitorCache;
}

- (NSMutableSet<NSString *> *)executedTaskNames {
    if (!_executedTaskNames) {
        _executedTaskNames = [NSMutableSet set];
    }
    return _executedTaskNames;
}

- (OPMonitorEvent *)batchReportMonitor {
    if (!_batchReportMonitor) {
        _batchReportMonitor = [[OPMonitorEvent alloc] initWithService:nil
                                                                 name:kTraceReportKeyEventName
                                                          monitorCode:EPMMonitorBaseBatchCode.batch_monitor];
    }
    return _batchReportMonitor;
}

#if DEBUG
-(void)dealloc {
    if (!self.traceFinished && !self.everSerialized && self.monitorCache.count > 0) {
        [OPTraceLoggerObjc _errorWithTrace:self
                                   message: [NSString stringWithFormat: @"trace has cache some monitor but not call finished or serialize before dealloc, cache count: %@", self.monitorCache]
                                      file: [NSString stringWithUTF8String:__OP_FILE_NAME__]
                                  function: [NSString stringWithUTF8String:__FUNCTION__]
                                      line: __LINE__];
    }
}
#endif

@end

