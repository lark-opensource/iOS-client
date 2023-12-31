//
//  HMDUploadHelper.m
//  Heimdallr
//
//  Created by fengyadong on 2018/3/8.
//

#import "HMDUploadHelper.h"
#import "HMDInfo.h"
#import "HMDNetworkHelper.h"
#import "HMDInjectedInfo.h"
#import "HMDInfo+AppInfo.h"
#import "HMDInfo+CustomInfo.h"
#import "HMDInfo+DeviceInfo.h"
#import "HMDInfo+DeviceEnv.h"
#import "HMDInfo+SystemInfo.h"
#import "HMDInfo+AutoTestInfo.h"
#import "HMDMacro.h"
CLANG_DIAGNOSTIC_PUSH
CLANG_DIAGNOSTIC_IGNORE_STRICT_PROTOTYPES
#import <Hermas/Hermas.h>
CLANG_DIAGNOSTIC_POP

#import <TTReachability/TTReachability.h>
#if RANGERSAPM
#import "HMDInfo+CPUModel.h"
#import "HMDInjectedInfo+APMInsightInfo.h"
#endif

//此字段用来过滤一些老版本的非法数据，如果后面解析规则改变的话也可以更改
static NSString *const KHMDCrashVersionString = @"1.0";

@interface HMDUploadHelper()

@property (nonatomic, strong) HMDInfo *info;
@property (nonatomic, strong) HMDInjectedInfo *injecedInfo;

@property (nonatomic, strong) NSString *currentLanguage;
@property (nonatomic, strong) NSString *currentRegion;
@property (nonatomic, assign) NSInteger currentMillisecondsFromGMT;

@end

@implementation HMDUploadHelper

+ (instancetype)sharedInstance {
    static HMDUploadHelper* instance = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[HMDUploadHelper alloc] init];
    });
    
    return instance;
}

- (instancetype)init {
    if (self = [super init]) {
        _info = [HMDInfo defaultInfo];
        _injecedInfo = [HMDInjectedInfo defaultInfo];
        if (hermas_enabled()) {
            self.currentRegion = [self.info currentRegion];
            self.currentLanguage = [self.info currentLanguage];
// #warning lanuage 和 region 重新设置都会重启所有APP，原则上不需要监听的
            self.currentMillisecondsFromGMT = [[NSTimeZone localTimeZone] secondsFromGMT] / 3600;
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(currentLocalDidChange) name:NSCurrentLocaleDidChangeNotification object:nil];
            
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(currentTimeZoneDidChange) name:NSSystemTimeZoneDidChangeNotification object:nil];
            
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(currentNetworkTypeDidChange) name:TTReachabilityChangedNotification object:nil];
            
            [self addObserverForInjectedInfo];
        }
    }
    
    return self;
}

- (void)dealloc {
    if (hermas_enabled()) {
        [[NSNotificationCenter defaultCenter] removeObserver:self];
        
        [[HMDInjectedInfo defaultInfo] removeObserver:self forKeyPath:@"sessionID"];
        [[HMDInjectedInfo defaultInfo] removeObserver:self forKeyPath:@"userID"];
        [[HMDInjectedInfo defaultInfo] removeObserver:self forKeyPath:@"deviceID"];
        [[HMDInjectedInfo defaultInfo] removeObserver:self forKeyPath:@"scopedUserID"];
        [[HMDInjectedInfo defaultInfo] removeObserver:self forKeyPath:@"scopedDeviceID"];
        [[HMDInjectedInfo defaultInfo] removeObserver:self forKeyPath:@"customHeader"];
    }
}

