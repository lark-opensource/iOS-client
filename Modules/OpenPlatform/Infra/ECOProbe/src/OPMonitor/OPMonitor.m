//
//  OPMonitor.m
//  LarkOPInterface
//
//  Created by yinyuan on 2020/5/21.
//

#import "OPMonitor.h"
#import "OPMonitorService.h"
#import <ECOProbe/ECOProbe-Swift.h>
#import "OPTraceProtocol.h"
#import "ECOSafeMutableDictionary.h"

OPMonitorEvent * _Nonnull OPNewMonitor(NSString * _Nonnull eventName) {
    return [[OPMonitorEvent alloc] initWithService:nil name:eventName monitorCode:nil];
}

OPMonitorEvent * _Nonnull OPNewMonitorEvent(id<OPMonitorCodeProtocol> _Nonnull monitorCode) {
    return [[OPMonitorEvent alloc] initWithService:nil name:nil monitorCode:monitorCode];
}

NSString * const kEventKeyCPUTime = @"cpu_time";                         // 距离开机启动的毫秒数，包含休眠时间, 这里做成私有常量，不对外可见，不允许修改
NSString * const kMonitorMetaError = @"_monitor_meta_error";

@interface OPMonitorEvent ()

@property (nonatomic, weak, nullable) id<OPMonitorServiceProtocol> service;

@property (nonatomic, assign, readwrite) NSTimeInterval time;
@property (nonatomic, assign, readwrite) NSTimeInterval startTime;
@property (nonatomic, assign, readwrite) NSTimeInterval endTime;

@property (nonatomic, strong, readwrite) NSMutableDictionary *metricsData;
@property (nonatomic, strong, readwrite) NSMutableDictionary *categoriesData;

@property (nonatomic, strong) NSLock *tagsLock;
@property (nonatomic, strong, readwrite) NSMutableSet<NSString *> *tags;

@property (nonatomic, assign, readwrite) BOOL flushed;

@property (nonatomic, strong, readwrite) id<OPMonitorCodeProtocol> innerMonitorCode;
@property (nonatomic, strong, readwrite) id<OPMonitorCodeProtocol> innerMonitorCodeIfError;
@property (atomic, copy, readwrite) NSString *fileName;
@property (atomic, copy, readwrite) NSString *funcName;
@property (nonatomic, assign, readwrite) NSInteger line;

@property (nonatomic, assign, readwrite) OPMonitorLevel eventLevel;

@property (atomic, strong, readwrite) NSError *error;

/// 外部指定的 metrics 数据，优先级最高
@property (nonatomic, strong, readwrite) NSDictionary *appendedMetricsData;
/// 外部指定的 Categories 数据，优先级最高
@property (nonatomic, strong, readwrite) NSDictionary *appendedCategoriesData;

@property (nonatomic, assign, readwrite) OPMonitorReportPlatform platform;

@property (nonatomic, strong) NSLock *flushTasksLock;
@property (nonatomic, strong) NSMutableArray<OPMonitorFlushTask *> *flushTasks;
@end

#ifndef WeakSelf
    #define WeakSelf __weak typeof(self) wself = self
#endif

#ifndef StrongSelf
    #define StrongSelf __strong typeof(wself) self = wself;
#endif

@implementation OPMonitorEvent

- (id)copyWithZone:(NSZone *)zone {
    OPMonitorEvent *copied = [[OPMonitorEvent alloc] initWithService:self.service name:self.name monitorCode:self.innerMonitorCode];

    copied.time = self.time;
    copied.metricsData = self.metricsData.copy;
    copied.categoriesData = self.categoriesData.copy;
    // copied.flushed = self.flushed;
    copied.tags = self.tags.copy;
    copied.innerMonitorCode = self.innerMonitorCode;
    copied.innerMonitorCodeIfError = self.innerMonitorCodeIfError;
    copied.fileName = self.fileName;
    copied.funcName = self.funcName;
    copied.line = self.line;
    copied.platform = self.platform;
    return copied;
}

