//
//  HMDHeimdallrConfig.m
//  Heimdallr
//
//  Created by 刘诗彬 on 2018/12/13.
//

#import "HMDHeimdallrConfig.h"
#import "HMDGeneralAPISettings.h"
#import "HMDCustomEventSetting.h"
#import "NSObject+HMDAttributes.h"
#import "HMDHeimdallrConfig+cleanup.h"
#import "NSDictionary+HMDSafe.h"
#import "NSArray+HMDSafe.h"
#import "HMDCloudCommandConfig.h"
#import "HMDHermasCleanupSetting.h"
#import "HMDMacro.h"
CLANG_DIAGNOSTIC_PUSH
CLANG_DIAGNOSTIC_IGNORE_STRICT_PROTOTYPES
#import <Hermas/Hermas.h>
CLANG_DIAGNOSTIC_POP

NSString *const kEnablePerformanceMonitor = @"enable_performance_monitor";

@interface HMDHeimdallrConfig ()
@property (nonatomic, copy, readwrite) NSDictionary<NSString *,HMDModuleConfig *> *activeModulesMap;
@property (nonatomic, copy, readwrite) NSDictionary<NSString *, HMDModuleConfig *> *allModulesMap;
@property (nonatomic, strong, readwrite) HMDGeneralAPISettings *apiSettings;
@property (nonatomic, strong, readwrite) HMDCloudCommandConfig *cloudCommandConfig;
@end

@implementation HMDHeimdallrConfig

- (instancetype)init
{
    return [self initWithDictionary:nil];
}

- (instancetype)initWithDictionary:(NSDictionary *)data
{
    self = [super init];
    if (self) {
        [self parseConfigData:data];
    }
    return self;
}

- (instancetype)initWithJSONData:(NSData *)jsonData
{
    if (!jsonData) {
        return nil;
    }
    NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:nil];
    if (![dictionary isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    return [self initWithDictionary:dictionary];
}

- (void)parseConfigData:(NSDictionary *)data
{
    //general
    NSDictionary *generalDict = [data hmd_dictForKey:@"general"];
    NSDictionary *cleanupDict = [generalDict hmd_dictForKey:@"cleanup"];
    
    NSDictionary *apiSettingDict = [generalDict hmd_dictForKey:@"slardar_api_settings"];
    self.apiSettings = [HMDGeneralAPISettings hmd_objectWithDictionary:apiSettingDict];
    [self parseCleanupConfig:cleanupDict];
    
    //custom event settings
    NSDictionary *customEventSettingDict = [data hmd_dictForKey:@"custom_event_settings"];
    self.customEventSetting = [HMDCustomEventSetting hmd_objectWithDictionary:customEventSettingDict];
    
    self.commonInfo = [generalDict hmd_dictForKey:@"common_info"];
    
    //modules
    NSMutableDictionary *moduleConfigDict = [NSMutableDictionary dictionary];
    [moduleConfigDict hmd_addEntriesFromDict:[data hmd_dictForKey:@"exception_modules"]];
    [moduleConfigDict hmd_addEntriesFromDict:[data hmd_dictForKey:@"network_image_modules"]];
    [moduleConfigDict hmd_addEntriesFromDict:[data hmd_dictForKey:@"performance_modules"]];
    [moduleConfigDict hmd_setObject:[data hmd_dictForKey:@"tracing"] forKey:@"tracing"];

    [self parseHeimdallrModules:moduleConfigDict];
    
    //cloudcommand
    [self parseCloudCommandConfig:data];
}

- (void)parseHeimdallrModules:(NSDictionary *)moduleConfig
{
    NSMutableDictionary *activeModulesMap = [NSMutableDictionary dictionary];
    NSMutableDictionary *allModulesMap = [NSMutableDictionary dictionary];
    NSArray *avaliableModules = [HMDModuleConfig allRemoteModuleClasses];
    [moduleConfig enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        if (![obj isKindOfClass:[NSDictionary class]]) {
            return ;
        }
        for (Class clazz in avaliableModules) {
            if ([[(id)clazz configKey] isEqualToString:key]) {
                HMDModuleConfig *config = [[clazz alloc] initWithDictionary:obj];
                [config updateWithAPISettings:self.apiSettings];
                if ([config canStart]) {
                    [activeModulesMap hmd_setObject:config forKey:key];
                }
                [allModulesMap hmd_setObject:config forKey:key];
            }
        }
    }];

    self.activeModulesMap = activeModulesMap;
    self.allModulesMap = allModulesMap;
}

