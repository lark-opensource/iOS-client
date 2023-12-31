//
//  BDPAuthorization+Utils.m
//  Timor
//
//  Created by liuxiangxin on 2019/12/10.
//

#import "BDPAuthorization+BDPUtils.h"
#import "BDPCommon.h"
#import "BDPCommonManager.h"
#import "BDPAuthorizationUtilsDefine.h"
#import "BDPUtils.h"
#import "BDPSTLQueue.h"
#import <ECOInfra/NSDictionary+BDPExtension.h>
#import "BDPTimorClient.h"
#import "BDPI18n.h"
#import "EEFeatureGating.h"

#define kBDPAuthScopeQueueWaitingUserInfoKey @"waiting"
#define kBDPAuthScopeQueueSTLQueueUserInfoKey @"queue"

#define MAP_AUTH_FREE_TYPE(INNER_SCOPE, AUTH_FREE_TYPE) \
if ([innerScope isEqualToString:INNER_SCOPE]) { \
    return AUTH_FREE_TYPE; \
} \

@implementation BDPAuthorization (BDPUtils)

#pragma mark - Safe Completion

- (BDPAuthorizationRequestCompletion)generateSafeCompletion:(BDPAuthorizationRequestCompletion)completion
                                                   uniqueID:(OPAppUniqueID *)uniqueID
{
    void (^completionBlock)(BDPAuthorizationPermissionResult) = ^(BDPAuthorizationPermissionResult result) {
        BDPCommon *common = [[BDPCommonManager sharedManager] getCommonWithUniqueID:uniqueID];
        if ((common && !common.isDestroyed) || uniqueID.appType == BDPTypeWebApp) {
            AUTH_COMPLETE(result)
        }
    };
    
    return completionBlock;
}

- (BDPAuthorizationRequestCompletion)generateSafeCompletion:(BDPAuthorizationRequestCompletion)completion
                                                   uniqueID:(OPAppUniqueID *)uniqueID
                                                     method:(BDPJSBridgeMethod *)method
{
    WeakSelf;
    void (^completionBlock)(BDPAuthorizationPermissionResult) = ^(BDPAuthorizationPermissionResult result) {
        StrongSelfIfNilReturn;
        BDPCommon *common = [[BDPCommonManager sharedManager] getCommonWithUniqueID:uniqueID];
        if ((common && !common.isDestroyed) || uniqueID.appType == BDPTypeWebApp) {
            AUTH_COMPLETE(result)
        }
    };
    
    return completionBlock;
}

#pragma mark - Scope Request Queue

- (BOOL)scopeQueueCreateIfNeeded:(NSString *)scope
{
    if (!BDPIsEmptyString(scope)) {
        if (![self.scopeQueue bdp_objectForKey:scope ofClass:[NSMutableDictionary class]]) {
            // Create New Queue
            BDPSTLQueue *queue = [[BDPSTLQueue alloc] init];
            NSMutableDictionary *scopeQueue = [[NSMutableDictionary alloc] init];
            [scopeQueue setValue:@(NO) forKey:kBDPAuthScopeQueueWaitingUserInfoKey];
            [scopeQueue setValue:queue forKey:kBDPAuthScopeQueueSTLQueueUserInfoKey];
            
            // Set Value For Scope
            [self.scopeQueue setValue:scopeQueue forKey:scope];
            return YES;
        }
    }
    return NO;
}

- (void)scopeQueueStartWaiting:(NSString *)scope
{
    if (!BDPIsEmptyString(scope)) {
        // Create ScopeQueue IF NEEDED
        [self scopeQueueCreateIfNeeded:scope];
        
        // Set Scope Waiting YES
        NSMutableDictionary *scopeQueue = [self.scopeQueue bdp_objectForKey:scope ofClass:[NSMutableDictionary class]];
        [scopeQueue setValue:@(YES) forKey:kBDPAuthScopeQueueWaitingUserInfoKey];
    }
}

