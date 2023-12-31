//
//  BDWebInterceptor.m
//  BDWebKit
//
//  Created by li keliang on 2020/3/13.
//

#import "BDWebInterceptor.h"
#import <BDWebCore/WKWebView+Plugins.h>
#import "BDWebInterceptorPluginObject.h"
#import "BDWebURLSchemeTask.h"
#import "BDWebURLSchemeHandler.h"
#import "BDWebDefaultURLSchemaHandler.h"
#import "BDWebDefaultRequestDecorator.h"
#import "WKWebView+BDInterceptor.h"

#import <objc/runtime.h>
#import <BDWebCore/IWKUtils.h>
#import <BDTrackerProtocol/BDTrackerProtocol.h>
#import <ByteDanceKit/BTDMacros.h>

#import <BDWebKit/BDWebKitSettingsManger.h>

@implementation WKWebViewConfiguration(BDWebInterceptor)

- (BOOL)bdw_enableInterceptor
{
    return [objc_getAssociatedObject(self, _cmd) boolValue];
}

- (void)setBdw_enableInterceptor:(BOOL)bdw_enableInterceptor
{
    objc_setAssociatedObject(self, @selector(bdw_enableInterceptor), @(bdw_enableInterceptor), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)bdw_skipFalconWaitFix
{
    return [objc_getAssociatedObject(self, _cmd) boolValue];
}

- (void)setBdw_skipFalconWaitFix:(BOOL)bdw_skipFalconWaitFix
{
    objc_setAssociatedObject(self, @selector(bdw_skipFalconWaitFix), @(bdw_skipFalconWaitFix), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end

@implementation WKWebView (BDWebInterceptor)

- (id<BDWebInterceptorMonitor>)bdw_interceptorMonitor
{
    id(^blk)(void) = objc_getAssociatedObject(self, _cmd);
    return blk ? blk() : nil;
}

- (void)setBdw_interceptorMonitor:(id<BDWebInterceptorMonitor>)bdw_interceptorMonitor
{
    __weak id<BDWebInterceptorMonitor> weakMonitor = bdw_interceptorMonitor;
    objc_setAssociatedObject(self, @selector(bdw_interceptorMonitor), (id)^(void){ return weakMonitor; } , OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (id<BDWebInterceptorMonitor>)bdw_interceptorHandler
{
    id(^blk)(void) = objc_getAssociatedObject(self, _cmd);
    return blk ? blk() : nil;
}

- (void)setBdw_interceptorHandler:(id<BDWebInterceptorHandler>)bdw_interceptorHandler {
    __weak id<BDWebInterceptorHandler> weakMonitor = bdw_interceptorHandler;
    objc_setAssociatedObject(self, @selector(bdw_interceptorHandler), (id)^(void){ return weakMonitor; } , OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end

@interface BDWebInterceptor()

@property (nonatomic) NSMutableArray<Class<BDWebURLSchemeTaskHandler>> *schemaHandlers;
@property (nonatomic) NSMutableArray<Class<BDWebRequestDecorator>> *requestDecorators;
@property (nonatomic) NSMutableArray<Class<BDWebRequestFilter>> *requestFilters;

@end

@implementation BDWebInterceptor

+ (instancetype)sharedInstance {
    static dispatch_once_t onceToken;
    static BDWebInterceptor *instance = nil;
    dispatch_once(&onceToken,^{
        instance = [[super allocWithZone:NULL] init];
    });
    return instance;
}

+ (id)allocWithZone:(struct _NSZone *)zone{
    return [self sharedInstance];
}

static NSHashTable * _globalInterceptorMonitors = nil;
+ (NSHashTable *)bdw_globalInterceptorMonitors
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken,^{
        _globalInterceptorMonitors = [NSHashTable weakObjectsHashTable];
    });
    return _globalInterceptorMonitors;
}

+ (void)addGlobalInterceptorMonitor:(id<BDWebInterceptorMonitor>)interceptorMonitor
{
    btd_dispatch_async_on_main_queue(^{
        [BDWebInterceptor.bdw_globalInterceptorMonitors addObject:interceptorMonitor];
    });
}

+ (void)removeGlobalInterceptorMonitor:(id<BDWebInterceptorMonitor>)interceptorMonitor
{
    btd_dispatch_async_on_main_queue(^{
        [BDWebInterceptor.bdw_globalInterceptorMonitors removeObject:interceptorMonitor];
    });
}

static NSHashTable * _globalRequestFilters = nil;
+ (NSHashTable *)bdw_globalRequestFilters
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken,^{
        _globalRequestFilters = [NSHashTable weakObjectsHashTable];
    });
    return _globalRequestFilters;
}

+ (void)addGlobalRequestFilter:(id<BDWebRequestFilter>)requestFilter
{
    @synchronized (self) {
        [BDWebInterceptor.bdw_globalRequestFilters addObject:requestFilter];
    }
}

+ (void)removeGlobalRequestFilter:(id<BDWebRequestFilter>)requestFilter
{
    @synchronized (self) {
        [BDWebInterceptor.bdw_globalRequestFilters removeObject:requestFilter];
    }
}

+ (BOOL)willBlockRequest:(NSURLRequest *)request
{
    @synchronized (self) {
        BOOL willBlock = NO;
        for (NSObject<BDWebRequestFilter> *filter in BDWebInterceptor.bdw_globalRequestFilters) {
            if ([filter respondsToSelector:@selector(bdw_willBlockRequest:)]) {
                willBlock = [filter bdw_willBlockRequest:request];
                if (willBlock) {
                    return YES;
                }
            }
        }
        return NO;
    }
}

+ (NSURLRequest *)willDecorateRequest:(NSURLRequest *)request
{
    __block NSURLRequest *finalRequest = [request mutableCopy];
    NSArray<Class<BDWebRequestDecorator>> *decorators = [[BDWebInterceptor sharedInstance] bdw_requestDecorators];
    if (decorators.count > 0) {
        [decorators enumerateObjectsUsingBlock:^(Class _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            id<BDWebRequestDecorator> decorator = (id<BDWebRequestDecorator>)[[obj alloc] init];
            finalRequest = [decorator bdw_decorateRequest:finalRequest];
        }];
    }
    return finalRequest;
}

+ (void)willDecorateURLProtocolTask:(id<BDWebURLProtocolTask>)urlProtocolTask
{
    NSArray<Class<BDWebRequestDecorator>> *decorators = [[BDWebInterceptor sharedInstance] bdw_requestDecorators];
    if (decorators.count > 0) {
        [decorators enumerateObjectsUsingBlock:^(Class _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            id<BDWebRequestDecorator> decorator = (id<BDWebRequestDecorator>)[[obj alloc] init];
            SEL selector = @selector(bdw_decorateURLProtocolTask:);
            if ([decorator respondsToSelector:(selector)]) {
                [decorator bdw_decorateURLProtocolTask:urlProtocolTask];
            }
        }];
    }
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _schemaHandlers = [[NSMutableArray alloc] initWithObjects:BDWebDefaultURLSchemaHandler.class, nil];
        _requestDecorators = [[NSMutableArray alloc] initWithObjects:BDWebDefaultRequestDecorator.class, nil];
    }
    return self;
}

- (void)registerCustomURLSchemaHandler:(Class<BDWebURLSchemeTaskHandler>)schemaHandler
{
    [self p_setupInterceptorIfNeeded];
    @synchronized (self.schemaHandlers) {
        if (![self.schemaHandlers containsObject:schemaHandler]) {
            [self.schemaHandlers insertObject:schemaHandler atIndex:0];
        }
    }
}

- (Class<BDWebURLSchemeTaskHandler>)schemaHandlerClassWithURLRequest:(NSURLRequest *)request webview:(WKWebView *)webview
{
    NSArray<Class<BDWebURLSchemeTaskHandler>> *clsArray = webview.bdw_schemeHandlerCls;
    // 如果在useTTNetForFalconWhiteList切TTNet白名单中，则在BDWebDefaultURLSchemaHandler（如果存在的话）前添加BDWebViewSchemeTaskHandler
    clsArray = [self processSchemeHandlers:clsArray withWebview:webview];
    __block Class<BDWebURLSchemeTaskHandler> schemaHandlerClass = nil;
    
    // check clsArray first
    if (clsArray.count > 0) {
        [clsArray enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(Class<BDWebURLSchemeTaskHandler> _Nonnull handlerCls, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([handlerCls respondsToSelector:@selector(bdw_canHandleRequest:webview:)]) {
                if ([handlerCls bdw_canHandleRequest:request webview:webview]) {
                    schemaHandlerClass = handlerCls;
                    *stop = YES;
                }
            } else if ([handlerCls bdw_canHandleRequest:request]) {
                schemaHandlerClass = handlerCls;
                *stop = YES;
            }
        }];
    }
    
    if (schemaHandlerClass != nil) {
        return schemaHandlerClass;
    }
    
    @synchronized (self.schemaHandlers) {
        // 如果在useTTNetForFalconWhiteList切TTNet白名单中，则在BDWebDefaultURLSchemaHandler前添加BDWebViewSchemeTaskHandler
        NSArray *schemaHandlers = clsArray = [self processSchemeHandlers:self.schemaHandlers withWebview:webview];
        [schemaHandlers enumerateObjectsUsingBlock:^(Class<BDWebURLSchemeTaskHandler>  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj respondsToSelector:@selector(bdw_canHandleRequest:webview:)]) {
                if ([obj bdw_canHandleRequest:request webview:webview]) {
                    schemaHandlerClass = obj;
                    *stop = YES;
                    return;
                }
            } else if ([obj bdw_canHandleRequest:request]) {
                schemaHandlerClass = obj;
                *stop = YES;
            }
        }];
        return schemaHandlerClass;
    }
}

