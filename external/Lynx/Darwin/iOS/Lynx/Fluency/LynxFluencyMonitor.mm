//  Copyright 2023 The Lynx Authors. All rights reserved.

#import "LynxFluencyMonitor.h"
#import "LynxFPSMonitor.h"
#import "LynxGenericReportInfo.h"
#import "LynxService.h"
#import "LynxServiceAppLogProtocol.h"
#import "LynxTemplateRender.h"
#import "LynxView+Internal.h"
#include "tasm/fluency/fluency_tracer.h"
@interface LynxFluencyMonitor ()

@property(nonatomic, readwrite) LynxFPSMonitor *monitor;

@end

@implementation LynxFluencyMonitor {
}

- (instancetype)init {
  if (self = [super init]) {
    self.monitor = [[LynxFPSMonitor alloc] init];
  }
  return self;
}

+ (instancetype)sharedInstance {
  static LynxFluencyMonitor *sharedInstance = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    sharedInstance = [[LynxFluencyMonitor alloc] init];
  });
  return sharedInstance;
}

- (BOOL)shouldSendAllScrollEvent {
  return lynx::tasm::FluencyTracer::IsEnable();
}

- (void)startWithScrollInfo:(LynxScrollInfo *)info {
  if (info.lynxView == nil) {
    // This method should be called synchronic when a UIScrollView in LynxView is scrolling. Info's
    // lynxView should not be nil.
    return;
  }
  LynxFPSRecord *record = [self.monitor beginWithKey:info];
  // If one scroll event does not stop after 10 seconds, we stop it manually.
  NSTimeInterval timeout = 10;
  [record setTimeout:timeout
          completion:^(LynxFPSRecord *_Nonnull record) {
            [[LynxFluencyMonitor sharedInstance] stopWithScrollInfo:(LynxScrollInfo *)(record.key)];
          }];
}

- (void)stopWithScrollInfo:(LynxScrollInfo *)info {
  LynxFPSRecord *record = [self.monitor endWithKey:info];
  if (record.duration < 0.2) {
    // just ignore scroll event with duration less than 200ms.
    return;
  }
  [self reportWithRecord:record view:info.lynxView tag:info.scrollMonitorTagName];
}

+ (NSDictionary *)jsonFromRecord:(LynxFPSRecord *)record tag:(NSString *)tag {
  if (record == nil) {
    return nil;
  }
  LynxFPSRawMetrics metrics = record.metrics;
  LynxFPSDerivedMetrics derivedMetrics = record.derivedMetrics;
  return @{
    @"lynxsdk_fluency_scene" : @"scroll",
    @"lynxsdk_fluency_tag" : tag ?: @"default_tag",
    @"lynxsdk_fluency_dur" : @(record.duration),
    @"lynxsdk_fluency_fps" : @(record.framesPerSecond),
    @"lynxsdk_fluency_frames_number" : @(record.frames),
    @"lynxsdk_fluency_drop1_count" : @(metrics.drop1Count),
    @"lynxsdk_fluency_drop1_count_per_second" : @(derivedMetrics.drop1PerSecond),
    @"lynxsdk_fluency_drop3_count" : @(metrics.drop3Count),
    @"lynxsdk_fluency_drop3_count_per_second" : @(derivedMetrics.drop3PerSecond),
    @"lynxsdk_fluency_drop7_count" : @(metrics.drop7Count),
    @"lynxsdk_fluency_drop7_count_per_second" : @(derivedMetrics.drop7PerSecond),
  };
}

- (void)reportWithRecord:(LynxFPSRecord *)record view:(LynxView *)lynxView tag:(NSString *)tag {
  if (lynxView == nil || record == nil) {
    // lynxView has been released, so we can directly drop this record.
    return;
  }
  NSDictionary *extraData = [[lynxView.templateRender genericReportInfo] toJson];
  NSDictionary *json = [self.class jsonFromRecord:record tag:tag];
  dispatch_async(dispatch_get_main_queue(), ^{
    [LynxService(LynxServiceAppLogProtocol) onReportEvent:@"lynxsdk_fluency_event"
                                                    props:json
                                                extraData:extraData];
  });
}

@end
