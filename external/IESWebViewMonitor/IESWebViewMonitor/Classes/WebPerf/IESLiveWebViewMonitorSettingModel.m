//
//  IESLiveWebViewMonitorSettingModel.m
//  IESWebViewMonitor
//
//  Created by renpengcheng on 2019/8/2.
//

#import "IESLiveWebViewMonitorSettingModel.h"
#import "IESLiveWebViewMonitor.h"
#import "IESLiveMonitorUtils.h"

static NSMutableDictionary *pMonitorSetting = nil;

static NSString *kAPMReportKey = @"APMReport";
static NSString *kPerformanceReportKey = @"performanceReport";
static NSString *kMsgErrorReportKey = @"msgErrorReport";
static NSString *kBlockListKey = @"reportBlockList";
static NSString *kReportHttpErrorKey = @"httpError";
static NSString *kResourceTimingReportKey = @"resourceTimingRpeport";
static NSString *kCommonSettingKey = @"commonSetting";
static NSString *kORIGMapKey = @"kORIGMapKey";
static NSString *kModelKey = @"kModelKey";

#define iStr(str) @#str

#define TargetValueForKey(valueType, key) \
(dic[key] && [dic[key] isKindOfClass:[valueType class]] ? dic[key] : nil)

@interface IESLiveWebViewMonitorSettingModel ()

@property (nonatomic, copy) NSDictionary *apmReportConfig;

/** navigation timing 等信息*/
@property (nonatomic, copy) NSDictionary *performanceReportConfig;

/** js error， resource error 等信息配置*/
@property (nonatomic, copy) NSDictionary *errorMsgReportConfig;

/** resourceTiming 等信息配置*/
@property (nonatomic, copy) NSDictionary *resourceTimingReportConfig;

@property (nonatomic, copy) NSArray *blockList;

/** 通用配置*/
@property (nonatomic, copy) NSDictionary *commonSettings;

@property (nonatomic, copy) NSString *configDescp;

@property (nonatomic, copy) NSString *commonDesp;

@end

@implementation IESLiveWebViewMonitorSettingModel

- (instancetype)initWithSettingMap:(NSDictionary *)dic {
    if (self = [super init]) {
        _apmReportConfig = TargetValueForKey(NSDictionary, kAPMReportKey);
        _performanceReportConfig = TargetValueForKey(NSDictionary, kPerformanceReportKey);
        _errorMsgReportConfig = TargetValueForKey(NSDictionary, kMsgErrorReportKey);
        _resourceTimingReportConfig = TargetValueForKey(NSDictionary, kResourceTimingReportKey);
        _commonSettings = TargetValueForKey(NSDictionary, kCommonSettingKey);
        _blockList = TargetValueForKey(NSArray, kBlockListKey);
        [self setDefaultValueIfNeeded];
    }
    return self;
}

- (void)setDefaultValueIfNeeded {
    if (!(self.commonSettings.count)) {
        _commonSettings = @{};
    }
    
    if (!(self.apmReportConfig.count)) {
        self.apmReportConfig =  @{
                              @"FPSMonitor": @{
                                      @"interval": @(3000) // 间隔上报周期，单位ms
                                      },
                              @"MemoryMonitor": @{
                                      @"interval": @(3000) // 间隔上报周期，单位ms
                                      },
                              };
    }
    if (!(self.performanceReportConfig.count)) {
        self.performanceReportConfig = @{
                                            @"PerformanceMonitor": @{
                                                 //@"interval": @(100), // 是否周期轮询到load, 如果不设置，即不轮询， 单位ms
                                                 @"checkPoint": @[@"DOMContentLoaded", @"load"] // 需要上报的时机
                                                 }
                                         };
    }
    if (!(self.errorMsgReportConfig.count)) {
        self.errorMsgReportConfig = @{
                                        @"StaticErrorMonitor": @{
                                                @"ignore": @[]
                                                },
                                        };
    }
    if (!(self.resourceTimingReportConfig.count)) {
        self.resourceTimingReportConfig = @{
                                                @"StaticPerformanceMonitor": @{
                                                    @"slowSession": @(8000), // 慢会话标准， 单位ms， 超过改时间上报
                                                    @"sampleRate": @(1.0) // 采样率，默认100%
                                                    },
                                                };
    }
    if (!(self.blockList.count)
        || ![self.blockList containsObject:@"about:blank"]) {
        NSMutableArray *array = [(self.blockList ?: @[]) mutableCopy];
        [array addObject:@"about:blank"];
        self.blockList = [array copy];
    }
}

