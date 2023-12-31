//
//  BDPRouteMediatorDelegate.m
//  EEMicroAppSDK
//
//  Created by MJXin on 2021/4/9.
//

#import "BDPRouteMediatorDelegate.h"
#import <OPFoundation/EMAAlertController.h>
#import "EMAAppEngine.h"
#import "EMAI18n.h"
#import "EERoute.h"
#import <OPFoundation/EMANetworkCommonConfiguration.h>
#import <OPFoundation/BDPI18n.h>
#import <OPFoundation/BDPResponderHelper.h>
#import <OPFoundation/BDPRouteMediator.h>
#import <OPFoundation/BDPApplicationManager.h>
#import <NetworkExtension/NEHotspotHelper.h>
#import <OPFoundation/OPFoundation-Swift.h>
#import <EEMicroAppSDK/EEMicroAppSDK-Swift.h>
#import <OPSDK/OPSDK-Swift.h>
@interface BDPRouteMediatorDelegate()<BDPRouteMediatorProtocol>
@end

@implementation BDPRouteMediatorDelegate

+ (instancetype)shared {
    static id instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[[self class] alloc] init];
    });
    return instance;
}

- (void)setDelegate {
    [BDPRouteMediator sharedManager].delegate = self;
}

- (NSMutableURLRequest *)appMetaRequestWithURL:(NSString *)url params:(NSDictionary *)params uniqueID:(BDPUniqueID  * _Nullable)uniqueID {
    BDPLogInfo(@"appMetaRequest url=%@", url);
    NSMutableDictionary *mParams = params.mutableCopy;
    NSString *sessionId = EMAAppEngine.currentEngine.account.userSession;
    if (BDPIsEmptyString(sessionId)) {
        //  此处仅作为埋点上报使用，辅助解决问题，排查是否出现sessionId为空的情况，不影响此处的代码逻辑
        OPError *operror =  OPErrorWithMsg(CommonMonitorCodeMeta.invalid_params, @"session id for meta request is empty");
        NSAssert(NO, operror.description);
    }
    if([OPSDKFeatureGating enableKeepRedundantSessionInRequest]){
        mParams[@"sessionid"] = sessionId;
    }
    NSString *appID = params[@"appid"];
    if (appID && uniqueID && [EMAAppEngine.currentEngine.onlineConfig isMicroAppTestForUniqueID:uniqueID]) {   // 灰度逻辑
        NSString *versionTypeString = [mParams bdp_stringValueForKey:@"version"];
        if (!versionTypeString || [versionTypeString isEqualToString:OPAppVersionTypeToString(OPAppVersionTypeCurrent)]) {
            [mParams setValue:@"test" forKey:@"version"];
        }
    }
    mParams[@"language"] = [BDPApplicationManager language];
    NSError *error;
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:15];
    request.HTTPMethod = @"POST";
    [mParams addEntriesFromDictionary:[EMANetworkCommonConfiguration getCommonOpenPlatformRequestWithURLString: url]];
    NSData *requstData = [NSJSONSerialization dataWithJSONObject:mParams options:NSJSONWritingPrettyPrinted error:&error];
    request.HTTPBody = requstData;
    [request setValue:@"application/json" forHTTPHeaderField:@"content-type"];
    [request setValue:sessionId forHTTPHeaderField:@"X-Tma-Host-Sessionid"];
    request.HTTPShouldUsePipelining = YES;
    [EMANetworkCommonConfiguration addCommonConfigurationForRequest:request];
    return request;
}

- (void)onWebviewCreate:(BDPUniqueID *)uniqueID webview:(BDPWebViewComponent *)webview {
    NSArray *urlList = [EMAAppEngine.currentEngine.onlineConfig cookieUrlsForUniqueID:uniqueID];
    for (NSString *url in urlList) {
        NSArray *cookies = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookiesForURL:[NSURL URLWithString: url]];
        for (NSHTTPCookie *cookie in cookies) {
            [[NSHTTPCookieStorage sharedHTTPCookieStorage] deleteCookie:cookie];
            [WKWebsiteDataStore.defaultDataStore.httpCookieStore deleteCookie:cookie completionHandler:nil];
        }
    }
}

- (void)onWebviewDestroy:(BDPUniqueID *)uniqueID webview:(BDPWebViewComponent *)webview {}


- (BOOL)needUpdateAlertForUniqueID:(BDPUniqueID *)uniqueID {
    if (EMAAppEngine.currentEngine.onlineConfig.updateMineAboutEnable == NO) {
        BDPLogInfo(@"needUpdate? updateMineAboutEnable is no, app=%@", uniqueID);
        return NO;
    }
    UIViewController *topVC = [BDPResponderHelper topViewControllerFor:[BDPResponderHelper topmostView:uniqueID.window]];
    [UDDialogForOC presentDialogFrom:topVC title:nil content:EMAI18n.app_update_tip cancelTitle:BDPI18n.cancel cancelDismissCompletion:^{
        BDPLogInfo(@"needUpdate? click cancel, clean task, app=%@", uniqueID);
        [self exitCleanTask:uniqueID];
    } confirmTitle:EMAI18n.update_now confirmDismissCompletion:^{
        id<EMAProtocol> delegate = [EMARouteProvider getEMADelegate];
        if ([delegate respondsToSelector:@selector(openMineAboutVCWithUniqueID:fromController:)]) {
            BDPLogInfo(@"needUpdate? click update, reopen, app=%@", uniqueID);
            [delegate openMineAboutVCWithUniqueID:uniqueID fromController:topVC];
            [self exitLastCleanTask:uniqueID];
        }
    }];
    BDPLogInfo(@"needUpdate? updateMineAboutEnable is yes, app=%@", uniqueID);
    return YES;
}

- (NSDictionary *)validWifiSecureStrength {
    NSArray *supportedNetworkInterfaces = [NEHotspotHelper supportedNetworkInterfaces];
    if (supportedNetworkInterfaces && [supportedNetworkInterfaces count] > 0) {
        NSDictionary *wifiInfo = [[NSMutableDictionary alloc] init];
        NEHotspotNetwork* net = [supportedNetworkInterfaces objectAtIndex:0];
        [wifiInfo setValue:net.SSID forKey:@"SSID"];
        [wifiInfo setValue:net.BSSID forKey:@"BSSID"];
        [wifiInfo setValue:[NSNumber numberWithBool:net.secure] forKey:@"secure"];
        [wifiInfo setValue:[NSNumber numberWithFloat:((net.signalStrength * 50) - 100)] forKey:@"signalStrength"];
        return wifiInfo;
    }
    return nil;
}

- (void)exitCleanTask:(BDPUniqueID *)uniqueID {
    // TODO: 这个逻辑不够安全，新容器上线后可考虑删除
    UINavigationController *nav = [OPNavigatorHelper topmostNavWithSearchSubViews:NO window:uniqueID.window];
    [nav popViewControllerAnimated:YES];
    // 重启需要冷启动
    [[BDPWarmBootManager sharedManager] cleanCacheWithUniqueID:uniqueID];
}

- (void)exitLastCleanTask:(BDPUniqueID *)uniqueID {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        UINavigationController *nav = [OPNavigatorHelper topmostNavWithSearchSubViews:NO window:uniqueID.window];
        if (nav && nav.viewControllers.count >= 2) {
            NSMutableArray *vcs = [NSMutableArray arrayWithArray:nav.viewControllers];
            [vcs removeObjectAtIndex:vcs.count - 2];
            [nav setViewControllers:vcs];
            // 重启需要冷启动
            [[BDPWarmBootManager sharedManager] cleanCacheWithUniqueID:uniqueID];
        }
    });
}
@end
