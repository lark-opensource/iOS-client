//
//  WKWebViewConfiguration+PublicInterface.m
//  IESWebViewMonitor
//
//  Created by bytedance on 2021/11/29.
//

#import "WKWebViewConfiguration+PublicInterface.h"
#import "BDWebView+BDWebViewMonitor.h"
#import <objc/runtime.h>

@implementation WKWebViewConfiguration (PublicInterface)

- (BOOL)bdwm_disableMonitor {
    return [self.settings[kWebviewInstanceConfigDisableMonitor] boolValue];
}

- (void)setBdwm_disableMonitor:(BOOL)bdwm_disableMonitor {
    NSNumber *disable = @(bdwm_disableMonitor);
    NSMutableDictionary *newSettings = [self.settings mutableCopy];
    newSettings[kWebviewInstanceConfigDisableMonitor] = disable;
    self.settings = newSettings;
}

- (BOOL)bdwm_disableInjectBrowser {
    return [self.settings[kWebviewInstanceConfigDisableInjectBrowser] boolValue];
}

- (void)setBdwm_disableInjectBrowser:(BOOL)bdwm_disableInjectBrowser {
    NSNumber *disable = @(bdwm_disableInjectBrowser);
    NSMutableDictionary *newSettings = [self.settings mutableCopy];
    newSettings[kWebviewInstanceConfigDisableInjectBrowser] = disable;
    self.settings = newSettings;
}

- (NSDictionary *)settings {
    NSDictionary *dict = objc_getAssociatedObject(self, _cmd);
    if (!dict) {
        dict = [NSDictionary new];
    }
    return dict;
}

- (void)setSettings:(NSDictionary *)settings {
    objc_setAssociatedObject(self, @selector(settings), settings, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
