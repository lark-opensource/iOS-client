//
//  EMADebugUtil+Business.m
//  EEMicroAppSDK
//
//  Created by justin on 2022/12/29.
//

#import "EMADebugUtil+Business.h"
#import "EERoute.h"
#import "EMAAppEngine.h"
#import <EEMicroAppSDK/EEMicroAppSDK-Swift.h>
#import <TTMicroApp/BDPAppLoadManager+Util.h>
#import <TTMicroApp/BDPBaseContainerController.h>
#import <TTMicroApp/BDPStorageManager.h>
#import <TTMicroApp/BDPTask.h>
#import <TTMicroApp/BDPTaskManager.h>
#import <OPFoundation/NSURLComponents+EMA.h>
#import <OPFoundation/BDPTimorClient.h>
#import <OPFoundation/OPFoundation-Swift.h>

// Debug 工具代码，无需进行统一存储规则检查
// lint:disable lark_storage_check

@implementation EMADebugUtil (Business)

- (void)clearMicroAppProcesses {
    UINavigationController *nv = [OPNavigatorHelper topmostNavWithSearchSubViews:NO window:OPWindowHelper.fincMainSceneWindow];
    NSArray *viewControllers = nv.viewControllers;
    NSMutableArray *newViewControllers = viewControllers.mutableCopy;
    for (UIViewController *vc in viewControllers) {
        if ([vc isKindOfClass:BDPBaseContainerController.class]) {
            [newViewControllers removeObject:vc];
        }
    }
    [nv setViewControllers:newViewControllers.copy animated:NO];
    [EERoute.sharedRoute clearTaskCache];
}

- (void)clearMicroAppFileCache {
    [self clearMicroAppProcesses];
    [[BDPTimorClient sharedClient] clearAllUserCache];
    [BDPVersionManager setupBundleVersionIfNeed:OPAppTypeGadget];
}

- (void)clearMicroAppFolders {
    BDPResolveModule(storageModule, BDPStorageModuleProtocol, BDPTypeNativeApp);
    [[storageModule sharedLocalFileManager] restoreToOriginalState];
    [BDPAppLoadManager clearAllMetas];
    [self clearMicroAppProcesses];
    [[storageModule sharedLocalFileManager] cleanAllUserCacheExceptIdentifiers:nil];
    [BDPVersionManager setupBundleVersionIfNeed:OPAppTypeGadget];
}

- (void)clearH5AppFolders {
    BDPResolveModule(storageModulWebApp, BDPStorageModuleProtocol, BDPTypeWebApp);
    [[storageModulWebApp sharedLocalFileManager] restoreToOriginalState];
    
    BDPResolveModule(metaManagerWebApp, MetaInfoModuleProtocol, BDPTypeWebApp)
    [metaManagerWebApp removeAllMetas];
}

- (void)clearMicroAppPermission {
    [self clearMicroAppFileCache];
    NSString *libraryPath = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) lastObject];
    NSString *reVal = [libraryPath stringByAppendingPathComponent:@"MicroAppBackup"];
    [NSFileManager.defaultManager removeItemAtPath:reVal error:nil];
}

- (void)clearAppAllCookies {
    NSArray<NSHTTPCookie *> *cookies = [NSHTTPCookieStorage sharedHTTPCookieStorage].cookies.copy;
    [cookies enumerateObjectsUsingBlock:^(NSHTTPCookie * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [[NSHTTPCookieStorage sharedHTTPCookieStorage] deleteCookie:obj];
    }];
}

- (void)clearJSSDKFileCache {
    [self clearMicroAppProcesses];
    [NSFileManager.defaultManager removeItemAtPath:[[BDPGetResolvedModule(BDPStorageModuleProtocol, BDPTypeNativeApp) sharedLocalFileManager] pathForType:BDPLocalFilePathTypeJSLib] error:nil];

    // 清理版本号
    [NSUserDefaults.standardUserDefaults removeObjectForKey:@"TMAkLocalLibUpdateVersionKey"];
    [NSUserDefaults.standardUserDefaults removeObjectForKey:@"kLocalLibUpdateVersionKeyString"];
    [NSUserDefaults.standardUserDefaults removeObjectForKey:@"TMAkLocalLibBaseVersionKey"];
    [NSUserDefaults.standardUserDefaults removeObjectForKey:@"kLocalLibBaseVersionKeyString"];
}