- (instancetype)initWithService:(id<OPMonitorServiceProtocol> _Nullable) service
                           name:(NSString * _Nullable)name
                    monitorCode:(id<OPMonitorCodeProtocol> _Nullable)monitorCode {

    return [self initWithService:service
                            name:name
                     monitorCode:monitorCode
                        platform:OPMonitorReportPlatformUnknown
                enableThreadSafe:NO];
}
- (instancetype)initWithService:(id<OPMonitorServiceProtocol> _Nullable) service
                           name:(NSString * _Nullable)name
                    monitorCode:(id<OPMonitorCodeProtocol> _Nullable)monitorCode
                       platform:(OPMonitorReportPlatform) platform {
    return [self initWithService:service name:name monitorCode:monitorCode platform:platform enableThreadSafe:NO];
}

- (instancetype)initWithService:(id<OPMonitorServiceProtocol> _Nullable) service
                           name:(NSString * _Nullable)name
                    monitorCode:(id<OPMonitorCodeProtocol> _Nullable)monitorCode
                       platform:(OPMonitorReportPlatform) platform
               enableThreadSafe:(BOOL) threadSafe {
    if (self = [super init]) {
        if (name && ![name isKindOfClass:NSString.class]) {
            NSAssert(NO, @"OPMonitorEvent name should be NSString class");
            name = nil;
        }
        if (monitorCode && ![monitorCode conformsToProtocol: @protocol(OPMonitorCodeProtocol)]) {
            NSAssert(NO, @"OPMonitorEvent monitorCode should be OPMonitorCode class");
            monitorCode = nil;
        }
        _flushTasks = [NSMutableArray array];
        _flushTasksLock = [[NSLock alloc] init];
        _service = service ?: OPMonitorService.defaultService;
        _name = name ?: [self.service.config defaultEventNameForDomain:(monitorCode ? monitorCode.domain : nil)];

        _innerMonitorCode = monitorCode;

        // 初始化公共参数
        _metricsData = self.service.config.commonMetrics.mutableCopy ?: [[NSMutableDictionary alloc] initWithCapacity:20];
        _categoriesData = self.service.config.commonCatrgories.mutableCopy ?: [[NSMutableDictionary alloc] initWithCapacity:20];
        _tags = self.service.config.commonTags.mutableCopy ?: NSMutableSet.set;
        _tagsLock = [[NSLock alloc]init];
        _platform = platform == OPMonitorReportPlatformUnknown ? self.service.config.defaultPlatform : platform;
        if (threadSafe) {
            _metricsData = [[ECOSafeMutableDictionary alloc] initWithDictionary:_metricsData];
            _categoriesData = [[ECOSafeMutableDictionary alloc] initWithDictionary:_categoriesData];
        }
    }
    return self;
}

- (instancetype _Nonnull)initWithService:(id<OPMonitorServiceProtocol> _Nullable)service
                                    name:(NSString * _Nullable)name
                                 metrics:(NSDictionary *)metrics
                              categories:(NSDictionary *)categories
                                platform:(OPMonitorReportPlatform) platform {
    if (self = [self initWithService:service name:name monitorCode:nil platform:platform]) {
        self.appendedMetricsData = metrics;
        self.appendedCategoriesData = categories;
    }
    return self;
}

- (instancetype _Nonnull)initWithService:(id<OPMonitorServiceProtocol> _Nullable)service
                                    name:(NSString * _Nullable)name
                                 metrics:(NSDictionary *)metrics
                              categories:(NSDictionary *)categories {
    if (self = [self initWithService:service name:name monitorCode:nil]) {
        self.appendedMetricsData = metrics;
        self.appendedCategoriesData = categories;
    }
    return self;
}

/*-------------------------------------------------------*/
//                        基本方法
/*-------------------------------------------------------*/

