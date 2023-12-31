//
//  EMAPluginAuthorizationCustomImpl.m
//  EEMicroAppSDK
//
//  Created by yinyuan on 2019/2/28.
//

#import "EMAPluginAuthorizationCustomImpl.h"
#import <OPFoundation/EMAAlertController.h>
#import "EMAI18n.h"
#import <OPFoundation/EMASandBoxHelper.h>
#import "EMAUserAuthorizationSynchronizer.h"
#import <OPFoundation/BDPAuthorization.h>
#import <OPFoundation/BDPCommonManager.h>
#import <OPFoundation/BDPI18n.h>
#import <TTMicroApp/BDPPermissionController.h>
#import <OPFoundation/BDPResponderHelper.h>
#import <OPFoundation/BDPUniqueID.h>
#import <OPFoundation/BDPUtils.h>
#import <ECOInfra/NSDictionary+BDPExtension.h>
#import <OPFoundation/TMACustomHelper.h>
#import "EERoute.h"
#import <ECOInfra/EMANetworkManager.h>
#import <OPFoundation/EMANetworkCipher.h>
#import <OPFoundation/EMANetworkAPI.h>
#import <OPFoundation/EMARequestUtil.h>
#import <ECOInfra/JSONValue+BDPExtension.h>
#import <TTMicroApp/BDPMetaTTCode.h>
#import <OPFoundation/TMASecurity.h>
#import "EMAAppEngine.h"
#import <OPFoundation/TMASessionManager.h>
#import <OPFoundation/BDPAuthorization+BDPUtils.h>
#import <OPFoundation/BDPAuthorizationUtilsDefine.h>
#import <OPFoundation/BDPMonitorEvent.h>
#import <OPFoundation/BDPMonitorHelper.h>
//#import <LarkOPInterface/OPBadge.h>
#import <LarkOPInterface/LarkOPInterface-Swift.h>
#import <ECOProbe/OPTraceService.h>
#import <ECOProbe/OPTrace.h>
#import <TTMicroApp/TTMicroApp-Swift.h>
#import <OPFoundation/EEFeatureGating.h>
#import <OPFoundation/OPFoundation-Swift.h>
#import <EEMicroAppSDK/EEMicroAppSDK-Swift.h>
#import <ECOInfra/ECOInfra-Swift.h>

@implementation EMAPluginAuthorizationCustomImpl

