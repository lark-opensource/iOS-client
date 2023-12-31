//
//  EMAUserAuthorizationSynchronizer.m
//  EEMicroAppSDK
//
//  Created by houjihu on 2019/7/23.
//

#import "EMAUserAuthorizationSynchronizer.h"
#import <OPFoundation/BDPUtils.h>
#import <ECOInfra/NSDictionary+BDPExtension.h>
#import <ECOInfra/NSURLSession+TMA.h>
#import <ECOInfra/EMANetworkManager.h>
#import <OPFoundation/EMANetworkAPI.h>
#import <OPFoundation/EMAMonitorHelper.h>
#import <OPFoundation/EMASandBoxHelper.h>
#import <OPFoundation/EMADebugUtil.h>
#import <OPFoundation/BDPAuthorization.h>
#import <OPFoundation/BDPAuthorization+BDPUtils.h>
#import <TTMicroApp/BDPTask.h>
#import <OPFoundation/BDPModel.h>
#import <OPFoundation/BDPCommonManager.h>
#import <ECOInfra/BDPLog.h>
#import <ECOInfra/JSONValue+BDPExtension.h>
#import "EMAAppEngine.h"
#import <OPFoundation/BDPTracingManager.h>
#import <OPFoundation/EMARequestUtil.h>
#import <OPFoundation/BDPJSBridgeProtocol.h>
#import <TTMicroApp/TTMicroApp-Swift.h>
#import <OPFoundation/GadgetSessionStorage.h>
#import <ECOProbe/OPTrace.h>
#import <ECOProbe/OPTraceService.h>
#import <OPFoundation/EEFeatureGating.h>
#import <OPFoundation/BDPMonitorEvent.h>
#import <OPFoundation/OPFoundation-Swift.h>
#import <ECOInfra/ECOInfra-Swift.h>

static NSString *kOnlineScopeKeyPrefix = @"scope.";
static NSString *kOnlineScopeAuthKey = @"auth";
static NSString *kOnlineScopeModifyTimeKey = @"modifyTime";
static NSString *kOnlineScopeMod = @"mod";
@implementation EMAUserAuthorizationSynchronizer

#pragma mark - 从服务器同步

#pragma mark Public

/// merge和同步本地设备授权信息与线上数据
+ (void)syncLocalAuthorizationsWithAppModel:(BDPModel *)appModel {
    if ([EMADebugUtil.sharedInstance debugConfigForID:kEMADebugConfigDoNotUseAuthDataFromRemote].boolValue) {
        // 不使用远端同步数据
        return;
    }
    NSString *scopeKey = @"userAuthScope";
    if ([BDPAuthorization authorizationFree]) {
        scopeKey = @"userAuthScopeList";
    }
    // 将getAppMeta授权信息中的时间戳与本设备最后修改权限的时间戳相比较
    NSDictionary *onlineUserAuthScopes = [appModel.extraDict bdp_dictionaryValueForKey:scopeKey];
    NSDictionary<NSString *, NSString *> *mapForStorageKeyToScopeKey = [BDPAuthorization mapForStorageKeyToScopeKey];
    BDPLogInfo(@"onlineUserAuthScopes: %@", BDPParamStr(onlineUserAuthScopes));
    if (BDPIsEmptyDictionary(onlineUserAuthScopes)) {
        // 1.线上scope为空，则说明从未同步过授权状态，需要将本设备历史数据全部同步
        [self firstSyncLocalAuthorizationsWithUniqueID:appModel.uniqueID mapForStorageKeyToScopeKey:mapForStorageKeyToScopeKey];
    } else {
        // 2.否则取线上数据与本地数据的较新者，持久化到本地并同步到线上
        [self compareAndSyncAuthorizations:onlineUserAuthScopes uniqueID:appModel.uniqueID mapForStorageKeyToScopeKey:mapForStorageKeyToScopeKey];
    }
}

#pragma mark Private

