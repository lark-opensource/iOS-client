//
//  BDPAuthorization.m
//  Timor
//
//  Created by 王浩宇 on 2018/11/17.
//

#import "BDPAuthorization.h"
#import "BDPAuthorization+BDPEvent.h"
#import "BDPAuthorization+BDPSchema.h"
#import "BDPAuthorization+BDPSystemPermission.h"
#import "BDPAuthorization+BDPUI.h"
#import "BDPAuthorization+BDPUserPermission.h"
#import "BDPAuthorization+BDPUtils.h"
#import "BDPAuthorizationSettingManager.h"
#import "BDPAuthorizationUtilsDefine.h"
#import "BDPBundle.h"
//#import "BDPCommonManager.h"
#import "BDPDeviceHelper.h"
#import "BDPI18n.h"
#import <ECOInfra/BDPLog.h>
#import "BDPMonitorHelper.h"
#import "BDPNetworkManager.h"
#import "BDPResponderHelper.h"
#import "BDPSDKConfig.h"
#import "BDPSandBoxHelper.h"
#import "BDPSchemaCodec+Private.h"
#import "BDPSchemaCodec.h"
#import "BDPTimorClient.h"
#import "BDPUserInfoManager.h"
#import "BDPUtils.h"
#import "BDPAppContext.h"
#import <ECOInfra/JSONValue+BDPExtension.h>
#import "NSArray+BDPExtension.h"
#import <ECOInfra/NSDictionary+BDPExtension.h>
#import "UIViewController+BDPExtension.h"
#import <ECOInfra/EMAFeatureGating.h>
#import "EEFeatureGating.h"

@interface BDPAuthorizationDelegateImpl: NSObject<BDPAuthorizationDelegate>

@property (nonatomic, weak) BDPJSBridgeEngine engine;

@end

@implementation BDPAuthorizationDelegateImpl

- (UIViewController * _Nullable)controller {
    return self.engine.bridgeController;
}

@end

NSString *const kBDPAuthFailedScopeStorageKey = @"bdp_auth_fail_scope";

/// BDPScope提供给外部使用，带"scope."前缀
NSString * const BDPScopeCamera = BDPScope(camera);
NSString * const BDPScopeAlbum = BDPScope(album);
NSString * const BDPScopeUserInfo = BDPScope(userInfo);
NSString * const BDPScopeUserLocation = BDPScope(userLocation);
NSString * const BDPScopeRecord = BDPScope(record);
NSString * const BDPScopeAddress = BDPScope(address);
NSString * const BDPScopeWritePhotosAlbum = BDPScope(writePhotosAlbum);
NSString * const BDPScopeScreenRecord = BDPScope(screenRecord);
NSString * const BDPScopeClipboard = BDPScope(clipboard);
NSString * const BDPScopeAppBadge = BDPScope(appBadge);
NSString * const BDPScopeRunData = BDPScope(runData);
NSString * const BDPScopeBluetooth = BDPScope(bluetooth);


/// BDPInnerScope用于BDPAuthorization内部使用，同时也是保存于DB的key值，同时对应了TMAAPIAuth.plis里面的声明
/// 实际上通过usedScopes给到外部的接口是BDPInnerScope的值，因此BDPInnerScope还是需要对外开放？
NSString * const BDPInnerScopeCamera = @"camera";
NSString * const BDPInnerScopeAlbum = @"album";
NSString * const BDPInnerScopeUserInfo = @"userinfo";
NSString * const BDPInnerScopeUserLocation = @"location";
NSString * const BDPInnerScopeRecord = @"microphone";
NSString * const BDPInnerScopeAddress = @"address";
NSString * const BDPInnerScopePhoneNumber = @"phoneNumber";
NSString * const BDPInnerScopeScreenRecord = @"screenRecord";
NSString * const BDPInnerScopeClipboard = @"clipboard";
NSString * const BDPInnerScopeAppBadge = @"appBadge";
NSString * const BDPInnerScopeRunData = @"runData";
NSString * const BDPInnerScopeBluetooth = @"bluetooth";

// Be consistent with the fields in the file ez.dat
NSString * const BDPInnerAuthConfigKeyPermission = @"Permission";
NSString * const BDPInnerAuthConfigKeyScope = @"Scope";
NSString * const BDPInnerAuthConfigKeyWhiteList = @"WhiteList";

@interface BDPAuthorization ()

