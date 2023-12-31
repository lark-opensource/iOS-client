//
//  BDWebViewDelegateRegister.m
//  IESWebViewMonitor
//
//  Created by renpengcheng on 2019/8/11.
//

#import "BDWebViewDelegateRegister.h"
#import "IESLiveWebViewMonitor+Private.h"
#import "BDWebViewGeneralReporter.h"
#import "IESLiveMonitorUtils.h"
#import <objc/runtime.h>

#define hookWKWebViewTime(Time, ORIGSelStr, despStr) \
\
static void ieslive_wk##Time(id slf, SEL sel, WKWebView *wkWebView, WKNavigation *navigation) { \
    IESWebViewDelegateSafeCallORIG(slf, \
    IMP ORIGWK##Time = [IESLiveMonitorUtils getORIGImp:BDWebViewGeneralReporter.ORIGImpDic \
                                            cls:curCls \
                                        ORIGCls:&methodCls \
                                            sel:NSStringFromSelector(sel) \
                                         assert:NO]; \
    IESWebViewPrepareCallORIG \
    if (ORIGWK##Time) { \
        ((void(*)(id, SEL, WKWebView*, WKNavigation*))ORIGWK##Time)(slf, sel, wkWebView, navigation); \
    } \
    if (!lastCallClass) { \
        for (id block in insertedWK##Time##Blocks) { \
            ((void(^)(WKWebView *wkWebView, WKNavigation *navigation, NSError*))block)(wkWebView, navigation, nil); \
        } \
    } \
    ) \
} \
 \
static void hook_wk##Time(WKWebView *slf, SEL sel, id<WKNavigationDelegate>delegate) { \
    NSString *selStr = ORIGSelStr; \
    IMP ORIG##Time = nil; \
    Class delegateCls = [BDWebViewGeneralReporter getTargetDelegateClass:delegate]; \
    [IESLiveMonitorUtils addMethodToClass:delegateCls \
                                   selStr:selStr \
                                  funcPtr:(IMP*)&ORIG##Time \
                               hookMethod:(IMP)ieslive_wk##Time \
                                     desp:despStr]; \
    if (ORIG##Time) { \
        [BDWebViewGeneralReporter prepareORIGForClass:delegateCls]; \
        BDWebViewGeneralReporter.ORIGImpDic[delegateCls][selStr] = [NSValue valueWithPointer:ORIG##Time]; \
    } \
}

#define hookWKWebViewTimeWithError(Time, ORIGSelStr, despStr) \
\
static void ieslive_wk##Time(id slf, SEL sel, WKWebView *wkWebView, WKNavigation *navigation, NSError *error) { \
    IESWebViewDelegateSafeCallORIG(slf, \
    IMP ORIGWK##Time = [IESLiveMonitorUtils getORIGImp:BDWebViewGeneralReporter.ORIGImpDic \
                                            cls:curCls \
                                        ORIGCls:&methodCls \
                                            sel:NSStringFromSelector(sel) \
                                         assert:NO]; \
    IESWebViewPrepareCallORIG \
    if (ORIGWK##Time) { \
        ((void(*)(id, SEL, WKWebView*, WKNavigation*, NSError*))ORIGWK##Time)(slf, sel, wkWebView, navigation, error); \
    } \
    if (!lastCallClass) { \
        for (id block in insertedWK##Time##Blocks) { \
            ((void(^)(WKWebView *wkWebView, WKNavigation *navigation, NSError*))block)(wkWebView, navigation, error); \
        } \
    } \
    ) \
} \
\
static void hook_wk##Time(WKWebView *slf, SEL sel, id<WKNavigationDelegate>delegate) { \
    NSString *selStr = ORIGSelStr; \
    IMP ORIG##Time = nil; \
    Class delegateCls = [BDWebViewGeneralReporter getTargetDelegateClass:delegate]; \
    [IESLiveMonitorUtils addMethodToClass:delegateCls \
                                   selStr:selStr \
                                  funcPtr:(IMP*)&ORIG##Time \
                               hookMethod:(IMP)ieslive_wk##Time \
                                     desp:despStr]; \
    if (ORIG##Time) { \
        [BDWebViewGeneralReporter prepareORIGForClass:delegateCls]; \
        BDWebViewGeneralReporter.ORIGImpDic[delegateCls][selStr] = [NSValue valueWithPointer:ORIG##Time]; \
    } \
}