/// 首次将本设备历史数据全部同步
+ (void)firstSyncLocalAuthorizationsWithUniqueID:(BDPUniqueID *)uniqueID mapForStorageKeyToScopeKey:(NSDictionary<NSString *, NSString *> *)mapForStorageKeyToScopeKey {
    // 1.本地数据添加当时的时间戳
    // 2.同步到线上
    BDPAuthorization *auth = [self authForUniqueID:uniqueID];
    [self syncLocalAuthorizationsWithAuthProvider:auth mapForStorageKeyToScopeKey:mapForStorageKeyToScopeKey];
}

/// 将getAppMeta授权信息中的时间戳与本设备最后修改权限的时间戳相比较，merge后并将本设备较新的历史数据同步
+ (void)compareAndSyncAuthorizations:(NSDictionary *)onlineUserAuthScopes uniqueID:(BDPUniqueID *)uniqueID mapForStorageKeyToScopeKey:(NSDictionary<NSString *, NSString *> *)mapForStorageKeyToScopeKey {
    // 判断本地数据是否有某些权限比较新
    BOOL areLocalAuthorizationsNewer = NO;
    BDPAuthorization *auth = [self authForUniqueID:uniqueID];
    NSDictionary *usedScopesDict = [auth.usedScopesDict copy];
    NSInteger usedScopesCount = usedScopesDict.count;

    // 1. 遍历线上数据的keys
    for (NSString *onlineScopeKey in onlineUserAuthScopes.allKeys) {
        if (BDPIsEmptyString(onlineScopeKey)) {
            continue;
        }
        NSDictionary *onlineScopeDict = onlineUserAuthScopes[onlineScopeKey];
        BOOL onlineApproved = [onlineScopeDict bdp_boolValueForKey:kOnlineScopeAuthKey];
        NSInteger onlineMod = [onlineScopeDict integerValueForKey:kOnlineScopeMod defaultValue:1];
        // 时间戳单位为毫秒，需要先转换为秒
        NSTimeInterval onlineModifyTimestamp = [onlineScopeDict bdp_doubleValueForKey:kOnlineScopeModifyTimeKey] / 1000;

        NSString *scopeKey = [kOnlineScopeKeyPrefix stringByAppendingString:onlineScopeKey];
        // 这边灰度阶段使用olineScopeKey转换成scopeKey.待全量后删除原先onlineScopeKey拼接scope.的方式;
        scopeKey = [self convertOnlineScopeKeyToScopeKey:onlineScopeKey defaultKey:scopeKey];

        NSComparisonResult result = [self compareLocalAuthorizationWithUniqueID:uniqueID scopeKey:scopeKey onlineApproved:onlineApproved onlineModifyTimestamp:onlineModifyTimestamp onlineMod:onlineMod auth:auth mapForStorageKeyToScopeKey:mapForStorageKeyToScopeKey];
        BDPLogInfo(@"compareResult: %@", BDPParamStr(result));
        if (result == NSOrderedDescending) {
            // 如果本地数据比较新，则标识需同步到线上
            areLocalAuthorizationsNewer = YES;
        } else if (result == NSOrderedAscending) {
            // 如果线上数据比较新，则将数据写入本地
            [self saveToLocalAuthorizationWithUniqueID:uniqueID scopeKey:scopeKey approved:onlineApproved modifyTimestamp:onlineModifyTimestamp mod:onlineMod mapForStorageKeyToScopeKey:mapForStorageKeyToScopeKey];
        }
        if([usedScopesDict.allKeys containsObject:scopeKey]) {
            usedScopesCount--;
        }
    }
    // 2. 如果本地数据还有没遍历到的key，则需要同步到线上
    if(!areLocalAuthorizationsNewer) {
        if (usedScopesCount > 0) {
            areLocalAuthorizationsNewer = YES;
        }
    }
    // 如果本地数据是否有某些权限比较新，则将本地数据全部同步到线上
    if (areLocalAuthorizationsNewer) {
        BDPAuthorization *auth = [self authForUniqueID:uniqueID];
        [self syncLocalAuthorizationsWithAuthProvider:auth mapForStorageKeyToScopeKey:mapForStorageKeyToScopeKey];
    }
}