+ (instancetype)sharedPlugin {
    static id sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

/// 后期补充的需要授权的 API-Scope 列表（不再修改 ez.dat 加密文件）
- (NSDictionary *)additionalPermissionConfigs {
    NSMutableDictionary *map = [NSMutableDictionary dictionary];
    // clipboard
    map[@"setClipboardData"] = BDPInnerScopeClipboard;
    map[@"getClipboardData"] = BDPInnerScopeClipboard;
    // location
    map[@"startLocationUpdate"] = BDPInnerScopeUserLocation;
    // locationV2
    map[@"startLocationUpdateV2"] = BDPInnerScopeUserLocation;
    map[@"getLocationV2"] = BDPInnerScopeUserLocation;
    map[@"chooseLocationV2"] = BDPInnerScopeUserLocation;
    map[@"openLocationV2"] = BDPInnerScopeUserLocation;

    map[@"startBeaconDiscovery"] = BDPInnerScopeUserLocation;
    // runData
    map[@"getStepCount"] = BDPInnerScopeRunData;
    //bluetooth
    if([EMAFeatureGating boolValueForKey: EEFeatureGatingKeyScopeBluetoothEnable]) {
        map[@"openBluetoothAdapter"] = BDPInnerScopeBluetooth;
    }
    if ([EMAFeatureGating boolValueForKey: EEFeatureGatingKeyGetUserInfoAuth]) {
        map[@"getUserInfo"] = BDPInnerScopeUserInfo;
    }
    return [map copy];
}

/// 不再需要经过用户同意的权限
- (NSArray<NSString *> *)alwaysApprovedPermissions {
    NSMutableArray *arr = [NSMutableArray array];
    [arr addObject: @"scanCode"];     // 扫码不需要用户权限
    [arr addObject: @"openLocation"]; // 查看地址不需要用户权限
    [arr addObject: @"chooseImage"];  // 选择图片不需要用户权限
    [arr addObject: @"chooseVideo"];  // 选择相机不需要用户权限
    [arr addObject: @"getUserInfo"];  // 获取用户信息不需要用户权限，作为组织资源在后台授权
    if ([EMAFeatureGating boolValueForKey: EEFeatureGatingKeyGetUserInfoAuth]) {
        [arr removeObject:@"getUserInfo"];
    }
    return [arr copy];
}

/// 后期补充的授权 scope 信息（不再修改 ez.dat 加密文件）
- (NSDictionary *)additionalScopeConfigs {
    NSMutableDictionary *result = [@{
        BDPInnerScopeClipboard: @{
            @"name": BDPI18n.LittleApp_TTMicroApp_PermissionName_Clipboard,
            @"title": BDPI18n.LittleApp_TTMicroApp_PermissionName_Clipboard,
            @"description": BDPI18n.LittleApp_TTMicroApp_PermissionMsg_Clipboard,
            @"description_new": BDPI18n.LittleApp_TTMicroApp_PermissionDescri_Clipboard,
        },
        BDPInnerScopeAppBadge: @{
            @"name": BDPI18n.OpenPlatform_AppCenter_BadgeTab,
            @"title": BDPI18n.OpenPlatform_AppCenter_BadgeTab,
            @"description": BDPI18n.OpenPlatform_AppCenter_BadgeTtl,
            @"description_new": BDPI18n.OpenPlatform_AppCenter_BadgeTtl,
        },

        BDPInnerScopeRunData: @{
            @"name": BDPI18n.LittleApp_StepsApi_ScopeName,
            @"title": BDPI18n.LittleApp_StepsApi_ScopeNameDetail,
            @"description": BDPI18n.LittleApp_StepsApi_ScopeDescForPopup,
            @"description_new": BDPI18n.LittleApp_StepsApi_ScopeDescForClient,
        }
    } mutableCopy];
   
    if ([EMAFeatureGating boolValueForKey: EEFeatureGatingKeyScopeBluetoothEnable]) {
        result[BDPInnerScopeBluetooth] = @{
            @"name": EMAI18n.LittleApp_UserInfoPermission_BluetoothPermName,
            @"title": EMAI18n.LittleApp_UserInfoPermission_BluetoothPermNameFull,
            @"description": EMAI18n.LittleApp_UserInfoPermission_BluetoothPermDesc,
            @"description_new":  EMAI18n.LittleApp_UserInfoPermission_BluetoothPermListDisplay,
        };
    }
    return result;
}

- (NSDictionary *)bdp_customAPIAuthConfig:(NSDictionary *)defaultAPIAuthConfig forUniqueID:(BDPUniqueID *)uniqueID {
    NSMutableDictionary *config = (defaultAPIAuthConfig ?: @{}).mutableCopy;
    
    // MARK: - reset permission settings
    NSMutableDictionary *permissions = [config dictionaryValueForKey:BDPInnerAuthConfigKeyPermission defalutValue:@{}].mutableCopy;
    
    // add additional permissions to the map
    [permissions addEntriesFromDictionary:[self additionalPermissionConfigs]];
    
    // remove always allow permissions from the map
    [permissions removeObjectsForKeys:[self alwaysApprovedPermissions]];
    
    // reset "Permission" map
    config[BDPInnerAuthConfigKeyPermission] = permissions;
    
    // MARK: - reset scope settings
    
    NSMutableDictionary *scopes = [config dictionaryValueForKey:BDPInnerAuthConfigKeyScope defalutValue:@{}].mutableCopy;
    
    // add additional scope to the map
    [scopes addEntriesFromDictionary:[self additionalScopeConfigs]];
    
    // reset "Scope" map
    config[BDPInnerAuthConfigKeyScope] = scopes;

    return config.copy;
}

- (BOOL)bpd_isApiAvailable:(NSString *)apiName forUniqueID:(BDPUniqueID *)uniqueID {
    return [[[EMAAppEngine currentEngine] onlineConfig] isApiAvailable:apiName forUniqueID:uniqueID];
}

/// 调用tt.getSetting，始终返回已授权状态
- (NSDictionary *)bdp_customGetSettingUsedScopesDict:(NSDictionary *)usedScopesDict {
    NSMutableDictionary *newUsedScopesDict = [usedScopesDict mutableCopy];
    if(![EMAFeatureGating boolValueForKey:EEFeatureGatingKeyGetUserInfoAuth]){
        newUsedScopesDict[@"scope.userInfo"] = @YES;
    }
    return newUsedScopesDict;
}

- (void)bdp_notifyUpdatingScopes:(NSDictionary<NSString *, NSNumber *> *)scopes withAuthProvider:(BDPAuthStorageProvider)authProvider {
    // 授权状态更改时，将修改时间戳同步保存到本地
    // 将本地数据同步到线上
    [EMAUserAuthorizationSynchronizer updateScopeModifyTimeAndSyncToOnlineWithStorageDict:scopes withAuthProvider:authProvider completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        [self updateAppBadgeWithAuthProvider:authProvider scopes:scopes];
    }];
}

