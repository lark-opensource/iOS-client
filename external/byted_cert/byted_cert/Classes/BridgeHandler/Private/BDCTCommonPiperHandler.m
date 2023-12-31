//
//  BytedCertCommonPiperHandler.m
//  BytedCertDemo
//
//  Created by chenzhendong.ok@bytedance.com on 2021/7/5.
//  Copyright © 2021 Bytedance Inc. All rights reserved.
//

#import "BDCTCommonPiperHandler.h"
#import "BytedCertManager+Private.h"
#import "BytedCertWrapper.h"
#import "BDCTCorePiperHandler.h"

#import <ByteDanceKit/BTDMacros.h>
#import <ByteDanceKit/UIApplication+BTDAdditions.h>
#import <ByteDanceKit/UIDevice+BTDAdditions.h>
#import <BDTrackerProtocol/BDTrackerProtocol.h>


@implementation BDCTCommonPiperHandler

+ (NSDictionary *)appInfo {
    NSMutableDictionary *data = [NSMutableDictionary dictionary];
    [data setValue:[BytedCertManager aid] forKey:@"aid"];
    [data setValue:[BytedCertManager appName] forKey:@"appName"];
    [data setValue:[UIApplication btd_versionName] forKey:@"appVersion"];
    [data setValue:[UIApplication btd_versionName] forKey:@"versionCode"];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    [data setValue:[UIApplication btd_platformName] forKey:@"device_platform"]; // 客户端操作系统 iphone/ipad
#pragma clang diagnostic pop
    [data setValue:[UIDevice btd_platform] forKey:@"device_type"]; // 手机型号
    [data setValue:BytedCertSDKVersion forKey:@"sdkVersion"];
    [data setValue:BDTrackerProtocol.deviceID forKey:@"did"];
    [data setValue:BDTrackerProtocol.installID forKey:@"iid"];
    [data setValue:@"7374" forKey:@"sdkId"];
    CGFloat statusBarHeight = 0;
    if (@available(iOS 13.0, *)) {
        UIStatusBarManager *statusBarManager = [[UIApplication.sharedApplication.keyWindow windowScene] statusBarManager];
        statusBarHeight = statusBarManager.statusBarFrame.size.height * UIScreen.mainScreen.scale;
    } else {
        statusBarHeight = [UIApplication sharedApplication].statusBarFrame.size.height * UIScreen.mainScreen.scale;
    }
    if (statusBarHeight == 0) {
        statusBarHeight = BytedCertManager.shareInstance.statusBarHeight;
    }
    [data setValue:@(statusBarHeight) forKey:@"statusBarHeight"];
    return data.copy;
}

- (void)registerHandlerWithWebView:(WKWebView *)webView {
    [webView.tt_engine.bridgeRegister registerBridge:^(TTBridgeRegisterMaker *_Nonnull maker) {
        maker.bridgeName(@"getAppInfo").handler(^(NSDictionary *_Nullable params, TTBridgeCallback _Nonnull callback, id<TTBridgeEngine> _Nonnull engine, UIViewController *_Nullable controller) {
            btd_dispatch_async_on_main_queue(^{
                NSDictionary *appInfo = [self.class appInfo];
                NSMutableDictionary *jsbResult = [appInfo mutableCopy];
                jsbResult[@"data"] = appInfo;
                callback(TTBridgeMsgSuccess, [BDCTCorePiperHandler jsbCallbackResultWithParams:jsbResult error:nil], nil);
            });
        });
    }];
}

@end