// 如果在useTTNetForFalconWhiteList切TTNet白名单中，则在BDWebDefaultURLSchemaHandler（如果存在的话）前添加BDWebViewSchemeTaskHandler
- (NSArray *)processSchemeHandlers:(NSArray<Class<BDWebURLSchemeTaskHandler>> *)clsArray withWebview:(WKWebView *)webview
{
    NSArray<NSString *> *useTTNetWhiteList = [BDWebKitSettingsManger useTTNetForFalconWhiteList];
    NSString *url = webview.URL.absoluteString;
    __block BOOL useTTNet = NO;
    __block BOOL isInAllowList = NO;
    if (useTTNetWhiteList && useTTNetWhiteList.count > 0) {
        [useTTNetWhiteList enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([url containsString:obj]) {
                isInAllowList = YES;
                *stop = YES;
            }
        }];
        if (isInAllowList) {
            if ([clsArray containsObject:BDWebDefaultURLSchemaHandler.class] && ![clsArray containsObject:NSClassFromString(@"BDWebViewSchemeTaskHandler")]) {
                useTTNet = YES;
            }
        }
        if (useTTNet) {
            NSMutableArray *result = [[NSMutableArray alloc] initWithArray:clsArray];
            NSInteger index = [result indexOfObject:BDWebDefaultURLSchemaHandler.class];
            [result insertObject:NSClassFromString(@"BDWebViewSchemeTaskHandler") atIndex:index];
            return [result copy];
        }
    }
    return clsArray;
}

- (void)registerCustomRequestDecorator:(Class<BDWebRequestDecorator>)requestDecorator
{
    [self p_setupInterceptorIfNeeded];
    @synchronized (self.requestDecorators) {
        if (![self.requestDecorators containsObject:requestDecorator]) {
            [self.requestDecorators insertObject:requestDecorator atIndex:0];
        }
    }
}

- (void)removeCustomRequestDecorator:(Class<BDWebRequestDecorator>)requestDecorator
{
    @synchronized (self.requestDecorators) {
        if ([self.requestDecorators containsObject:requestDecorator]) {
            [self.requestDecorators removeObject:requestDecorator];
        }
    }
}


- (NSArray<Class<BDWebRequestDecorator>> *)bdw_requestDecorators
{
    NSArray<Class<BDWebRequestDecorator>> *decorators = nil;
    @synchronized (self.requestDecorators) {
        decorators = [self.requestDecorators copy];
    }
    return decorators;
}

- (void)setupClassPluginForWebInterceptor
{
    [self p_setupInterceptorIfNeeded];
}

#pragma mark - Private Methods

- (void)p_setupInterceptorIfNeeded
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [WKWebView IWK_loadPlugin:[BDWebInterceptorPluginObject new]];
    });
}

@end
