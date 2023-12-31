//  Copyright 2022 The Lynx Authors. All rights reserved.

#import "LynxLifecycleTracker.h"
#import "LynxService.h"
#import "LynxServiceAppLogProtocol.h"

@implementation LynxLifecycleTracker

- (void)lynxViewDidStartLoading:(LynxView *)view {
  NSDictionary *extraInfo = [_genericReportInfo toJson];
  dispatch_async(dispatch_get_main_queue(), ^{
    [LynxService(LynxServiceAppLogProtocol) onReportEvent:@"lynxsdk_open_page"
                                                    props:nil
                                                extraData:extraInfo];
  });
}

- (void)lynxView:(LynxView *)lynxView onSetup:(NSDictionary *)info {
  NSDictionary *extraInfo = [_genericReportInfo toJson];
  dispatch_async(dispatch_get_main_queue(), ^{
    [LynxService(LynxServiceAppLogProtocol) onTimingSetup:info withExtraData:extraInfo];
  });
}

- (void)lynxView:(LynxView *)lynxView
        onUpdate:(NSDictionary *)info
          timing:(NSDictionary *)updateTiming {
  NSDictionary *extraInfo = [_genericReportInfo toJson];
  dispatch_async(dispatch_get_main_queue(), ^{
    [LynxService(LynxServiceAppLogProtocol) onTimingUpdate:info
                                              updateTiming:updateTiming
                                                 extraData:extraInfo];
  });
}

@end