- (NSDictionary *)headerInfo {
    NSMutableDictionary *header = [NSMutableDictionary dictionaryWithCapacity:20];
    
    //自定义Header
    if (self.injecedInfo.customHeader.count > 0) {
        [header addEntriesFromDictionary:self.injecedInfo.customHeader];
    }
    
    //deviceInfo
    [header setValue:@"iOS" forKey:@"os"];
    NSInteger millisecondsFromGMT =  [[NSTimeZone localTimeZone] secondsFromGMT] / 3600;
    [header setValue:@(millisecondsFromGMT) forKey:@"timezone"];
    [header setValue:[NSNumber numberWithBool:[self.info isEnvAbnormal]] forKey:@"is_env_abnormal"];
    [header setValue:[self.info systemVersion] forKey:@"os_version"];
    [header setValue:[self.info decivceModel] forKey:@"device_model"];
    [header setValue:[self.info currentLanguage] forKey:@"language"];
    [header setValue:[self.info resolutionString] forKey:@"resolution"];
    [header setValue:[self.info countryCode] forKey:@"region"];
    [header setValue:[NSNumber numberWithUnsignedInteger:[self.info devicePerformaceLevel]] forKey:@"device_performance_level"];
#if RANGERSAPM
    [header setValue:[self.info cpuModel] forKey:@"cpu_model"];
    [header setValue:[HMDInfo CPUArchForMajor:self.info.cpuType minor:self.info.cpuSubType] forKey:@"cpu_arch"];
#endif
    [header setValue:@([self.info isMacARM]) forKey:@"is_mac_arm"];

    //appInfo
    [header setValue:[self.info bundleIdentifier] forKey:@"package_name"];
    [header setValue:[self.info shortVersion] forKey:@"app_version"];
    [header setValue:[self.info buildVersion] forKey:@"update_version_code"];
    [header setValue:[self.info appDisplayName] forKey:@"display_name"];
    [header setValue:@([self.info isUpgradeUser]) forKey:@"is_upgrade_user"];
    [header setValue:KHMDCrashVersionString forKey:@"crash_version"];
#if !RANGERSAPM
    [header setValue:[self.info sdkVersion] forKey:@"heimdallr_version"];
    [header setValue:[self.info sdkVersion] forKey:@"sdk_version"];
    [header setValue:@([self.info sdkVersionCode]) forKey:@"heimdallr_version_code"];
#else
    [header setValue:[self.info sdkVersion] forKey:@"crash_sdk_version_name"];
    [header setValue:@([self.info sdkVersionCode]) forKey:@"crash_sdk_version_code"];
#endif
    
    //networkInfo
    NSString *carrierName = [HMDNetworkHelper carrierName] ?: @"";
    [header setValue:carrierName forKey:@"carrier"];
    NSString *carrierMCC = [HMDNetworkHelper carrierMCC] ?: @"";
    NSString *carrierMNC = [HMDNetworkHelper carrierMNC] ?: @"";
    [header setValue:[NSString stringWithFormat:@"%@%@",carrierMCC,carrierMNC] forKey:@"mcc_mnc"];
    [header setValue:[HMDNetworkHelper connectTypeName] forKey:@"access"];
    NSArray<NSString *> *carrierRegions = [HMDNetworkHelper carrierRegions];
    if (carrierRegions.count == 0) {
        [header setValue:@"" forKey:@"carrier_region"];
    } else {
        [header setValue:carrierRegions.firstObject forKey:@"carrier_region"];
        
        for (NSUInteger index = 1; index < carrierRegions.count; index++) {
            [header setValue:[carrierRegions objectAtIndex:index]forKey:[NSString stringWithFormat:@"carrier_region%lu",(unsigned long)index]];
        }
    }

    //injectedInfo
    [header setValue:[self.injecedInfo channel] forKey:@"channel"];
    [header setValue:[self.injecedInfo appID] forKey:@"aid"];
    [header setValue:[self.injecedInfo appName] forKey:@"appName"];
    [header setValue:[self.injecedInfo installID] forKey:@"install_id"];
    [header setValue:[self.injecedInfo deviceID] forKey:@"device_id"];
    [header setValue:[self.injecedInfo userID] forKey:@"uid"];
    if ([self.injecedInfo scopedDeviceID]) {
        [header setValue:[self.injecedInfo scopedDeviceID] forKey:@"scoped_device_id"];
    }
    if ([self.injecedInfo scopedUserID]) {
        [header setValue:[self.injecedInfo scopedUserID] forKey:@"scoped_user_id"];
    }
#if RANGERSAPM
    [header setValue:[self.injecedInfo userUniqueID] forKey:@"user_unique_id"];
    [header setValue:[self.injecedInfo abVersionID] forKey:@"ab_sdk_version"];
    [header setValue:[self.injecedInfo ssID] forKey:@"ssid"];
#endif
    
    // atuoTestInfo
    if ([HMDInfo isBytest]) {
        [header setValue:[[HMDInfo defaultInfo] automationTestInfoDic] forKey:@"test_runtime"];
        
        // offlineInfo
        [header setValue:@(YES) forKey:@"offline"];
    }
    
    return [header copy];
}