- (void)updateAppBadgeWithAuthProvider:(BDPAuthorization *)authProvider scopes:(NSDictionary<NSString *, NSNumber *> *)scopes {
    if (!authProvider || !authProvider.source || !scopes || ![scopes objectForKey:BDPInnerScopeAppBadge]) {
        return;
    }
    BOOL needShow = [scopes bdp_boolValueForKey:BDPInnerScopeAppBadge];
    NSString *appID = authProvider.source.uniqueID.appID;
    BDPType appType = authProvider.source.uniqueID.appType;

    NSMutableDictionary *extra = [NSMutableDictionary dictionary];
    [extra setObject:@(needShow) forKey:@"needShow"];
    [extra setObject:@(AppBadgeUpdateNodeSceneAppSetting) forKey:@"scene"]; // 不分about、setting来源
    UpdateBadgeRequestParameters *extraModel = [[UpdateBadgeRequestParameters alloc] initWithType:UpdateBadgeRequestParametersTypeNeedShow];
    extraModel.scene = AppBadgeUpdateNodeSceneAppSetting;
    extraModel.needShow = needShow;
    id<EMAProtocol> delegate = [EMARouteProvider getEMADelegate];
    
    [delegate updateAppBadge:appID appType:[self appTypeToBadgeAppType:appType] extra:extraModel completion:nil];
    PullBadgeRequestParameters *pullExtra = [[PullBadgeRequestParameters alloc] initWithScene:AppBadgePullNodeSceneRustNet];
    [delegate pullAppBadge:appID appType:[self appTypeToBadgeAppType:appType] extra:pullExtra completion:nil];
}

- (AppBadgeAppType)appTypeToBadgeAppType:(OPAppType)appType {
    AppBadgeAppType type = AppBadgeAppTypeUnknown;
    if (appType == OPAppTypeGadget) {
        type = AppBadgeAppTypeNativeApp;
    } else if (appType == OPAppTypeWebApp) {
        type = AppBadgeAppTypeWebApp;
    } else if (appType == OPAppTypeWidget) {
        type = AppBadgeAppTypeNativeCard;
    }
    return type;
}


- (void)bdp_onPersmissionDisabledWithParam:(NSDictionary *)params firstTime:(BOOL)firstTime authProvider:(BDPAuthorization *)authProvider inController:(UIViewController * _Nullable)controller {
    if (firstTime) {
        // 首次拒绝权限不用给提示
        return;
    }

    UIViewController *viewController = [TMACustomHelper isInTabBarController:controller] ? controller.navigationController : controller;
    UINavigationController *nav = viewController.navigationController;

    NSString *name = params[@"appName"];
    NSString *title = [NSString stringWithFormat:BDPI18n.permissions_is_requesting, name];
    if (BDPIsEmptyString(name)) {
        title = BDPI18n.LittleApp_TTMicroApp_AllowAppPrmssn;
    }

    // 适配DarkMode:使用主端提供的UDDilog
    UDDialog *dialog = [UDOCDialogBridge createDialog];
    [UDOCDialogBridge setTitleWithDialog:dialog text:title];
    [UDOCDialogBridge setContentWithDialog:dialog text:params[@"description"]];
    [UDOCDialogBridge addSecondaryButtonWithDialog:dialog text:BDPI18n.cancel dismissCompletion:^{

    }];
    [UDOCDialogBridge addButtonWithDialog:dialog text:BDPI18n.microapp_m_permission_go_to_settings dismissCompletion:^{
        UIViewController *vc = [[BDPPermissionController alloc] initWithAuthProvider:authProvider];
        [nav pushViewController:vc animated:YES];
    }];
    
    if ([UDRotation isAutorotateFrom:controller]) {
        [UDOCDialogBridge setAutorotatableWithDialog:dialog enable:YES];
    }

    [controller presentViewController:(UIViewController *)dialog animated:YES completion:nil];
}