#pragma mark - navigation start

static NSMutableArray *insertedWKRequestStartBlocks = nil;
static NSMutableArray *insertedWKRedirectStartBlocks = nil;
static NSMutableArray *insertedWKNavigationStartBlocks = nil;
static NSMutableArray *insertedWKResponsePolicyBlocks = nil;

// WKWebView
//- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(null_unspecified WKNavigation *)navigation
hookWKWebViewTime(RequestStart, @"webView:didStartProvisionalNavigation:", "v32@0:8@16@24")

//- (void)webView:(WKWebView *)webView didCommitNavigation:(null_unspecified WKNavigation *)navigation
hookWKWebViewTime(NavigationStart, @"webView:didCommitNavigation:", "v32@0:8@16@24")

//- (void)webView:(WKWebView *)webView didReceiveServerRedirectForProvisionalNavigation:(null_unspecified WKNavigation *)navigation;
hookWKWebViewTime(RedirectStart, @"webView:didReceiveServerRedirectForProvisionalNavigation:", "v32@0:8@16@24")

// - (void)webView:(WKWebView *)webView decidePolicyForNavigationResponse:(WKNavigationResponse *)navigationResponse decisionHandler:(void (^)(WKNavigationResponsePolicy))decisionHandler; // v40@0:8@16@24@?32
//hookWKWebViewTimeWithResponse(ResponseStart, @"webView:decidePolicyForNavigationResponse:decisionHandler:", "v40@0:8@16@24@?32")

static void ieslive_wkResponsePolicy(id slf, SEL sel, WKWebView *wkWebView, WKNavigationResponse *response, void (^decisionHandler)(WKNavigationResponsePolicy)) {
    IESWebViewDelegateSafeCallORIG(slf,
    IMP ORIGWKResponseStart = [IESLiveMonitorUtils getORIGImp:BDWebViewGeneralReporter.ORIGImpDic
                                            cls:curCls
                                        ORIGCls:&methodCls
                                            sel:NSStringFromSelector(sel)];
    IESWebViewPrepareCallORIG
    if (ORIGWKResponseStart) {
        ((void(*)(id, SEL, WKWebView*, WKNavigationResponse*, void (^)(WKNavigationResponsePolicy)))ORIGWKResponseStart)(slf, sel, wkWebView, response, decisionHandler);
    } else {
        decisionHandler(WKNavigationResponsePolicyAllow);
    }
    if (!lastCallClass) {
        for (id block in insertedWKResponsePolicyBlocks) {
            ((void(^)(WKWebView *wkWebView, WKNavigationResponse *response, void (^)(WKNavigationResponsePolicy)))block)(wkWebView, response, decisionHandler);
        }
    }
    )
}

static void ieslive_wkSetNavigationDelegate(WKWebView *slf, SEL sel, id<WKNavigationDelegate>delegate) {
    IESWebViewSafeCallORIG(slf,
    IMP ORIGWKSetNavigationDelegate = [IESLiveMonitorUtils getORIGImp:BDWebViewGeneralReporter.ORIGImpDic
                                                                  cls:curCls
                                                              ORIGCls:&methodCls
                                                                  sel:NSStringFromSelector(sel)];
    IESWebViewPrepareCallORIG
    if (ORIGWKSetNavigationDelegate) {
        ((void(*)(WKWebView*, SEL, id<WKNavigationDelegate>))ORIGWKSetNavigationDelegate)(slf, sel, delegate);
    }
                           )
    delegate = slf.navigationDelegate;
    if (![slf lastCallClass] && delegate) {
        [BDWebViewGeneralReporter bdwm_hookClass:delegate error:nil];
        NSPointerArray *insertedIMPS = [BDWebViewGeneralReporter getDelegateIMPs:slf.class];
        for (NSInteger i = 0; i < insertedIMPS.count; ++i) {
            ((void(*)(WKWebView*, SEL, id<WKNavigationDelegate>))[(NSValue*)[insertedIMPS pointerAtIndex:i] pointerValue])(slf ,sel, delegate);
        }
    }
}