/// 启用线程安全模式，addCategoryValue、addMetricsValue 时使用线程安全的字典
- (OPMonitorEvent * _Nonnull (^)(void))enableThreadSafe {
    WeakSelf;
    return ^OPMonitorEvent *(void) {
        StrongSelf;
        self.metricsData = [[ECOSafeMutableDictionary alloc] initWithDictionary:self.metricsData];
        self.categoriesData = [[ECOSafeMutableDictionary alloc] initWithDictionary:self.categoriesData];
        return self;
    };
}

- (OPMonitorEvent * _Nonnull (^ _Nonnull)(NSString * _Nonnull key, AnyType _Nullable value))addMetricValue {
    __weak typeof(self) weakSelf = self;
    return ^OPMonitorEvent *(NSString * _Nonnull key, AnyType _Nullable value) {
        typeof(weakSelf) self = weakSelf;
        if (key && self && !self.flushed) {
            self.metricsData[key] = value;
        }
        return self;
    };
}

- (OPMonitorEvent * _Nonnull (^ _Nonnull)(NSString * _Nonnull key, AnyType _Nullable value))addCategoryValue {
    __weak typeof(self) weakSelf = self;
    return ^OPMonitorEvent *(NSString * _Nonnull key, AnyType _Nullable value) {
        typeof(weakSelf) self = weakSelf;
        [self addCategoryValue:value withKey:key];
        return self;
    };
}

- (void)addCategoryValue:(AnyType _Nullable)value withKey:(NSString * _Nonnull)key {
    if (!key || self.flushed) {
        return;
    }
    if (value && ![value isKindOfClass:NSString.class] && ![value isKindOfClass:NSNumber.class]) {
        if (![NSJSONSerialization isValidJSONObject:value]) {
            // 不能转JSON类型的数据
            NSString *error_msg = [NSString stringWithFormat:@"event value must be a valid JSONObject. %@.%@ is %@. file:%@ function:%@ line:%@", self.name, key, [value class], self.fileName, self.funcName, @(self.line)];
            OPLogError(error_msg);
            NSAssert(NO, error_msg);
            self.categoriesData[kMonitorMetaError] = error_msg;
            value = [value description];
        }
    }
    self.categoriesData[key] = value;
}

- (void)addCategoryMap:(NSDictionary<NSString *, AnyType> * _Nonnull)categoryMap {
    [categoryMap enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, AnyType  _Nonnull obj, BOOL * _Nonnull stop) {
        if (![obj isKindOfClass:NSNull.class]) {
            [self addCategoryValue:obj withKey:key];
        }
    }];
}

- (OPMonitorEvent *(^)(NSString *))addTag {
    __weak typeof(self) weakSelf = self;
    return ^OPMonitorEvent *(NSString *tag) {
        typeof(weakSelf) self = weakSelf;
        if (self && !self.flushed && [tag isKindOfClass:NSString.class] && tag.length) {
            [_tagsLock lock];
            [self.tags addObject:tag];
            [_tagsLock unlock];
        }
        return self;
    };
}

- (OPMonitorEvent * (^)(NSDictionary *map))addMap {
    __weak typeof(self) weakSelf = self;
    return ^OPMonitorEvent *(NSDictionary *map) {
        typeof(weakSelf) self = weakSelf;
        if (map && self && map && !self.flushed) {
                for (NSString *key in [map allKeys]) {
                    id value = map[key];
                    if ([value isKindOfClass:NSNumber.class]) {
                        self.metricsData[key] = value;
                    } else {
                        self.categoriesData[key] = value;
                    }
                }
        }
        return self;
    };
}