- (NSDictionary<NSString *, NSString *> *)bdp_customMapForStorageKeyToScopeKey:(NSDictionary<NSString *, NSString *> *)map;
{
    if (map == nil) {
        return map;
    }
    NSMutableDictionary *mutMap = map.mutableCopy;
    [mutMap setValue:@"scope.deviceID" forKey:@"deviceID"];
    //头条目前使用scope.album做tt.saveImageToPhotosAlbum, tt.saveVideoToPhotosAlbum 两个接口的scope值，lark还是保留之前逻辑使用scope.writePhotosAlbum做scope
    [mutMap setValue:@"scope.writePhotosAlbum" forKey:@"album"];
    return mutMap.copy;
}

- (BOOL)bdp_shouldCustomizePemissionForInnerScope:(NSString *)innerScope completion:(void (^)(BDPAuthorizationPermissionResult))completion {
    if (!BDPIsEmptyString(innerScope)) {
        /// 涉及相机、用户信息等权限不再需要经过用户同意，直接返回有效状态
        if(![EMAFeatureGating boolValueForKey:EEFeatureGatingKeyGetUserInfoAuth]){
            NSArray<NSString *> *approvedScopeList = @[@"userinfo"];
            if ([approvedScopeList containsObject:innerScope]) {
                if (completion) {
                    completion(BDPAuthorizationPermissionResultEnabled);
                }
                return YES;
            }
        }
    }
    return NO;
}

/** chooseImage/chooseVideo/scanCode这些操作，用户可感知，属于读相册权限，直接允许调用。
saveImageToPhotosAlbum/saveVideoToPhotosAlbum这些操作，用户不可感知，属于写相册权限，需要经过用户同意才能调用。
 */
- (BOOL)bdp_shouldCheckAllUserPermissionsForInvokeName:(NSString *)invokeName {
    if (BDPIsEmptyString(invokeName)) {
        return NO;
    }
    NSArray<NSString *> *approvedPermissions = [self alwaysApprovedPermissions];
    if ([approvedPermissions containsObject:invokeName]) {
        return NO;
    }
    return YES;
}