static void hook_wkResponsePolicy(WKWebView *slf, SEL sel, id<WKNavigationDelegate>delegate) {
    NSString *selStr = @"webView:decidePolicyForNavigationResponse:decisionHandler:";
    IMP ORIGResponseStart = nil;
    Class delegateCls = [BDWebViewGeneralReporter getTargetDelegateClass:delegate];
    [IESLiveMonitorUtils addMethodToClass:delegateCls
                                   selStr:selStr
                                  funcPtr:(IMP*)&ORIGResponseStart
                               hookMethod:(IMP)ieslive_wkResponsePolicy
                                     desp:"v40@0:8@16@24@?32"];
    if (ORIGResponseStart) {
        [BDWebViewGeneralReporter prepareORIGForClass:delegateCls];
        BDWebViewGeneralReporter.ORIGImpDic[delegateCls][selStr] = [NSValue valueWithPointer:ORIGResponseStart];
    }
}

#pragma mark - navigation end

static NSMutableArray *insertedWKNavigationFinishBlocks = nil;
static NSMutableArray *insertedWKRequestFailBlocks = nil;
static NSMutableArray *insertedWKNavigationFailBlocks = nil;

// WKWebView
// - (void)webView:(WKWebView *)webView didFinishNavigation:(null_unspecified WKNavigation *)navigation;
hookWKWebViewTime(NavigationFinish,  @"webView:didFinishNavigation:", "v32@0:8@16@24")

//- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(null_unspecified WKNavigation *)navigation withError:(NSError *)error
hookWKWebViewTimeWithError(RequestFail,  @"webView:didFailProvisionalNavigation:withError:";, "v40@0:8@16@24@32")

//- (void)webView:(WKWebView *)webView didFailNavigation:(null_unspecified WKNavigation *)navigation withError:(NSError *)error;
hookWKWebViewTimeWithError(NavigationFail, @"webView:didFailNavigation:withError:", "v40@0:8@16@24@32")

@implementation BDWebViewDelegateRegister