@property (nonatomic, copy) NSArray *whiteList;
@property (nonatomic, copy, readwrite) NSDictionary *permission;
@property (nonatomic, copy, readwrite) NSDictionary *scope;
@property (nonatomic, strong, readwrite) NSMutableDictionary *scopeQueue;
@property (nonatomic, strong, readwrite) NSMutableArray *recordFailedScopes;
@property (nonatomic, copy, readwrite) NSDictionary *userInfo;
@property (nonatomic, strong, readwrite) BDPAuthStorageProvider storage;
@property (nonatomic, strong, readwrite) id<BDPMetaWithAuthProtocol> source;
@property (nonatomic, assign, readwrite) BOOL shouldCombinedAuthorize;

@end

@implementation BDPAuthorization

static NSNumber *authorizationFreeFGValue = nil;
+ (BOOL)authorizationFree {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (!authorizationFreeFGValue) {
            authorizationFreeFGValue = @([EMAFeatureGating boolValueForKey:@"openplatform.authorize.free_auth"]);
        }
    });
    
    return [authorizationFreeFGValue boolValue];
}

#pragma mark - Initialize
/*-----------------------------------------------*/
//              Initialize - 初始化相关
/*-----------------------------------------------*/
- (instancetype)initWithAuthDataSource:(id<BDPMetaWithAuthProtocol>)source storage:(BDPAuthStorageProvider)storage
{
    self = [super init];
    if (self) {
        NSString *resource = [[BDPBundle mainBundle] pathForResource:@"ez" ofType:@"dat"];
        NSData *plistData = BDPDecodeDataFromPath(resource);
        if (plistData) {
            NSError *error;
            NSPropertyListFormat format;
            NSDictionary* dict =  [NSPropertyListSerialization propertyListWithData:plistData options:NSPropertyListImmutable format:&format error:&error];
            // 自定义权限配置
            BDPPlugin(authorizationPlugin, BDPAuthorizationPluginDelegate);
            if ([authorizationPlugin respondsToSelector:@selector(bdp_customAPIAuthConfig:forUniqueID:)]) {
                NSDictionary *customDict = [authorizationPlugin bdp_customAPIAuthConfig:dict forUniqueID:source.uniqueID];
                if (customDict) {
                    dict = customDict.copy;
                }
            }
            _permission = [dict bdp_dictionaryValueForKey:BDPInnerAuthConfigKeyPermission];
            _scope = [dict bdp_dictionaryValueForKey:BDPInnerAuthConfigKeyScope];
            _whiteList = [dict bdp_arrayValueForKey:BDPInnerAuthConfigKeyWhiteList];
            [self localizationScope];
        }
        _scopeQueue = [[NSMutableDictionary alloc] init];
        _source = source;
        _storage = storage;
    }
    _shouldCombinedAuthorize = [[BDPAuthorizationSettingManager sharedManager] shouldUseCombineAuthorizeForUniqueID:source.uniqueID];
    
    return self;
}

#pragma mark - Variables Getters & Setters
/*-----------------------------------------------*/
//     Variables Getters & Setters - 变量相关
/*-----------------------------------------------*/
- (BOOL)updateScope:(NSString *)scope
           approved:(BOOL)approved
{
    return [self updateScope:scope approved:approved notify:YES];
}

- (BOOL)updateScope:(NSString *)scope
           approved:(BOOL)approved
             notify:(BOOL)notify {
    if (BDPIsEmptyString(scope)) {
        return NO;
    }
    
    BOOL result = [self updateScopes:@{scope: @(approved)} notify:notify];
    return result;
}

- (BOOL)updateScopes:(NSDictionary<NSString *, NSNumber *> *)scopes notify:(BOOL)notify {
    __block BOOL result = NO;
    if (BDPIsEmptyDictionary(scopes)) {
        BDPLogInfo(@"empty scope");
        return result;
    }
    NSMutableDictionary<NSString *, NSNumber *> *savedScopes = [NSMutableDictionary<NSString *, NSNumber *> dictionary];
    scopes = [scopes copy];
    [scopes enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSNumber * _Nonnull obj, BOOL * _Nonnull stop) {
        if (BDPIsEmptyString(key)) {
            BDPLogInfo(@"empty scope key");
            return;
        }
        if (!obj || ![obj isKindOfClass:[NSNumber class]]) {
            BDPLogInfo(@"empty scope value");
            return;
        }
        BOOL approved = [obj boolValue];
        NSString *scope = key;
        if (!self.scope[scope]) {
            BDPLogInfo(@"setScope %@ no this scope", BDPParamStr(scope, approved, self.scope));
            return;
        }
        BOOL thisResult = [self.storage setObject:@(approved) forKey:scope];
        if (thisResult) {
            result = YES;
            savedScopes[key] = obj;
        }
        // 因为跨域问题下线（本来对逻辑也不会有影响）https://bytedance.feishu.cn/sheets/shtcnKW7ycWRcKWM800kJR8Ydne?sheet=Fm3SGT
        BDPLogInfo(@"setScope %@", BDPParamStr(scope, approved, thisResult));
    }];
    if (result && notify) {
        BDPPlugin(authorizationPlugin, BDPAuthorizationPluginDelegate);
        if ([authorizationPlugin respondsToSelector:@selector(bdp_notifyUpdatingScopes:withAuthProvider:)]) {
            [authorizationPlugin bdp_notifyUpdatingScopes:savedScopes withAuthProvider:self];
        }
    }
    return result;
}

