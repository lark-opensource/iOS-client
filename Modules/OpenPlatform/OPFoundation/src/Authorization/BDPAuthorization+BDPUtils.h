//
//  BDPAuthorization+Utils.h
//  Timor
//
//  Created by liuxiangxin on 2019/12/10.
//

#import <UIKit/UIkit.h>
#import "BDPAuthorization.h"

typedef NS_OPTIONS(int64_t, BDPAuthorizationFreeType) {
    BDPAuthorizationFreeTypeCamera = 1,
    BDPAuthorizationFreeTypeAlubum = 1 << 1,
    BDPAuthorizationFreeTypeUserInfo = 1 << 2,
    BDPAuthorizationFreeTypeMicrophone = 1 << 3,
    BDPAuthorizationFreeTypeAddress = 1 << 4,
    BDPAuthorizationFreeTypeUserLocation = 1 << 5,
    BDPAuthorizationFreeTypeScreenRecord = 1 << 6,
    BDPAuthorizationFreeTypeClipboard = 1 << 7,
    BDPAuthorizationFreeTypeAppBadge = 1 << 8,
    BDPAuthorizationFreeTypeRunData = 1 << 9
};

NS_ASSUME_NONNULL_BEGIN

@interface BDPAuthorization (BDPUtils)

#pragma mark - Safe Completion

- (BDPAuthorizationRequestCompletion)generateSafeCompletion:(BDPAuthorizationRequestCompletion)completion
                                                   uniqueID:(OPAppUniqueID *)uniqueID;

- (BDPAuthorizationRequestCompletion)generateSafeCompletion:(BDPAuthorizationRequestCompletion)completion
                                                   uniqueID:(OPAppUniqueID *)uniqueID
                                                     method:(BDPJSBridgeMethod *)method;

#pragma mark - Scope Request Queue

- (BOOL)scopeQueueCreateIfNeeded:(NSString *)scope;

- (void)scopeQueueAddCompletion:(BDPAuthorizationRequestCompletion)completion scope:(NSString *)scope;

- (void)scopeQueueStartWaiting:(NSString *)scope;

- (BOOL)scopeQueueIsWaiting:(NSString *)scope;

- (void)scopeQueueExcuteAllCompletion:(BDPAuthorizationPermissionResult)result scope:(NSString *)scope;

#pragma mark - Scope Map

/**
    注意, 后续服务端新申请的小程序权限格式会比较复杂, 不再是之前scope前缀+权限名, 而是client:run_data:readonly
    当前有1张storageKey(BDPInnerScopeKey)映射到BDPScopeKey的表格
    有1张BDPScopeKey映射到onlineKey(服务端上保存的)
 */

/// 从storage key到 scope key的映射
/// [key1] --> scope.[key2]
+ (NSDictionary<NSString *, NSString *> *)mapForStorageKeyToScopeKey;

+ (NSMutableDictionary * _Nullable)transformScopeToDict:(NSString *)scope value:(NSNumber *)value dictionary:(NSMutableDictionary *)dict;

+ (BDPPermissionScopeType)transformScopeToScopeType:(NSString *)scope;

+ (NSString * _Nullable)transfromScopeToInnerScope:(NSString *)scope;

/// 根据服务端key获取BDPScopeKey, 找不到则返回入参
+ (NSString * _Nonnull)transformOnlineScopeToScope:(NSString * _Nonnull)onlineScope;

/// 根据BDPScopeKey获取服务端key, 找不到则返回入参
+ (NSString * _Nonnull)transformScopeKeyToOnlineScope:(NSString * _Nonnull)scopeKey;

+ (NSString * _Nullable)transfromScopeTypeToInnerScope:(BDPPermissionScopeType)scopeType;

+ (BDPAuthorizationFreeType)authorizationFreeTypeForInnerScope:(NSString *)innerScope;

#pragma mark - localization

- (void)localizationScope;

@end

NS_ASSUME_NONNULL_END