static NSMutableSet *monitoredClass = nil;
+ (void)startMonitorWithClasses:(NSSet *)classes
    onlyMonitorNavigationFinish:(BOOL)onlyMonitorNavigationFinish {
    if (!monitoredClass) {
        monitoredClass = [NSMutableSet set];
    }
    
    for (Class cls in classes) {
        if ([monitoredClass containsObject:cls]) {
            continue;
        }
        [monitoredClass addObject:cls];
        if ([cls isKindOfClass:object_getClass([WKWebView class])]) {
            [self insertIMP2WKSetNavigationDelegate:(IMP)hook_wkRequestFail forCls:cls];
            [self insertIMP2WKSetNavigationDelegate:(IMP)hook_wkRedirectStart forCls:cls];
            [self insertIMP2WKSetNavigationDelegate:(IMP)hook_wkNavigationFinish forCls:cls];
            [self insertIMP2WKSetNavigationDelegate:(IMP)hook_wkNavigationFail forCls:cls];
            [self insertIMP2WKSetNavigationDelegate:(IMP)hook_wkResponsePolicy forCls:cls];
            if (!onlyMonitorNavigationFinish) {
                [self insertIMP2WKSetNavigationDelegate:(IMP)hook_wkRequestStart forCls:cls];
                [self insertIMP2WKSetNavigationDelegate:(IMP)hook_wkNavigationStart forCls:cls];
            }
            
            [self registerWKBlock:^(WKWebView * _Nonnull wkWebView, WKNavigation * _Nonnull navigation, NSError * _Nonnull error) {
                [BDWebViewGeneralReporter updateMonitorOfWKWebView:wkWebView statusCode:nil error:nil withType:BDNavigationFinishType];
            } forTime:NavigationFinish forClass:cls];
            
            [self registerWKBlock:^(WKWebView * _Nonnull wkWebView, WKNavigation * _Nonnull navigation, NSError * _Nonnull error) {
                [BDWebViewGeneralReporter updateMonitorOfWKWebView:wkWebView statusCode:nil error:nil withType:BDRequestStartType];
            } forTime:RequestStart forClass:cls];
            
            [self registerWKBlock:^(WKWebView * _Nonnull wkWebView, WKNavigation * _Nonnull navigation, NSError * _Nonnull error) {
                [BDWebViewGeneralReporter updateMonitorOfWKWebView:wkWebView statusCode:nil error:error withType:BDRequestFailType];
            } forTime:RequestFail forClass:cls];
            
            [self registerWKBlock:^(WKWebView * _Nonnull wkWebView, WKNavigation * _Nonnull navigation, NSError * _Nonnull error) {
                [BDWebViewGeneralReporter updateMonitorOfWKWebView:wkWebView statusCode:nil error:nil withType:BDRedirectStartType];
            } forTime:RedirectStart forClass:cls];
            
            [self registerWKBlock:^(WKWebView * _Nonnull wkWebView, WKNavigation * _Nonnull navigation, NSError * _Nonnull error) {
                [BDWebViewGeneralReporter updateMonitorOfWKWebView:wkWebView statusCode:nil error:nil withType:BDNavigationStartType];
            } forTime:NavigationStart forClass:cls];
            
            [self registerWKBlock:^(WKWebView * _Nonnull wkWebView, WKNavigation * _Nonnull navigation, NSError * _Nonnull error) {
                [BDWebViewGeneralReporter updateMonitorOfWKWebView:wkWebView statusCode:nil error:error withType:BDNavigationFailType];
            } forTime:NavigationFail forClass:cls];
            
            [self registerWKBlock:^(WKWebView * _Nonnull wkWebView, WKNavigationResponse * _Nonnull navigationResponse, NSError * _Nonnull error) {
                NSInteger statusCode = 0;
                if ([navigationResponse.response isKindOfClass:[NSHTTPURLResponse class]]) {
                    statusCode = [(NSHTTPURLResponse*)navigationResponse.response statusCode];
                }
                [BDWebViewGeneralReporter updateMonitorOfWKWebView:wkWebView statusCode:[NSNumber numberWithInteger:statusCode] error:error withType:BDNavigationPreFinishType];
            } forTime:NavigationPreFinish forClass:cls];
            
        } else {
            // 运行时调用 (OtherWebView)
            Class pUITriggerClass = NSClassFromString(@"BDOtherWebViewCycleTrigger");
            SEL pUITriggerSel = NSSelectorFromString(@"startMonitorWithClass:monitorClass:onlyMonitorNavigationFinish:");
            if ([pUITriggerClass respondsToSelector:pUITriggerSel]) {
                Method pUITriggerMethod = class_getClassMethod(pUITriggerClass, pUITriggerSel);
                IMP pUITriggerImp = method_getImplementation(pUITriggerMethod);
                ((void(*)(Class, SEL, Class, NSMutableSet *, BOOL))pUITriggerImp)(pUITriggerClass, pUITriggerSel, cls, monitoredClass, onlyMonitorNavigationFinish);
            }
        }
    };
}

#pragma mark - public api
+ (void)insertIMP2WKSetNavigationDelegate:(IMP)imp forCls:(Class)cls {
    [BDWebViewGeneralReporter prepareForClass:cls];
    if (![BDWebViewGeneralReporter.insertedDelegateIMPs[cls] count]) {
        IMP ORIGSetNavigationDelegate = [IESLiveMonitorUtils hookMethod:cls sel:@selector(setNavigationDelegate:) imp:(IMP)ieslive_wkSetNavigationDelegate];
        if (ORIGSetNavigationDelegate) {
            BDWebViewGeneralReporter.ORIGImpDic[cls][@"setNavigationDelegate:"] = [NSValue valueWithPointer:ORIGSetNavigationDelegate];
        }
    }
    [BDWebViewGeneralReporter.insertedDelegateIMPs[cls] addPointer:(__bridge void * _Nullable)([NSValue valueWithPointer:imp])];
}

