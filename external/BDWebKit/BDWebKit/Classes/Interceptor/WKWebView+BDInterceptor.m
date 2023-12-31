//
//  WKWebView+BDInterceptor.m
//  BDWebKit
//
//  Created by caiweilong on 2020/3/29.
//

#import "WKWebView+BDInterceptor.h"
#import "BDWebURLSchemeHandler.h"
#import <BDWebCore/IWKUtils.h>
#import "NSObject+BDWRuntime.h"
#import "BDWebURLSchemeTaskHandler.h"
#import <pthread.h>

@interface BDWebInterceptorArray : NSObject
{
    pthread_mutex_t _mutex;
}

@property (nonatomic, strong, readwrite) NSMutableArray *innerArray;

- (void)addObject:(id)o;

- (void)removeObject:(id)o;

- (NSArray *)copyAsNSArray;

- (NSUInteger)indexOfObject:(id)o;

- (BOOL)containsObject:(id)o;

@end

@implementation BDWebInterceptorArray

- (void)dealloc
{
    pthread_mutex_destroy(&_mutex);
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        pthread_mutex_init(&_mutex, 0);
        _innerArray = [NSMutableArray arrayWithCapacity:3];
    }
    return self;
}

- (void)addObject:(id)o {
    pthread_mutex_lock(&_mutex);
    if (![_innerArray containsObject:o]) {
        [_innerArray addObject:o];
    }
    pthread_mutex_unlock(&_mutex);
}

- (void)removeObject:(id)o {
    pthread_mutex_lock(&_mutex);
    [_innerArray removeObject:o];
    pthread_mutex_unlock(&_mutex);
}

- (NSArray *)copyAsNSArray {
    pthread_mutex_lock(&_mutex);
    id arr = [_innerArray copy];
    pthread_mutex_unlock(&_mutex);
    return arr;
}

- (NSUInteger)indexOfObject:(id)o {
    pthread_mutex_lock(&_mutex);
    NSUInteger idx = [_innerArray indexOfObject:o];
    pthread_mutex_unlock(&_mutex);
    return idx;
}

- (BOOL)containsObject:(id)o {
    pthread_mutex_lock(&_mutex);
    BOOL isContain = [_innerArray containsObject:o];
    pthread_mutex_unlock(&_mutex);
    return isContain;
}

@end

@implementation WKWebView (BDIntetceptor)

- (BDWebInterceptorArray *)bdw_schemeHandler {
    if ([self bdw_getAttachedObjectForKey:@"bdwSchemeHandler"] == nil) {
        [self bdw_attachObject:[[BDWebInterceptorArray alloc] init] forKey:@"bdwSchemeHandler"];
    }

    return  [self bdw_getAttachedObjectForKey:@"bdwSchemeHandler"];
}

- (NSArray *)bdw_schemeHandlerCls {
    return [self.bdw_schemeHandler copyAsNSArray];
}


- (void)bdw_registerSchemeHandlerClass:(Class)handler {
    if (![handler conformsToProtocol:@protocol(BDWebURLSchemeTaskHandler)] ) {
        return;
    }
    [self.bdw_schemeHandler addObject:handler];
}

- (void)bdw_unregisterSchemeHandlerClass:(Class)handler {
    [self.bdw_schemeHandler removeObject:handler];
}

+ (void)bdw_hookHandlesURLScheme {
    IWKMetaClassSwizzle(self, @selector(handlesURLScheme:), @selector(bdw_handlesURLScheme:));
}

+ (BOOL)bdw_handlesURLScheme:(NSString *)name {
    if ([name isEqualToString:@"http"] ||
        [name isEqualToString:@"https"]) {
        return NO;
    }
    if (name.length == 0) {
        return NO;
    }
    return [self bdw_handlesURLScheme:name];
}

+ (BOOL)bdw_canHandleRedirection {
    Class cls = [self bdw_schemeTaskRedirectionImplClass];
    if (cls && [cls instancesRespondToSelector:[self bdw_schemeTaskRedirectionSelector]]) {
        return YES;
    }
    return NO;
}

+ (SEL)bdw_schemeTaskRedirectionSelector {
    // _didPerformRedirection:newRequest:
    NSString *sel = @"_didPerformRedirection:newRequest:";
    return NSSelectorFromString(sel);
}

+ (Class)bdw_schemeTaskRedirectionImplClass {
    // WKURLSchemeTaskImpl
    NSString *cls = @"WKURLSchemeTaskImpl";
    return NSClassFromString(cls);
}

@end

@implementation WKWebViewConfiguration(BDInterceptor)

- (void)bdw_installURLSchemeHandler
{
    if ([WKWebView bdw_canHandleRedirection]) {
        // 如果无法处理重定向，则不拦截WebView请求
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            [WKWebView bdw_hookHandlesURLScheme];
        });
        
        if (![objc_getAssociatedObject(self, _cmd) boolValue]) {
            if (![self urlSchemeHandlerForURLScheme:@"http"]) {
                BDWebURLSchemeHandler *httpHandler = [[BDWebURLSchemeHandler alloc] init];
                [self setURLSchemeHandler:httpHandler forURLScheme:@"http"];
            }
    
            if (![self urlSchemeHandlerForURLScheme:@"https"]) {
                BDWebURLSchemeHandler *httpsHandler = [[BDWebURLSchemeHandler alloc] init];
                [self setURLSchemeHandler:httpsHandler forURLScheme:@"https"];
            }
            objc_setAssociatedObject(self, _cmd, @(YES), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }
    }
}

@end