- (OPMonitorEvent * (^)(id<OPTraceProtocol> trace))tracing {
    __weak typeof(self) weakSelf = self;
    return ^OPMonitorEvent *(id<OPTraceProtocol> trace) {
        typeof(weakSelf) self = weakSelf;
        if (trace && self && !self.flushed) {
            // API 变更，这里先额外加一层检查 & 处理
            if ([trace conformsToProtocol:@protocol(OPTraceProtocol)]) {
                self.addCategoryValue(OPMonitorEventKey.trace_id, trace.traceId);
            } else if([trace isKindOfClass:[NSString class]]) {
                NSAssert(NO, @"OPMonitor tracing should use OPTrace instance");
                self.addCategoryValue(OPMonitorEventKey.trace_id, trace);
            } else {
                NSAssert(NO, @"OPMonitor tracing should use OPTrace instance");
            }
        }
        return self;
    };
}

- (OPMonitorEvent * _Nonnull (^ _Nonnull)(OPMonitorReportPlatform platform))setPlatform {
    __weak typeof(self) weakSelf = self;
    return ^OPMonitorEvent *(OPMonitorReportPlatform platform) {
        typeof(weakSelf) self = weakSelf;
        if (self && !self.flushed) {
            self.platform = platform;
        }
        return self;
    };
}

- (void (^)(void))flush {
    if (self && !self.flushed) {

        // 提交前数据处理

            // 应用 Tags
            if (!self.categoriesData[OPMonitorEventKey.monitor_tags]) {
                self.categoriesData[OPMonitorEventKey.monitor_tags] = [self tagsInLine];
            }

            // 应用 monitorCode
            if (self.innerMonitorCode) {
                [self applyMonitorCode:self.innerMonitorCode];
            } else if(self.innerMonitorCodeIfError && [self hasError]) {
                [self applyMonitorCode:self.innerMonitorCodeIfError];
            }
            // OPMonitor 与 OPError 解耦
            // 目前 OPError 拆在不同的模块中，为兼容并避免循环依赖这里用一些手法处理
            Class cls = NSClassFromString(@"OPError");
            if(cls != nil) {
                SEL sel = NSSelectorFromString(@"monitorCode");
                if([self.error isKindOfClass:cls] && [self.error respondsToSelector:sel]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
                    id code = [self.error performSelector:sel];
#pragma clang diagnostic pop
                    if (code && [code conformsToProtocol:@protocol(OPMonitorCodeProtocol)]) {
                        [self applyOPErrorMonitorCode:code];
                    }
                }
            }

            // 如果没有打时间，则默认打上时间
            if (self.time <= 0) {
                self.setTime(NSDate.date.timeIntervalSince1970);
            }

            // 应用 Error 信息
            if (self.error) {
                self.categoriesData[OPMonitorEventKey.error_code] = @(self.error.code);
                self.categoriesData[OPMonitorEventKey.error_domain] = self.error.domain;

                NSString *errorMsg = self.categoriesData[OPMonitorEventKey.error_msg];

                if (errorMsg) {
                    // 同时设置了 error 和 error_msg 就合并一下
                    NSString *errorDesc = self.error.localizedDescription;
                    errorMsg = [NSString stringWithFormat:@"%@, %@", errorDesc, errorMsg];
                } else {
                    errorMsg = self.error.localizedDescription;
                }
                self.categoriesData[OPMonitorEventKey.error_msg] = errorMsg;
            }

            NSTimeInterval systemUptime = NSProcessInfo.processInfo.systemUptime;
            self.addMetricValue(kEventKeyCPUTime, @((unsigned long long)(systemUptime * 1000)));

            // 由外部指定的数据优先级最高
            if (self.appendedMetricsData) {
                [self.metricsData addEntriesFromDictionary:self.appendedMetricsData];
            }
            if (self.appendedCategoriesData) {
                [self.categoriesData addEntriesFromDictionary:self.appendedCategoriesData];
            }

        [self.service flush:self platform: self.platform];

        [self.service log:self];

        self.flushed = YES;
    };
    return ^{};
}

- (void (^ _Nonnull)(const char* _Nullable fileName, const char* _Nullable funcName, NSInteger line))__flushWithContextInfo {
    return ^(const char* _Nullable fileName, const char* _Nullable funcName, NSInteger line){
        self.fileName = fileName ? [NSString stringWithUTF8String:fileName] : nil;
        self.funcName = funcName ? [NSString stringWithUTF8String:funcName] : nil;
        self.line = line;
        [self executeAllTasks];
        [self flush];
    };
}

