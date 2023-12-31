//
//  BDTuringConfig+SMSCode.m
//  BDTuring
//
//  Created by bob on 2021/8/6.
//

#import "BDTuringConfig+SMSCode.h"
#import "BDTuringConfig+Parameters.h"
#import "BDTuringCoreConstant.h"
#import "BDTuringSandBoxHelper.h"
#import "BDTuringDeviceHelper.h"
#import "BDTuringUtility.h"
#import "BDTNetworkManager.h"
#import <UIKit/UIKit.h>

@implementation BDTuringConfig (SMSCode)

- (NSMutableDictionary *)sendCodeParameters {
    NSMutableDictionary *postParameters = [NSMutableDictionary dictionaryWithCapacity:BDTuringDictionaryCapacityLarge];
    
    [postParameters setValue:self.appName forKey:kBDTuringAPPName];
    [postParameters setValue:self.channel forKey:@"channel"];
    
    [postParameters setValue:[self stringFromDelegateSelector:@selector(installID)] forKey:kBDTuringInstallID];
    [postParameters setValue:[self stringFromDelegateSelector:@selector(userID)] forKey:kBDTuringUserID];
    [postParameters setValue:[self stringFromDelegateSelector:@selector(deviceID)] forKey:@"device_id"];

    [postParameters setValue:[BDTuringDeviceHelper systemVersion] forKey:kBDTuringOSVersion];
    [postParameters setValue:[BDTuringDeviceHelper deviceBrand] forKey:kBDTuringDeviceBrand];
    [postParameters setValue:[BDTuringDeviceHelper resolutionString] forKey:kBDTuringResolution];
    [postParameters setValue:[BDTuringSandBoxHelper appVersion] forKey:@"version_code"];
    
    [postParameters setValue:BDTuringOSName forKey:@"device_platform"];
    [postParameters setValue:@([self.appID integerValue]) forKey:@"app_id"];
    NSInteger dpi = [[UIScreen mainScreen] scale];
    [postParameters setValue:@(dpi).stringValue forKey:@"dpi"];
    [postParameters setValue:[BDTuringDeviceHelper deviceModel] forKey:@"device_type"];
    [postParameters setValue:self.language forKey:@"language"];
    [postParameters setValue:[BDTNetworkManager networkType] forKey:@"ac"];
    [postParameters setValue:@"441" forKey:@"screen_width"];
    
    return postParameters;
}

- (NSMutableDictionary *)checkCodeParameters {
    NSMutableDictionary *postParameters = [NSMutableDictionary dictionaryWithCapacity:BDTuringDictionaryCapacityLarge];
    [postParameters setValue:@([self.appID integerValue]) forKey:@"app_id"];
    [postParameters setValue:self.language forKey:@"language"];

    return postParameters;
}

@end
