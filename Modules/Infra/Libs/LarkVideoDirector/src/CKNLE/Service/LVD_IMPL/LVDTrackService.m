//
//  LVDTrackService.m
//  LarkVideoDirector
//
//  Created by 李晨 on 2022/1/20.
//

#import "LVDTrackService.h"
#import "LarkVideoDirector/LarkVideoDirector-Swift.h"

@implementation LVDTrackService

- (NSString *)deviceID {
    return [LVDCameraConfig deviceID];
}

- (void)trackEvent:(NSString *)event
             label:(NSString *)label
             value:(nullable NSString *)value
             extra:(nullable NSString *)extra
        attributes:(nullable NSDictionary *)attributes {
    [LVDCameraMonitor trackWithEvent:event params:attributes];
}

- (void)trackEvent:(NSString *)event
            params:(nullable NSDictionary *)params
   needStagingFlag:(BOOL)needStagingFlag {
    [LVDCameraMonitor trackWithEvent:event params:params];
}

- (void)track:(NSString *)event params:(NSDictionary *)params {
    [LVDCameraMonitor trackWithEvent:event params:params];
}

- (void)trackEvent:(NSString *)event params:(nullable NSDictionary *)params {
    [LVDCameraMonitor trackWithEvent:event params:params];
}

- (void)trackEvent:(NSString *)event attributes:(nullable NSDictionary *)attributes {
    [LVDCameraMonitor trackWithEvent:event params:attributes];
}

- (void)trackLogData:(NSDictionary *)dict {
    [LVDCameraMonitor trackWithLogData:dict];
}

@end
