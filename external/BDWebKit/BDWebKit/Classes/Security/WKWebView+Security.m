//
//  WKWebView+Security.m
//  BDWebKit-Pods-Aweme
//
//  Created by huangzhongwei on 2021/4/16.
//

#import "WKWebView+Security.h"
#import "BDWebSecHttpsGuardPlugin.h"
#import <BDWebCore/WKWebView+Plugins.h>

@implementation WKWebView (Security)
+(void)enableSecurity:(id<BDWebSecSettingDelegate>)settingsDelegate {
    [BDWebSecSettingManager setSettingsDelegate:settingsDelegate];
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if ([BDWebSecSettingManager bdForceHttpsRequest]) {
            [WKWebView IWK_loadPlugin:[[BDWebSecHttpsGuardPlugin alloc] init]];
        }
    });

}

@end
