//
//  monitor.m
//  Playground
//
//  Created by bytedance on 2021/11/15.
//

#import "MonitorInfo.h"
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnullability-completeness"
#import <Heimdallr/HMDTTMonitor.h>
#pragma clang diagnostic pop

@interface MonitorInfo ()

@property(nonatomic, copy, readwrite) NSString* appID;
@end

@implementation MonitorInfo
- (nonnull instancetype)init:(nonnull NSString*)appID
                    deviceID:(nonnull NSString*)deviceID
                     channel:(nonnull NSString*)channel
                   hostAppID:(nonnull NSString*)hostAppID
                  appVersion:(nonnull NSString*)appVersion {
  if (self = [super init]) {
    self.appID = appID;  // VMSDK iOS app ID
    self.deviceID = deviceID;
    self.channel = channel;
    self.hostAppID = hostAppID;
    self.appVersion = appVersion;
  }
  return self;
}
@end