- (void)scopeQueueAddCompletion:(BDPAuthorizationRequestCompletion)completion scope:(NSString *)scope
{
    if (!BDPIsEmptyString(scope) && completion) {
        // Create ScopeQueue IF NEEDED
        [self scopeQueueCreateIfNeeded:scope];
        
        // Set Scope Waiting YES (Add Completion Should Be Done When Waiting is YES)
        NSMutableDictionary *scopeQueue = [self.scopeQueue bdp_objectForKey:scope ofClass:[NSMutableDictionary class]];
        [scopeQueue setValue:@(YES) forKey:kBDPAuthScopeQueueWaitingUserInfoKey];
        
        // EnQueue
        BDPSTLQueue *queue = [scopeQueue bdp_objectForKey:kBDPAuthScopeQueueSTLQueueUserInfoKey ofClass:[BDPSTLQueue class]];
        [queue enqueue:completion];
    }
}

- (BOOL)scopeQueueIsWaiting:(NSString *)scope
{
    if (!BDPIsEmptyString(scope)) {
        return [self.scopeQueue[scope] bdp_boolValueForKey:kBDPAuthScopeQueueWaitingUserInfoKey];
    }
    return NO;
}

- (void)scopeQueueExcuteAllCompletion:(BDPAuthorizationPermissionResult)result scope:(NSString *)scope
{
    if (!BDPIsEmptyString(scope)) {
        // Get Queue
        NSMutableDictionary *scopeQueue = [self.scopeQueue bdp_objectForKey:scope ofClass:[NSMutableDictionary class]];
        BDPSTLQueue *queue = [scopeQueue bdp_objectForKey:kBDPAuthScopeQueueSTLQueueUserInfoKey ofClass:[BDPSTLQueue class]];
        
        // Clear ScopeType Waiting Status
        [scopeQueue setValue:@(NO) forKey:kBDPAuthScopeQueueWaitingUserInfoKey];
        
        // Enumerate Each Object And Excute
        [queue enumerateObjectsUsingBlock:^(id  _Nonnull object, BOOL * _Nonnull stop) {
            void (^completion)(BDPAuthorizationPermissionResult) = object;
            if ([object isKindOfClass:[completion class]]) {
                AUTH_COMPLETE(result)
            }
        }];
    }
}

#pragma mark - Scope map

+ (NSString *)transfromScopeToInnerScope:(NSString *)scope
{
    __block NSString *innerScope = scope;
    NSDictionary<NSString *, NSString *> *map = [self mapForStorageKeyToScopeKey];
    [map enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull innerScopeKey, NSString * _Nonnull scopeKey, BOOL * _Nonnull stop) {
        if ([scopeKey isEqualToString:scope]) {
            innerScope = innerScopeKey;
            *stop = YES;
        }
    }];
    if ([scope isEqualToString:BDPScopeWritePhotosAlbum]) {
        return BDPInnerScopeAlbum;
    }
    return innerScope;
}

+ (NSString *)transfromScopeTypeToInnerScope:(BDPPermissionScopeType)scopeType
{
    if (scopeType == BDPPermissionScopeTypeAlbum) {
        return BDPInnerScopeAlbum;
    } else if (scopeType == BDPPermissionScopeTypeCamera) {
        return BDPInnerScopeCamera;
    } else if (scopeType == BDPPermissionScopeTypeLocation) {
        return BDPInnerScopeUserLocation;
    } else if (scopeType == BDPPermissionScopeTypeAddress) {
        return BDPInnerScopeAddress;
    } else if (scopeType == BDPPermissionScopeTypeUserInfo) {
        return BDPInnerScopeUserInfo;
    } else if (scopeType == BDPPermissionScopeTypeMicrophone) {
        return BDPInnerScopeRecord;
    } else if (scopeType == BDPPermissionScopeTypePhoneNumber) {
        return BDPInnerScopePhoneNumber;
    } else if (scopeType == BDPPermissionScopeTypeScreenRecord) {
        return BDPInnerScopeScreenRecord;
    } else if (scopeType == BDPPermissionScopeTypeClipboard) {
        return BDPInnerScopeClipboard;
    } else if (scopeType == BDPPermissionScopeTypeAppBadge) {
        return BDPInnerScopeAppBadge;
    } else if (scopeType == BDPPermissionScopeTypeRunData) {
        return BDPInnerScopeRunData;
    } else if (scopeType == BDPPermissionScopeTypeBluetooth) {
        return BDPInnerScopeBluetooth;
    }
    

    return nil;
}