/// 将网络授权信息中的时间戳与本设备最后修改权限的时间戳相比较，如果有新的数据则写入本地
+ (BOOL)compareAndSaveToLocalAuthorizations:(NSDictionary *)onlineUserAuthScopes uniqueID:(BDPUniqueID *)uniqueID mapForStorageKeyToScopeKey:(NSDictionary<NSString *, NSString *> *)mapForStorageKeyToScopeKey onlineScopeModifyTimeKey: (NSString *)onlineScopeModifyTimeKey auth:(BDPAuthorization *)auth {
    // 线上有新的权限数据
    BOOL hasNewData = NO;

    // 1. 遍历线上数据的keys
    for (NSString *onlineScopeKey in onlineUserAuthScopes.allKeys) {
        if (BDPIsEmptyString(onlineScopeKey)) {
            continue;
        }
        NSDictionary *onlineScopeDict = onlineUserAuthScopes[onlineScopeKey];
        BOOL onlineApproved = [onlineScopeDict bdp_boolValueForKey:kOnlineScopeAuthKey];
        NSInteger onlineMod = [onlineScopeDict integerValueForKey:kOnlineScopeMod defaultValue:1];
        // 时间戳单位为毫秒，需要先转换为秒
        NSTimeInterval onlineModifyTimestamp = [onlineScopeDict bdp_doubleValueForKey:(!BDPIsEmptyString(onlineScopeModifyTimeKey) ? onlineScopeModifyTimeKey : kOnlineScopeModifyTimeKey)] / 1000;

        NSString *scopeKey = [kOnlineScopeKeyPrefix stringByAppendingString:onlineScopeKey];
        // 这边灰度阶段使用olineScopeKey转换成scopeKey.待全量后删除原先onlineScopeKey拼接scope.的方式;
        scopeKey = [self convertOnlineScopeKeyToScopeKey:onlineScopeKey defaultKey:scopeKey];

        NSComparisonResult result = [self compareLocalAuthorizationWithUniqueID:uniqueID scopeKey:scopeKey onlineApproved:onlineApproved onlineModifyTimestamp:onlineModifyTimestamp onlineMod:onlineMod auth:auth mapForStorageKeyToScopeKey:mapForStorageKeyToScopeKey];
        BDPLogInfo(@"compareResult: %@", BDPParamStr(result));

        if (result == NSOrderedAscending) {
            // 如果线上数据比较新，则将数据写入本地
            [self saveToLocalAuthorizationWithUniqueID:uniqueID scopeKey:scopeKey approved:onlineApproved modifyTimestamp:onlineModifyTimestamp mod:onlineMod mapForStorageKeyToScopeKey:mapForStorageKeyToScopeKey auth:auth];
            hasNewData = YES;
        }
    }
    return hasNewData;
}

