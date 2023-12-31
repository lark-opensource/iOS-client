//
//  TSPKConfigs.m
//  Aweme
//
//  Created by admin on 2021/11/13.
//

#import "TSPKConfigs.h"
#import <ByteDanceKit/NSDictionary+BTDAdditions.h>
#import <ByteDanceKit/NSArray+BTDAdditions.h>
#import "TSPrivacyKitConstants.h"
#import "TSPKLock.h"

static NSString * const TSPKDetectorKey = @"Detector";
static NSString * const TSPKRuleKey = @"Rule";
static NSString * const TSPKVersionKey = @"Version";

@interface TSPKConfigs()

@property (nonatomic) BOOL enableRelativeTime;
@property (nonatomic, strong) id<TSPKLock> lock;
@end

@implementation TSPKConfigs

- (instancetype)init {
    if (self = [super init]) {
        _lock = [TSPKLockFactory getLock];
        _enableRelativeTime = YES;
    }
    return self;
}

+ (instancetype)sharedConfig {
    static TSPKConfigs *config;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        config = [[TSPKConfigs alloc] init];
    });
    return config;
}

- (void)setMonitorConfig:(NSDictionary *__nullable)config {
    _monitorConfig = config;
    [self updateEnableReceiveExternalLog];
}

- (NSNumber *)isDataTypeEnable:(NSString *)dataType {
    NSDictionary *channel = [_monitorConfig btd_dictionaryValueForKey:@"channel"];
    NSDictionary *dataTypeDict = [channel btd_dictionaryValueForKey:@"data_types"];
    NSNumber *isEnable = [dataTypeDict btd_numberValueForKey:dataType];
    return isEnable;
}

- (NSNumber *)isPipelineEnable:(NSString *)pipelineName {
    NSDictionary *channel = [_monitorConfig btd_dictionaryValueForKey:@"channel"];
    NSDictionary *pipelineDict = [channel btd_dictionaryValueForKey:@"pipelines"];
    NSNumber *isEnable = [pipelineDict btd_numberValueForKey:pipelineName];
    return isEnable;
}

- (NSNumber *)isApiEnable:(NSString *)api {
    NSDictionary *channel = [_monitorConfig btd_dictionaryValueForKey:@"channel"];
    NSDictionary *apiDict = [channel btd_dictionaryValueForKey:@"apis"];
    NSNumber *isEnable = [apiDict btd_numberValueForKey:api];
    return isEnable;
}

- (NSNumber *)isRuleEngineDataTypeEnable:(NSString *)dataType {
    NSDictionary *channel = [_monitorConfig btd_dictionaryValueForKey:@"rule_engine_channel"];
    NSDictionary *dataTypeDict = [channel btd_dictionaryValueForKey:@"data_types"];
    NSNumber *isEnable = [dataTypeDict btd_numberValueForKey:dataType];
    return isEnable;
}
 
- (NSNumber *)isRuleEnginePipelineEnable:(NSString *)pipelineName {
    NSDictionary *channel = [_monitorConfig btd_dictionaryValueForKey:@"rule_engine_channel"];
    NSDictionary *pipelineDict = [channel btd_dictionaryValueForKey:@"pipelines"];
    NSNumber *isEnable = [pipelineDict btd_numberValueForKey:pipelineName];
    return isEnable;
}
 
- (NSNumber *)isRuleEngineApiEnable:(NSString *)api {
    NSDictionary *channel = [_monitorConfig btd_dictionaryValueForKey:@"rule_engine_channel"];
    NSDictionary *apiDict = [channel btd_dictionaryValueForKey:@"apis"];
    NSNumber *isEnable = [apiDict btd_numberValueForKey:api];
    return isEnable;
}

- (NSArray *)ruleConfigs {
    return [_monitorConfig btd_arrayValueForKey:TSPKRuleKey];
}

- (NSDictionary *)detectorConfigs {
    NSDictionary *configs = [_monitorConfig btd_dictionaryValueForKey:TSPKDetectorKey];
    if (configs) {
        return configs;
    } else {
        return _defaultDetectedPlanConfigs;
    }
}

- (NSDictionary *)customAnchorConfigs {
    return [_monitorConfig btd_dictionaryValueForKey:@"CustomAnchor"];
}

