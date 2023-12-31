//
//  BDWebSecSettingManager.m
//  BDWebKit-Pods-Aweme
//
//  Created by huangzhongwei on 2021/4/16.
//

#import "BDWebSecSettingManager.h"
#import <objc/message.h>

static id<BDWebSecSettingDelegate> kSettingsDelegate;

@implementation BDWebSecSettingManager
+ (void)setSettingsDelegate:(id<BDWebSecSettingDelegate>)settingsDelegate {
    kSettingsDelegate = settingsDelegate;
}

+ (id<BDWebSecSettingDelegate>)settingsDelegate {
    return kSettingsDelegate;
}

+ (BOOL)canProxy2Delegate:(SEL)sel {
    return [[kSettingsDelegate class] respondsToSelector:sel];
}

+ (BOOL)bdForceHttpsRequest {
    if ([BDWebSecSettingManager canProxy2Delegate:_cmd]) {
        return [[kSettingsDelegate class] bdForceHttpsRequest];
    } else {
        return NO;
    }
}

+ (BOOL)shouldForceHttpsForURL:(NSString *)url {
    if ([BDWebSecSettingManager canProxy2Delegate:_cmd]) {
        return [[kSettingsDelegate class] shouldForceHttpsForURL:url];
    } else {
        return YES;
    }
}

@end