- (void)checkJSSDKDebugConfig {
    // 清理所有小程序进程
    [EMADebugUtil.sharedInstance clearMicroAppProcesses];
    // 清理JSSDK文件缓存
    [EMADebugUtil.sharedInstance clearJSSDKFileCache];

    EMADebugConfig *config = [EMADebugUtil.sharedInstance debugConfigForID:kEMADebugConfigIDUseSpecificJSSDKURL];
    NSString *text = [EMADebugUtil.sharedInstance debugConfigForID:kEMADebugConfigIDSpecificJSSDKURL].stringValue;
    if (config.boolValue && text && text.length > 0) {
        // 更新JSSDK为指定URL
        [EERoute.sharedRoute setJSSDKUrlString:text];
    }else {
        // 重新登录EERoute
        // 如果FG打开, 这里getEERouteDelegate获取到是空, 也应该传入空; 如果FG关闭, 直接从EERoute.sharedRoute取delegate, 也生效.
        id<EMAProtocol> delegate = getEERouteDelegate();
        [EERoute.sharedRoute loginWithDelegate:delegate
                                   accoutToken:EMAAppEngine.currentEngine.account.accountToken
                                        userID:EMAAppEngine.currentEngine.account.userID
                                   userSession:EMAAppEngine.currentEngine.account.userSession
                                       envType:EMAAppEngine.currentEngine.config.envType
                                  domainConfig:EMAAppEngine.currentEngine.config.domainConfig
                                       channel:EMAAppEngine.currentEngine.config.channel
                                      tenantID:EMAAppEngine.currentEngine.account.tenantID];
    }
}

- (void)checkBlockJSSDKDebugConfig:(BOOL)needExit {
    EMADebugConfig *config = [EMADebugUtil.sharedInstance debugConfigForID:kEMADebugConfigIDUseSpecificBlockJSSDKURL];
    NSString *text = [EMADebugUtil.sharedInstance debugConfigForID:kEMADebugConfigIDSpecificBlockJSSDKURL].stringValue;
    if (config.boolValue && text && text.length > 0) {
        // 更新JSSDK为指定URL
        [EERoute.sharedRoute setBlockJSSDKUrlString:text];
    }
    if (needExit) {
        exit(0);
    }
}

- (void)checkAndSetDebuggerConnection {
    if ([EMADebugUtil.sharedInstance debugConfigForID:kEMADebugConfigIDEnableRemoteDebugger].boolValue
        && !BDPIsEmptyString([EMADebugUtil.sharedInstance debugConfigForID:kEMADebugConfigIDRemoteDebuggerURL].stringValue)) {
        NSURLComponents *url = [NSURLComponents componentsWithString:[EMADebugUtil.sharedInstance debugConfigForID:kEMADebugConfigIDRemoteDebuggerURL].stringValue];
        [url setQueryItemWithKey:@"allow" value:@"true"];
        [EERoute.sharedRoute handleDebuggerWSURL:url.string];
    } else {
        [EERoute.sharedRoute handleDebuggerWSURL:@"ws:?allow=false"];
    }
}

-(void)reloadCurrentGadgetPage{
    ///直接reload导致小程序在后台 无法发送请求（API逻辑），因此增加延时以满足业务方诉求
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSSet *aliveSets = [BDPWarmBootManager sharedManager].aliveAppUniqueIdSet;
        for (BDPUniqueID *uniqueID in aliveSets) {
            BDPTask *task = [[BDPTaskManager sharedManager] getTaskWithUniqueID:uniqueID];
            if ([task.containerVC isKindOfClass:BDPAppContainerController.class]) {
                BDPAppContainerController *container = (BDPAppContainerController *)task.containerVC;
                [container.appController.currentAppPage.appPage reloadAndRefreshTerminateState];
            }
        }
    });
    
}

-(void)triggerMemorywarning{
    NSSet *aliveSets = [BDPWarmBootManager sharedManager].aliveAppUniqueIdSet;
    for (BDPUniqueID *uniqueID in aliveSets) {
        BDPTask *task = [[BDPTaskManager sharedManager] getTaskWithUniqueID:uniqueID];
         [task.context bdp_fireEvent:@"onMemoryWarning" sourceID:NSNotFound data:nil];
    }
}


@end
