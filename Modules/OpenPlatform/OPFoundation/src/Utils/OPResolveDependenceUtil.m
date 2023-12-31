//
//  OPResolveDependenceUtil.m
//  OPFoundation
//
//  Created by justin on 2023/1/9.
//

#import "OPResolveDependenceUtil.h"
#import <OPFoundation/OPFoundation-Swift.h>
#import "BDPTimorClient.h"
#import <ECOInfra/BDPLog.h>

@implementation OPResolveDependenceUtil

/// 是否降级，默认不降级
+ (BOOL)degradeResolveDependence {
    return NO;
}

+ (Class<OPDowngradeResolveDependenceDelegate>)resolveDependenceImp {
    static dispatch_once_t onceToken;
    static Class<OPDowngradeResolveDependenceDelegate> resolveImpClass = nil;
    dispatch_once(&onceToken, ^{
        resolveImpClass = (Class<OPDowngradeResolveDependenceDelegate>)NSClassFromString(@"OPDowngradeResolveDependenceImpl");
    });
    return resolveImpClass;
}

+(Class<BDPVersionManagerDelegate>)versionManagerClass {
    if([self degradeResolveDependence]){
        return [[self resolveDependenceImp]  versionManagerClass];
    }else {
        return [BDPTimorClient sharedClient].versionManagerPlugin;
    }
}

+(Class<BDPPermissionViewControllerDelegate>)permissionViewControllerClass {
    if([self degradeResolveDependence]){
        return [[self resolveDependenceImp] permissionViewControllerClass];
    }else {
        return [BDPTimorClient sharedClient].permissionVCPlugin;
    }
}


+ (EMAAppEngineConfig *)currentAppEngineConfig {
    
    if([self degradeResolveDependence]) {
        return [[self resolveDependenceImp] currentAppEngineConfig];
    }else {
        BDPPlugin(appEnginePlugin, EMAAppEnginePluginDelegate);
        return appEnginePlugin.config;
    }
    
}

+ (EMAAppEngineAccount *)currentAppEngineAccount {
    
    if([self degradeResolveDependence]) {
        return [[self resolveDependenceImp] currentAppEngineAccount];
    }else {
        BDPPlugin(appEnginePlugin, EMAAppEnginePluginDelegate);
        return appEnginePlugin.account;
    }
}

+ (EMAConfig *)currentAppEngineOnlineConfig {
    if([self degradeResolveDependence]) {
        return [[self resolveDependenceImp] currentAppEngineOnlineConfig];
    }else {
        BDPPlugin(appEnginePlugin, EMAAppEnginePluginDelegate);
        return appEnginePlugin.onlineConfig;
    }
}


+ (NSString *)blockIDWithID:(OPAppUniqueID *)uniqueID {
    if([self degradeResolveDependence]) {
        return [[self resolveDependenceImp] blockIDWithID:uniqueID];
    }else {
        Class<OPGadgetPluginDelegate> opGadgetPlugin = [BDPTimorClient sharedClient].opGadgetPlugin;
        return [opGadgetPlugin blockIDWithID:uniqueID];
    }
}

+ (NSString *)hostWithID:(OPAppUniqueID *)uniqueID {
    if([self degradeResolveDependence]) {
        return [[self resolveDependenceImp] hostWithID:uniqueID];
    }else {
        Class<OPGadgetPluginDelegate> opGadgetPlugin = [BDPTimorClient sharedClient].opGadgetPlugin;
        return [opGadgetPlugin hostWithID:uniqueID];
    }
}

+ (NSString * _Nullable)packageVersionWithID:(OPAppUniqueID *)uniqueID {
    if([self degradeResolveDependence]) {
        return [[self resolveDependenceImp] packageVersionWithID:uniqueID];
    }else {
        Class<OPGadgetPluginDelegate> opGadgetPlugin = [BDPTimorClient sharedClient].opGadgetPlugin;
        return [opGadgetPlugin packageVersionWithID:uniqueID];
    }
}

+ (id<OPTraceProtocol> _Nullable)blockTraceWithID:(OPAppUniqueID *)uniqueID {
    if([self degradeResolveDependence]) {
        return [[self resolveDependenceImp] blockTraceWithID:uniqueID];
    }else {
        Class<OPGadgetPluginDelegate> opGadgetPlugin = [BDPTimorClient sharedClient].opGadgetPlugin;
        return [opGadgetPlugin blockTraceWithID:uniqueID];
    }
}

// == BDPPreloadHelper.preHandleEnable()
+ (BOOL)enablePrehandle {
    if([self degradeResolveDependence]) {
        return [[self resolveDependenceImp] enablePrehandle];
    }else {
        Class<OPGadgetPluginDelegate> opGadgetPlugin = [BDPTimorClient sharedClient].opGadgetPlugin;
        return [opGadgetPlugin enablePrehandle];
    }
}

// 内部调用[[BDPWarmBootManager sharedManager] updateMaxWarmBootCacheCount:(int)count];
+ (void)updateMaxWarmBootCacheCount:(int)maxCount {
    if([self degradeResolveDependence]) {
        [[self resolveDependenceImp] updateMaxWarmBootCacheCount:maxCount];
    }else {
        Class<OPGadgetPluginDelegate> opGadgetPlugin = [BDPTimorClient sharedClient].opGadgetPlugin;
        [opGadgetPlugin updateMaxWarmBootCacheCount:maxCount];
    }
}


@end
