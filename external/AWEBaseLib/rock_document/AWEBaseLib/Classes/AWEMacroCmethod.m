//
//  AWEMacroCmethod.m
//  AWEBaseLib-Pods-Aweme
//
//  Created by zhangchi on 2020/8/18.
//

#import <Foundation/Foundation.h>
#import "AWEMacros.h"

BOOL isRunningOnMac() {
    static dispatch_once_t onceToken;
    static BOOL isRunningOnMac = NO;
    dispatch_once(&onceToken, ^{
        if (@available(iOS 14.0, *)) {
            isRunningOnMac = [NSProcessInfo processInfo].isMacCatalystApp || [NSProcessInfo processInfo].isiOSAppOnMac;
        } else if (@available(iOS 13.0, *)) {
            isRunningOnMac = [NSProcessInfo processInfo].isMacCatalystApp;
        }
    });
    return isRunningOnMac;
}

CGFloat getSrceenWidth() {
    if (isRunningOnMac()) {
        if (@available(iOS 13.0, *)) {
            for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
                if (scene.activationState == UISceneActivationStateForegroundActive && [scene isKindOfClass:UIWindowScene.class]) {
                    for (UIWindow *window in ((UIWindowScene *)scene).windows) {
                        if (window.isKeyWindow) {
                            return window.bounds.size.width;
                        }
                    }
                }
            }
        }
    }
    return [[UIScreen mainScreen] bounds].size.width;
}

CGFloat getSrceenHeight() {
    if (isRunningOnMac()) {
        if (@available(iOS 13.0, *)) {
            for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
                if (scene.activationState == UISceneActivationStateForegroundActive && [scene isKindOfClass:UIWindowScene.class]) {
                    for (UIWindow *window in ((UIWindowScene *)scene).windows) {
                        if (window.isKeyWindow) {
                            return window.bounds.size.height;
                        }
                    }
                }
            }
        }
    }
    return [[UIScreen mainScreen] bounds].size.height;
}
