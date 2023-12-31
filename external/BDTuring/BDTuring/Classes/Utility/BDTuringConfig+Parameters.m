//
//  BDTuringConfig+Parameters.m
//  BDTuring
//
//  Created by bob on 2019/12/26.
//

#import "BDTuringConfig+Parameters.h"
#import "BDTuringCoreConstant.h"
#import "BDTuringSandBoxHelper.h"
#import "BDTuringDeviceHelper.h"
#import "BDTuringMacro.h"

#import "NSObject+BDTuring.h"
#import "BDTuringUtility.h"
#import "BDTuringVerifyModel+Config.h"
#import "BDTuringVerifyState.h"
#import "BDTuringEventConstant.h"
#import <objc/runtime.h>
#import <objc/message.h>

@implementation BDTuringConfig (Parameters)

@dynamic model;

- (NSMutableDictionary *)commonParameters {
    NSMutableDictionary *queryParams = [self requestQueryParameters];
    [queryParams setValue:[self stringFromDelegateSelector:@selector(deviceID)] forKey:kBDTuringDeviceID];
    [queryParams setValue:[self stringFromDelegateSelector:@selector(installID)] forKey:kBDTuringInstallID];
    NSString *userID = [self stringFromDelegateSelector:@selector(userID)];
    [queryParams setValue:userID forKey:kBDTuringUserID];
    [queryParams setValue:[self stringFromDelegateSelector:@selector(sessionID)] forKey:kBDTuringSessionID];

    [queryParams setValue:BDTuringOS forKey:kBDTuringOS];
    [queryParams setValue:BDTuringOSName forKey:kBDTuringOSName];
    [queryParams setValue:[BDTuringDeviceHelper systemVersion] forKey:kBDTuringOSVersion];
    [queryParams setValue:[BDTuringDeviceHelper deviceModel] forKey:kBDTuringDeviceModel];
    [queryParams setValue:[BDTuringDeviceHelper deviceBrand] forKey:kBDTuringDeviceBrand];
    [queryParams setValue:[BDTuringDeviceHelper resolutionString] forKey:kBDTuringResolution];
    
    return queryParams;
}

- (NSMutableDictionary *)commonWebURLQueryParameters {
    NSMutableDictionary *paramters = [self commonParameters];
    [paramters setValue:self.channel forKey:kBDTuringChannel];
    [paramters setValue:[BDTuringSandBoxHelper appVersion] forKey:kBDTuringAppVersion];
    
    return paramters;
}

- (NSMutableDictionary *)turingWebURLQueryParameters {
    NSMutableDictionary *paramters = [self commonWebURLQueryParameters];
    [self.model appendKVToQueryParameters:paramters];
    if ([NSThread isMainThread]) {
        UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
        NSInteger orientationValue = (orientation == UIInterfaceOrientationPortrait || orientation == UIInterfaceOrientationPortraitUpsideDown) ? 2 : 1;
        [paramters setValue:@(orientationValue) forKey:kBDTuringOrientation];
    }
    
    return paramters;
}

- (NSMutableDictionary *)eventParameters {
    NSMutableDictionary *paramters = [self commonParameters];
    [self.model appendKVToEventParameters:paramters];
    
    return paramters;
}

- (NSMutableDictionary *)twiceVerifyRequestQueryParameters {
    NSMutableDictionary *queryParams = [NSMutableDictionary dictionaryWithCapacity:BDTuringDictionaryCapacityLarge];

    [queryParams setValue:self.appID forKey:kBDTuringAPPID]; //aid
    [queryParams setValue:self.appName forKey:kBDTuringAPPName]; //app_name
    [queryParams setValue:[BDTuringSandBoxHelper appVersion] forKey:@"app_version"]; //app_version
    [queryParams setValue:self.channel forKey:@"channel"]; // channel
    [queryParams setValue:[self stringFromDelegateSelector:@selector(deviceID)] forKey:kBDTuringDeviceID]; //did
    [queryParams setValue:[self stringFromDelegateSelector:@selector(installID)] forKey:kBDTuringInstallID]; //iid
    [queryParams setValue:[BDTuringSandBoxHelper appVersion] forKey:@"version_code"];
    [queryParams setValue:BDTuringOSName forKey:@"device_platform"]; //device_platform
    [queryParams setValue:[BDTuringDeviceHelper deviceModel] forKey:@"device_type"]; //device_type
    [queryParams setValue:[BDTuringDeviceHelper systemVersion] forKey:@"os_version"];//os_version
    [queryParams setValue:!BDTuring_isValidString(self.locale) ? [BDTuringDeviceHelper localeIdentifier] : self.locale forKey:kBDTuringLocale];
    
    return queryParams;
}

- (NSMutableDictionary *)requestQueryParameters {
    NSMutableDictionary *queryParams = [NSMutableDictionary dictionaryWithCapacity:BDTuringDictionaryCapacityLarge];
    
    [queryParams setValue:self.appName forKey:kBDTuringAPPName];
    [queryParams setValue:self.appID forKey:kBDTuringAPPID];
    [queryParams setValue:self.channel forKey:@"channel"];
    [queryParams setValue:[BDTuringSandBoxHelper appVersion] forKey:@"app_version"];
    [queryParams setValue:[BDTuringSandBoxHelper appVersion] forKey:@"version_code"];
    [queryParams setValue:BDTuringSDKVersion forKey:kBDTuringSDKVersion];
    [queryParams setValue:[BDTuringDeviceHelper localeIdentifier] forKey:kBDTuringLocale];
    [queryParams setValue:self.language forKey:kBDTuringLanguage];
    [queryParams setValue:self.appKey forKey:kBDTuringAPPKey];
    
    return queryParams;
}

- (NSMutableDictionary *)requestPostParameters {
    NSMutableDictionary *paramters = [self commonParameters];
    return paramters;
}

- (NSString *)stringFromDelegateSelector:(SEL)selector {
    NSString *value = nil;
    __strong typeof(self.delegate) delegate = self.delegate;
    if ([delegate respondsToSelector:selector]) {
        value = ((NSString * (*)(id, SEL))objc_msgSend)(delegate, selector);
        /// check type
        if (![value isKindOfClass:[NSString class]]) {
            value = nil;
        }
    }
    
    return [value copy];
}

@end
