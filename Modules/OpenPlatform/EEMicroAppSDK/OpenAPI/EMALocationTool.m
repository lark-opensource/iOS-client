//
//  EMALocationTool.m
//  EEMicroAppSDK
//
//  Created by tujinqiu on 2019/12/18.
//

#import "EMALocationTool.h"
#import <TTMicroApp/TMAPluginLocation.h>
#import <OPFoundation/BDPUtils.h>

@implementation EMALocationTool

+ (void)getLocationWithParams:(NSDictionary *)params completion:(void (^)(CLLocation * _Nullable location))completion
{
    if (!params) {
        BLOCK_EXEC(completion, nil);
        return;
    }
    BOOL enable = [CLLocationManager locationServicesEnabled];
    if (!enable) {
        BLOCK_EXEC(completion, nil);
        return;
    }
    int status = [CLLocationManager authorizationStatus];
    if (status != kCLAuthorizationStatusAuthorizedAlways && status != kCLAuthorizationStatusAuthorizedWhenInUse) {
        BLOCK_EXEC(completion, nil);
        return;
    }
    [[TMAPluginLocation sharedPlugin] getLocationWithParam:params callback:^(BDPJSBridgeCallBackType type, NSDictionary *dic) {
        if (type == BDPJSBridgeCallBackTypeSuccess) {
            CLLocationDegrees latitude = [dic bdp_doubleValueForKey:@"latitude"];
            CLLocationDegrees longitude = [dic bdp_doubleValueForKey:@"longitude"];
            CLLocationSpeed speed = [dic bdp_doubleValueForKey:@"speed"];
            CLLocationDistance altitude = [dic bdp_doubleValueForKey:@"altitude"];
            CLLocationAccuracy verticalAccuracy = [dic bdp_doubleValueForKey:@"verticalAccuracy"];
            CLLocationAccuracy horizontalAccuracy = [dic bdp_doubleValueForKey:@"horizontalAccuracy"];
            long long timestamp_int64_t = [[dic objectForKey:@"timestamp"] longLongValue];
            NSDate *timestamp = [NSDate dateWithTimeIntervalSince1970:timestamp_int64_t / 1000.0];
            CLLocationCoordinate2D cor = {latitude, longitude};
            CLLocation *lo = [[CLLocation alloc] initWithCoordinate:cor altitude:altitude horizontalAccuracy:horizontalAccuracy verticalAccuracy:verticalAccuracy course:0 speed:speed timestamp:timestamp];
            BLOCK_EXEC(completion, lo);
        } else {
            BLOCK_EXEC(completion, nil);
        }
    } context:nil];
}

@end