#pragma mark - public

+ (id)getValue:(NSDictionary *)dic cls:(Class)cls {
    while (cls) {
        if (dic[cls]) {
            return dic[cls];
        }
        cls = [cls superclass];
    }
    return nil;
}

+ (IESLiveWebViewMonitorSettingModel*)settingModelForWebView:(Class)webViewCls {
    return [self getValue:pMonitorSetting[kModelKey] cls:webViewCls];
}

+ (NSDictionary *)settingMapForWebView:(Class)webViewCls {
    return [self getValue:pMonitorSetting[kORIGMapKey] cls:webViewCls];
}

+ (void)setConfig:(NSDictionary *)config forClasses:(NSSet<Class>*)classes {
    NSDictionary *configCopy = [config copy];
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        pMonitorSetting = [NSMutableDictionary dictionary];
        pMonitorSetting[kORIGMapKey] = [NSMutableDictionary dictionary];
        pMonitorSetting[kModelKey] = [NSMutableDictionary dictionary];
    });
    
    IESLiveWebViewMonitorSettingModel *model = [[IESLiveWebViewMonitorSettingModel alloc]
                                                initWithSettingMap:configCopy];
    if (model) {
        for (Class cls in classes) {
            pMonitorSetting[kModelKey][(id <NSCopying>)cls] = model;
            pMonitorSetting[kORIGMapKey][(id <NSCopying>)cls] = configCopy;
        }
    }
}

+ (BOOL)switchStatusForKey:(NSString *)key webViewClass:(Class)webViewCls {
    if (key.length <= 0 || !webViewCls) {
        return NO;
    }
    NSDictionary *setting = [self settingMapForWebView:webViewCls];
    if (setting && setting[key]) {
        return [setting[key] boolValue]; 
    }
    return NO;
}

// filter classes which have already started monitor
+ (NSSet *)filterStartedClass:(NSSet<Class>*)classes {
    NSMutableSet *filterSet = [[NSMutableSet alloc] init];
    NSMutableDictionary *oriMaps = pMonitorSetting[kORIGMapKey];
    for (Class cls in classes) {
        if (!oriMaps[cls]) {
            [filterSet addObject:cls];
        }
    }
    return filterSet;
}

- (NSString *)jsonDescription {
    NSString *slardarConfig = iStr(SlardarHybrid('config', {
        sendCommonParams:
        %@,
        monitors:
        %@
    }));
    return [NSString stringWithFormat:slardarConfig, [self commonDesp], [self configDescp]];
}

- (void)setBid:(NSString *)bid {
    if (bid.length) {
        NSMutableDictionary *commonSettings = [self.commonSettings ?: @{} mutableCopy];
        commonSettings[@"bid"] = bid;
        self.commonSettings = [commonSettings copy];
        _bid = [bid copy];
    }
}

- (void)setPid:(NSString *)pid {
    if (pid.length) {
        NSMutableDictionary *commonSettings = [self.commonSettings ?: @{} mutableCopy];
        commonSettings[@"pid"] = pid;
        self.commonSettings = [commonSettings copy];
        _pid = [pid copy];
    }
}

- (void)setCommonSettings:(NSDictionary *)commonSettings {
    if (commonSettings.count) {
        _commonSettings = [commonSettings copy];
        _commonDesp = [[IESLiveMonitorUtils convertAndTrimToJsonData:self.commonSettings] copy];
    }
}

- (NSString *)commonDesp {
    if (!_commonDesp) {
        _commonDesp = [[IESLiveMonitorUtils convertAndTrimToJsonData:self.commonSettings] copy];
    }
    return _commonDesp;
}

- (NSString *)configDescp {
    if (!_configDescp) {
        NSMutableDictionary *configs = [NSMutableDictionary dictionary];
        !(self.apmReportConfig.count) ?: [configs addEntriesFromDictionary:self.apmReportConfig];
        !(self.performanceReportConfig.count) ?: [configs addEntriesFromDictionary:self.performanceReportConfig];
        !(self.errorMsgReportConfig.count) ?: [configs addEntriesFromDictionary:self.errorMsgReportConfig];
        !(self.resourceTimingReportConfig.count) ?: [configs addEntriesFromDictionary:self.resourceTimingReportConfig];
        _configDescp = [[IESLiveMonitorUtils convertAndTrimToJsonData:configs] copy];
    }
    return _configDescp;
}


@end
