//
//  NSURLProtocol+WebKitSupport.m
//  NSURLProtocol+WebKitSupport
//

#import "NSURLProtocol+WebKitSupport.h"
#import <WebKit/WebKit.h>
#import <objc/runtime.h>

FOUNDATION_STATIC_INLINE NSString *p_base64DecodedString(NSString *origin)
{
    NSData *data = [[NSData alloc] initWithBase64EncodedString:origin options:0];
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

FOUNDATION_STATIC_INLINE Class ContextControllerClass()
{
    static Class cls;
    if (!cls) {
        NSString *key = @"browsingContextController";
        cls = [[[WKWebView new] valueForKey:key] class];
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

@implementation NSURLProtocol (WebKitSupport)

static NSMutableArray<NSString *> *s_registeredSchemes;

+ (void)wk_initRegisteredSchemesIfNeeded
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        s_registeredSchemes = [NSMutableArray array];
    });
}


+ (void)wk_registerScheme:(NSString *)scheme
{
    [self wk_initRegisteredSchemesIfNeeded];
    
    if ([s_registeredSchemes containsObject:scheme]) {
        [self wk_unregisterScheme:scheme];
        [s_registeredSchemes removeObject:scheme];
    }
    
    Class cls = ContextControllerClass();
    SEL sel = RegisterSchemeSelector();
    if ([(id)cls respondsToSelector:sel]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [(id)cls performSelector:sel withObject:scheme];
#pragma clang diagnostic pop
        //
        [s_registeredSchemes addObject:scheme];
    }
}

+ (void)wk_unregisterScheme:(NSString *)scheme
{
    [self wk_initRegisteredSchemesIfNeeded];
    if (![s_registeredSchemes containsObject:scheme]) {
        return;
    }
    
    Class cls = ContextControllerClass();
    SEL sel = UnregisterSchemeSelector();
    if ([(id)cls respondsToSelector:sel]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [(id)cls performSelector:sel withObject:scheme];
#pragma clang diagnostic pop
        //
        [s_registeredSchemes removeObject:scheme];
    }
}

+ (void)wk_unregisterAllCustomSchemes
{
    [self wk_initRegisteredSchemesIfNeeded];
    
    NSArray<NSString *> *schemes = [s_registeredSchemes copy];
    [schemes enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [self wk_unregisterScheme:obj];
    }];
}

@end