+ (NSMutableDictionary *)transformScopeToDict:(NSString *)scope value:(NSNumber *)value dictionary:(NSMutableDictionary *)dict
{
    // Invalid Dictionary
    if (![dict isKindOfClass:[NSMutableDictionary class]]) {
        return nil;
    }

    NSDictionary<NSString *, NSString *> *map = [self mapForStorageKeyToScopeKey];
    NSString *scopeKey = map[scope];
    if (!BDPIsEmptyString(scopeKey)) {
        [dict setValue:value forKey:scopeKey];
    }

    return [dict mutableCopy];
}

+ (BDPPermissionScopeType)transformScopeToScopeType:(NSString *)scope
{
    BDPPermissionScopeType scopeType = BDPPermissionScopeTypeUnknown;
    if ([scope hasPrefix:BDPScopePrefix]) {
        scope = [self transfromScopeToInnerScope:scope];
    }
    
    if ([scope isEqualToString:BDPInnerScopeCamera]) {
        scopeType = BDPPermissionScopeTypeCamera;
    } else if ([scope isEqualToString:BDPInnerScopeAlbum]) {
        scopeType = BDPPermissionScopeTypeAlbum;
    } else if ([scope isEqualToString:BDPInnerScopeRecord]) {
        scopeType = BDPPermissionScopeTypeMicrophone;
    } else if ([scope isEqualToString:BDPInnerScopeUserLocation]) {
        scopeType = BDPPermissionScopeTypeLocation;
    } else if ([scope isEqualToString:BDPInnerScopeUserInfo]) {
        scopeType = BDPPermissionScopeTypeUserInfo;
    } else if ([scope isEqualToString:BDPInnerScopeAddress]) {
        scopeType = BDPPermissionScopeTypeAddress;
    } else if ([scope isEqualToString:BDPInnerScopeScreenRecord]) {
        scopeType = BDPPermissionScopeTypeScreenRecord;
    } else if ([scope isEqualToString:BDPInnerScopeClipboard]) {
        scopeType = BDPPermissionScopeTypeClipboard;
    } else if ([scope isEqualToString:BDPInnerScopeAppBadge]) {
        scopeType = BDPPermissionScopeTypeAppBadge;
    } else if ([scope isEqualToString:BDPInnerScopeRunData]) {
        scopeType = BDPPermissionScopeTypeRunData;
    } else if ([scope isEqual:BDPInnerScopeBluetooth]) {
        scopeType = BDPPermissionScopeTypeBluetooth;
    }
    
    return scopeType;
}

+ (NSDictionary<NSString *, NSString *> *)mapForStorageKeyToScopeKey {
    static NSDictionary<NSString *, NSString *> *dict;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dict = @{
                   BDPInnerScopeCamera: BDPScopeCamera,
                   BDPInnerScopeAlbum: BDPScopeAlbum,
                   BDPInnerScopeRecord: BDPScopeRecord,
                   BDPInnerScopeUserLocation: BDPScopeUserLocation,
                   BDPInnerScopeUserInfo: BDPScopeUserInfo,
                   BDPInnerScopeAddress: BDPScopeAddress,
                   BDPInnerScopeScreenRecord: BDPScopeScreenRecord,
                   BDPInnerScopeClipboard: BDPScopeClipboard,
                   BDPInnerScopeAppBadge: BDPScopeAppBadge,
                   BDPInnerScopeRunData: BDPScopeRunData,
                   BDPInnerScopeBluetooth: BDPScopeBluetooth,
                   @"invoiceTitle": @"scope.invoiceTitle",
                   @"werun": @"scope.werun"
                   };
        // 支持宿主自定义已授权map
        BDPPlugin(authorizationPlugin, BDPAuthorizationPluginDelegate);
        if ([authorizationPlugin respondsToSelector:@selector(bdp_customMapForStorageKeyToScopeKey:)]) {
            dict = [authorizationPlugin bdp_customMapForStorageKeyToScopeKey:dict];
        }
    });
    return dict;
}

