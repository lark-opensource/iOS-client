//
//  HMDClassCoverageManager.m
//  Pods
//
//  Created by kilroy on 2020/6/8.
//

#import "HMDClassCoverageManager.h"
#import "HMDInfo+DeviceInfo.h"
#import "HMDInfo+CustomInfo.h"
#import "HMDClassCoverageConfig.h"
#import "HMDALogProtocol.h"
#import "HMDClassCoverageChecker.h"
#import "HMDClassCoverageUploader.h"
#import "HMDNetworkReachability.h"
#import "HMDGCD.h"
#import "HMDMacroManager.h"
#import "HMDInfo+AppInfo.h"
#import "HMDUserDefaults.h"

@interface HMDClassCoverageManager ()

@property (nonatomic, strong) HMDClassCoverageChecker *checker;
@property (nonatomic, strong) HMDClassCoverageUploader *uploader;
@property (nonatomic, strong) dispatch_queue_t managerQueue;

@end


@implementation HMDClassCoverageManager

+ (instancetype)sharedInstance {
    static HMDClassCoverageManager *shared;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[self alloc] init];
    });
    return shared;
}

- (instancetype)init {
    if (self = [super init]) {
        _checker = [HMDClassCoverageChecker new];
        _uploader = [HMDClassCoverageUploader new];
        _managerQueue = dispatch_queue_create("com.heimdallr.classcoverage.manager", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

#pragma mark - HeimdallrModule Protocol Method

- (BOOL)needSyncStart {
    return NO;
}

- (BOOL)isAppUpdated {
    // 1 updated , 0 not updated, -1 default
    static int appUpdatedFlag = -1;
    if (appUpdatedFlag != -1) {
        return appUpdatedFlag == 1;
    }
    NSString* lastAppVersion = [[HMDUserDefaults standardUserDefaults] stringForKey:@"app_version"];
    NSString* currentAppVersion = [HMDInfo defaultInfo].shortVersion;
    [[HMDUserDefaults standardUserDefaults] setString:currentAppVersion forKey:@"app_version"];
    appUpdatedFlag = [lastAppVersion isEqualToString:currentAppVersion]?0:1;
    return appUpdatedFlag == 1;
}

- (void)start {
    [super start];
    //Check if device satisfy requirement
    BOOL deviceSupport = [self isDeviceSupported];
    BOOL configSupport = [self isConfigurationSupported];
    BOOL uploadEnvSupport = [self isUploadEnvSupported];
    if (deviceSupport && configSupport) {
        if ([self isAppUpdated]) {
            [HMDClassCoverageUploader cleanClassCoverageFiles];
            HMDALOG_PROTOCOL_INFO_TAG(@"Heimdallr", @"Heimdallr ClassCoverage Module delete old data because app is updated.");
            HMDLog(@"App is updated");
        }else if (uploadEnvSupport) {
            hmd_safe_dispatch_async(self.managerQueue, ^{
                [self.uploader uploadAfterAppLaunched];
            });
        }
        hmd_safe_dispatch_async(self.managerQueue, ^{
            [self activateClassCoverageChecker];
        });
    }
    else if (!deviceSupport) {
        HMDALOG_PROTOCOL_INFO_TAG(@"Heimdallr", @"Heimdallr ClassCoverage Module start failed because the performance of device is poor.");
        HMDLog(@"The performance of device is poor!");
    }
    else {
        HMDALOG_PROTOCOL_INFO_TAG(@"Heimdallr", @"Heimdallr ClassCoverage Module start failed because the test channel is not supported.");
        HMDLog(@"The test channel is not supported!");
    }
}

- (void)updateConfig:(HMDModuleConfig *)config {
    [super updateConfig:config];
    if ([self isDeviceSupported] && self.isRunning) {
        [self activateClassCoverageChecker];
    }
}

- (void)stop {
    [super stop];
    [self.checker invalidate];
}

- (BOOL)isDeviceSupported {
    HMDClassCoverageConfig *config = (HMDClassCoverageConfig *)self.config;
    return ([HMDInfo defaultInfo].devicePerformaceLevel >= config.devicePerformanceLevelThreshold);
}

- (BOOL)isConfigurationSupported {
    //Unavaliable in DEBUG Configuration
    return !HMD_IS_DEBUG;
}

- (BOOL)isUploadEnvSupported {
    HMDClassCoverageConfig *config = (HMDClassCoverageConfig *)self.config;
    return ((config.wifiOnly && [HMDNetworkReachability isWifiConnected])
            || (!config.wifiOnly && [HMDNetworkReachability isConnected]));
}

- (void)activateClassCoverageChecker {
    HMDClassCoverageConfig *config = (HMDClassCoverageConfig *)self.config;
    [self.checker activateByConfig:config.checkInterval];
}

#pragma mark - For Local Test

- (void)manuallyGenerateReportWithCheckInterval:(NSTimeInterval)checkInterval
                                       wifiOnly:(BOOL)wifiOnly {
    //check if device is supported && check if this device can upload files
    //Remove restriction of DEBUG in this case
    BOOL deviceSupport = ([HMDInfo defaultInfo].devicePerformaceLevel >= 2);
    BOOL uploadSupport = ((wifiOnly && [HMDNetworkReachability isWifiConnected]) || (!wifiOnly && [HMDNetworkReachability isConnected]));
    if (deviceSupport) {
        if (uploadSupport) {
            hmd_safe_dispatch_async(self.managerQueue, ^{
                [self.uploader uploadAfterAppLaunched];
            });
        }
        hmd_safe_dispatch_async(self.managerQueue, ^{
            [self.checker activateByConfig:checkInterval];
        });
    }
    else if (!deviceSupport) {
        HMDLog(@"The performance of device is poor!");
    }
}

@end
