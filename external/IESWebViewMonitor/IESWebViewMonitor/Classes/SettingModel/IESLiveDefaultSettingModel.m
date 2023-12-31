//
//  IESLiveDefaultSettingModel.m
//  IESWebViewMonitor
//
//  Created by renpengcheng on 2019/9/4.
//

// 默认配置
//  @{
//    @"APMReport": @{ // js
//            @"FPSMonitor" : @{
//                    @"interval": @(3000) // 间隔上报周期，单位ms
//                    },
//            @"MemoryMonitor": @{
//                    @"interval": @(3000) // 间隔上报周期，单位ms，iOS没有mem。。。
//                    },
//            },
//    @"performanceReport": @{
//            @"PerformanceMonitor": @{
//                    //@"interval": @(100), // 是否周期轮询到load, 如果不设置，即不轮询， 单位ms，不建议开启
//                    @"checkPoint": @[@"DOMContentLoaded", @"load"] // 需要上报的时机
//                    }
//            },
//    @"msgErrorReport": @{
//            @"StaticErrorMonitor": @{
//                    @"ignore": @[] // 忽略的error列表，支持正则
//                    },
//            },
//    @"resourceTimingRpeport": @{
//            @"StaticPerformanceMonitor": @{
//                    @"slowSession": @(8000), // 慢会话标准， 单位ms， 超过该时间则上报，不受采样率控制
//                    @"sampleRate": @(1) // 采样率，默认100%
//                    },
//            },
//    @"reportBlockList": @[@"about:blank"], // 上报黑名单
//    @"offlineMonitor": @(YES), //离线化监控，用户统计离线化覆盖率
//    @"navigationMonitor": @(NO), //跳转监控，客户端串联页面跳转链路
//    @"emptyMonitor": @(NO), //白屏监控
//    @"webCoreMonitor" : @(NO), // webCore 监控
//    };

#import "IESLiveDefaultSettingModel.h"
#import "BDHybridMonitorDefines.h"

@implementation IESLiveFPSReportConfig : NSObject

- (NSDictionary *)toDic {
    return @{@"interval" : @(self.interval)};
}

- (instancetype)copyWithZone:(NSZone *)zone {
    IESLiveFPSReportConfig *config = [[[self class] allocWithZone:zone] init];
    config.interval = self.interval;
    return config;
}

@end

@implementation IESLiveMemoryReportConfig : NSObject

- (NSDictionary *)toDic {
    return @{@"interval" : @(self.interval)};
}

- (instancetype)copyWithZone:(NSZone *)zone {
    IESLiveMemoryReportConfig *config = [[[self class] allocWithZone:zone] init];
    config.interval = self.interval;
    return config;
}

@end

@implementation IESLiveAPMReportConfig : NSObject

- (NSDictionary *)toDic {
    return @{
             @"APMReport": @{
                     @"FPSMonitor" : [self.fpsReportConfig toDic],
                     @"MemoryMonitor" : [self.memoryReportConfig toDic]
                     }
             };
}

- (instancetype)copyWithZone:(NSZone *)zone {
    IESLiveAPMReportConfig *config = [[[self class] allocWithZone:zone] init];
    config.fpsReportConfig = [self.fpsReportConfig copyWithZone:zone];
    config.memoryReportConfig = [self.memoryReportConfig copyWithZone:zone];
    return config;
}

@end

@implementation IESLivePerformanceMonitorConfig : NSObject

- (NSDictionary *)toDic {
    return @{@"checkPoint" : self.checkPoint ?: @[]};
}

- (instancetype)copyWithZone:(NSZone *)zone {
    IESLivePerformanceMonitorConfig *config = [[[self class] allocWithZone:zone] init];
    config.checkPoint = [self.checkPoint copyWithZone:zone];
    return config;
}

@end

@implementation IESLivePerformanceReportConfig : NSObject