- (NSNumber *)statusForScope:(NSString *)scope  {
    if([scope isEqualToString:@"userinfo"] && ![EMAFeatureGating boolValueForKey: EEFeatureGatingKeyGetUserInfoAuth]){
        return nil;
    }
    NSNumber *result = [self.storage objectForKey:scope];
    if (![result isKindOfClass:[NSNumber class]]) {
        return nil;
    }
    if (![self.class authorizationFree] && ![self modForScope:scope]) {
        return nil;
    }
    return result;
}

- (BOOL)modForScope:(NSString *)scope {
    NSString *scopeModKey = [NSString stringWithFormat:@"%@Mod", scope];
    NSNumber *mod = [self.storage objectForKey:scopeModKey];
    if ([self.class authorizationFree] && [mod isKindOfClass:[NSNumber class]] && mod.intValue == 0) {
        return NO;
    }
    return YES;
}

- (NSArray<NSDictionary *> *)usedScopes
{
    NSMutableArray *scopes = [[NSMutableArray alloc] initWithCapacity:self.scope.count];
    [self.scope enumerateKeysAndObjectsUsingBlock:^(id _Nonnull key, id _Nonnull obj, BOOL *_Nonnull stop) {
        NSNumber *value = [self statusForScope:key];
        BOOL mod = [self modForScope:key];
        if (value != nil) {
            [scopes addObject:@{@"key" : key, @"name" : obj[@"name"] ?: @"", @"value" : value, @"mod" : @(mod)}];
        }
    }];
    return [scopes copy];
}

- (NSDictionary *)usedScopesDict
{
    NSMutableDictionary *scopes = [[NSMutableDictionary alloc] initWithCapacity:self.scope.count];
    [self.scope enumerateKeysAndObjectsUsingBlock:^(id _Nonnull key, id _Nonnull obj, BOOL *_Nonnull stop) {
        NSNumber *value = [self statusForScope:key];
        if (value) {
            [BDPAuthorization transformScopeToDict:key value:value dictionary:scopes];
        }
    }];
    
    return [scopes copy];
}

- (NSDictionary *)usedScopesStorageKVDict
{
    NSMutableDictionary *scopes = [[NSMutableDictionary alloc] initWithCapacity:self.scope.count];
    [self.scope enumerateKeysAndObjectsUsingBlock:^(id _Nonnull key, id _Nonnull obj, BOOL *_Nonnull stop) {
        NSNumber *value = [self statusForScope:key];
        scopes[key] = value;
    }];
    return [scopes copy];
}

#pragma mark - BDPJSBridgeAuthorizationProtocol
/*-----------------------------------------------*/
//  BDPJSBridgeAuthorizationProtocol - 权限校验协议
/*-----------------------------------------------*/
- (void)checkAuthorization:(BDPJSBridgeMethod *)method
                    engine:(BDPJSBridgeEngine)engine
                completion:(void (^)(BDPAuthorizationPermissionResult result))completion
{
    // 白名单API - 仅在下发的白名单列表中存在时才能调用，这些API预设在资源文件plist内的"WhiteList"字段
    if ([_whiteList containsObject:method.name]) {
        if (![_source.whiteAuthList containsObject:method.name]) {
            BDPLogInfo(@"whiteList");
            AUTH_COMPLETE(BDPAuthorizationPermissionResultPlatformDisabled);
            return;
        }
    }
    
    // 黑名单API - 在下发的黑名单列表中存在则不能调用
    if ([_source.blackAuthList containsObject:method.name]) {
        BDPLogInfo(@"blackList");
        AUTH_COMPLETE(BDPAuthorizationPermissionResultPlatformDisabled);
        return;
    }
    
    // 请求权限
    BDPJSBridgeAuthorization auth = engine.authorization;
    // 构造delegate
    BDPAuthorizationDelegateImpl *impl = [BDPAuthorizationDelegateImpl new];
    impl.engine = engine;
    [self requestUserPermissionIfNeed:method uniqueID:engine.uniqueID authProvider:auth delegate:impl completion:completion];
}