/// 将getAppMeta授权信息中具体某权限的时间戳与本设备最后修改权限的时间戳相比较
+ (NSComparisonResult)compareLocalAuthorizationWithUniqueID:(BDPUniqueID *)uniqueID scopeKey:(NSString *)scopeKey onlineApproved:(BOOL)onlineApproved onlineModifyTimestamp:(NSTimeInterval)onlineModifyTimestamp onlineMod:(NSInteger)onlineMod auth:(BDPAuthorization *)auth mapForStorageKeyToScopeKey:(NSDictionary<NSString *, NSString *> *)mapForStorageKeyToScopeKey {
    BDPLogInfo(@"compareLocalAuthorization, uniqueID=%@, scopeKey=%@, onlineApproved=%@, onlineModifyTimestamp=%@", uniqueID, scopeKey, @(onlineApproved), @(onlineModifyTimestamp));
    TMAKVStorage *storage = auth.storage;
    NSDate *onlineModifyDate = [NSDate dateWithTimeIntervalSince1970:onlineModifyTimestamp];
    NSString *storageKey = [self transformScopeKeyToStorageKey:scopeKey mapForStorageKeyToScopeKey:mapForStorageKeyToScopeKey];
    if (BDPIsEmptyString(storageKey)) {
        return NSOrderedAscending;
    }
    // 线上mod为0 或 本地mod=0 使用线上数据
    if(onlineMod == 0) {
        return NSOrderedAscending;
    }
    
    NSString *modStorageKey = [self modStorageKey:storageKey];
    NSNumber *localMod = [storage objectForKey:modStorageKey];
    if (localMod && [localMod isKindOfClass:[NSNumber class]] && localMod.intValue == 0) {
        return NSOrderedAscending;
    }
    // 1.如果本地没有授权数据，则直接使用线上数据
    NSNumber *localScopeValue = [auth statusForScope:storageKey];
    if (!localScopeValue || ![localScopeValue isKindOfClass:[NSNumber class]]) {
        return NSOrderedAscending;
    }
    BOOL localApproved = [localScopeValue boolValue];
    NSString *modifyTimeStorageKey = [self modifyTimeStorageKey:storageKey];
    NSNumber *timestamp = [storage objectForKey:modifyTimeStorageKey];
    // 2.如果本地有授权数据，但没有时间戳
    if (!timestamp || ![timestamp isKindOfClass:[NSNumber class]]) {
        // 2.1 如果本地已授权，而线上禁止权限，则同步本地数据
        // 2.2 如果本地与线上授权状态相同，则使用线上数据
        // 2.3 如果本地禁止权限，而线上已授权，则使用线上数据
        if (onlineApproved || (onlineApproved == localApproved) ) {
            return NSOrderedAscending;
        } else {
            return NSOrderedDescending;
        }
    }
    // 3.如果本地有授权数据和时间戳，则比较两者的时间先后顺序
    // 时间戳单位为毫秒，需要先转换为秒
    NSDate *localModifyDate = [NSDate dateWithTimeIntervalSince1970:([timestamp doubleValue] / 1000)];
    return [localModifyDate compare:onlineModifyDate];
}

+ (BDPAuthorization *)authForUniqueID:(BDPUniqueID *)uniqueID {
    BDPCommon *common = BDPCommonFromUniqueID(uniqueID);
    BDPAuthorization *auth = common.auth;
    return auth;
}

/// 获取本地授权信息。
/// 如果存在本地数据没有时间戳的情况，则取当前时间，并保存到本地
+ (NSDictionary *)localAuthorizationsWithAuthProvider:(BDPAuthorization *)authProvider mapForStorageKeyToScopeKey:(NSDictionary<NSString *, NSString *> *)mapForStorageKeyToScopeKey {
    BDPAuthStorageProvider storage = authProvider.storage;
    NSDictionary *usedScopesStorageKVDict = [authProvider.usedScopesStorageKVDict copy];
    NSMutableDictionary *localAuthorizations = [NSMutableDictionary dictionary];
    [usedScopesStorageKVDict enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull storageKey, NSNumber * _Nonnull authValue, BOOL * _Nonnull stop) {
        NSString *scopeKey = mapForStorageKeyToScopeKey[storageKey];
        if (BDPIsEmptyString(storageKey) || BDPIsEmptyString(scopeKey)) {
            return;
        }
        if (!authValue || ![authValue isKindOfClass:[NSNumber class]]) {
            return;
        }
        NSMutableDictionary *scopeValue = [NSMutableDictionary dictionary];
        scopeValue[kOnlineScopeAuthKey] = authValue;
        NSString *modifyTimeStorageKey = [self modifyTimeStorageKey:storageKey];
        NSNumber *timestamp = [storage objectForKey:modifyTimeStorageKey];
        if (!timestamp || ![timestamp isKindOfClass:[NSNumber class]]) {
            /// 如果本地数据没有时间戳，则取当前时间，并保存到本地
            NSTimeInterval timeInterval = NSDate.date.timeIntervalSince1970;
            // 时间戳单位取毫秒
            timestamp = @((NSInteger)(timeInterval * 1000));
            BOOL localApproved = [authValue boolValue];
            [self updateScopeModifyTimeWithStorageDict:@{storageKey: @(localApproved)} modifyTimestamp:timeInterval storage:storage];
        }
        // 本地mod=0时，不同步数据到线上
        NSString *modStorageKey = [self modStorageKey:storageKey];
        NSNumber *mod = [storage objectForKey:modStorageKey];
        if (mod && [mod isKindOfClass:[NSNumber class]] && [mod intValue] == 0) {
            BDPLogInfo(@"%@'s mode == 0 not sync to server", scopeKey);
            return;
        }
        scopeValue[kOnlineScopeModifyTimeKey] = timestamp;
        NSString *onlineScopeKey = scopeKey;
        NSString *prefix = kOnlineScopeKeyPrefix;
        if ([scopeKey hasPrefix:prefix]) {
            onlineScopeKey = [scopeKey substringFromIndex:prefix.length];
        }

        // 这边灰度阶段使用olineScopeKey/scopeKey映射表.待全量后删除原先scopeKey删除scope.前缀的方式;
        if ([EEFeatureGating boolValueForKey:EEFeatureGatingKeyNewScopeMapRule]) {
            onlineScopeKey = [BDPAuthorization transformScopeKeyToOnlineScope:scopeKey];//非空保护
            BDPLogInfo(@"get onlineScopeKey: %@ from mapForScopeToOnlineScopeKey", onlineScopeKey);
        }

        localAuthorizations[onlineScopeKey] = scopeValue;
    }];
    return localAuthorizations;
}

