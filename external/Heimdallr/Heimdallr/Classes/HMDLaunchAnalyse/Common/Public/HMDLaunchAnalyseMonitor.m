//
//  HMDLaunchAnalyseMonitor.m
//  AWECloudCommand
//
//  Created by maniackk on 2020/9/14.
//

#import "HMDLaunchAnalyseMonitor.h"
#import "Heimdallr+Private.h"
#import "HMDLaunchAnalyseConfig.h"
#import "HMDCaptureBacktrace.h"
#import "HMDUserDefaults.h"
#import "NSDictionary+HMDSafe.h"
// Utility
#import "HMDMacroManager.h"

// 硬编码，在HMDLaunchTracing有同名通知
static NSNotificationName const kHMDFinishLaunchNotificationName = @"kHMDFinishLaunchNotificationName";

#define kLAUNCHANALYSECONFIG  @"kLAUNCHANALYSECONFIG"

@interface HMDLaunchAnalyseMonitor()

@property (nonatomic, strong) HMDLaunchAnalyseConfig *customConfig;
@property (nonatomic, strong) HMDCaptureBacktrace *captureBacktrace;

@end

@implementation HMDLaunchAnalyseMonitor

+ (void)load
{
    if (HMD_IS_DEBUG) return;
    BOOL isBackgroundLaunch = [UIApplication sharedApplication].applicationState == UIApplicationStateBackground;
    if (!isBackgroundLaunch) {
        [[HMDLaunchAnalyseMonitor sharedMonitor] startLaunchSample];
    }
}

#pragma mark--- super implement

+ (instancetype)sharedMonitor {
    static HMDLaunchAnalyseMonitor *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[HMDLaunchAnalyseMonitor alloc] init];
    });
    return instance;
}

- (instancetype)init{
    self = [super init];
    if (self) {
        _customConfig = [self getLaunchAnalyseConfig];
        if (_customConfig) {
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notificationFinishLaunch) name:kHMDFinishLaunchNotificationName object:nil];
        }
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)start
{
    [super start];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveConfigNotification:) name:HMDConfigManagerDidUpdateNotification object:nil];
}

- (void)stop
{
    [super stop];
}

- (BOOL)needSyncStart {
    return YES;
}

- (BOOL)performanceDataSource {
    return NO;
}

- (BOOL)exceptionDataSource {
    return YES;
}

- (void)receiveConfigNotification:(NSNotification *)notification {
    if ([notification.object isKindOfClass:[NSDictionary class]]) {
        NSArray *appIDs = notification.object[HMDConfigManagerDidUpdateAppIDKey];
        HMDConfigManager *updatedConfigManager = notification.object[HMDConfigManagerDidUpdateConfigKey];
        if (appIDs.count && updatedConfigManager.appID && [appIDs containsObject:updatedConfigManager.appID]) {
            [self storeLaunchAnalyseConfig:updatedConfigManager.appID];
        }
    }
}

#pragma mark - private method

- (HMDLaunchAnalyseConfig *)getLaunchAnalyseConfig
{
    HMDLaunchAnalyseConfig *launchAnalyseConfig;
    NSDictionary *dic = [[HMDUserDefaults standardUserDefaults] objectForKeyCompatibleWithHistory:kLAUNCHANALYSECONFIG];
    if (dic) {
        launchAnalyseConfig = [[HMDLaunchAnalyseConfig alloc] init];
        launchAnalyseConfig.maxErrorTime = [dic hmd_integerForKey:@"max_error_time"];
        launchAnalyseConfig.maxCollectTime = [dic hmd_integerForKey:@"max_collect_time"];
        launchAnalyseConfig.enableOpen = [dic hmd_boolForKey:@"enable_open"];
    }
    return launchAnalyseConfig;
}

- (void)storeLaunchAnalyseConfig:(NSString *)appID
{
    HMDLaunchAnalyseConfig *launchAnalyseConfig;
    if (appID) {
        HMDHeimdallrConfig *config = [[HMDConfigManager sharedInstance] remoteConfigWithAppID:appID];
        NSArray *modules = config.activeModulesMap.allValues;
        for (HMDModuleConfig *config in modules) {
            id<HeimdallrModule> module = [config getModule];
            if ([[module moduleName] isEqualToString:kHMDModuleLaunchAnalyse]) {
                launchAnalyseConfig = (HMDLaunchAnalyseConfig *)config;
                break;
            }
        }
    }
    [[HMDUserDefaults standardUserDefaults] removeObjectForKey:kLAUNCHANALYSECONFIG];
    if (launchAnalyseConfig && launchAnalyseConfig.enableOpen) {
        NSMutableDictionary *dic = [NSMutableDictionary dictionary];
        [dic hmd_setObject:@(launchAnalyseConfig.maxCollectTime) forKey:@"max_collect_time"];
        [dic hmd_setObject:@(launchAnalyseConfig.maxErrorTime) forKey:@"max_error_time"];
        [dic hmd_setObject:@(launchAnalyseConfig.enableOpen) forKey:@"enable_open"];
        [[HMDUserDefaults standardUserDefaults] setObject:dic.copy forKey:kLAUNCHANALYSECONFIG];
    }
}

- (void)startLaunchSample
{
    if (self.customConfig && self.customConfig.maxCollectTime > 0)
    {
        [self.captureBacktrace startCapture];
    }
}

- (void)notificationFinishLaunch
{
    [self.captureBacktrace stopCapture:YES];
}

#pragma mark --- get method ---

- (HMDCaptureBacktrace *)captureBacktrace
{
    if (!_captureBacktrace) {
        _captureBacktrace = [[HMDCaptureBacktrace alloc] initCaptureWithType:@"launch_analyse" maxCaptureTime:self.customConfig.maxCollectTime maxErrorTime:self.customConfig.maxErrorTime];
    }
    return _captureBacktrace;
}

@end