- (NSDictionary *)toDic {
    return @{@"performanceReport" : @{@"PerformanceMonitor" :[self. performanceMonitorConfig toDic]}};
}

- (instancetype)copyWithZone:(NSZone *)zone {
    IESLivePerformanceReportConfig *config = [[[self class] allocWithZone:zone] init];
    config.performanceMonitorConfig = [self.performanceMonitorConfig copyWithZone:zone];
    return config;
}

@end

@implementation IESLiveStaticErrorMonitorConfig : NSObject

- (NSDictionary *)toDic {
    return @{@"ignore" : self.ignore ?: @[]};
}

- (instancetype)copyWithZone:(NSZone *)zone {
    IESLiveStaticErrorMonitorConfig *config = [[[self class] allocWithZone:zone] init];
    config.ignore = [self.ignore copyWithZone:zone];
    return config;
}

@end

@implementation IESLiveErrorMsgReportConfig : NSObject

- (NSDictionary *)toDic {
    return @{@"msgErrorReport" : @{@"StaticErrorMonitor" : [self.staticErrorMonitorConfig toDic]}};
}

- (instancetype)copyWithZone:(NSZone *)zone {
    IESLiveErrorMsgReportConfig *config = [[[self class] allocWithZone:zone] init];
    config.staticErrorMonitorConfig = [self.staticErrorMonitorConfig copyWithZone:zone];
    return config;
}

@end

@implementation IESLiveStaticPerformanceMonitor : NSObject

- (NSDictionary *)toDic {
    return @{@"slowSession" : @(self.slowSession),
             @"sampleRate" : @(self.sampleRate)
             };
}

- (instancetype)copyWithZone:(NSZone *)zone {
    IESLiveStaticPerformanceMonitor *config = [[[self class] allocWithZone:zone] init];
    config.slowSession = self.slowSession;
    config.sampleRate = self.sampleRate;
    return config;
}

@end

@implementation IESLiveResourceTimingReportConfig : NSObject

- (NSDictionary *)toDic {
    return @{@"resourceTimingRpeport" : @{@"StaticPerformanceMonitor": [self.staticPerformanceMonitorConfig toDic]}};
}

- (instancetype)copyWithZone:(NSZone *)zone {
    IESLiveResourceTimingReportConfig *config = [[[self class] allocWithZone:zone] init];
    config.staticPerformanceMonitorConfig = [self.staticPerformanceMonitorConfig copyWithZone:zone];
    return config;
}

@end

@implementation IESLiveDefaultSettingModel