+ (void)registerWKBlock:(void(^)(WKWebView *wkWebView, id navigation, NSError *error))block
                forTime:(WebViewNavigationTime)time
               forClass:(Class)cls {
    void (^transFormBlock)(WKWebView*, id, NSError*) = ^(WKWebView *wkWebView, id navigation, NSError *error) {
        if ([wkWebView isKindOfClass:cls]) {
            block(wkWebView, navigation, error);
        }
    };
    switch (time) {
        case RequestStart:
            [self insertBlock2WKRequestStart:transFormBlock];
            break;
            
        case RequestFail:
            [self insertBlock2WKRequestFail:transFormBlock];
            break;
            
        case RedirectStart:
            [self insertBlock2WKRedirectStart:transFormBlock];
            break;
        
        case NavigationStart:
            [self insertBlock2WKNavigationStart:transFormBlock];
            break;
            
        case NavigationPreFinish:
            [self insertBlock2WKResponsePolicy:transFormBlock];
            break;
            
        case NavigationFinish:
            [self insertBlock2WKNavigationFinish:transFormBlock];
            break;
            
        case NavigationFail:
            [self insertBlock2WKNavigationFail:transFormBlock];
            break;
            
        default:
            break;
    }
}

+ (void)insertBlock2WKRequestStart:(void(^)(WKWebView *wkWebView, WKNavigation *navigation, NSError *error))block {
    if (!insertedWKRequestStartBlocks) {
        insertedWKRequestStartBlocks = [NSMutableArray array];
    }
    
    [insertedWKRequestStartBlocks addObject:block];
}

+ (void)insertBlock2WKRequestFail:(void(^)(WKWebView *wkWebView, WKNavigation *navigation, NSError *error))block {
    if (!insertedWKRequestFailBlocks) {
        insertedWKRequestFailBlocks = [NSMutableArray array];
    }
    
    [insertedWKRequestFailBlocks addObject:block];
}

+ (void)insertBlock2WKRedirectStart:(void(^)(WKWebView *wkWebView, WKNavigation *navigation, NSError *error))block {
    if (!insertedWKRedirectStartBlocks) {
        insertedWKRedirectStartBlocks = [NSMutableArray array];
    }
    
    [insertedWKRedirectStartBlocks addObject:block];
}

+ (void)insertBlock2WKNavigationStart:(void(^)(WKWebView *wkWebView, WKNavigation *navigation, NSError *error))block {
    if (!insertedWKNavigationStartBlocks) {
        insertedWKNavigationStartBlocks = [NSMutableArray array];
    }
    
    [insertedWKNavigationStartBlocks addObject:block];
}

+ (void)insertBlock2WKNavigationFinish:(void(^)(WKWebView *wkWebView, WKNavigation *navigation, NSError *error))block {
    if (!insertedWKNavigationFinishBlocks) {
        insertedWKNavigationFinishBlocks = [NSMutableArray array];
    }
    
    [insertedWKNavigationFinishBlocks addObject:block];
}

+ (void)insertBlock2WKNavigationFail:(void(^)(WKWebView *wkWebView, WKNavigation *navigation, NSError *error))block {
    if (!insertedWKNavigationFailBlocks) {
        insertedWKNavigationFailBlocks = [NSMutableArray array];
    }
    
    [insertedWKNavigationFailBlocks addObject:block];
}

+ (void)insertBlock2WKResponsePolicy:(void(^)(WKWebView *wkWebView, WKNavigationResponse *navigation, NSError *error))block {
    if (!insertedWKResponsePolicyBlocks) {
        insertedWKResponsePolicyBlocks = [NSMutableArray array];
    }
    
    [insertedWKResponsePolicyBlocks addObject:block];
}


@end