- (void (^)(id<OPMonitorServiceProtocol> service,
            const char* _Nullable fileName,
            const char* _Nullable funcName,
            NSInteger line))__flushWithContextInfoWithService {
    __weak typeof(self) weakSelf = self;
    return ^void (id<OPMonitorServiceProtocol> service, const char* _Nullable fileName, const char* _Nullable funcName, NSInteger line) {
        typeof(weakSelf) self = weakSelf;
        if (self && !self.flushed) {
            self.service = service;
            self.fileName = fileName ? [NSString stringWithUTF8String:fileName] : nil;
            self.funcName = funcName ? [NSString stringWithUTF8String:funcName] : nil;
            self.line = line;

            [self.flushTasksLock lock];
            NSArray *flushingTasks = [self.flushTasks copy];
            [self.flushTasks removeAllObjects];
            [self.flushTasksLock unlock];
            OPMonitorEvent *taskExecuteTarget = self;
            if ([service conformsToProtocol:@protocol(OPTraceProtocol)]) {
                id<OPTraceProtocol> traceService = (id<OPTraceProtocol>)service;
                if (![traceService batchEnabled]) {
                    // 向 OPTrace 塞数据时，判定 OPTrace 的 batch 开关。
                    // 若 trace 此状态为关闭，则不应该继续操作，提前退出
                    return;
                }
                taskExecuteTarget = traceService.batchReportMonitor ?: self;
            }
            OPMonitorFlushTask *task;
            for (NSUInteger index = 0; index < flushingTasks.count; index++) {
                task = [flushingTasks objectAtIndex:index];
                if (task && [service shouldExecuteTask:task.name]) {
                    [task executeOnMonitor:taskExecuteTarget];
                }
            }

            [self flush];
        }
    };
}

- (void)setMonitorService:(id<OPMonitorServiceProtocol>)service {
    if (service && [service respondsToSelector:@selector(flush:platform:)]) {
        self.service = service;
    }
}

- (void)removeRedundantData {
    [self.categoriesData removeObjectsForKeys:OPMonitorRedundantDataKeys.safe_delete_keys];
}

- (void)addFlushTaskWithName:(NSString *)name task:(FlushTaskBlock)task {
    OPMonitorFlushTask *flushTask = [[OPMonitorFlushTask alloc] initTaskWithName:name task:task];
    [self.flushTasksLock lock];
    [self.flushTasks addObject:flushTask];
    [self.flushTasksLock unlock];
}

- (void)executeAllTasks {
    OPMonitorFlushTask *task;
    [self.flushTasksLock lock];
    NSArray *flushingTasks = [self.flushTasks copy];
    [self.flushTasks removeAllObjects];
    [self.flushTasksLock unlock];
    for (NSUInteger index = 0; index < flushingTasks.count; index ++) {
        task = [flushingTasks objectAtIndex:index];
        if (task && [self.service shouldExecuteTask:task.name]) {
            [task executeOnMonitor:self];
        }
    }
}

/*-------------------------------------------------------*/
//                    Monitor: 监控
/*-------------------------------------------------------*/
#pragma mark - Monitor
- (OPMonitorEvent * _Nonnull (^)(OPMonitorLevel))setLevel {
    __weak typeof(self) weakSelf = self;
    return ^OPMonitorEvent *(OPMonitorLevel level) {
        typeof(weakSelf) self = weakSelf;
        if (self && !self.flushed) {
            self.eventLevel = level;
            self.addCategoryValue(OPMonitorEventKey.monitor_level, @(level));
        }
        return self;
    };
}

- (OPMonitorLevel)level {
    return self.eventLevel;
}