+ (NSString *)transformOnlineScopeToScope:(NSString *)onlineScope
{
    if (!onlineScope) {
        NSAssert(onlineScope, @"transformOnlineScopeToScope can not pass nil");
        BDPLogError(@"get nil params");
        return @"";
    }

    __block NSString *result = onlineScope;
    NSDictionary<NSString *, NSString *> *map = [self mapForScopeToOnlineScopeKey];
    [map enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull scopeKey, NSString * _Nonnull onlineScopeKey, BOOL * _Nonnull stop) {
        if ([onlineScope isEqualToString:onlineScopeKey]) {
            result = scopeKey;
            *stop = YES;
        }
    }];

    return result;
}

+ (NSString *)transformScopeKeyToOnlineScope:(NSString *)scopeKey {
    if (!scopeKey) {
        NSAssert(scopeKey, @"transformScopeKeyToOnlineScope can not pass nil");
        BDPLogError(@"get nil params");
        return @"";
    }

    NSString *result = [self mapForScopeToOnlineScopeKey][scopeKey] ?: scopeKey;
    return result;
}

+ (NSDictionary<NSString *, NSString *> *)mapForScopeToOnlineScopeKey {
    static NSDictionary<NSString *, NSString *> *map;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSMutableDictionary *tmp = [NSMutableDictionary dictionary];
        tmp[BDPScopeCamera] = @"camera";
        tmp[BDPScopeAlbum] = @"album";
        tmp[BDPScopeWritePhotosAlbum] = @"writePhotosAlbum";
        tmp[BDPScopeRecord] = @"record";
        tmp[BDPScopeUserLocation] = @"userLocation";
        tmp[BDPScopeUserInfo] = @"userInfo";
        tmp[BDPScopeAddress] = @"address";
        tmp[BDPScopeScreenRecord] = @"screenRecord";
        tmp[BDPScopeClipboard] = @"clipboard";
        tmp[BDPScopeAppBadge] = @"appBadge";
        tmp[BDPScopeRunData] = @"client:run_data:readonly";
        tmp[@"scope.invoiceTitle"] = @"invoiceTitle";
        tmp[@"scope.werun"] = @"werun";
        if([EMAFeatureGating boolValueForKey: EEFeatureGatingKeyGetUserInfoAuth]) {
            tmp[BDPScopeUserInfo] = @"client:user_info:readonly";
        }
        if ([EMAFeatureGating boolValueForKey:EEFeatureGatingKeyScopeBluetoothEnable]) {
            tmp[BDPScopeBluetooth] = @"client:bluetooth";
        }
        map = [tmp copy];
    });
    return map;
}

+ (BDPAuthorizationFreeType)authorizationFreeTypeForInnerScope:(NSString *)innerScope
{
    MAP_AUTH_FREE_TYPE(BDPInnerScopeCamera, BDPAuthorizationFreeTypeCamera)
    MAP_AUTH_FREE_TYPE(BDPInnerScopeAlbum, BDPAuthorizationFreeTypeAlubum)
    MAP_AUTH_FREE_TYPE(BDPInnerScopeRecord, BDPAuthorizationFreeTypeMicrophone)
    MAP_AUTH_FREE_TYPE(BDPInnerScopeUserLocation, BDPAuthorizationFreeTypeUserLocation)
    MAP_AUTH_FREE_TYPE(BDPInnerScopeUserInfo, BDPAuthorizationFreeTypeUserInfo)
    MAP_AUTH_FREE_TYPE(BDPInnerScopeAddress, BDPAuthorizationFreeTypeAddress)
    MAP_AUTH_FREE_TYPE(BDPInnerScopeScreenRecord, BDPAuthorizationFreeTypeScreenRecord)
    MAP_AUTH_FREE_TYPE(BDPInnerScopeClipboard, BDPAuthorizationFreeTypeClipboard)
    MAP_AUTH_FREE_TYPE(BDPInnerScopeAppBadge, BDPAuthorizationFreeTypeAppBadge)
    MAP_AUTH_FREE_TYPE(BDPScopeWritePhotosAlbum, BDPAuthorizationFreeTypeAlubum)
    MAP_AUTH_FREE_TYPE(BDPInnerScopeRunData, BDPAuthorizationFreeTypeRunData)
    return 0;
}

