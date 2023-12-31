//
//  OPMonitorService.m
//  LarkOPInterface
//
//  Created by yinyuan on 2020/5/21.
//

#import "OPMonitorService.h"
#import <ECOProbe/ECOProbe-Swift.h>
#import "OPMacros.h"

@interface OPMonitorService()

@end

@implementation OPMonitorService

- (instancetype _Nonnull)initWithConfig:(OPMonitorServiceConfig * _Nullable)config
{
    self = [super init];
    if (self) {
        _config = config ?: [[OPMonitorServiceConfig alloc] initWithReportProtocol:nil logProtocol:nil];
    }
    return self;
}

/// 向全局默认的 MonitorService 注入上报、日志能力
/// @param config 外部实现的 config，包含上报、注入能力。
+ (void)setup:(OPMonitorServiceConfig * _Nonnull)config {
    OPMonitorService *service = [self defaultService];
    if ([service isKindOfClass:OPMonitorService.class]) {
        // FIXME: service.config 不能使用直接替换的方式，需要使用更新<甚至无感知的>方式实现上报与日志能力的注入
        // 外部在 OPMonitor 初始化过程中需要从 config 中读取配置，直接替换可能导致外部感知的 service.config 被释放掉
        [service.config injectConfigAbilityFrom:config];
    }
}

+ (id<OPMonitorServiceProtocol> _Nonnull)defaultService {
    static id<OPMonitorServiceProtocol> service;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        service = [[OPMonitorService alloc] initWithConfig:nil];
    });
    return service;
}

#pragma mark - OPMonitorServiceProtocol
- (void)flush:(OPMonitorEvent * _Nonnull)monitor platform:(OPMonitorReportPlatform)platform {
    if (!monitor) {
        return;
    }

    [self reportWithName:monitor.name metrics:monitor.metrics categories:monitor.categories platform:platform];
}

- (OPMonitorServiceConfig * _Nonnull)config {
    return _config;
}

- (void)log:(OPMonitorEvent * _Nonnull)monitor {
    if (!monitor) {
        return;
    }

    OPMonitorLogLevel level = OPMonitorLogLevelInfo;
    switch (monitor.level) {
        case OPMonitorLevelTrace:
        case OPMonitorLevelNormal:
            level = OPMonitorLogLevelInfo;
            break;
        case OPMonitorLevelWarn:
            level = OPMonitorLogLevelWarn;
            break;
        case OPMonitorLevelError:
            level = OPMonitorLogLevelError;
            break;
        case OPMonitorLevelFatal:
            level = OPMonitorLogLevelFatal;
            break;
        default:
            break;
    }

    NSString *tag = OPMonitorConstants.default_log_tag;
    NSString *file = monitor.fileName;
    NSString * function = monitor.funcName;
    NSInteger line = monitor.line;
    NSString *content = [NSString stringWithFormat:@"monitor_event:%@|%@|%@,data%@",
                         monitor.data[OPMonitorEventKey.time] ?: @"",
                         monitor.name ?: @"",
                         monitor.data[OPMonitorEventKey.trace_id] ?: @"",
                         monitor.jsonData];
    [self logWithLevel:level tag:tag file:file function:function line:line content:content];
}


/// 默认都执行 Task
/// @param name task 名称
- (BOOL)shouldExecuteTask:(NSString *) name {
    return YES;
}

#pragma mark - OPMonitorReportProtocol
- (void)reportWithName:(NSString * _Nonnull)name
               metrics:(NSDictionary<NSString *,id> * _Nullable)metrics
            categories:(NSDictionary<NSString *,id> * _Nullable)categories
              platform:(OPMonitorReportPlatform)platform {
    if ([self.config respondsToSelector:@selector(reportWithName:metrics:categories:platform:)]) {
        [self.config reportWithName:name metrics:metrics categories:categories platform:platform];
    } else {
        OPLogError(@"⚠️ Please setup the OPMonitorService.config!!!");
    }
}

#pragma mark - OPMonitorLogProtocol
- (void)logWithLevel:(OPMonitorLogLevel)level tag:(NSString * _Nullable)tag file:(NSString * _Nullable)file function:(NSString * _Nullable)function line:(NSInteger)line content:(NSString * _Nullable)content {
    if ([self.config respondsToSelector:@selector(logWithLevel:tag:file:function:line:content:)]) {
        [self.config logWithLevel:level tag:tag file:file function:function line:line content:content];
    } else {
        OPLog(level, @"[OPMonitorService][%@][%@][%@ %@:%@]%@", @(level),  tag, file, function, @(line), content);
    }
}

@end