- (OPMonitorEvent * (^)(id<OPMonitorCodeProtocol> monitorCode))setMonitorCode {
    __weak typeof(self) weakSelf = self;
    return ^OPMonitorEvent *(id<OPMonitorCodeProtocol> monitorCode) {
        typeof(weakSelf) self = weakSelf;
        if (self && !self.flushed && [monitorCode conformsToProtocol:@protocol(OPMonitorCodeProtocol)]) {
            self.innerMonitorCode = monitorCode;
        }
        return self;
    };
}

- (OPMonitorEvent *(^)(id<OPMonitorCodeProtocol>))setMonitorCodeIfError {
    __weak typeof(self) weakSelf = self;
    return ^OPMonitorEvent *(id<OPMonitorCodeProtocol> monitorCode) {
        typeof(weakSelf) self = weakSelf;
        if (self && !self.flushed && [monitorCode conformsToProtocol:@protocol(OPMonitorCodeProtocol)]) {
            self.innerMonitorCodeIfError = monitorCode;
        }
        return self;
    };
}

/*-------------------------------------------------------*/
//                    Error: 异常采集
/*-------------------------------------------------------*/
#pragma mark - Error

- (OPMonitorEvent *(^)(NSError *))setError {
    __weak typeof(self) weakSelf = self;
    return ^OPMonitorEvent *(NSError *error) {
        typeof(weakSelf) self = weakSelf;
        if (error && self && !self.flushed) {
            self.error = error;

            // OPMonitor 与 OPError 解耦
            // 目前 OPError 拆在不同的模块中，为兼容并避免循环依赖这里用一些手法处理
            Class cls = NSClassFromString(@"OPError");
            if(cls != nil) {
                SEL sel = NSSelectorFromString(@"disableAutoReport");
                if([error isKindOfClass:cls] && [error respondsToSelector:sel]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
                    [error performSelector:sel];
#pragma clang diagnostic pop
                }
            }
        }
        return self;
    };
}

- (OPMonitorEvent * (^)(NSString *))setErrorCode {
    __weak typeof(self) weakSelf = self;
    return ^OPMonitorEvent *(NSString *errorCode) {
        typeof(weakSelf) self = weakSelf;
        if (self && !self.flushed) {
            self.addCategoryValue(OPMonitorEventKey.error_code, errorCode);
        }
        return self;
    };
}

- (OPMonitorEvent * (^)(NSString *))setErrorMessage {
    __weak typeof(self) weakSelf = self;
    return ^OPMonitorEvent *(NSString *errorMessage) {
        typeof(weakSelf) self = weakSelf;
        if (self && !self.flushed) {
            self.addCategoryValue(OPMonitorEventKey.error_msg, errorMessage);
        }
        return self;
    };
}

/// 是否有错误信息
- (BOOL)hasError {
    return self.categoriesData[OPMonitorEventKey.error_msg] || self.categoriesData[OPMonitorEventKey.error_code];
}

/*-------------------------------------------------------*/
//                    Timing: 时间函数
/*-------------------------------------------------------*/
#pragma mark - Timing

- (OPMonitorEvent * _Nonnull (^ _Nonnull)(NSTimeInterval time))setTime {
    __weak typeof(self) weakSelf = self;
    return ^OPMonitorEvent *(NSTimeInterval time) {
        typeof(weakSelf) self = weakSelf;
        if (self && !self.flushed) {
            self.time = time;
            self.addMetricValue(OPMonitorEventKey.time, @((unsigned long long)(self.time * 1000)));
        }
        return self;
    };
}

- (OPMonitorEvent * _Nonnull (^ _Nonnull)(void))timing {
    __weak typeof(self) weakSelf = self;
    return ^OPMonitorEvent *(void) {
        typeof(weakSelf) self = weakSelf;
        if (self && !self.flushed) {
            NSTimeInterval time = NSDate.date.timeIntervalSince1970;
            if (self.startTime) {
                NSTimeInterval duration = time - self.startTime;
                self.endTime = time;
                self.addMetricValue(OPMonitorEventKey.duration, @((unsigned long long)(duration*1000)));
            }else {
                self.startTime = time;
            }
        }
        return self;
    };
}

