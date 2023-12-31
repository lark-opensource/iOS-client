//
//  BDAutoTrack+Filter.m
//  RangersAppLog
//
//  Created by bob on 2020/6/11.
//

#import "BDAutoTrack+Filter.h"
#import "BDAutoTrackFilter.h"
#import "BDAutoTrack+Private.h"
#import "BDAutoTrackServiceCenter.h"
#import "BDAutoTrackLocalConfigService.h"
#import "BDAutoTrackSettingsRequest.h"

@implementation BDAutoTrack (Filter)

- (void)setFilterEnable:(BOOL)enable {
    NSString *appID = self.appID;
    if (enable) {
        BDAutoTrackFilter *service = (BDAutoTrackFilter *)bd_standardServices(BDAutoTrackServiceNameFilter, appID);
        if (service == nil) {
            service = [[BDAutoTrackFilter alloc] initWithAppID:appID];
            [service registerService];
            [service loadBlockList];
        }
    } else {
        BDAutoTrackFilter *service = (BDAutoTrackFilter *)bd_standardServices(BDAutoTrackServiceNameFilter, appID);
        [service clearBlockList];
        [service unregisterService];
    }
    
    dispatch_async(self.serialQueue, ^{
        [[BDAutoTrack trackWithAppID:appID].localConfig saveEventFilterEnabled:enable];
    });
}

@end