- (NSArray * __nullable)dynamicAspectConfigs{
    NSArray *config = [_monitorConfig btd_arrayValueForKey:@"Aspect"];
    if (config == nil) {
        // set dafault value
        /*        {                                   \
         \"klassName\": \"UIDevice\",              \
         \"methodName\": \"identifierForVendor\",             \
         \"methodVariants\": [\"tspk_identifierForVendor\", \"swizzled_identifierForVendor\"],             \
         \"apiType\": \"IDFV\",             \
         \"returnType\":\"@\",             \
         \"needFuse\": true,                 \
         \"isClassMethod\": false          \
       }, */
        NSString *defaultStr = @"[]";
//      defaultStr = @"[                          \
//            {                                               \
//              \"klassName\": \"ASIdentifierManager\",              \
//              \"methodName\": \"advertisingIdentifier\",             \
//              \"apiType\": \"PnS_IDFA\",             \
//              \"returnType\":\"@\",             \
//              \"needFuse\": false,                 \
//              \"isClassMethod\": false,          \
//              \"detector\": \"MethodDenyDetector\",          \
//              \"needLogCaller\": true                        \
//            }                                                \
//          ]";
        NSError *err;
        NSData *objectData = [defaultStr dataUsingEncoding:NSUTF8StringEncoding];
        config = [NSJSONSerialization JSONObjectWithData:objectData
                                              options:NSJSONReadingMutableContainers
                                                error:&err];
    }
    return config;
}

- (NSArray *)apiStatisticsConfigs {
    return [_monitorConfig btd_arrayValueForKey:@"api_statistics_configs"];
}

- (NSDictionary *)performanceStatisticsConfigs {
    return [_monitorConfig btd_dictionaryValueForKey:@"PerformanceStatistics"];
}

- (NSDictionary *)crossPlatformConfigs {
    return [_monitorConfig btd_dictionaryValueForKey:@"CrossPlatform"];
}

- (NSDictionary *__nullable)callFilterConfigs {
    return [_monitorConfig btd_dictionaryValueForKey:@"call_filter"];
}

- (NSDictionary *__nullable)signalConfigs {
    return [_monitorConfig btd_dictionaryValueForKey:@"signal"];
}

- (NSArray *__nullable)pageStatusConfigs {
    return [_monitorConfig btd_arrayValueForKey:@"page_status"];
}

- (BOOL)enableMergeCustomAndSystemBacktraces {
    return [_monitorConfig btd_boolValueForKey:@"merge_custom_system_backtraces" default:YES];
}

- (BOOL)enableRemoveLastStartBacktrace {
    return [_monitorConfig btd_boolValueForKey:@"remove_last_start_backtraces" default:NO];
}

- (BOOL)enableSetupAppLifeCycleObserver {
    return [_monitorConfig btd_boolValueForKey:@"enable_app_life_cycle_observer" default:YES];
}

- (BOOL)enableSetupMediaNotificationObserver {
    return [_monitorConfig btd_boolValueForKey:@"enable_media_notification_observer" default:YES];
}

static NSString *const TSPKEnableReceiveExternalLogUserDefaultKey = @"TSPKEnableReceiveExternalLogKey";
static NSString *const TSPKEnableReceiveExternalLogServerKey = @"enable_receive_external_log";

- (BOOL)enableReceiveExternalLog {
    BOOL enable = NO;
    if (_monitorConfig != nil) {
        enable = [_monitorConfig btd_boolValueForKey:TSPKEnableReceiveExternalLogServerKey default:NO];
    } else {
        enable = [[NSUserDefaults standardUserDefaults] boolForKey:TSPKEnableReceiveExternalLogUserDefaultKey];
    }
    return enable;
}

- (void)updateEnableReceiveExternalLog {
    BOOL enable = [_monitorConfig btd_boolValueForKey:TSPKEnableReceiveExternalLogServerKey default:NO];
    [[NSUserDefaults standardUserDefaults] setBool:enable forKey:TSPKEnableReceiveExternalLogUserDefaultKey];
}

- (BOOL)isEnableUploadAPICostTimeStatistics {
    return [[self performanceStatisticsConfigs] btd_boolValueForKey:@"APICostTimeStatistics"];
}

- (NSString *)settingVersion {
    NSString *settingVersionStr = (NSString *)[_monitorConfig objectForKey:TSPKVersionKey];
    return [settingVersionStr length] > 0 ? settingVersionStr : @"";
}

- (BOOL)isRelativeTimeEnable {
    NSNumber *enableRelativeTime = (NSNumber *)[_monitorConfig objectForKey:@"EnableRelativeTime"];
    return enableRelativeTime == nil ? YES : [enableRelativeTime boolValue];
}

- (BOOL)enable {
    NSNumber *enable = (NSNumber *)[_monitorConfig objectForKey:@"Enable"];
    return enable == nil ? YES : [enable boolValue];
}

- (BOOL)enableNetworkInit {
    NSNumber *enable = (NSNumber *)[_monitorConfig objectForKey:@"EnableNetworkInit"];
    return enable == nil ? NO : [enable boolValue];
}

- (BOOL)enableUploadAlog {
    NSNumber *enable = (NSNumber *)[_monitorConfig objectForKey:@"alog_enabled"];
    return enable == nil ? YES : [enable boolValue];
}

- (NSTimeInterval)timeRangeToUploadAlog {
    NSNumber *timeRange = (NSNumber *)[_monitorConfig objectForKey:@"alog_duration"];
    return timeRange == nil ? 2 : [timeRange doubleValue];
}

