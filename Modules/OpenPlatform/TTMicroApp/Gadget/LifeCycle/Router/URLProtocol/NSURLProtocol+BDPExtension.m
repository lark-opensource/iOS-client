//
//  NSURLProtocol+BDPExtension.m
//  Timor
//
//  Created by CsoWhy on 2018/8/15.
//

#import "NSURLProtocol+BDPExtension.h"
#import <WebKit/WebKit.h>

FOUNDATION_STATIC_INLINE Class WKContextControllerClass(WKWebView *webview)
{
    static Class cls;
    if (!cls) {
        NSString *key = @"browsingContextController";
        if ([webview isKindOfClass:[WKWebView class]]) {
            cls = [[webview valueForKey:key] class];
        } else { // 节省一次WKWebview创建, 6Plus可优化50~100ms+
            cls = [[[WKWebView new] valueForKey:key] class];
        }
    }
    return cls;
}

FOUNDATION_STATIC_INLINE SEL RegisterSchemeSelector()
{
    NSString *selString = @"registerSchemeForCustomProtocol:";
    return NSSelectorFromString(selString);
}

FOUNDATION_STATIC_INLINE SEL UnregisterSchemeSelector()
{
    NSString *selString = @"unregisterSchemeForCustomProtocol:";
    return NSSelectorFromString(selString);
}

@implementation NSURLProtocol (BDPExtension)

#pragma mark - Register & UnRegister
+ (void)bdp_registerScheme:(NSString *)scheme
{
    Class cls = WKContextControllerClass(nil);
    SEL sel = RegisterSchemeSelector();
    if ([(id)cls respondsToSelector:sel]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [(id)cls performSelector:sel withObject:scheme];
#pragma clang diagnostic pop
    }
}

+ (void)bdp_unregisterScheme:(NSString *)scheme
{
    Class cls = WKContextControllerClass(nil);
    SEL sel = UnregisterSchemeSelector();
    if ([(id)cls respondsToSelector:sel]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [(id)cls performSelector:sel withObject:scheme];
#pragma clang diagnostic pop
    }
}

+ (void)bdp_registerSchemes:(NSArray<NSString *> *)schemes withWKWebview:(WKWebView *)wkwebview {
    Class cls = WKContextControllerClass(wkwebview);
    SEL sel = RegisterSchemeSelector();
    if ([(id)cls respondsToSelector:sel]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        for (NSString *scheme in schemes) {
            [(id)cls performSelector:sel withObject:scheme];
        }
#pragma clang diagnostic pop
    }
}

+ (void)bdp_unregisterSchemes:(NSArray<NSString *> *)schemes withWKWebview:(WKWebView *)wkwebview {
    Class cls = WKContextControllerClass(wkwebview);
    SEL sel = UnregisterSchemeSelector();
    if ([(id)cls respondsToSelector:sel]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        for (NSString *scheme in schemes) {
            [(id)cls performSelector:sel withObject:scheme];
        }
#pragma clang diagnostic pop
    }
}

@end
