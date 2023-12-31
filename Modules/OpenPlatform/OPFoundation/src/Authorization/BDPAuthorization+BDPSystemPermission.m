//
//  BDPAuthorization+SystemPermission.m
//  Timor
//
//  Created by liuxiangxin on 2019/12/10.
//

#import <Photos/Photos.h>
#import <AVFoundation/AVFoundation.h>
#import "BDPAuthorization+BDPSystemPermission.h"
#import "BDPAuthorization+BDPUI.h"
#import "BDPAuthorization+BDPUtils.h"
#import "BDPMacroUtils.h"
#import "BDPUtils.h"
#import <ECOInfra/NSDictionary+BDPExtension.h>
#import "BDPAuthorizationUtilsDefine.h"
#import <OPFoundation/OPFoundation-Swift.h>

static NSString *const kScopeSystemPermissionsKey = @"systemPermissions";

@implementation BDPAuthorization (BDPSystemPermission)

#pragma mark - Permission Request

// 递归挨个获取系统授权,并返回每个权限的授权情况
- (void)requestSystemPermissionForScopeListIfNeeded:(NSArray<NSString *> *)scopeList
                                           uniqueID:(OPAppUniqueID *)uniqueID
                                         completion:(void (^)(NSDictionary<NSString *, NSNumber *> *))completion
{
    NSMutableArray<NSString*> *list = scopeList.mutableCopy;
    NSMutableDictionary<NSString *, NSNumber *> *resultDic = [NSMutableDictionary dictionary];
    
    [self _requestSystemPermissionForScopeListIfNeeded:list
                                              uniqueID:uniqueID
                                             resultDic:resultDic
                                            completion:completion];
}

- (void)_requestSystemPermissionForScopeListIfNeeded:(NSMutableArray<NSString *> *)scopeList
                                            uniqueID:(OPAppUniqueID *)uniqueID
                                           resultDic:(NSMutableDictionary<NSString *, NSNumber *> *)resultDic
                                          completion:(void (^)(NSDictionary<NSString *, NSNumber *> *))completion
{
    if (!scopeList.count) {
        AUTH_COMPLETE(resultDic.copy)
        return;
    }
    
    __block NSString *nextScope = scopeList.lastObject;
    [scopeList removeLastObject];
    WeakSelf;
    [self requestSystemPermissionForScopeIfNeed:nextScope uniqueID:uniqueID completion:^(BDPAuthorizationPermissionResult res) {
        StrongSelfIfNilReturn;
        [resultDic setValue:@(res) forKey:nextScope];
        [self _requestSystemPermissionForScopeListIfNeeded:scopeList uniqueID:uniqueID resultDic:resultDic completion:completion];
    }];
}

// 获取某个scope对应的系统权限
- (void)requestSystemPermissionForScopeIfNeed:(NSString *)scope
                                     uniqueID:(OPAppUniqueID *)uniqueID
                                   completion:(BDPAuthorizationRequestCompletion)completion
{
    // 获取安全回调
    completion = [self generateSafeCompletion:completion uniqueID:uniqueID];
    
    // Transform Command to System Auth List
    NSArray<NSNumber *> *systemPermissionList = [self systemPermissionTypeListForScope:scope];
    BDPLogInfo(@"requestSystemPermissions %@", BDPParamStr(scope, systemPermissionList));

    WeakSelf;
    [self requestSystemPermissions:systemPermissionList.mutableCopy completion:^(BDPAuthorizationPermissionResult result, BDPAuthorizationSystemPermissionType disabledPermission) {
        StrongSelfIfNilReturn;
        BDPLogInfo(@"requestSystemPermissions completion %@", BDPParamStr(result, disabledPermission));
        if (result == BDPAuthorizationPermissionResultSystemDisabled) {
            [[self class] showAlertNoPermission:disabledPermission];
        }

        AUTH_COMPLETE(result);
    }];
}

// 排队挨个获取系统权限， 如果某个权限失败， 就不会再继续往下申请了
- (void)requestSystemPermissions:(NSMutableArray<NSNumber *> *)permissionList
                      completion:(void (^)(BDPAuthorizationPermissionResult result, BDPAuthorizationSystemPermissionType disabledPermission))completion
{
    if (!permissionList.count) {
        //有两种情况可以到达这里：
        //1. list本身是空的，不需要任何系统授权
        //2. list中所有的系统权限都申请成功了
        AUTH_COMPLETE(BDPAuthorizationPermissionResultEnabled, BDPAuthorizationSystemPermissionTypeUnknown)
        return;
    }
    
    NSNumber *permissionWrapper = permissionList.lastObject;
    [permissionList removeLastObject];
    
    if (![permissionWrapper isKindOfClass:NSNumber.class]) {
        [self requestSystemPermissions:permissionList completion:completion];
        return;
    }
    
    BDPAuthorizationSystemPermissionType systemPermission = (BDPAuthorizationSystemPermissionType)[permissionWrapper integerValue];
    WeakSelf;
    [[self class] checkSystemPermission:systemPermission completion:^(BOOL isSuccess) {
        StrongSelfIfNilReturn;
        if (isSuccess) {
            [self requestSystemPermissions:permissionList completion:completion];
        } else {
            AUTH_COMPLETE(BDPAuthorizationPermissionResultSystemDisabled, systemPermission)
        }
    }];
}


