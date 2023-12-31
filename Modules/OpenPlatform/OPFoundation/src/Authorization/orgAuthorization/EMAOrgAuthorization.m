//
//  EMAOrgAuthorization.m
//  EEMicroAppSDK
//
//  Created by yin on 2019/11/13.
//

#import "EMAOrgAuthorization.h"
#import <OPFoundation/BDPCommonManager.h>
#import <OPFoundation/BDPUniqueID.h>
#import <OPFoundation/BDPUtils.h>
#import <ECOInfra/NSDictionary+BDPExtension.h>

@implementation EMAOrgAuthorization

- (instancetype)init {
    if (self = [super init]) {
    }
    return  self;
}

+ (BOOL)orgAuthWithAuthScopes:(NSDictionary *)orgAuth invokeName:(NSString *)invokeName {
    if (BDPIsEmptyDictionary(orgAuth)) {
        return YES;
    }
    NSString *authName = [[EMAOrgAuthorization mapForOrgAuthToInvokeName] valueForKey:invokeName];
    if (BDPIsEmptyString(authName)) {
        return NO;
    }
    NSDictionary *authDict = [orgAuth bdp_dictionaryValueForKey:authName];
    if (BDPIsEmptyDictionary(authDict)) {
        return NO;
    }
    BOOL hasAuth = [authDict bdp_boolValueForKey:@"auth"];
    return hasAuth;
}

+ (NSDictionary<NSString *, NSString *> *)mapForOrgAuthToInvokeName {
    static NSDictionary<NSString *, NSString *> *dict;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dict = @{
                   @"chooseChat": @"chatInfo",
                   @"getChatInfo": @"chatInfo",
                   @"onChatBadgeChange": @"chatInfo",
                   @"offChatBadgeChange": @"chatInfo",
                   @"shareAppMessageDirectly": @"chatInfo",
                   @"chooseContact": @"contactInfo",
                   @"getDeviceID": @"deviceID",
                   @"getSecurityEnv" : @"client:securityinfo",
                   @"getLegacyDeviceID" : @"deviceID"
                   };
    });
    return dict;
}

@end
