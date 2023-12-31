//
//  BDPAuthorizationPluginDelegate.h
//  Timor
//
//  Created by houjihu on 2019/3/20.
//

#ifndef BDPAuthorizationPluginDelegate_h
#define BDPAuthorizationPluginDelegate_h

#import "BDPBasePluginDelegate.h"
#import "BDPJSBridgeProtocol.h"
#import "BDPAuthorization.h"

@class TMAKVStorage;


/*-----------------------------------------------*/
//             Authorization/ 权限相关
/*-----------------------------------------------*/
@protocol BDPAuthorizationPluginDelegate <BDPBasePluginDelegate>
/**
 *  返回自定义的 APIAuthConfig，返回nil则使用 TMAAPIAuth.plist 配置
 *  defaultAPIAuthConfig 默认的从 TMAAPIAuth.plist 中读取的配置
 *  {
 *      Permission
 *      WhiteList
 *      Scope
 *  }
 */
- (NSDictionary *)bdp_customAPIAuthConfig:(NSDictionary *)defaultAPIAuthConfig forUniqueID:(BDPUniqueID *)uniqueID;


/// 获取api是否在小程序中有权限调用，配置内容在https://cloud.bytedance.net/appSettings-v2/detail/config/145010/detail/status
/// @param apiName api名称
/// @param uniqueID 小程序id
- (BOOL)bpd_isApiAvailable:(NSString *)apiName forUniqueID:(BDPUniqueID *)uniqueID;

/// 定制返回tt.getSetting API调用结果，例如可定制userInfo始终是已授权状态
- (NSDictionary *)bdp_customGetSettingUsedScopesDict:(NSDictionary *)usedScopesDict;

/// 在授权状态变更时通知
- (void)bdp_notifyUpdatingScopes:(NSDictionary<NSString *, NSNumber *> *)scopes withAuthProvider:(BDPAuthStorageProvider)authProvider;

/**
 * 当调用权限未授权接口时调用
 * params: scope, scopeName, description, appID, appName, appIcon
 */
- (void)bdp_onPersmissionDisabledWithParam:(NSDictionary *)params firstTime:(BOOL)firstTime authProvider:(BDPAuthorization *)authProvider inController:(UIViewController * _Nullable)controller;

/// 自定义innerScope --> scope(scope.[*])的map
- (NSDictionary<NSString *, NSString *> *)bdp_customMapForStorageKeyToScopeKey:(NSDictionary<NSString *, NSString *> *)map;

/// 自定义授权状态
/// innerScope: 内部storage存储的scope key
/// completion: 自定义授权状态时需要执行的动作
- (BOOL)bdp_shouldCustomizePemissionForInnerScope:(NSString *)innerScope completion:(void (^)(BDPAuthorizationPermissionResult))completion;

/// 检查是否需要指定invokeName的授权状态，用于调用requestAllUserPermissions:engine:completion方法前检查
/// invokeName: command.invokeName
- (BOOL)bdp_shouldCheckAllUserPermissionsForInvokeName:(NSString *)invokeName;

- (void)bdp_fetchAuthorizeData:(id)authProvider storage:(BOOL)storage completion:(void (^ _Nonnull)(NSDictionary * _Nullable result, NSDictionary * _Nullable bizData, NSError * _Nullable error))completion;

@end

#endif /* BDPAuthorizationPluginDelegate_h */
