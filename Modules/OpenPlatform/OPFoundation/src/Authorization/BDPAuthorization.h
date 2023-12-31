//
//  BDPAuthorization.h
//  Timor
//
//  Created by 王浩宇 on 2018/11/17.
//

#import <Foundation/Foundation.h>
#import "BDPModel.h"
#import "BDPAppMetaBriefProtocol.h"
#import <ECOInfra/TMAKVDatabase.h>
#import "BDPPermissionScope.h"
#import "OPJSEngineProtocol.h"
#import "BDPJSBridgeProtocol.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, BDPAuthorizationURLDomainType) {
    BDPAuthorizationURLDomainTypeUnknown = 0,
    BDPAuthorizationURLDomainTypeWebView,
    BDPAuthorizationURLDomainTypeRequest,
    BDPAuthorizationURLDomainTypeUpload,
    BDPAuthorizationURLDomainTypeDownload,
    BDPAuthorizationURLDomainTypeWebSocket,
    BDPAuthorizationURLDomainTypeSchemaHost,
    BDPAuthorizationURLDomainTypeSchemaAppIds,
    BDPAuthorizationURLDomainTypeWebViewComponentSchema
};

typedef NS_ENUM(NSInteger, BDPAuthorizationSystemPermissionType) {
    BDPAuthorizationSystemPermissionTypeUnknown = 0,
    BDPAuthorizationSystemPermissionTypeCamera,
    BDPAuthorizationSystemPermissionTypeMicrophone,
    BDPAuthorizationSystemPermissionTypeAlbum
};

typedef void(^BDPAuthorizationRequestCompletion)(BDPAuthorizationPermissionResult result);

FOUNDATION_EXTERN NSString * const BDPScopeCamera;
FOUNDATION_EXTERN NSString * const BDPScopeAlbum;
FOUNDATION_EXTERN NSString * const BDPScopeUserInfo;
FOUNDATION_EXTERN NSString * const BDPScopeUserLocation;
FOUNDATION_EXTERN NSString * const BDPScopeRecord;
FOUNDATION_EXTERN NSString * const BDPScopeAddress;
FOUNDATION_EXTERN NSString * const BDPScopeWritePhotosAlbum;
FOUNDATION_EXTERN NSString * const BDPScopeScreenRecord;
FOUNDATION_EXTERN NSString * const BDPScopeClipboard;
FOUNDATION_EXTERN NSString * const BDPScopeAppBadge;
FOUNDATION_EXTERN NSString * const BDPScopeRunData;
FOUNDATION_EXTERN NSString * const BDPInnerScopeBluetooth;

FOUNDATION_EXPORT NSString * const BDPInnerScopeCamera;
FOUNDATION_EXPORT NSString * const BDPInnerScopeAlbum;
FOUNDATION_EXPORT NSString * const BDPInnerScopeUserInfo;
FOUNDATION_EXPORT NSString * const BDPInnerScopeUserLocation;
FOUNDATION_EXPORT NSString * const BDPInnerScopeRecord;
FOUNDATION_EXPORT NSString * const BDPInnerScopeAddress;
FOUNDATION_EXPORT NSString * const BDPInnerScopePhoneNumber;
FOUNDATION_EXTERN NSString * const BDPInnerScopeScreenRecord;
FOUNDATION_EXTERN NSString * const BDPInnerScopeClipboard;
FOUNDATION_EXTERN NSString * const BDPInnerScopeAppBadge;
FOUNDATION_EXTERN NSString * const BDPInnerScopeRunData;
FOUNDATION_EXTERN NSString * const BDPScopeBluetooth;

FOUNDATION_EXTERN NSString * const BDPInnerAuthConfigKeyPermission;
FOUNDATION_EXTERN NSString * const BDPInnerAuthConfigKeyScope;
FOUNDATION_EXTERN NSString * const BDPInnerAuthConfigKeyWhiteList;

@interface BDPAuthorization : NSObject <BDPJSBridgeAuthorizationProtocol>
@property (nonatomic, copy, readonly) NSDictionary *scope;

@property (nonatomic, strong, readonly) BDPAuthStorageProvider storage;
@property (nonatomic, copy, readonly) NSDictionary *permission;
@property (nonatomic, copy, readonly) NSDictionary *userInfo;
@property (nonatomic, strong, readonly) id<BDPMetaWithAuthProtocol> source;
@property (nonatomic, strong, readonly) NSMutableArray *recordFailedScopes;
@property (nonatomic, strong, readonly) NSMutableDictionary *scopeQueue;
@property (nonatomic, assign, readonly) BOOL shouldCombinedAuthorize;
@property (nonatomic, copy, nullable) NSString* (^authSyncSession)(void);

- (instancetype)initWithAuthDataSource:(id<BDPMetaWithAuthProtocol>)source storage:(BDPAuthStorageProvider)storage;

/**
 更改授权状态，默认通知宿主

 @param scope 标识授权范围的storage key
 @param approved 是否允许
 @return 是否保存成功
 */
- (BOOL)updateScope:(NSString *)scope approved:(BOOL)approved;

/**
 更改授权状态

 @param scope 标识授权范围的storage key
 @param approved 是否允许
 @param notify 是否通知宿主
 @return 是否保存成功
 */
- (BOOL)updateScope:(NSString *)scope approved:(BOOL)approved notify:(BOOL)notify;
/**
 批量更改授权状态

 @param scopes 标识授权范围的storage键值对：@{(NSString *)scope: @((BOOL)approved)}
 @param notify 是否通知宿主
 @return 是否保存成功
 */
- (BOOL)updateScopes:(NSDictionary<NSString *, NSNumber *> *)scopes notify:(BOOL)notify;

/**
 获取授权状态值

 @param scope 标识授权范围的storage key
 @return 授权状态值
 */
- (NSNumber * __nullable)statusForScope:(NSString *)scope;
- (NSArray<NSDictionary *> *)usedScopes;

// 对齐开放平台权限名称
- (NSDictionary *)usedScopesDict;

/// scope storage kv
- (NSDictionary *)usedScopesStorageKVDict;

// 获取权限的mod
- (BOOL)modForScope:(NSString *)scope;

- (void)onPersmissionDisabledForScope:(NSString *)scope firstTime:(BOOL)firstTime authProvider:(BDPAuthorization *)authProvider delegate:(id<BDPAuthorizationDelegate>)delegate;
- (void)hasUserinfoWithengine:(BDPJSBridgeEngine)engine completion:(void (^)(BOOL on))completion;

- (void)fetchAuthorizeData:(BOOL)storage completion:(void (^ _Nonnull)(NSDictionary * _Nullable result, NSDictionary * _Nullable bizData, NSError * _Nullable error))completion;

/// 免授权逻辑是否开启，依赖 FG openplatform.authorize.free_auth
+ (BOOL)authorizationFree;

@end

NS_ASSUME_NONNULL_END