/// [key]ModifyTime
+ (NSString *)modifyTimeStorageKey:(NSString *)storageKey {
    return [NSString stringWithFormat:@"%@ModifyTime", storageKey];
}

/// [key]Mod
+ (NSString *)modStorageKey:(NSString *)storageKey {
    return [NSString stringWithFormat:@"%@Mod", storageKey];
}

/// 将onlineScopeKey转换成scopeKey.(新的转换方式)
+ (NSString *)convertOnlineScopeKeyToScopeKey:(NSString *)onlineScopeKey defaultKey:(NSString *)defaultKey {
    NSString *result = defaultKey;
    // 这边灰度阶段使用olineScopeKey转换成scopeKey.待全量后删除原先onlineScopeKey拼接scope.的方式;
    if ([EEFeatureGating boolValueForKey:EEFeatureGatingKeyNewScopeMapRule]) {
        result = [BDPAuthorization transformOnlineScopeToScope:onlineScopeKey];
        BDPLogInfo(@"transform onlineKey: %@ to scopeKey: %@", onlineScopeKey, result);
    }
    return result;
}

#pragma mark - 同步到服务器

#pragma mark Public

/// 更新授权状态变更时间戳，并将本地数据同步到线上，completionHandler表示网络请求结果
+ (void)updateScopeModifyTimeAndSyncToOnlineWithStorageDict:(NSDictionary<NSString *, NSNumber *> *)storageDict withAuthProvider:(BDPAuthorization *)authProvider completionHandler:(void (^)(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error))completionHandler {
    BDPAuthStorageProvider storage = authProvider.storage;
    // 授权状态更改时，将修改时间戳同步保存到本地
    NSTimeInterval modifyTimestamp = NSDate.date.timeIntervalSince1970;
    [self updateScopeModifyTimeWithStorageDict:storageDict modifyTimestamp:modifyTimestamp storage:storage];
    // 将本地数据同步到线上
    NSDictionary<NSString *, NSString *> *mapForStorageKeyToScopeKey = [BDPAuthorization mapForStorageKeyToScopeKey];
    [self syncLocalAuthorizationsWithAuthProvider:authProvider mapForStorageKeyToScopeKey:mapForStorageKeyToScopeKey completionHandler:completionHandler];
}

/// 更新授权状态变更时间戳
+ (void)updateScopeModifyTimeWithStorageDict:(NSDictionary<NSString *, NSNumber *> *)storageDict modifyTimestamp:(NSTimeInterval)modifyTimestamp storage:(BDPAuthStorageProvider)storage {
    // 时间戳单位取毫秒
    NSNumber *timestamp = @((NSInteger)(modifyTimestamp * 1000));
    [storageDict enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSNumber * _Nonnull obj, BOOL * _Nonnull stop) {
        if (BDPIsEmptyString(key)) {
            return;
        }
        NSString *storageKey = key;
        NSString *modifyTimeStorageKey = [self modifyTimeStorageKey:storageKey];
        [storage setObject:timestamp forKey:modifyTimeStorageKey];
    }];
}

