//
//  BDAutoTrack+ET.m
//  RangersAppLog
//
//  Created by bob on 2020/6/11.
//

#import "BDAutoTrack+ET.h"
#import "BDAutoTrackETService.h"
#import "BDAutoTrackServiceCenter.h"

@implementation BDAutoTrack (ET)

+ (void)setETEnable:(BOOL)enable withAppID:(NSString *)appID {
    if (enable) {
        BDAutoTrackETService *service = (BDAutoTrackETService *)bd_standardServices(BDAutoTrackServiceNameLog, appID);
        if (service == nil) {
            service = [[BDAutoTrackETService alloc] initWithAppID:appID];
            [service registerService];
        }
    } else {
        BDAutoTrackETService *service = (BDAutoTrackETService *)bd_standardServices(BDAutoTrackServiceNameLog, appID);
        [service unregisterService];
    }
}

+ (void)setETReportInterval:(long long)interval {
    NSString *appID = [self appID];
    BDAutoTrackETService *service = (BDAutoTrackETService *)bd_standardServices(BDAutoTrackServiceNameLog, appID);
    if ([service isKindOfClass:BDAutoTrackETService.class]) {
        [service setETReportTimeInterval:interval];
    }
}

@end
