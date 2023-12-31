//
//  WKWebView+Keyboard.m
//  BDWebKit
//
//  Created by li keliang on 2020/3/15.
//

#import "WKWebView+Keyboard.h"
#import <objc/runtime.h>

@implementation WKWebView (Keyboard)

- (BOOL)bdw_keyboardDisplayRequiresUserAction
{
    if (objc_getAssociatedObject(self, _cmd)) {
        return [objc_getAssociatedObject(self, _cmd) boolValue];
    } else {
        return YES;
    }
}

- (void)setBdw_keyboardDisplayRequiresUserAction:(BOOL)bdw_keyboardDisplayRequiresUserAction
{
    [BDWebKeyboardManager setupIfNeeded];
    objc_setAssociatedObject(self, @selector(bdw_keyboardDisplayRequiresUserAction), @(bdw_keyboardDisplayRequiresUserAction), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end

@implementation BDWebKeyboardManager

+ (void)setupIfNeeded
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        static IMP original;
        Class class = NSClassFromString(@"WKContentView");
        if (@available(iOS 11.3, *)) {
            SEL selector;
            if (@available(iOS 13.0, *)) {
                selector = sel_getUid("_elementDidFocus:userIsInteracting:blurPreviousNode:activityStateChanges:userObject:");
            } else if (@available(iOS 12.2, *)) {
                selector = sel_getUid("_elementDidFocus:userIsInteracting:blurPreviousNode:changingActivityState:userObject:");
            } else {
                selector = sel_getUid("_startAssistingNode:userIsInteracting:blurPreviousNode:changingActivityState:userObject:");
            }
            
            Method method = class_getInstanceMethod(class, selector);
            static dispatch_once_t onceToken;
            dispatch_once(&onceToken, ^{
                original = method_getImplementation(method);
            });
            IMP override = imp_implementationWithBlock(^void(id me, void* arg0, BOOL arg1, BOOL arg2, BOOL arg3, id arg4) {
                WKWebView *webView = [me valueForKey:@"_webView"];
                if (webView) {
                    arg1 = !webView.bdw_keyboardDisplayRequiresUserAction;
                }
                ((void (*)(id, SEL, void*, BOOL, BOOL, BOOL, id))original)(me, selector, arg0, arg1, arg2, arg3, arg4);
            });
            method_setImplementation(method, override);
        } else {
            SEL selector = sel_getUid("_startAssistingNode:userIsInteracting:blurPreviousNode:userObject:");
            Method method = class_getInstanceMethod(class, selector);
            static dispatch_once_t onceToken;
            dispatch_once(&onceToken, ^{
                original = method_getImplementation(method);
            });
            IMP override = imp_implementationWithBlock(^void(id me, void* arg0, BOOL arg1, BOOL arg2, id arg3) {
                WKWebView *webView = [me valueForKey:@"_webView"];
                if (webView) {
                    arg1 = !webView.bdw_keyboardDisplayRequiresUserAction;
                }
                ((void (*)(id, SEL, void*, BOOL, BOOL, id))original)(me, selector, arg0, arg1, arg2, arg3);
            });
            method_setImplementation(method, override);
        }
    });
}

@end