+ (IESLiveDefaultSettingModel *)defaultModel {
    IESLiveDefaultSettingModel *model = [[IESLiveDefaultSettingModel alloc] init];
    
    // APMReport
    model.apmReportConfig = [[IESLiveAPMReportConfig alloc] init];
    IESLiveFPSReportConfig *fpsReportConfig = [[IESLiveFPSReportConfig alloc] init];
    fpsReportConfig.interval = 3000;
    IESLiveMemoryReportConfig *memoryReportConfig = [[IESLiveMemoryReportConfig alloc] init];
    memoryReportConfig.interval = 3000;
    model.apmReportConfig.fpsReportConfig = fpsReportConfig;
    model.apmReportConfig.memoryReportConfig = memoryReportConfig;
    
    // PerformanceReport
    IESLivePerformanceMonitorConfig *performanceMonitorConfig = [[IESLivePerformanceMonitorConfig alloc] init];
    performanceMonitorConfig.checkPoint = @[@"DOMContentLoaded", @"load"];
    IESLivePerformanceReportConfig *performanceReportConfig = [[IESLivePerformanceReportConfig alloc] init];
    performanceReportConfig.performanceMonitorConfig = performanceMonitorConfig;
    model.performanceReportConfig = performanceReportConfig;
    
    // ErrorMsgReportConfig
    IESLiveStaticErrorMonitorConfig *staticErrorMonitorConfig = [[IESLiveStaticErrorMonitorConfig alloc] init];
    staticErrorMonitorConfig.ignore = @[];
    IESLiveErrorMsgReportConfig *errorMsgReportConfig = [[IESLiveErrorMsgReportConfig alloc] init];
    errorMsgReportConfig.staticErrorMonitorConfig = staticErrorMonitorConfig;
    model.errorMsgReportConfig = errorMsgReportConfig;
    
    // ResourceTimingReportConfig
    IESLiveStaticPerformanceMonitor *staticPerformanceMonitor = [[IESLiveStaticPerformanceMonitor alloc] init];
    staticPerformanceMonitor.slowSession = 8000;
    staticPerformanceMonitor.sampleRate = 1;
    IESLiveResourceTimingReportConfig *resourceTimingReportConfig = [[IESLiveResourceTimingReportConfig alloc] init];
    resourceTimingReportConfig.staticPerformanceMonitorConfig = staticPerformanceMonitor;
    model.resourceTimingReportConfig = resourceTimingReportConfig;
    
    // OfflineMonitor
    model.offlineMonitor = NO;
    // NavigationMonitor
    model.navigationMonitor = YES;
    // webCore
    model.webCoreMonitor = YES;
    // EmptyMonitor
    model.emptyMonitor = YES;
    
    model.injectBrowser = YES;
    
    model.onlyMonitorOffline = NO;
    
    model.onlyMonitorNavigationFinish = NO;
    
    model.turnOnWebJSBMonitor = YES;
    model.turnOnWebFetchMonitor = YES; // 默认为YES，监控web的fetch这个jsb的错误
    model.turnOnWebBlankMonitor = YES; // 默认为YES，监控web的白屏

    model.turnOnLynxJSBMonitor = YES; // 默认为YES，监控lynx的JSB错误
    model.turnOnLynxFetchMonitor = YES; // 默认为YES，监控lynx的fetch这个jsb的错误
    model.turnOnLynxBlankMonitor = YES;
    
    model.turnOnWebJSBPerfMonitor = YES;
    model.turnOnLynxJSBPerfMonitor = YES;
    
    model.turnOnFalconMonitor = YES;
    
    model.turnOnLynxCustomErrorMonitor = YES;
    
    model.turnOnCollectBackAction = NO;
    model.turnOnCollectAsyncAction = YES;
    
    return model;
}

- (instancetype)copyWithZone:(NSZone *)zone {
    IESLiveDefaultSettingModel *settingModel = [[[self class] allocWithZone:zone] init];
    settingModel.apmReportConfig = [self.apmReportConfig copyWithZone:zone];
    settingModel.performanceReportConfig = [self.performanceReportConfig copyWithZone:zone];
    settingModel.errorMsgReportConfig = [self.errorMsgReportConfig copyWithZone:zone];
    settingModel.resourceTimingReportConfig = [self.resourceTimingReportConfig copyWithZone:zone];
    settingModel.blockList = [self.blockList copyWithZone:zone];
    settingModel.offlineMonitor = self.offlineMonitor;
    settingModel.navigationMonitor = self.navigationMonitor;
    settingModel.webCoreMonitor = self.webCoreMonitor;
    settingModel.emptyMonitor = self.emptyMonitor;
    settingModel.injectBrowser = self.injectBrowser;
    settingModel.bizTag = self.bizTag;
    settingModel.onlyMonitorNavigationFinish = self.onlyMonitorNavigationFinish;
    settingModel.webViewInitSels = self.webViewInitSels;
    settingModel.onlyMonitorOffline = self.onlyMonitorOffline;
    settingModel.turnOnWebJSBMonitor = self.turnOnWebJSBMonitor;
    settingModel.turnOnWebFetchMonitor = self.turnOnWebFetchMonitor;
    settingModel.turnOnWebBlankMonitor = self.turnOnWebBlankMonitor;
    settingModel.turnOnLynxJSBMonitor = self.turnOnLynxJSBMonitor;
    settingModel.turnOnLynxFetchMonitor = self.turnOnLynxFetchMonitor;
    settingModel.turnOnLynxBlankMonitor = self.turnOnLynxBlankMonitor;
    settingModel.turnOnWebJSBPerfMonitor = self.turnOnWebJSBPerfMonitor;
    settingModel.turnOnLynxJSBPerfMonitor = self.turnOnLynxJSBPerfMonitor;
    settingModel.turnOnFalconMonitor = self.turnOnFalconMonitor;
    settingModel.turnOnLynxCustomErrorMonitor = self.turnOnLynxCustomErrorMonitor;
    settingModel.turnOnCollectBackAction = self.turnOnCollectBackAction;
    settingModel.turnOnCollectAsyncAction = self.turnOnCollectAsyncAction;
    return settingModel;
}