- (NSTimeInterval)timeDelayToUploadAlog {
    NSNumber *timeDelay = (NSNumber *)[_monitorConfig objectForKey:@"alog_upload_time_delay"];
    return timeDelay == nil ? 2 : [timeDelay doubleValue];
}

- (NSInteger)maxUploadCount {
    NSNumber *maxUploadCount = (NSNumber *)[_monitorConfig objectForKey:@"alog_max_upload_count"];
    return maxUploadCount == nil ? 2 : [maxUploadCount integerValue];
}

- (BOOL)enablePermissionChecker {
    NSNumber *enable = (NSNumber *)[_monitorConfig objectForKey:@"enablePermissionChecker"];
    return enable == nil ? YES : [enable boolValue];
}

- (BOOL)enableViewControllerPreload {
    NSNumber *enable = (NSNumber *)[_monitorConfig objectForKey:@"enableViewControllerPreload"];
    return enable == nil ? YES : [enable boolValue];
}

- (BOOL)enableBizInfoUpload {
    NSNumber *enable = (NSNumber *)[_monitorConfig objectForKey:@"enableBizInfoUpload"];
    return enable == nil ? YES : [enable boolValue];
}

- (NSInteger)maxURLCacheSize {
    NSNumber *urlMaxCacheSize = [_monitorConfig btd_numberValueForKey:@"maxURLCacheSize"];
    return urlMaxCacheSize == nil ? 3 : [urlMaxCacheSize integerValue];
}

- (void)updateRuleAndDetectorPartOfMonitorConfig:(NSDictionary *)monitorConfig {
    [self.lock lock];
    NSMutableDictionary *mutableNewMonitorConfig = _monitorConfig.mutableCopy;
    mutableNewMonitorConfig[TSPKDetectorKey] = monitorConfig[TSPKDetectorKey];
    mutableNewMonitorConfig[TSPKRuleKey] = monitorConfig[TSPKRuleKey];
    mutableNewMonitorConfig[TSPKVersionKey] = monitorConfig[TSPKVersionKey];
    
    _monitorConfig = mutableNewMonitorConfig.copy;
    
    [self.lock unlock];
}

- (NSArray *)frequencyConfigs {
    NSArray *frequencyConfigs = [_monitorConfig btd_arrayValueForKey:@"frequency_configs"];
    return frequencyConfigs;
}

- (NSArray *)cacheConfigs {
    return [_monitorConfig btd_arrayValueForKey:@"cache_configs"];
}

- (BOOL)enableLocationDelegate {
    NSNumber *enable = (NSNumber *)[_monitorConfig objectForKey:@"enable_location_delegate"];
    return enable == nil ? NO : [enable boolValue];
}

- (BOOL)enableCalendarRequestCompletion {
    NSNumber *enable = (NSNumber *)[_monitorConfig objectForKey:@"enable_calendar_request_completion"];
    return enable == nil ? NO : [enable boolValue];
}

- (BOOL)enableUseAppLifeCycleCurrentTopView {
    NSNumber *enable = (NSNumber *)[_monitorConfig objectForKey:@"enable_use_applifecycle_current_top_view"];
    return enable == nil ? NO : [enable boolValue];
}

- (BOOL)enableGuardUserInput
{
    NSNumber *sampleRateNumber = [_monitorConfig btd_numberValueForKey:@"guard_user_input_sample_rate"];
    NSUInteger sampleRate = sampleRateNumber == nil ? 0 : [sampleRateNumber unsignedIntegerValue];
    return [self isEnableForSampleRate:sampleRate];
}

- (BOOL)enableUploadStack
{
    NSNumber *enable = (NSNumber *)[_monitorConfig objectForKey:@"enable_upload_stack"];
    return enable == nil ? NO : [enable boolValue];
}

- (BOOL)isEnableUploadStackWithApiId:(NSNumber *)apiId
{
    NSDictionary *apiSampleRateDic = [_monitorConfig btd_dictionaryValueForKey:@"api_upload_stack_sample_rate"];
    NSString *apiIdString = [NSString stringWithFormat:@"%@",apiId];
    NSUInteger sampleRate;
    if ([[apiSampleRateDic allKeys] containsObject:apiIdString]) {
        sampleRate = [apiSampleRateDic btd_intValueForKey:apiIdString];
    } else {
        sampleRate = 1;
    }
    
    return [self isEnableForSampleRate:sampleRate];
}

- (BOOL)isEnableForSampleRate:(NSUInteger)sampleRate
{
    if (sampleRate == 0) {
        return NO;
    }
    if (sampleRate == 1) {
        return YES;
    }
    // Sampling based on timestamp to ensure dispersion
    // For example, in the case of SampleRate == 10, the probability of timestamp modulo 10 == 1 is 1/10
    NSUInteger currentTime = (NSUInteger)CFAbsoluteTimeGetCurrent();
    return currentTime % sampleRate == 1;
}

@end