#pragma mark - Permission Check

+ (void)checkSystemPermissionWithTips:(BDPAuthorizationSystemPermissionType)type
                           completion:(BDPAuthorizationSystemPermissionCompletion)completion
{
    [self checkSystemPermission:type completion:^(BOOL isSuccess) {
        if (!isSuccess) {
            [[self class] showAlertNoPermission:type];
        }
        AUTH_COMPLETE(isSuccess)
    }];
}

+ (void)checkSystemPermission:(BDPAuthorizationSystemPermissionType)type
                   completion:(BDPAuthorizationSystemPermissionCompletion)completion
{
    switch (type) {
        case BDPAuthorizationSystemPermissionTypeCamera:
            [self checkCameraPermission:completion];
            break;
        case BDPAuthorizationSystemPermissionTypeMicrophone:
            [self checkMicrophonePermission:completion];
            break;
        case BDPAuthorizationSystemPermissionTypeAlbum:
            [self checkAlbumPermission:completion];
            break;
        case BDPAuthorizationSystemPermissionTypeUnknown:
            AUTH_COMPLETE(YES);
            break;
    }
}

+ (void)checkMicrophonePermission:(void (^)(BOOL isSuccess))completion
{
    // Check Permission
    AVAuthorizationStatus videoAuthStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeAudio];
    if (videoAuthStatus == AVAuthorizationStatusNotDetermined) { // 未询问用户是否授权
        NSError *error;
        [OPSensitivityEntry AVAudioSession_requestRecordPermissionForToken:OPSensitivityEntryTokenBDPAuthorization_checkMicrophonePermission_AVAudioSession_requestRecordPermission session:[AVAudioSession sharedInstance] error:&error response:^(BOOL granted) {
            BDPExecuteOnMainQueue(^{
                AUTH_COMPLETE(granted);
            });
        }];
        if (error != nil) {
            BDPLogError(@"checkMicrophonePermission error %@", error);
            AUTH_COMPLETE(false);
        }
    } else if (videoAuthStatus == AVAuthorizationStatusRestricted || videoAuthStatus == AVAuthorizationStatusDenied) { // 未授权
        AUTH_COMPLETE(NO);
    } else {
        AUTH_COMPLETE(YES);
    }
}

+ (void)checkCameraPermission:(void (^)(BOOL isSuccess))completion
{
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if (authStatus == AVAuthorizationStatusNotDetermined) {
        NSError *error;
        [OPSensitivityEntry AVCaptureDevice_requestAccessVideoForToken: OPSensitivityEntryTokenBDPAuthorization_checkCameraPermission_AVCaptureDevice_requestAccess error:&error completionHandler:^(BOOL granted) {
            BDPExecuteOnMainQueue(^{
                AUTH_COMPLETE(granted);
            });
        }];
        if (error != nil) {
            BDPLogError(@"checkCameraPermission error %@", error);
            AUTH_COMPLETE(NO);
        }
    } else if ((authStatus == AVAuthorizationStatusRestricted || authStatus == AVAuthorizationStatusDenied)) {
        AUTH_COMPLETE(NO); // 无权限
    } else { // 已授权
        AUTH_COMPLETE(YES);
    }
}

+ (void)checkAlbumPermission:(void (^)(BOOL isSuccess))completion
{
    PHAuthorizationStatus authStatus = [PHPhotoLibrary authorizationStatus];
    if (authStatus == PHAuthorizationStatusNotDetermined) {
        NSError *error;
        [OPSensitivityEntry photos_PHPhotoLibrary_requestAuthorizationForToken: OPSensitivityEntryTokenPHPhotoLibrary_requestAuthorization_BDPAuthorization_checkAlbumPermission
         error:&error
         handler: ^(NSInteger status) {
            BDPExecuteOnMainQueue(^{
                if (status == AVAuthorizationStatusRestricted || status == AVAuthorizationStatusDenied) { // 无权限
                    AUTH_COMPLETE(NO);
                } else { // 已授权
                    AUTH_COMPLETE(YES);
                }
            });
        }];
        if (error != nil) {
            BDPLogError(@"checkAlbumPermission error %@", error);
            AUTH_COMPLETE(NO);
        }
    } else if ((authStatus == PHAuthorizationStatusRestricted || authStatus == PHAuthorizationStatusDenied)) {
        AUTH_COMPLETE(NO);
    } else { // 已授权
        AUTH_COMPLETE(YES);
    }
}

- (NSArray<NSNumber *> *)systemPermissionTypeListForScope:(NSString *)scope
{
    NSDictionary *scopeDic = [self.scope bdp_objectForKey:scope];
    NSArray<NSNumber *> *list = [scopeDic bdp_objectForKey:kScopeSystemPermissionsKey];
    
    return list.copy;
}

@end