- (OPMonitorEvent * _Nonnull (^ _Nonnull)(NSTimeInterval duration))setDuration {
    __weak typeof(self) weakSelf = self;
    return ^OPMonitorEvent *(NSTimeInterval duration) {
        typeof(weakSelf) self = weakSelf;
        if (self && !self.flushed) {
            self.addMetricValue(OPMonitorEventKey.duration, @((unsigned long long)(duration * 1000)));
        }
        return self;
    };
}

/*-------------------------------------------------------*/
//                    Data: 读取数据
/*-------------------------------------------------------*/

- (NSDictionary *)data {

    NSMutableDictionary *data = [NSMutableDictionary dictionary];
    self.categoriesData ? [data addEntriesFromDictionary:self.categoriesData.copy] : nil;
    self.metricsData ? [data addEntriesFromDictionary:self.metricsData.copy] : nil;
    return data.copy;
}

- (NSMutableDictionary *)metrics {
    return self.metricsData.copy;
}

- (NSMutableDictionary *)categories {
    return self.categoriesData.copy;
}

- (NSString *)jsonData {
    return [self JSON:self.data withOptions:NSJSONWritingPrettyPrinted];
}

/*-------------------------------------------------------*/
//              Common Utils: result_type
/*-------------------------------------------------------*/

- (OPMonitorEvent * _Nonnull (^ _Nonnull)(NSString * _Nullable resultType))setResultType {
    __weak typeof(self) weakSelf = self;
    return ^OPMonitorEvent *(NSString *resultType) {
        typeof(weakSelf) self = weakSelf;
        if (self && !self.flushed) {
            self.addCategoryValue(OPMonitorEventKey.result_type, resultType);
        }
        return self;
    };
}

- (OPMonitorEvent * _Nonnull (^ _Nonnull)(void))setResultTypeSuccess {
    __weak typeof(self) weakSelf = self;
    return ^OPMonitorEvent *(void) {
        typeof(weakSelf) self = weakSelf;
        if (self && !self.flushed) {
            self.setResultType(OPMonitorEventValue.success);
        }
        return self;
    };
}

- (OPMonitorEvent * _Nonnull (^ _Nonnull)(void))setResultTypeFail {
    __weak typeof(self) weakSelf = self;
    return ^OPMonitorEvent *(void) {
        typeof(weakSelf) self = weakSelf;
        if (self && !self.flushed) {
            self.setResultType(OPMonitorEventValue.fail);
        }
        return self;
    };
}

- (OPMonitorEvent * _Nonnull (^ _Nonnull)(void))setResultTypeCancel {
    __weak typeof(self) weakSelf = self;
    return ^OPMonitorEvent *(void) {
        typeof(weakSelf) self = weakSelf;
        if (self && !self.flushed) {
            self.setResultType(OPMonitorEventValue.fail);
        }
        return self;
    };
}

- (OPMonitorEvent * _Nonnull (^ _Nonnull)(void))setResultTypeTimeout {
    __weak typeof(self) weakSelf = self;
    return ^OPMonitorEvent *(void) {
        typeof(weakSelf) self = weakSelf;
        if (self && !self.flushed) {
            self.setResultType(OPMonitorEventValue.timeout);
        }
        return self;
    };
}

/*-------------------------------------------------------*/
//                      Others
/*-------------------------------------------------------*/

/// 生成 tag0,tag1,tag2...
- (NSString * _Nullable)tagsInLine {
    if (!_tags || _tags.count == 0) {
        return nil;
    }
    NSMutableString *tagsInLine = [NSMutableString string];
    __block BOOL firstItem = YES;
    [_tagsLock lock];
    [_tags enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, BOOL * _Nonnull stop) {
        if (!firstItem) {
            [tagsInLine appendString:@","];
        }
        [tagsInLine appendString:obj];
        if (firstItem) {
            firstItem = NO;
        }
    }];
    [_tagsLock unlock];
    return tagsInLine.copy;
}

