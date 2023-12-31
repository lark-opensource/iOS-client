//
//  BDTuringConfig+AccountSeal.m
//  BDTuring
//
//  Created by bob on 2020/3/5.
//

#import "BDTuringConfig+AccountSeal.h"
#import "BDTuringConfig+Parameters.h"
#import "BDTuringCoreConstant.h"
#import "BDTuringSandBoxHelper.h"

@implementation BDTuringConfig (AccountSeal)

- (NSMutableDictionary *)sealWebURLQueryParameters {
    NSMutableDictionary *paramters = [self commonWebURLQueryParameters];
    NSString *secUserID = [self stringFromDelegateSelector:@selector(secUserID)];
    [paramters setValue:secUserID forKey:@"sec_uid"];
    
    return paramters;
}

- (NSMutableDictionary *)sealRequestQueryParameters {
    NSMutableDictionary *paramters = [NSMutableDictionary dictionaryWithCapacity:BDTuringDictionaryCapacityLarge];
    
    NSString *secUserID = [self stringFromDelegateSelector:@selector(secUserID)];
    [paramters setValue:secUserID forKey:@"sec_uid"];
    [paramters setValue:[BDTuringSandBoxHelper appVersion] forKey:@"version_code"];
    [paramters setValue:[self stringFromDelegateSelector:@selector(deviceID)] forKey:@"device_id"];
    [paramters setValue:[self stringFromDelegateSelector:@selector(installID)] forKey:kBDTuringInstallID];
    NSString *userID = [self stringFromDelegateSelector:@selector(userID)];
    [paramters setValue:userID forKey:kBDTuringUserID];
    [paramters setValue:self.appName forKey:kBDTuringAPPName];
    [paramters setValue:self.appID forKey:kBDTuringAPPID];
    [paramters setValue:self.channel forKey:@"channel"];
    [paramters setValue:BDTuringOSName forKey:@"device_platform"];
    
    return paramters;
}


@end