#pragma makr - localization

- (void)localizationScope
{
    NSMutableDictionary *newScope = [NSMutableDictionary dictionary];
    [self.scope enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSDictionary *obj, BOOL * _Nonnull stop) {
        if (![obj isKindOfClass:[NSDictionary class]]) {
            *stop = YES;
        }
        NSMutableDictionary *tempDic = [NSMutableDictionary dictionaryWithDictionary:obj];
        if ([key isEqualToString:@"album"]) {
            tempDic[@"name"] = BDPI18n.album;
            tempDic[@"description"] = BDPI18n.album_desc;
            tempDic[@"title"] = BDPI18n.album_title;
        } else if ([key isEqualToString:@"camera"]) {
            tempDic[@"name"] = BDPI18n.camera;
            tempDic[@"description"] = BDPI18n.camera_desc;
            tempDic[@"title"] = BDPI18n.camera_title;
            tempDic[@"description_new"] = BDPI18n.OpenPlatform_Auth_Camera_Description;
        } else if ([key isEqualToString:@"microphone"]) {
            tempDic[@"name"] = BDPI18n.microphone;
            tempDic[@"description"] = BDPI18n.microphone_desc;
            tempDic[@"title"] = BDPI18n.microphone_title;
            tempDic[@"description_new"] = BDPI18n.microphone_description_new;
        } else if ([key isEqualToString:@"location"]) {
            tempDic[@"name"] = BDPI18n.location;
            tempDic[@"description"] = BDPI18n.location_desc;
            tempDic[@"title"] = BDPI18n.location_title;
            tempDic[@"description_new"] = BDPI18n.location_description_new;
        } else if ([key isEqualToString:@"userinfo"]) {
            tempDic[@"name"] = BDPI18n.LittleApp_UserInfoPermission_PermissionName;
            tempDic[@"description"] = BDPI18n.LittleApp_UserInfoPermission_PermissionDesc;
            tempDic[@"title"] = BDPI18n.userinfo;
            tempDic[@"description_new"] = BDPI18n.LittleApp_UserInfoPermission_PermissionDescForClient;
        } else if ([key isEqualToString:@"address"]) {
            tempDic[@"name"] = BDPI18n.address;
            tempDic[@"description"] = BDPI18n.address_desc;
            tempDic[@"title"] = BDPI18n.address_title;
            tempDic[@"description_new"] = BDPI18n.address_description_new;
        } else if ([key isEqualToString:BDPInnerScopeClipboard]) {
            tempDic[@"name"] = BDPI18n.LittleApp_TTMicroApp_PermissionName_Clipboard;
            tempDic[@"description"] = BDPI18n.LittleApp_TTMicroApp_PermissionMsg_Clipboard;
            tempDic[@"title"] = BDPI18n.LittleApp_TTMicroApp_PermissionName_Clipboard;
            tempDic[@"description_new"] = BDPI18n.LittleApp_TTMicroApp_PermissionDescri_Clipboard;
        } else if ([key isEqualToString:BDPInnerScopeAppBadge]) {
            tempDic[@"name"] = BDPI18n.OpenPlatform_AppCenter_BadgeTab;
            tempDic[@"description"] = BDPI18n.OpenPlatform_AppCenter_BadgeTtl;
            tempDic[@"title"] = BDPI18n.OpenPlatform_AppCenter_BadgeTab;
            tempDic[@"description_new"] = BDPI18n.OpenPlatform_AppCenter_BadgeTtl;
        } else if ([key isEqualToString:BDPInnerScopeRunData]) {
            tempDic[@"name"] = BDPI18n.LittleApp_StepsApi_ScopeName;
            tempDic[@"description"] = BDPI18n.LittleApp_StepsApi_ScopeDescForPopup;
            tempDic[@"title"] = BDPI18n.LittleApp_StepsApi_ScopeNameDetail;
            tempDic[@"description_new"] = BDPI18n.LittleApp_StepsApi_ScopeDescForClient;
        }

        newScope[key] = tempDic;
    }];
    
    [self setValue:newScope forKeyPath:NSStringFromSelector(@selector(scope))];
}

@end
