//
//  BDInstallExtraParams.m
//  BDInstall
//
//  Created by han yang on 2020/8/19.
//

#import "RALInstallExtraParams.h"
#import "BDAutoTrackDeviceHelper+CAID.h"
#import "BDAutoTrackRegisterService+CAID.h"

#pragma mark - CAID新增参数

@implementation RALInstallExtraParams

+ (NSDictionary <NSString *, NSObject *> *)extraIDsWithAppID:(NSString *)appID {
    NSMutableDictionary *result  = [[NSMutableDictionary alloc] init];
    BDAutoTrackRegisterService *rs = bd_registerServiceForAppID(appID);
    [result setValue:rs.caid forKey:@"caid1"];
    [result setValue:rs.prevCaid forKey:@"caid2"];
    return result;
}

+ (NSDictionary <NSString *, NSObject *> *)extraDeviceParams {
    NSMutableDictionary *result  = [[NSMutableDictionary alloc] init];
    [result setValue:bd_device_locale_language() forKey:@"locale_language"];
    [result setValue:bd_device_hardware_model() forKey:@"hardware_model"];
    [result setValue:bd_device_phone_name() forKey:@"phone_name"];
    return result;
}

@end
