//
//  BDPAuthorization+Event.m
//  Timor
//
//  Created by liuxiangxin on 2019/12/10.
//

#import "BDPAuthorization+BDPEvent.h"
#import "BDPAuthorization+BDPUI.h"
#import "BDPTracker.h"

@implementation BDPAuthorization (BDPEvent)

+ (void)eventCombineAuthRessltWithUniqueID:(BDPUniqueID *)uniqueID
                                authResult:(NSDictionary<NSString *, NSNumber *> *)resultDic
{
    //这里要上报聚合授权的结果， 只有所有都授权成功， 才算做是成功
    //如果有一个成功， 就算做是成功
    __block BOOL hasEnable = NO;
    __block BOOL hasSystemDisable = NO;
    __block BOOL hasUserDisable = NO;
    
    [resultDic enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull scope, NSNumber * _Nonnull resultObj, BOOL * _Nonnull stop) {
        BDPAuthorizationPermissionResult result = [resultObj integerValue];
        if (result == BDPAuthorizationPermissionResultEnabled) {
            hasEnable = YES;
            *stop = YES;
        } else if (result == BDPAuthorizationPermissionResultSystemDisabled) {
            hasSystemDisable = YES;
        } else if (result == BDPAuthorizationPermissionResultUserDisabled) {
            hasUserDisable = YES;
        }
    }];
    
    if (hasEnable) {
        [self eventAuthResultForScope:BDPPermissionScopeTypeAlbum
                               result:BDPAuthorizationPermissionResultEnabled
                 uniqueID:uniqueID
                         multipleAuth:YES];
        return;
    }
    
    
    BDPAuthorizationPermissionResult lastAuthFaildRes = BDPAuthorizationPermissionResultSystemDisabled;
    //如果有系统拒绝， 就要上报系统拒绝
    if (hasSystemDisable) {
        lastAuthFaildRes = BDPAuthorizationPermissionResultSystemDisabled;
    } else { //否则上报用户拒绝
        lastAuthFaildRes = BDPAuthorizationPermissionResultUserDisabled;
    }

    [self eventAuthResultForScope:BDPPermissionScopeTypeAlbum
                           result:lastAuthFaildRes
             uniqueID:uniqueID
                     multipleAuth:YES];
}

+ (void)eventAlertShowForScope:(BDPPermissionScopeType)scopeType
          uniqueID:(BDPUniqueID *)uniqueID
                  multipleAuth:(BOOL)isMultipleAuth
{
    NSString *eventType = [self eventAuthTypeForScopeType:scopeType];
    if (isMultipleAuth) {
        eventType = @"multiple";
    }
    if (!eventType.length) {
        return;
    }
    
    NSString *alertType = @"new";
    NSDictionary *attribute = @{@"auth_type": eventType,
                                @"alert_type": alertType};
    
    [BDPTracker event:@"mp_auth_alert_show" attributes:attribute uniqueID:uniqueID];
}

+ (void)eventAuthResultForScope:(BDPPermissionScopeType)scopeType
                         result:(BDPAuthorizationPermissionResult)result
           uniqueID:(BDPUniqueID *)uniqueID
                   multipleAuth:(BOOL)isMultipleAuth
{
    NSString *eventType = [self eventAuthTypeForScopeType:scopeType];
    if (isMultipleAuth) {
        eventType = @"multiple";
    }
    if (!eventType.length) {
        return;
    }
    
    NSString *failType = nil;
    switch (result) {
        case BDPAuthorizationPermissionResultEnabled:
            break;
        case BDPAuthorizationPermissionResultSystemDisabled:
            failType = @"system_reject";
            break;
        case BDPAuthorizationPermissionResultUserDisabled:
            failType = @"mp_reject";
            break;
        case BDPAuthorizationPermissionResultPlatformDisabled:
            failType = @"other";
            break;
        case BDPAuthorizationPermissionResultInvalidScope:
            failType = @"invalid_scope";
            break;
    }
    
    NSString *resString = result == BDPAuthorizationPermissionResultEnabled ? @"success": @"fail";
    NSString *alertType = @"new";
    
    NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
    [attributes setValue:eventType forKey:@"auth_type"];
    [attributes setValue:resString forKey:@"result"];
    [attributes setValue:failType forKey:@"fail_type"];
    [attributes setValue:alertType forKey:@"alert_type"];
    [BDPTracker event:@"mp_auth_alert_result" attributes:attributes.copy uniqueID:uniqueID];
}

+ (NSString *)eventAuthTypeForScopeType:(BDPPermissionScopeType)scopeType
{
    NSString *eventType = nil;
    switch (scopeType) {
        case BDPPermissionScopeTypeUnknown:
            break;
        case BDPPermissionScopeTypeLocation:
            eventType = @"location";
            break;
        case BDPPermissionScopeTypeAddress:
            eventType = @"address";
            break;
        case BDPPermissionScopeTypeCamera:
            eventType = @"camera";
            break;
        case BDPPermissionScopeTypeUserInfo:
            eventType = @"user_info";
            break;
        case BDPPermissionScopeTypeMicrophone:
            eventType = @"record";
            break;
        case BDPPermissionScopeTypePhoneNumber:
            eventType = @"phone_num";
            break;
        case BDPPermissionScopeTypeAlbum:
            eventType = @"photo";
            break;
        case BDPPermissionScopeTypeScreenRecord:
            eventType = @"screen_record";
            break;
        case BDPPermissionScopeTypeClipboard:
            eventType = @"clipboard";
            break;
        case BDPPermissionScopeTypeAppBadge:
            eventType = @"appBadge";
            break;
        case BDPPermissionScopeTypeRunData:
            eventType = @"runData";
            break;
        case BDPPermissionScopeTypeBluetooth:
            eventType = @"bluetooth";
            break;
    }
    return eventType;
}


@end