- (NSDictionary *)toDic {
    NSMutableDictionary *dic = [NSMutableDictionary dictionary];
    [dic addEntriesFromDictionary:[self.apmReportConfig toDic]];
    [dic addEntriesFromDictionary:[self.performanceReportConfig toDic]];
    [dic addEntriesFromDictionary:[self.errorMsgReportConfig toDic]];
    [dic addEntriesFromDictionary:[self. resourceTimingReportConfig toDic]];
    [dic setObject:self.blockList ?: @[@"about:blank"] forKey:@"reportBlockList"];
    [dic setObject:@(self.offlineMonitor) forKey:kBDWMOfflineMonitor];
    [dic setObject:@(self.navigationMonitor) forKey:kBDWMNavigationMonitor];
    [dic setObject:@(self.webCoreMonitor) forKey:kBDWMWebCoreMonitor];
    [dic setObject:@(self.emptyMonitor) forKey:kBDWMEmptyMonitor];
    [dic setObject:@(self.onlyMonitorOffline) forKey:kBDWMOnlyMonitorOffline];
    [dic setObject:@(self.injectBrowser) forKey:kBDWMInjectBrowser];
    [dic setObject:self.bizTag ?: @"" forKey:kBDWMBizTag];
    [dic setObject:@(self.onlyMonitorNavigationFinish) forKey:kBDWMOnlyMonitorNavigationFinish];
    [dic setObject:self.webViewInitSels ?: @{} forKey:@"kWebViewInitSelsKey"];
    
    [dic setObject:@(self.turnOnWebJSBMonitor) forKey:kBDWMJSBMonitor];
    [dic setObject:@(self.turnOnWebFetchMonitor) forKey:kBDWMFetchMonitor];
    [dic setObject:@(self.turnOnWebBlankMonitor) forKey:kBDWMWebBlankDetectMonitor];
    
    [dic setObject:@(self.turnOnLynxJSBMonitor) forKey:kBDWMLynxJSBMonitor];
    [dic setObject:@(self.turnOnLynxFetchMonitor) forKey:kBDWMLynxFetchMonitor];
    [dic setObject:@(self.turnOnLynxBlankMonitor) forKey:kBDWMLynxBlankDetectMonitor];
    
    [dic setObject:@(self.turnOnWebJSBPerfMonitor) forKey:kBDWMWebJSBPerfMonitor];
    [dic setObject:@(self.turnOnLynxJSBPerfMonitor) forKey:kBDWMLynxJSBPerfMonitor];
    
    [dic setObject:@(self.turnOnFalconMonitor) forKey:kBDWMFalconMonitor];
    
    [dic setObject:@(self.turnOnLynxCustomErrorMonitor) forKey:kBDWMLynxCustomErrorMonitor];
    
    [dic setObject:@(self.turnOnCollectBackAction) forKey:kBDWMWebCollectBackAction];
    [dic setObject:@(self.turnOnCollectAsyncAction) forKey:kBDWMWebCollectAsyncAction];
    
    return [dic copy];
}

@end
