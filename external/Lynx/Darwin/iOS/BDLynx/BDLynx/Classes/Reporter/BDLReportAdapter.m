// Copyright 2020 The Lynx Authors. All rights reserved.

#import "BDLReportAdapter.h"
#import <BDTrackerProtocol/BDTrackerProtocol.h>
#import "BDLExceptionReporter.h"
#import "BDLReportProtocol.h"
#import "BDLSDKManager.h"
#import "BDLSDKProtocol.h"
#import "LynxComponentRegistry.h"
#import "LynxVersion.h"

@implementation BDLReportAdapter

LYNX_LOAD_LAZY(BDL_BIND_SERVICE(BDLReportAdapter.class, BDLReportProtocol);)

+ (instancetype)sharedInstance {
  static id _instance = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    _instance = [[self alloc] init];
  });
  return _instance;
}

- (void)launchSession {
  // send for crash rate calculation
  NSString *appVersion = [BDL_SERVICE(BDLSDKProtocol) appVersion];
  [BDTrackerProtocol eventV3:@"sdk_session_launch"
                      params:@{
                        @"sdk_aid" : @"2951",
                        @"sdk_version" : [LynxVersion versionString],
                        @"app_version" : appVersion,
                      }];
}

- (void)reportException:(NSError *)error {
  [BDLExceptionReporter reportException:error];
}

- (NSString *)backtraceWithMessage:(NSString *)message bySkippedDepth:(NSUInteger)skippedDepth {
  return [BDLExceptionReporter backtraceWithMessage:message bySkippedDepth:skippedDepth + 1];
}

@end
