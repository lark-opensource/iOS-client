//
//  BDPAuthModule.m
//  Timor
//
//  Created by yin on 2020/4/2.
//

#import "BDPAuthModule.h"
#import <OPFoundation/BDPCommonManager.h>
#import <OPFoundation/BDPAuthorization+BDPUserPermission.h>
#import <OPFoundation/TMASessionManager.h>
#import <OPFoundation/BDPTracker.h>
#import <OPFoundation/BDPUserPluginDelegate.h>
#import <OPFoundation/BDPTimorClient.h>
#import <ECOInfra/NSDictionary+BDPExtension.h>
#import <OPFoundation/BDPSDKConfig.h>
#import "BDPSandboxEntity.h"
#import <OPFoundation/BDPStorageModuleProtocol.h>

@implementation BDPAuthModule

- (BOOL)checkSchema:(NSURL *)url uniqueID:(BDPUniqueID *)uniqueID errorMsg:(NSString *)failErrMsg {
    BDPType appType = uniqueID.appType;
    BOOL canOpenSchema = NO;
    if (appType == BDPTypeWebApp || appType == BDPTypeNativeCard || appType == BDPTypeBlock) {
        canOpenSchema = YES;
    } else {
        BDPCommon *common = BDPCommonFromUniqueID(uniqueID);
        canOpenSchema = [common.auth checkSchema:&url uniqueID:uniqueID errorMsg:&failErrMsg];
    }
    return canOpenSchema;
}

- (void)requestUserPermissionForScopeIfNeeded:(NSString *)scope context:(BDPPluginContext)context completion:(void (^)(BDPAuthorizationPermissionResult))completion {
    BDPType appType = context.engine.uniqueID.appType;
    if (appType == BDPTypeNativeCard) {
        completion(BDPAuthorizationPermissionResultEnabled);
    } else {
        BDPAuthorization *auth = ((BDPJSBridgeEngine)context.engine).authorization;
        BDPAuthModuleControllerProvider *provider = [[BDPAuthModuleControllerProvider alloc] init];
        provider.controller = context.controller;
        [auth requestUserPermissionForScopeIfNeeded:scope uniqueID:context.engine.uniqueID authProvider:auth delegate:provider completion:completion];
    }
}

- (NSString *)getSessionContext:(BDPPluginContext)context {
    BDPType appType = context.engine.uniqueID.appType;
    if (appType == BDPTypeWebApp) {
        return [context.engine getSession];
    } else if (appType == BDPTypeBlock || appType == BDPTypeThirdNativeApp) {
        BDPResolveModule(storageModule, BDPStorageModuleProtocol, appType);
        id<BDPSandboxProtocol> sandbox = [storageModule sandboxForUniqueId:context.engine.uniqueID];
        return [[TMASessionManager sharedManager] getSession:sandbox];
    } else {
        BDPUniqueID *uniqId = ((BDPJSBridgeEngine)context.engine).uniqueID;
        BDPCommon *common = BDPCommonFromUniqueID(uniqId);
        NSString *session = [[TMASessionManager sharedManager] getSession:common.sandbox];
        return session;
    }
}

- (NSDictionary *)userInfoDict:(NSDictionary *)data uniqueID:(BDPUniqueID *)uniqueID {
    if (uniqueID.appType == BDPTypeWebApp) {
        
    } else {
        BDPPlugin(userPlugin, BDPUserPluginDelegate);
        BDPCommon *common = [[BDPCommonManager sharedManager] getCommonWithUniqueID:uniqueID];
        if ([common.model.authList containsObject:@"getUserInfo"]) {
            NSMutableDictionary *mutableUserInfo = [data bdp_dictionaryValueForKey:@"userInfo"] ? [[data bdp_dictionaryValueForKey:@"userInfo"] mutableCopy]: [NSMutableDictionary new];
            [mutableUserInfo setValue:[userPlugin bdp_userId] forKey:@"userId"];
            [mutableUserInfo setValue:[userPlugin bdp_sessionId] forKey:@"sessionId"];
            
            NSMutableDictionary *mutableDict = [data mutableCopy];
            [mutableDict setValue:[mutableUserInfo copy] forKey:@"userInfo"];
            return [mutableDict copy];
        }
    }
    return data;
}


- (NSString *)userInfoURLUniqueID:(BDPUniqueID *)uniqueID {
    if (uniqueID.appType == BDPTypeWebApp) {
        return [BDPSDKConfig sharedConfig].userInfoH5URL;
    } else {
        return [BDPSDKConfig sharedConfig].userInfoURL;
    }
}

@end

@implementation BDPAuthModuleControllerProvider
@end