/// 更新授权的mod
+ (void)updateScopeMod:(NSString *)storageKey mod:(NSInteger)onlineMod storage:(BDPAuthStorageProvider)storage {
    NSString *modStorageKey = [self modStorageKey:storageKey];
    [storage setObject:@(onlineMod) forKey:modStorageKey];
}

#pragma mark Private

/// 将本设备授权信息同步到服务端。如果存在本地数据没有时间戳的情况，则取当前时间
+ (void)syncLocalAuthorizationsWithAuthProvider:(BDPAuthorization *)authProvider mapForStorageKeyToScopeKey:(NSDictionary<NSString *, NSString *> *)mapForStorageKeyToScopeKey
{
    [self syncLocalAuthorizationsWithAuthProvider:authProvider mapForStorageKeyToScopeKey:mapForStorageKeyToScopeKey completionHandler:nil];
}

/// 将本设备授权信息同步到服务端。如果存在本地数据没有时间戳的情况，则取当前时间，completionHandler表示网络请求结果
+ (void)syncLocalAuthorizationsWithAuthProvider:(BDPAuthorization *)authProvider mapForStorageKeyToScopeKey:(NSDictionary<NSString *, NSString *> *)mapForStorageKeyToScopeKey completionHandler:(void (^)(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error))completionHandler {
    NSDictionary *localAuthorizations = [self localAuthorizationsWithAuthProvider:authProvider mapForStorageKeyToScopeKey:mapForStorageKeyToScopeKey];
    if (BDPIsEmptyDictionary(localAuthorizations)) {
        BDPLogInfo(@"localAuthorizations is empty");
        return;
    }
    NSString *url = authProvider.source.uniqueID.appType == BDPTypeWebApp ? [EMAAPI syncClientAuthBySessionURL] : [EMAAPI syncClientAuthURL];
    NSDictionary *params;
    NSDictionary *header;
    if (authProvider.source.uniqueID.appType == BDPTypeWebApp) {
        params = @{
            @"appID": authProvider.source.uniqueID.appID ?: @"",
            @"h5Session": authProvider.authSyncSession() ?: @"",
            @"userAuthScope": localAuthorizations ?: @{}
        };
        header = [GadgetSessionFactory storageForAuthModule:authProvider].sessionHeader;
    } else {
        NSMutableDictionary *dict = [@{
            @"appID": authProvider.source.uniqueID.appID ?: @"",
            @"appVersion": [EMASandBoxHelper versionName] ?: @"",
            @"userAuthScope": localAuthorizations ?: @{}
        } mutableCopy];
        if (![EEFeatureGating boolValueForKey:@"openplatform.network.remove_larksession_from_req_body"]) {
            dict[@"sessionID"] = EMAAppEngine.currentEngine.account.userSession ?: @"";
        }
        params = [dict copy];
    }
    OPMonitorEvent *monitor = BDPMonitorWithName(kEventName_mp_sync_client_auth, nil).timing();
    //TODO: 网络专用 Trace, 派生了一级,勿直接使用.目前网络层级混乱,直接调了底层网络类,所以只能在这里派生(否者会和 EMARequestUtil 的封装冲突),网络重构后会统一修改 --majiaxin
    OPTrace *tracing =[EMARequestUtil generateRequestTracing:authProvider.source.uniqueID];

    void (^handleResult)(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error)
    = ^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error) {
            monitor.kv(kEventKey_result_type, kEventValue_fail).setError(error).flush();
        } else {
            NSDictionary *jsonObj = [data JSONValue];
            monitor.kv(kEventKey_result_type, kEventValue_success).timing().kv(@"error_code", jsonObj[@"error"]).kv(@"error_msg", jsonObj[@"message"]).flush();
        }
        if (completionHandler) {
            completionHandler(data, response, error);
        }
    };

    BOOL isWebApp = authProvider.source.uniqueID.appType == BDPTypeWebApp;
    NSString *path = isWebApp ? OPNetworkAPIPath.syncClientAuthBySession : OPNetworkAPIPath.syncClientAuth;
    if ([OPECONetworkInterface enableECOWithPath:path]) {
        OpenECONetworkAppContext *context = [[OpenECONetworkAppContext alloc] initWithTrace:tracing
                                                                                   uniqueId:authProvider.source.uniqueID
                                                                                     source:ECONetworkRequestSourceApi];
        [OPECONetworkInterface postForOpenDomainWithUrl:url
                                                context:context
                                                 params:params
                                                 header:header
                                      completionHandler:^(NSDictionary<NSString *,id> *json, NSData *data, NSURLResponse *response, NSError *error) {
            handleResult(data, response, error);
        }];
    } else {
        [[EMANetworkManager shared] postUrl:url params:params header:header completionHandler:handleResult eventName:@"syncClientAuth" requestTracing:tracing];
    }
}