- (void)bdp_fetchAuthorizeData:(BDPAuthorization *)authProvider storage:(BOOL)storage completion:(void (^ _Nonnull)(NSDictionary * _Nullable result, NSDictionary * _Nullable bizData, NSError * _Nullable error))completion {
    
    NSString *url = [EMAAPI getScopesURL];
    NSString *appID = authProvider.source.uniqueID.appID;
    BDPType appType = authProvider.source.uniqueID.appType;
    NSDictionary *params;
    params = @{
        @"appID": authProvider.source.uniqueID.appID ?: @"",
    };
    NSString *session = EMAAppEngine.currentEngine.account.userSession;
    NSDictionary *header = @{
        @"Cookie": [NSString stringWithFormat:@"session=%@", session]
    };

    OPMonitorEvent *monitor = BDPMonitorWithName(kEventName_op_app_auth_setting, authProvider.source.uniqueID).timing();

    WeakSelf;
    //TODO: 网络专用 Trace, 派生了一级,勿直接使用.目前网络层级混乱,直接调了底层网络类,所以只能在这里派生(否者会和 EMARequestUtil 的封装冲突),网络重构后会统一修改 --majiaxin
    OPTrace *tracing = [EMARequestUtil generateRequestTracing:authProvider.source.uniqueID];

    void (^handleResult)(NSData * _Nullable data, NSError * _Nullable error) = ^(NSData * _Nullable data, NSError * _Nullable error) {
        StrongSelf;
        NSError *serializationError = nil;
        NSDictionary *dataDict = [data JSONValueWithOptions:NSJSONReadingAllowFragments error:&serializationError];
        NSDictionary *userAuthScope;
        NSMutableDictionary *bizDict;
        BOOL hasNewData = NO;
        BOOL authFree =  [BDPAuthorization authorizationFree];
        if (serializationError || ![dataDict isKindOfClass:[NSDictionary class]]) {
            monitor.kv(kEventKey_result_type, kEventValue_fail).flush();
            if (completion) {
                completion(dataDict, nil, error);
            }
            return;
        }
        NSDictionary *scopeDataDict = [dataDict bdp_dictionaryValueForKey:@"data"];
        if ([scopeDataDict isKindOfClass:[NSDictionary class]]) {
            if (authFree) {
                userAuthScope = [scopeDataDict bdp_dictionaryValueForKey:@"userAuthScopeList"];
            } else {
                userAuthScope = [scopeDataDict bdp_dictionaryValueForKey:@"user_auth_scopes"];
            }
        }

        NSMutableArray *monitorScopes = [NSMutableArray array];
        // 验证返回的scope是否是支持的
        bizDict = [NSMutableDictionary dictionary];
        NSDictionary *keys = [BDPAuthorization mapForStorageKeyToScopeKey];
        for (NSString *key in userAuthScope.allKeys) {
            NSDictionary *value = [userAuthScope bdp_dictionaryValueForKey:key];
            NSString *scopeKey = key;
            if (![scopeKey hasPrefix:BDPScopePrefix]) {
                scopeKey = [NSString stringWithFormat:@"scope.%@", key];
            }

            // 这边灰度阶段使用olineScopeKey转换成scopeKey.待全量后删除原先onlineScopeKey拼接scope.的方式;
            if ([EEFeatureGating boolValueForKey:EEFeatureGatingKeyNewScopeMapRule]) {
                scopeKey = [BDPAuthorization transformOnlineScopeToScope:key];
                BDPLogInfo(@"transform onlineKey: %@ to scopeKey: %@", key, scopeKey);
            }

            NSString *authKey = [EMAUserAuthorizationSynchronizer transformScopeKeyToStorageKey:scopeKey mapForStorageKeyToScopeKey:keys];
            if (authKey && value && [value isKindOfClass:[NSDictionary class]]) {
                [bizDict setObject:value forKey:key];
                [monitorScopes addObject:@{@"scope": key, @"status": @([value bdp_boolValueForKey:@"auth"])}];
            }
        }
        if (storage) {
            hasNewData = [EMAUserAuthorizationSynchronizer compareAndSaveToLocalAuthorizations:bizDict uniqueID:authProvider.source.uniqueID mapForStorageKeyToScopeKey:keys onlineScopeModifyTimeKey:@"modify_time" auth:authProvider];
        }
        BDPLogInfo(@"fetchAuthorizeData invoke completion app=%@, appType=%@ hasNewData=%@ code=%@", appID, @(appType), @(hasNewData), @([dataDict integerValueForKey:@"code" defaultValue:-1]));
        monitor.kv(kEventKey_result_type, kEventValue_success).timing().kv(@"auth_setting_brief", monitorScopes).flush();

        NSMutableDictionary *extra = [NSMutableDictionary dictionary];
        if (bizDict) {
            if (authFree) {
                [extra setObject:bizDict forKey:@"userAuthScopeList"];
            } else {
                [extra setObject:bizDict forKey:@"userAuthScope"];
            }
        }
        [extra setValue:@(hasNewData) forKey:@"hasNewData"];
        if (completion) {
            completion(dataDict, extra, error);
        }
    };

    if ([OPECONetworkInterface enableECOWithPath:OPNetworkAPIPath.getScopes]) {
        OpenECONetworkAppContext *context = [[OpenECONetworkAppContext alloc] initWithTrace:tracing
                                                                                   uniqueId:authProvider.source.uniqueID
                                                                                     source:ECONetworkRequestSourceApi];
        [OPECONetworkInterface postForOpenDomainWithUrl:url
                                                context:context
                                                 params:params
                                                 header:header
                                      completionHandler:^(NSDictionary<NSString *,id> *json, NSData *data, NSURLResponse *response, NSError *error) {
            handleResult(data, error);
        }];
    } else {
        [[EMANetworkManager shared] requestUrl:url method:@"POST" params:params header:header completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            handleResult(data, error);
        } eventName:@"getScopes" requestTracing:tracing];
    }
}

@end