#pragma mark refactor

- (NSDictionary *) infrequentChangeHeaderParam {
    NSMutableDictionary *header = [NSMutableDictionary dictionaryWithCapacity:20];
    
    // 自定义Header
    if (self.injecedInfo.customHeader.count > 0) {
        [header addEntriesFromDictionary:self.injecedInfo.customHeader];
    }
    
    // deviceInfo
    // change when running
    [header setValue:@(self.currentMillisecondsFromGMT) forKey:@"timezone"];
    [header setValue:self.currentLanguage forKey:@"language"];
    [header setValue:self.currentRegion forKey:@"region"];
    // change when not running
    [header setValue:[self.info systemVersion] forKey:@"os_version"];
    
    

    //appInfo
    // change when not running
    [header setValue:[self.info shortVersion] forKey:@"app_version"];
    [header setValue:[self.info buildVersion] forKey:@"update_version_code"];
    [header setValue:@([self.info isUpgradeUser]) forKey:@"is_upgrade_user"];
    [header setValue:KHMDCrashVersionString forKey:@"crash_version"];
    [header setValue:[self.info sdkVersion] forKey:@"heimdallr_version"];
    [header setValue:[self.info sdkVersion] forKey:@"sdk_version"];
    [header setValue:@([self.info sdkVersionCode]) forKey:@"heimdallr_version_code"];
    
    
    //networkInfo
    // change when running
    NSString *carrierName = [HMDNetworkHelper carrierName] ?: @"";
    [header setValue:carrierName forKey:@"carrier"];
    NSString *carrierMCC = [HMDNetworkHelper carrierMCC] ?: @"";
    NSString *carrierMNC = [HMDNetworkHelper carrierMNC] ?: @"";
    [header setValue:[NSString stringWithFormat:@"%@%@",carrierMCC,carrierMNC] forKey:@"mcc_mnc"];
    // #warning access 暂定为低频变化（相对于hermas文件切换频率）
    [header setValue:[HMDNetworkHelper connectTypeName] forKey:@"access"];
    NSArray<NSString *> *carrierRegions = [HMDNetworkHelper carrierRegions];
    if (carrierRegions.count == 0) {
        [header setValue:@"" forKey:@"carrier_region"];
    } else {
        [header setValue:carrierRegions.firstObject forKey:@"carrier_region"];
        
        for (NSUInteger index = 1; index < carrierRegions.count; index++) {
            [header setValue:[carrierRegions objectAtIndex:index]forKey:[NSString stringWithFormat:@"carrier_region%lu",(unsigned long)index]];
        }
    }


    //injectedInfo
    // change when running
    [header setValue:[self.injecedInfo deviceID] forKey:@"device_id"];
    [header setValue:[self.injecedInfo userID] forKey:@"uid"];
    if ([self.injecedInfo scopedDeviceID]) {
        [header setValue:[self.injecedInfo scopedDeviceID] forKey:@"scoped_device_id"];
    }
    if ([self.injecedInfo scopedUserID]) {
        [header setValue:[self.injecedInfo scopedUserID] forKey:@"scoped_user_id"];
    }
    
    // change when not running
    [header setValue:[self.injecedInfo installID] forKey:@"install_id"];
    
    
    // atuoTestInfo
    // change when running
    if ([HMDInfo isBytest]) {
        [header setValue:[[HMDInfo defaultInfo] automationTestInfoDic] forKey:@"test_runtime"];
        
        // offlineInfo
        [header setValue:@(YES) forKey:@"offline"];
    }
    
    return [header copy];
}