/// 将线上授权信息写入本设备
+ (void)saveToLocalAuthorizationWithUniqueID:(BDPUniqueID *)uniqueID scopeKey:(NSString *)scopeKey approved:(BOOL)approved modifyTimestamp:(NSTimeInterval)modifyTimestamp mod:(NSInteger)onlineMod mapForStorageKeyToScopeKey:(NSDictionary<NSString *, NSString *> *)mapForStorageKeyToScopeKey {
    BDPAuthorization *auth = [self authForUniqueID:uniqueID];
    [self saveToLocalAuthorizationWithUniqueID:uniqueID scopeKey:scopeKey approved:approved modifyTimestamp:modifyTimestamp mod:onlineMod mapForStorageKeyToScopeKey:mapForStorageKeyToScopeKey auth:auth];
}

/// 将线上授权信息写入本设备，支持传入auth
+ (void)saveToLocalAuthorizationWithUniqueID:(BDPUniqueID *)uniqueID scopeKey:(NSString *)scopeKey approved:(BOOL)approved modifyTimestamp:(NSTimeInterval)modifyTimestamp mod:(NSInteger)onlineMod mapForStorageKeyToScopeKey:(NSDictionary<NSString *, NSString *> *)mapForStorageKeyToScopeKey auth:(BDPAuthorization *)auth {
    BDPLogInfo(@"saveToLocalAuthorization, uniqueID=%@, scopeKey=%@, approved=%@, modifyTimestamp=%@", uniqueID, scopeKey, @(approved), @(modifyTimestamp));
    NSString *storageKey = [self transformScopeKeyToStorageKey:scopeKey mapForStorageKeyToScopeKey:mapForStorageKeyToScopeKey];
    if (BDPIsEmptyString(storageKey)) {
        return;
    }
    [auth updateScope:storageKey approved:approved notify:NO];
    [self updateScopeMod:storageKey mod:onlineMod storage:auth.storage];
    [self updateScopeModifyTimeWithStorageDict:@{storageKey: @(approved)} modifyTimestamp:modifyTimestamp storage:auth.storage];
}

/// scope.[key1] --> key2
+ (NSString *)transformScopeKeyToStorageKey:(NSString *)scopeKey mapForStorageKeyToScopeKey:(NSDictionary<NSString *, NSString *> *)mapForStorageKeyToScopeKey {
    __block NSString *storageKey;
    [mapForStorageKeyToScopeKey enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull obj, BOOL * _Nonnull stop) {
        if (!BDPIsEmptyString(obj) && [(NSString *)obj isEqualToString:scopeKey]) {
            storageKey = key;
            *stop = YES;
        }
    }];
    if (BDPIsEmptyString(storageKey)) {
        return nil;
    }
    return storageKey;
}

+ (NSString *)transformOnlineScopeToScope:(NSString *)onlineScope {
    return [BDPAuthorization transformOnlineScopeToScope:onlineScope];
}

@end
