//
//  OPMonitorServiceConfig.m
//  LarkOPInterface
//
//  Created by yinyuan on 2020/5/21.
//

#import "OPMonitorServiceConfig.h"
#import "OPMonitorService.h"
#import <ECOProbe/ECOProbe-Swift.h>

@interface OPMonitorServiceConfig()

@property (nonatomic, strong, nonnull, readwrite) OPMonitorServiceRemoteConfig *remoteConfig;

@property (nonatomic, weak, nullable, readwrite) id<OPMonitorReportProtocol> reportProtocol;

@property (nonatomic, weak, nullable, readwrite) id<OPMonitorLogProtocol> logProtocol;

@end

@implementation OPMonitorServiceConfig

+ (OPMonitorServiceRemoteConfig * _Nonnull)globalRemoteConfig {
    static OPMonitorServiceRemoteConfig *config;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        config = [[OPMonitorServiceRemoteConfig alloc] init];
    });
    return config;
}


/// OPMonitorService 初始化，因调用时机可能会非常早(Passport 依赖)，初始化函数中需尽量避免其它依赖
/// @param reportProtocol 注入上报能力
/// @param logProtocol 注入日志能力
- (instancetype _Nonnull)initWithReportProtocol:(id<OPMonitorReportProtocol> _Nonnull)reportProtocol
                                    logProtocol:(id<OPMonitorLogProtocol> _Nonnull)logProtocol
{
    self = [super init];
    if (self) {
        _remoteConfig = OPMonitorServiceConfig.globalRemoteConfig;  // 默认使用全局远端配置
        _reportProtocol =  reportProtocol;
        _logProtocol = logProtocol;
        _defaultPlatform = OPMonitorReportPlatformUnknown;
    }
    return self;
}

- (void)injectConfigAbilityFrom:(OPMonitorServiceConfig * _Nonnull)config {
    if(config) {
        self.logProtocol = config.logProtocol;
        self.reportProtocol = config.reportProtocol;
    }
}

- (nullable NSDictionary<NSString *, id> *)debugWrapCategories:(NSDictionary<NSString *,id> * _Nullable)categories {
    if (!categories) {
        return nil;
    }
    NSMutableDictionary *mutableCategories = [categories mutableCopy];
    mutableCategories[@"debug_upload"] = @(YES);
    return [mutableCategories copy];
}

- (NSString * _Nonnull)defaultEventNameForDomain: (NSString * _Nullable) domain {
    // 针对 passport 业务域定制 event_name
    // TODO: 使用注入/远程下发的形式
    if (domain && [domain hasPrefix:@"client.passport.universal"]) {
        return OPMonitorConstants.default_passport_report_name;
    } else if (domain && [domain hasPrefix:@"client.passport."]) {
        return OPMonitorConstants.passport_watcher_name;
    }
    return self.defaultName ?: OPMonitorConstants.default_report_name;
}

#pragma mark - OPMonitorReportProtocol
- (void)reportWithName:(NSString * _Nonnull)name
               metrics:(NSDictionary<NSString *,id> * _Nullable)metrics
            categories:(NSDictionary<NSString *,id> * _Nullable)categories
              platform:(OPMonitorReportPlatform)platform {
    #if DEBUG
    /// 如果是DEBUG状态，且没有开启开关，则不进行report。同时，为了更好地标记是debug状态的上报，增加特殊标记
    if (!self.reportDebugEnable) {
        return;
    }
    categories = [self debugWrapCategories:categories];
    #endif


    // 延后 defaultPlatform 的 FG 调用至第一次上报请求发生时，避免在初始化流程中依赖 User 状态。
    // 依赖 User 时，外部可能会依赖 OPMonitor 导致单例死锁
    if(self.defaultPlatform == OPMonitorReportPlatformUnknown) {
        if (OPMonitorFeatureGatingWrapper.defaultReportToTea) {
            self.defaultPlatform = OPMonitorReportPlatformTea;
        } else {
            self.defaultPlatform = OPMonitorReportPlatformSlardar;
        }
    }
    // 外部初始化时，拿到的可能是 unknown，此时需要读一下最新值
    if(platform == OPMonitorReportPlatformUnknown) {
        platform = self.defaultPlatform;
    }

    NSMutableDictionary *data = NSMutableDictionary.dictionary;
    data[OPMonitorConstants.event_name] = name;
    if (metrics && [metrics isKindOfClass:NSDictionary.class]) {
        [data addEntriesFromDictionary:metrics];
    }
    if (categories && [categories isKindOfClass:NSDictionary.class]) {
        [data addEntriesFromDictionary:categories];
    }

    // 采样控制
    CGFloat sampleRate = [self.remoteConfig sampleRateWithData:data];
    if (sampleRate < 1) {
        // 因采样控制逻辑被拦截
        OPLogInfo(@"%@ sampleRate:%@", name, @(sampleRate));
        return;
    }

    if ([self.reportProtocol respondsToSelector:@selector(reportWithName:metrics:categories:platform:)]) {
        [self.reportProtocol reportWithName:name metrics:metrics categories:categories platform:platform];
    } else {
        OPLogError(@"⚠️ Please setup the OPMonitorServiceConfig.reportProtocol!!!");
    }
}

#pragma mark - OPMonitorLogProtocol
- (void)logWithLevel:(OPMonitorLogLevel)level tag:(NSString * _Nullable)tag file:(NSString * _Nullable)file function:(NSString * _Nullable)function line:(NSInteger)line content:(NSString * _Nullable)content {
    if ([self.logProtocol respondsToSelector:@selector(logWithLevel:tag:file:function:line:content:)]) {
        [self.logProtocol logWithLevel:level tag:tag file:file function:function line:line content:content];
    } else {
        OPLog(level, @"[OPMonitorService][%@][%@][%@ %@:%@]%@", @(level),  tag, file, function, @(line), content);
    }
}

@end