#pragma mark - Record Permission



- (void)removeFailedRecordScopeType:(BDPPermissionScopeType)scopeType
{
    NSMutableArray *mutScopes = [self recordFailedScopes];
    if ([mutScopes containsObject:@(scopeType)]) {
        [mutScopes removeObject:@(scopeType)];
    }
    if (mutScopes.count > 0) {
        [self.storage setObject:[mutScopes JSONRepresentation] forKey:kBDPAuthFailedScopeStorageKey];
    } else {
        [self.storage removeObjectForKey:kBDPAuthFailedScopeStorageKey];
    }
    self.recordFailedScopes = nil;
}

- (void)recordFailedScopeType:(BDPPermissionScopeType)scopeType
{
    NSMutableArray *mutScopes = [self recordFailedScopes];
    if (![mutScopes containsObject:@(scopeType)]) {
        [mutScopes addObject:@(scopeType)];
        [self.storage setObject:[mutScopes JSONRepresentation] forKey:kBDPAuthFailedScopeStorageKey];
        self.recordFailedScopes = nil;
    }
}

- (NSMutableArray *)recordFailedScopes
{
    if (!_recordFailedScopes) {
        NSString *scopesStr = [self.storage objectForKey:kBDPAuthFailedScopeStorageKey];
        NSArray *scopes = [scopesStr isKindOfClass:[NSString class]] ? [scopesStr JSONValue] : nil;
        _recordFailedScopes = [[NSMutableArray alloc] init];
        if ([scopes isKindOfClass:[NSArray class]]) {
            _recordFailedScopes = [[NSMutableArray alloc] initWithArray:scopes];
        }
    }
    return _recordFailedScopes;
}

- (void)onPersmissionDisabledForScope:(NSString *)scope
                            firstTime:(BOOL)firstTime
                         authProvider:(BDPAuthorization *)authProvider
                             delegate:(id<BDPAuthorizationDelegate>)delegate
{
    BDPLogInfo(@"onPersmissionDisabledForScope, scope=%@, firstTime=%@, id=%@", scope, @(firstTime), authProvider.source.uniqueID);
    // Get Implement
    BDPPlugin(authorizationPlugin, BDPAuthorizationPluginDelegate);

    // Check Implement Exist
    if ([authorizationPlugin respondsToSelector:@selector(bdp_onPersmissionDisabledWithParam:firstTime:authProvider:inController:)]) {
        NSMutableDictionary *params = [NSMutableDictionary dictionary];
        params[@"scope"] = scope;
        params[@"scopeName"] = self.scope[scope][@"name"];
        params[@"description"] = self.scope[scope][@"description"];
        params[@"appID"] = self.source.uniqueID.appID;
        params[@"appName"] = self.source.name;
        params[@"appIcon"] = self.source.icon;

        BDPExecuteOnMainQueue(^{
            [authorizationPlugin bdp_onPersmissionDisabledWithParam:params firstTime:firstTime authProvider:authProvider inController:[delegate controller]];
        });
        
    }
}

- (void)hasUserinfoWithengine:(BDPJSBridgeEngine)engine completion:(void (^)(BOOL on))completion
{
    WeakSelf;
    BDPAppContext *context = [[BDPAppContext alloc] init];
    context.controller = engine.bridgeController;
    context.engine = engine;
    [BDPUserInfoManager fetchUserInfoWithCredentials:NO context:context completion:^(NSDictionary * _Nonnull userInfo, NSError * _Nonnull error) {
        StrongSelfIfNilReturn;
        self.userInfo = userInfo;
        
        if (error) {
            AUTH_COMPLETE(NO)
            return;
        }
        AUTH_COMPLETE(YES)
    }];
}

- (void)fetchAuthorizeData:(BOOL)storage completion:(void (^ _Nonnull)(NSDictionary * _Nullable result, NSDictionary * _Nullable bizData, NSError * _Nullable error))completion {
    BDPPlugin(authorizationPlugin, BDPAuthorizationPluginDelegate);
    [authorizationPlugin bdp_fetchAuthorizeData:self storage:storage completion:completion];
}

@end
