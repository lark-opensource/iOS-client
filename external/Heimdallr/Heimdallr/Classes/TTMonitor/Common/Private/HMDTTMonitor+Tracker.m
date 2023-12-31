//
//  HMDTTMonitor+Tracker.m
//  Heimdallr
//
//  Created by Nickyo on 2023/9/6.
//

#import "HMDTTMonitor+Tracker.h"
#import "HMDSessionTracker.h"

static NSString * const kHeimdallrSDKAppID = @"2085";
static NSInteger const kHeimdallrSDKFlushCount = 5;

@implementation HMDTTMonitor (Tracker)

+ (instancetype)heimdallrTTMonitor {
    static HMDTTMonitor *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        HMDInjectedInfo *injectedInfo = [HMDInjectedInfo defaultInfo];
        NSAssert(nil != injectedInfo.appID, @"The host appID for 2085_monitor can NOT be nil!");
        
        HMDTTMonitorUserInfo *info = [[HMDTTMonitorUserInfo alloc] initWithAppID:kHeimdallrSDKAppID];
        info.hostAppID  = injectedInfo.appID;
        info.deviceID   = injectedInfo.deviceID;
        info.userID     = injectedInfo.userID;
        info.channel    = injectedInfo.channel;
        info.sdkVersion = [HMDSessionTracker currentSession].sdkVersion;
        info.flushCount = kHeimdallrSDKFlushCount;
        
        instance = [[HMDTTMonitor alloc] initMonitorWithAppID:info.appID injectedInfo:info];
    });
    return instance;
}

#pragma mark - HMDMonitorServiceProtocol

+ (void)trackService:(NSString *)serviceName metrics:(NSDictionary<NSString *,NSNumber *> *)metrics dimension:(NSDictionary<NSString *,NSString *> *)dimension extra:(NSDictionary *)extra {
    [[self heimdallrTTMonitor] hmdTrackService:serviceName metric:metrics category:dimension extra:extra];
}

+ (void)trackService:(NSString *)serviceName metrics:(NSDictionary<NSString *,NSNumber *> *)metrics dimension:(NSDictionary<NSString *,NSString *> *)dimension extra:(NSDictionary *)extra syncWrite:(BOOL)sync {
    [[self heimdallrTTMonitor] hmdTrackService:serviceName metric:metrics category:dimension extra:extra syncWrite:sync];
}

@end