- (void)parseCleanupConfig:(NSDictionary *)cleanupConfig
{
    if (hermas_enabled()) {
        NSMutableDictionary *refactorCleaupConfig = [NSMutableDictionary dictionaryWithDictionary:cleanupConfig];
        NSDictionary *hermasCleanupDict = [refactorCleaupConfig hmd_dictForKey:@"hermas_setting"];
        
        [refactorCleaupConfig removeObjectForKey:@"hermas_setting"];
        _cleanupConfig = [HMDCleanupConfig hmd_objectWithDictionary:[refactorCleaupConfig copy]];
        if (!_cleanupConfig) {
            _cleanupConfig = [[HMDCleanupConfig alloc] init];
        }
        _cleanupConfig.hermasCleanupSetting = [HMDHermasCleanupSetting hmd_objectWithDictionary:hermasCleanupDict];
        [self prepareCleanConfig:_cleanupConfig];
    } else {
        _cleanupConfig = [HMDCleanupConfig hmd_objectWithDictionary:cleanupConfig];
        if (!_cleanupConfig) {
            _cleanupConfig = [[HMDCleanupConfig alloc] init];
        }
        [self prepareCleanConfig:_cleanupConfig];
    }
}

- (void)parseCloudCommandConfig:(NSDictionary *)config
{
    if (config == nil) return;

    NSMutableDictionary *cloudCommandDict = [NSMutableDictionary dictionary];
    NSDictionary *performanceDict = [config hmd_dictForKey:@"performance_modules"];
    NSDictionary *diskDict = [performanceDict hmd_dictForKey:@"disk"];
    NSArray<NSString *> *complianceRelativePaths = [diskDict hmd_arrayForKey:@"compliance_relative_paths"];
    
    [cloudCommandDict hmd_setObject:complianceRelativePaths forKey:@"compliance_relative_paths"];
    _cloudCommandConfig = [[HMDCloudCommandConfig alloc] initWithParams:cloudCommandDict];
}

#pragma mark - getter

- (NSDictionary *)allowedLogTypes
{
    return self.customEventSetting.allowedLogTypes;
}

- (BOOL)needHookTTMonitor
{
    return self.customEventSetting.needHookTTMonitor;
}

- (BOOL)enableEventTrace
{
    return self.customEventSetting.enableEventTrace;
}

- (BOOL)enableNetQualityReport {
    return self.apiSettings.performanceAPISetting.enableNetQualityReport;
}

#pragma mark judge

- (BOOL)logTypeEnabled:(NSString *)logtype
{
    return [self.customEventSetting.allowedLogTypes hmd_boolForKey:logtype];
}

- (BOOL)customLogTypeEnable:(NSString*)logType withMonitorData:(NSDictionary *)data
{
    BOOL needSample = [self.customEventSetting.customAllowLogType hmd_hasKey:logType];
    if (!needSample) {
        return YES;
    }
    NSDictionary *sampleDict = [self.customEventSetting.customAllowLogType hmd_dictForKey:logType];
    if (sampleDict && sampleDict.count) {
        NSString *jsonPath = [[sampleDict allKeys] firstObject];
        id value = [data valueForKeyPath:jsonPath];
        NSString *strValue;
        if (value && [value isKindOfClass:[NSNumber class]]) {
            strValue = [(NSNumber *)value stringValue];
        } else if (value && [value isKindOfClass:[NSString class]] && ![value isEqualToString:@""]) {
            strValue = value;
        } else {
            return YES;
        }
        NSDictionary *mDict = [sampleDict hmd_dictForKey:jsonPath];
        if ([mDict hmd_hasKey:strValue]) {
            BOOL needUpload = [[sampleDict hmd_dictForKey:jsonPath] hmd_boolForKey:strValue];
            return needUpload;
        }
        
    }
    return YES;
}

- (BOOL)metricTypeEnabled:(NSString *)metricType
{
    return [self.customEventSetting.allowedMetricTypes hmd_boolForKey:metricType];
}

- (BOOL)serviceTypeEnabled:(NSString *)serviceType
{
    return [self.customEventSetting.allowedServiceTypes hmd_boolForKey:serviceType];
}

- (BOOL)logTypeHighPriorityEnable:(NSString *)logType
{
    if (self.customEventSetting.logTypeHighPriorityList &&
        [self.customEventSetting.logTypeHighPriorityList isKindOfClass:NSArray.class] &&
        [self.customEventSetting.logTypeHighPriorityList containsObject:logType]) {
        return YES;
    }
    return NO;
}

- (BOOL)serviceHighPriorityEnable:(NSString *)serviceType
{
    if (self.customEventSetting.serviceHighPriorityList &&
        [self.customEventSetting.serviceHighPriorityList isKindOfClass:NSArray.class] &&
        [self.customEventSetting.serviceHighPriorityList containsObject:serviceType]) {
        return YES;
    }
    return NO;
}

@end