- (NSDictionary *) constantHeaderParam {
    NSMutableDictionary *header = [NSMutableDictionary dictionaryWithCapacity:20];

    
    //deviceInfo
    [header setValue:@"iOS" forKey:@"os"];
    [header setValue:[NSNumber numberWithBool:[self.info isEnvAbnormal]] forKey:@"is_env_abnormal"];
    [header setValue:[self.info decivceModel] forKey:@"device_model"];
    [header setValue:[self.info resolutionString] forKey:@"resolution"];
    [header setValue:[NSNumber numberWithUnsignedInteger:[self.info devicePerformaceLevel]] forKey:@"device_performance_level"];
    [header setValue:@([self.info isMacARM]) forKey:@"is_mac_arm"];

    //appInfo
    [header setValue:[self.info bundleIdentifier] forKey:@"package_name"];
    [header setValue:[self.info appDisplayName] forKey:@"display_name"];

    //injectedInfo
    [header setValue:[self.injecedInfo channel] forKey:@"channel"];
    [header setValue:[self.injecedInfo appID] forKey:@"aid"];
    [header setValue:[self.injecedInfo appName] forKey:@"appName"];
    
    return [header copy];
}

#pragma mark KVO
- (void)addObserverForInjectedInfo {
    [[HMDInjectedInfo defaultInfo] addObserver:self
                                    forKeyPath:@"sessionID"
                                       options:0
                                       context:nil];
    [[HMDInjectedInfo defaultInfo] addObserver:self
                                    forKeyPath:@"userID"
                                       options:0
                                       context:nil];
    [[HMDInjectedInfo defaultInfo] addObserver:self
                                    forKeyPath:@"deviceID"
                                       options:0
                                       context:nil];
    [[HMDInjectedInfo defaultInfo] addObserver:self
                                    forKeyPath:@"scopedUserID"
                                       options:0
                                       context:nil];
    [[HMDInjectedInfo defaultInfo] addObserver:self
                                    forKeyPath:@"scopedDeviceID"
                                       options:0
                                       context:nil];
    [[HMDInjectedInfo defaultInfo] addObserver:self
                                    forKeyPath:@"customHeader"
                                       options:0
                                       context:nil];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    [[HMEngine sharedEngine] updateReportHeader:[self infrequentChangeHeaderParam]];
}

#pragma mark NSNotification
- (void)currentLocalDidChange {
    if (![self.currentLanguage isEqualToString:[self.info currentLanguage]] || ![self.currentRegion isEqualToString:[self.info currentRegion]]) {
        self.currentRegion = [self.info currentRegion];
        self.currentLanguage = [self.info currentLanguage];
        [[HMEngine sharedEngine] updateReportHeader:[self infrequentChangeHeaderParam]];
    }
}

- (void)currentTimeZoneDidChange {
    [[HMEngine sharedEngine] updateReportHeader:[self infrequentChangeHeaderParam]];
}

- (void)currentCarrierDidChange {
    [[HMEngine sharedEngine] updateReportHeader:[self infrequentChangeHeaderParam]];
}

- (void)currentNetworkTypeDidChange {
    [[HMEngine sharedEngine] updateReportHeader:[self infrequentChangeHeaderParam]];
}

@end
