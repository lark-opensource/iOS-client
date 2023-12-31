//
//  OPDowngradeResolveDependenceImpl.m
//  EEMicroAppSDK
//
//  Created by justin on 2023/1/9.
//

#import "OPDowngradeResolveDependenceImpl.h"
#import <TTMicroApp/BDPVersionManagerV2.h>
#import <TTMicroApp/BDPPermissionViewController.h>
#import "EMAAppEngine.h"
#import <TTMicroApp/TTMicroApp-Swift.h>
#import <TTMicroApp/BDPWarmBootManager.h>

@implementation OPDowngradeResolveDependenceImpl

+(Class<BDPVersionManagerDelegate>)versionManagerClass {
    // 减少对性能影响
    static dispatch_once_t onceToken;
    static Class<BDPVersionManagerDelegate> versionImpClass = nil;
    dispatch_once(&onceToken, ^{
        versionImpClass = [BDPVersionManagerV2 class];
    });
    return versionImpClass;
}

+(Class<BDPPermissionViewControllerDelegate>)permissionViewControllerClass {
    return [BDPPermissionViewController class];
}

+ (EMAAppEngineConfig *)currentAppEngineConfig {
    return [EMAAppEngine currentEngine].config;
}

+ (EMAAppEngineAccount *)currentAppEngineAccount {
    return [EMAAppEngine currentEngine].account;
}

+ (EMAConfig *)currentAppEngineOnlineConfig {
    return [EMAAppEngine currentEngine].onlineConfig;
}

+ (NSString *)blockIDWithID:(OPAppUniqueID *)uniqueID {
    return uniqueID.blockID;
}

+ (NSString *)hostWithID:(OPAppUniqueID *)uniqueID {
    return uniqueID.host;
}

+ (NSString * _Nullable)packageVersionWithID:(OPAppUniqueID *)uniqueID {
    return uniqueID.packageVersion;
}

+ (id<OPTraceProtocol> _Nullable)blockTraceWithID:(OPAppUniqueID *)uniqueID {
    return uniqueID.blockTrace;
}

+ (BOOL)enablePrehandle {
    //BDPPreloadHelper.preHandleEnable()
    return [BDPPreloadHelper preHandleEnable];
}

// From: BDPTimorClient 的 onMaxBootCacheCountChanged 实现
+ (void)updateMaxWarmBootCacheCount:(int)maxCount {
    [[BDPWarmBootManager sharedManager] updateMaxWarmBootCacheCount:maxCount];
}

@end