/// 将 monitorCode 的数据应用到最终埋点数据上
- (void)applyMonitorCode:(id<OPMonitorCodeProtocol>)monitorCode {
    if (!monitorCode) {
        return;
    }
    // 优先使用主动设置的 level 信息
    if (self.eventLevel == 0) {
        // monitor 的建议 level 作为缺省值
        self.eventLevel = monitorCode.level;
        self.categoriesData[OPMonitorEventKey.monitor_level] = @(monitorCode.level);
    }

    self.categoriesData[OPMonitorEventKey.monitor_domain] = monitorCode.domain;
    self.categoriesData[OPMonitorEventKey.monitor_code] = @(monitorCode.code);
    self.categoriesData[OPMonitorEventKey.monitor_message] = monitorCode.message;

    // Normal 级别的埋点不打印行号列号
    if (self.eventLevel == OPMonitorLevelTrace
        || self.eventLevel == OPMonitorLevelWarn
        || self.eventLevel == OPMonitorLevelError) {
        self.categoriesData[OPMonitorEventKey.monitor_file] = self.fileName;
        self.categoriesData[OPMonitorEventKey.monitor_function] = self.funcName;
        self.metricsData[OPMonitorEventKey.monitor_line] = @(self.line);
    }
}

/// 将 operror 的错误码数据应用到最终埋点数据上,如果没有设置monitorcode，则往monitor_***的key上也上报一份
- (void)applyOPErrorMonitorCode:(id<OPMonitorCodeProtocol>)opErrorMonitorCode {
    if (!opErrorMonitorCode) {
        return;
    }
    self.categoriesData[OPMonitorEventKey.ope_monitor_level] = @(opErrorMonitorCode.level);
    self.categoriesData[OPMonitorEventKey.ope_monitor_domain] = opErrorMonitorCode.domain;
    self.categoriesData[OPMonitorEventKey.ope_monitor_code] = @(opErrorMonitorCode.code);
    self.categoriesData[OPMonitorEventKey.ope_monitor_message] = opErrorMonitorCode.message;
    // 优先使用主动设置的 level 信息
    if (self.eventLevel == 0) {
        // monitor 的建议 level 作为缺省值
        self.eventLevel = opErrorMonitorCode.level;
        self.categoriesData[OPMonitorEventKey.monitor_level] = @(opErrorMonitorCode.level);
    }
    
    if (!self.categoriesData[OPMonitorEventKey.monitor_domain]) {
        self.categoriesData[OPMonitorEventKey.monitor_domain] = opErrorMonitorCode.domain;
    }
    
    if (!self.categoriesData[OPMonitorEventKey.monitor_code]) {
        self.categoriesData[OPMonitorEventKey.monitor_code] = @(opErrorMonitorCode.code);
    }
    
    if (!self.categoriesData[OPMonitorEventKey.monitor_message]) {
        self.categoriesData[OPMonitorEventKey.monitor_message] = opErrorMonitorCode.message;;
    }
    // Normal 级别的埋点不打印行号列号
    if (self.eventLevel == OPMonitorLevelTrace
        || self.eventLevel == OPMonitorLevelWarn
        || self.eventLevel == OPMonitorLevelError) {
        self.categoriesData[OPMonitorEventKey.monitor_file] = self.fileName;
        self.categoriesData[OPMonitorEventKey.monitor_function] = self.funcName;
        self.metricsData[OPMonitorEventKey.monitor_line] = @(self.line);
    }
}

- (NSString *)JSON:(NSDictionary *)dict withOptions:(NSJSONWritingOptions)options
{
    if ([NSJSONSerialization isValidJSONObject:dict]) {
        NSData * data = [NSJSONSerialization dataWithJSONObject:dict options:options error:nil];
        return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    }
    return nil;
}

@end
