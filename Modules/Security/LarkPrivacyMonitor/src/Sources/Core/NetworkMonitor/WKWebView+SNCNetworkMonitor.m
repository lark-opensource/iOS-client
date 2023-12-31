//
//  WKWebView+SNCNetworkMonitor.m
//  LarkPrivacyMonitor
//
//  Created by 汤泽川 on 2023/7/4.
//

#import "WKWebView+SNCNetworkMonitor.h"
#import "LarkPrivacyMonitor-Swift.h"
#import <objc/runtime.h>

void snc_swizzledMethod(Class cls, SEL originalSel, SEL swizzledSel) {
    Method originalMethod = class_getInstanceMethod(cls, originalSel);
    Method swizzledMethod = class_getInstanceMethod(cls, swizzledSel);
    
    BOOL didAddMethod =
    class_addMethod(cls,
                    originalSel,
                    method_getImplementation(swizzledMethod),
                    method_getTypeEncoding(swizzledMethod));
    if (didAddMethod) {
        class_replaceMethod(cls,
                            swizzledSel,
                            method_getImplementation(originalMethod),
                            method_getTypeEncoding(originalMethod));
    } else {
        method_exchangeImplementations(originalMethod, swizzledMethod);
    }
}

@implementation WKWebView (SNCNetworkMonitor)

+ (void)snc_setupNetworkMonitor {
    SEL originalSel = @selector(initWithFrame:configuration:);
    SEL swizzledSel = @selector(snc_networkMonitorInitWithFrame:configuration:);
    snc_swizzledMethod(self, originalSel, swizzledSel);
}

- (instancetype)snc_networkMonitorInitWithFrame:(CGRect)frame configuration:(WKWebViewConfiguration *)configuration {
    WKWebView* instance = [self snc_networkMonitorInitWithFrame:frame configuration:configuration];
    NSString *className = NSStringFromClass(self.class);
    BOOL isBDPContainer = [className isEqualToString:@"BDPAppPage"] || [className isEqualToString:@"BDPWebViewComponent"];
    if (!isBDPContainer) {
        [instance setupFetchMonitor];
        [instance setupNavMonitor];
        [instance addMessageHandler];
    }
    return instance;
}

@end
