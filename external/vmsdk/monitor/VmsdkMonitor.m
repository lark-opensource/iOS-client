//
//  VmsdkMonitor.m
//  Playground
//
//  Created by bytedance on 2021/11/15.
//

#import "VmsdkMonitor.h"
#import "VmsdkSettingsManager.h"

@implementation VmsdkMonitor

static HMDTTMonitor* monitor = nil;
+ (instancetype)sharedOnlyAppID {
  static dispatch_once_t onceToken;
  static VmsdkMonitor* instance = nil;
  dispatch_once(&onceToken, ^{
    HMDTTMonitorUserInfo* injectedInfo = [[HMDTTMonitorUserInfo alloc] initWithAppID:@"8398"];
    injectedInfo.deviceID = @"8398888";  // only for local test
    NSLog(@"monitor device id is: %@", injectedInfo.deviceID);
    monitor = [[HMDTTMonitor alloc] initMonitorWithAppID:@"8398" injectedInfo:injectedInfo];
    instance = [[VmsdkMonitor alloc] init];
  });
  return instance;
}

+ (instancetype)sharedMonitorInfo:(MonitorInfo*)info {
  static dispatch_once_t onceToken;
  static VmsdkMonitor* instance = nil;
  dispatch_once(&onceToken, ^{
    HMDTTMonitorUserInfo* injectedInfo = [[HMDTTMonitorUserInfo alloc] initWithAppID:info.appID];
    injectedInfo.deviceID = info.deviceID;
    injectedInfo.channel = info.channel;
    injectedInfo.hostAppID = info.hostAppID;
    injectedInfo.sdkVersion = info.appVersion;
    monitor = [[HMDTTMonitor alloc] initMonitorWithAppID:info.appID injectedInfo:injectedInfo];
    instance = [[VmsdkMonitor alloc] init];
  });

  [[VmsdkSettingsManager shareInstance] initSettings];
  return instance;
}

+ (HMDTTMonitor*)getMonitor {
  return monitor;
}

- (void)monitorEvent:(NSString*)serviceName
              metric:(NSDictionary*)metric
            category:(NSDictionary*)category
               extra:(NSDictionary*)extra {
  [monitor hmdTrackService:serviceName metric:metric category:category extra:extra];
}

+ (void)monitorEventStatic:(NSString*)serviceName
                    metric:(NSDictionary*)metric
                  category:(NSDictionary*)category
                     extra:(NSDictionary*)extra {
  if (monitor) {
    [monitor hmdTrackService:serviceName metric:metric category:category extra:extra];
  } else {
    NSLog(@"monitor is null, can't upload event data");
  }
}

@end
