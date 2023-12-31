//
//  BDWebView+BDWebViewMonitor.m
//  IESWebViewMonitor
//
//  Created by renpengcheng on 2019/10/28.
//

#import "BDWebView+BDWebViewMonitor.h"
#import "IESLiveWebViewMonitor.h"
#import "IESLiveWebViewMonitor+Private.h"
#import "IESLiveMonitorUtils.h"
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <objc/message.h>
#import "BDWebViewDelegateRegister.h"
#import "BDHybridMonitorDefines.h"
#import "IESLiveWebViewMonitorSettingModel.h"
#import "BDMonitorThreadManager.h"

NSString * const kWebviewInstanceConfigDisableMonitor = @"disable_monitor";
NSString * const kWebviewInstanceConfigDisableInjectBrowser = @"disable_inject_js_sdk";

@implementation WKWebView (BDWebViewMonitor)

#pragma mark - getter setter

- (BOOL)bdwm_disableMonitor {
    return [objc_getAssociatedObject(self, _cmd) boolValue];
}

- (void)setBdwm_disableMonitor:(BOOL)bdwm_disableMonitor {
    NSNumber *disable = @(bdwm_disableMonitor);
    objc_setAssociatedObject(self, @selector(bdwm_disableMonitor), disable, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSDictionary *)settings {
    NSDictionary *dict = objc_getAssociatedObject(self, _cmd);
    return dict;
}

- (void)setSettings:(NSDictionary *)settings {
    objc_setAssociatedObject(self, @selector(settings), settings, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)hasInjectedMonitor {
    return [objc_getAssociatedObject(self, _cmd) boolValue];
}

- (void)setHasInjectedMonitor:(BOOL)injected {
    NSNumber *num = @(injected);
    objc_setAssociatedObject(self, @selector(hasInjectedMonitor), num, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSTimeInterval)requestStartTime {
    return [objc_getAssociatedObject(self, _cmd) doubleValue];
}

- (void)setRequestStartTime:(NSTimeInterval)requestStartTime {
    NSNumber *num = @(requestStartTime);
    objc_setAssociatedObject(self, @selector(requestStartTime), num, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)isLiveWebView {
    return [objc_getAssociatedObject(self, _cmd) boolValue];
}

- (void)setIsLiveWebView:(BOOL)isLiveWebView {
    NSNumber *num = @(isLiveWebView);
    objc_setAssociatedObject(self, @selector(isLiveWebView), num, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSString *)bdwm_Bid {
    return self.performanceDic.bid;
}

- (void)setBdwm_Bid:(NSString *)bid {
    self.performanceDic.bid = bid;
}

- (NSString *)bdwm_Pid {
    return self.performanceDic.pid;
}

- (void)setBdwm_Pid:(NSString *)pid {
    self.performanceDic.pid = pid;
}

+ (NSHashTable *)bdwm_MonitorDelegates {
    return objc_getAssociatedObject(self, _cmd);
}

+ (void)setBdwm_MonitorDelegates:(NSHashTable *)monitorDelegates {
    objc_setAssociatedObject(self, @selector(bdwm_MonitorDelegates), monitorDelegates, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

+ (void)addDelegate:(id<IESWebViewMonitorDelegate>)delegate {
    if(!self.bdwm_MonitorDelegates) {
        self.bdwm_MonitorDelegates = [NSHashTable weakObjectsHashTable];
    }
    [self.bdwm_MonitorDelegates addObject:delegate];
}

#pragma mark - exchanged methods

/**

 ------ 注意！！！此处monitor交换的方法都需要用safeCallSelName:method:callOriMethod:的方式进行调用！！！因为需要规避同一继承链上的两个父子class同时被hook的情况----
 
 **/

- (instancetype)bdwm_initWithFrame:(CGRect)frame configuration:(WKWebViewConfiguration *)configuration {
    NSString *selName = @"initWithFrame:configuration:";
    
    Class lastCallClass = [self fetchLastCallClassForSelName:selName];
    Class methodCls = [self class];
    Class curCls = [self fetchLastCallClassForSelName:selName] ?: [self class];
    
    [IESLiveMonitorUtils getORIGImp:[IESLiveWebViewMonitor hook_ORIGDic] cls:curCls ORIGCls:&methodCls sel:selName];
    
    [self modifyLastCallClass:[methodCls superclass] forSelName:selName];

    NSString *ORIGSelStr = [kBDWMORIGPrefix stringByAppendingString:selName];
    SEL ORIGSel = NSSelectorFromString(ORIGSelStr);
    IMP ORIGImp = class_getMethodImplementation(lastCallClass ?: self.class, ORIGSel);
    
    WKWebView *instance;
    if (ORIGImp) {
        instance = ((WKWebView *(*)(WKWebView*,SEL,CGRect,WKWebViewConfiguration *))ORIGImp)(self, ORIGSel,frame,configuration);
    }
    
    SEL disableSel = NSSelectorFromString(@"bdwm_disableMonitor");
    if ([configuration respondsToSelector:disableSel]) {
        IMP disableImp = [configuration methodForSelector:disableSel];
        if (disableImp) {
            bool(*func)(id, SEL) = (void*)disableImp;
            [instance setBdwm_disableMonitor:func(configuration, disableSel)];
        }
    }
    
    if (self.settings == nil) {
        SEL settingsSel = NSSelectorFromString(@"settings");
        if ([configuration respondsToSelector:settingsSel]) {
            IMP settingsImp = [configuration methodForSelector:settingsSel];
            if (settingsImp) {
                NSDictionary*(*func)(id, SEL) = (void*)settingsImp;
                NSDictionary *settings = func(configuration, settingsSel);
                [instance setSettings:settings];
                [instance setBdwm_disableMonitor:
                 [settings[kWebviewInstanceConfigDisableMonitor] boolValue]
                ];
            }
        }
    }
    
    if (!instance.bdwm_disableMonitor) {
        instance.performanceDic.bdwm_webViewInitTs = [IESLiveMonitorUtils formatedTimeInterval];
    }
    
    curCls = nil;
    methodCls = nil;
    [self modifyLastCallClass:lastCallClass forSelName:selName];
    
    return instance;
}

- (void)bdwm_willMoveToSuperview:(nullable UIView *)newSuperview {
    NSString *selectorStr = @"willMoveToSuperview:";
    [self safeCallSelName:selectorStr method:^{
        if (!self.bdwm_disableMonitor) {
            if (newSuperview) { // add
                if (self.performanceDic.bdwm_attachTs <= 0) {
                    self.performanceDic.bdwm_attachTs = [IESLiveMonitorUtils formatedTimeInterval];
                }
            } else { // remove
                if (self.performanceDic.bdwm_detachTs <= 0) {
                    self.performanceDic.bdwm_detachTs = [IESLiveMonitorUtils formatedTimeInterval];
                }
            }
        }
    } callOriMethod:^(IMP ORIGImp,SEL ORIGSel) {
        ((void(*)(WKWebView*,SEL,UIView *))ORIGImp)(self, ORIGSel,newSuperview);
    }];
}

- (void)bdwm_willMoveToWindow:(nullable UIWindow *)newWindow {
    NSString *selectorStr = @"willMoveToWindow:";
    IESLiveWebViewPerformanceDictionary *perfDict = self.performanceDic;
    [self safeCallSelName:selectorStr method:^{
        if (perfDict) {
            if (newWindow) { // add
                // 这里改为通过 hasAttach 来判断的情况,是为了记录视图重用的情况.视图先remove了放到了复用池, 下次再attach到view 还能够触发attach的记录.原来的方式则不会更新
                if (!perfDict.bdwm_hasAttach) {
                    perfDict.bdwm_attachTs = [IESLiveMonitorUtils formatedTimeInterval];
                    perfDict.bdwm_detachTs = 0; // 重新添加到window之后, 之前detach的时间要重置
                    perfDict.bdwm_hasAttach = YES;
                }
            } else { // remove
                if (perfDict.bdwm_hasAttach) {
                    perfDict.bdwm_detachTs = [IESLiveMonitorUtils formatedTimeInterval];
                    perfDict.bdwm_hasAttach = NO;
                }
            }
        }
    } callOriMethod:^(IMP ORIGImp,SEL ORIGSel) {
        ((void(*)(WKWebView*,SEL,UIWindow *))ORIGImp)(self, ORIGSel,newWindow);
    }];
}

- (void)bdwm_removeFromSuperview {
    NSString *selectorStr = @"removeFromSuperview";
    [self safeCallSelName:selectorStr method:^{
        if (!self.bdwm_disableMonitor) {
            if (self.hasInjectedMonitor) {
                [self collectDataBeforeLeave];
            }
            for(NSObject<IESWebViewMonitorDelegate> *delegate in [[WKWebView class] bdwm_MonitorDelegates]) {
                if([delegate respondsToSelector:@selector(reportDataBeforeLeave:)]) {
                    [delegate reportDataBeforeLeave:self];
                }
            }
        }
    } callOriMethod:^(IMP ORIGImp,SEL ORIGSel) {
        ((void(*)(WKWebView*,SEL))ORIGImp)(self, ORIGSel);
    }];
}

- (void)bdwm_goBack {
    NSString *selectorStr = @"goBack";
    [self safeCallSelName:selectorStr method:^{
        // 这里担心有时序问题，触发goback之后是否还能拿到js的回调 @yangyi.peter
        if (!self.bdwm_disableMonitor) {
            if (self.hasInjectedMonitor) {
                [self collectDataBeforeLeave];
            }
            for(NSObject<IESWebViewMonitorDelegate> *delegate in [[WKWebView class] bdwm_MonitorDelegates]) {
                if([delegate respondsToSelector:@selector(reportDataBeforeLeave:)]) {
                    [delegate reportDataBeforeLeave:self];
                }
            }
        }
    } callOriMethod:^(IMP ORIGImp,SEL ORIGSel) {
        ((void(*)(WKWebView*,SEL))ORIGImp)(self, ORIGSel);
    }];
}

// 断开继承链的调用方式，避免出现monitor hook了继承链上的两个class，而继承链上的两个class出现调用super，而导致循环调用的问题。
- (void)safeCallSelName:(NSString *)selName method:(void(^)())method callOriMethod:(void(^)(IMP ORIGImp,SEL ORIGSel))oriMethod {
    Class lastCallClass = [self fetchLastCallClassForSelName:selName];
    Class methodCls = [self class];
    Class curCls = [self fetchLastCallClassForSelName:selName] ?: [self class];
    
    [IESLiveMonitorUtils getORIGImp:[IESLiveWebViewMonitor hook_ORIGDic] cls:curCls ORIGCls:&methodCls sel:selName assert:NO];
    
    if (!lastCallClass && method) {
        method();
    }
    
    [self modifyLastCallClass:[methodCls superclass] forSelName:selName];

    NSString *ORIGSelStr = [kBDWMORIGPrefix stringByAppendingString:selName];
    SEL ORIGSel = NSSelectorFromString(ORIGSelStr);
    IMP ORIGImp = class_getMethodImplementation(lastCallClass ?: self.class, ORIGSel);
    
    if (ORIGImp) {
        oriMethod(ORIGImp, ORIGSel);
    }
    
    curCls = nil;
    methodCls = nil;
    [self modifyLastCallClass:lastCallClass forSelName:selName];
}

- (WKNavigation*)bdwm_LoadRequest:(NSURLRequest *)request {
    return [self startLoadRequest:request isLive:NO];
}

// loadrequest比较特殊，当出现拦截的时候可能会有替换掉参数，然后重复调用自定的情况，特殊处理一下
- (WKNavigation*)startLoadRequest:(NSURLRequest *)request isLive:(BOOL)isLive {
    if (![self.lastParamsId isEqualToString:request.URL.absoluteString]) {
        [self setLastCallClass:nil];
    }
    
    Class lastCallClass = [self lastCallClass];
    Class methodCls = [self class];
    Class curCls = [self lastCallClass] ?: [self class];
    
    [IESLiveMonitorUtils getORIGImp:[IESLiveWebViewMonitor hook_ORIGDic] cls:curCls ORIGCls:&methodCls sel:@"loadRequest:"];
    
    if (!lastCallClass && !self.bdwm_disableMonitor) {
        [self recordLoadStartAndInstallJSSDK:request.URL.absoluteString isLive:isLive];
        if (self.lastParamsId
            && ![request.URL.absoluteString isEqualToString:self.lastParamsId]
            && !self.performanceDic.bdwm_isContainerReuse) {
            self.performanceDic.bdwm_isContainerReuse = YES;
        }
    }
    
    [self setLastCallClass:[methodCls superclass]];
    [self setLastParamsId:request.URL.absoluteString];
    NSString *ORIGSelStr = [kBDWMORIGPrefix stringByAppendingString:@"loadRequest:"];
    SEL ORIGSel = NSSelectorFromString(ORIGSelStr);
    IMP ORIGImp = class_getMethodImplementation(lastCallClass ?: self.class, ORIGSel);
    id result = nil;
    
    if (ORIGImp) {
        result = ((WKNavigation*(*)(WKWebView*,SEL,NSURLRequest*))ORIGImp)(self, ORIGSel, request);
    }
    
    curCls = nil;
    methodCls = nil;
    [self setLastCallClass:lastCallClass];

    return result;
}

- (void)recordLoadStartAndInstallJSSDK:(NSString *)urlString isLive:(BOOL)isLive {
    [self.performanceDic reportPVWithURLStr:urlString ?: @""];
    [self setRequestStartTime:[[NSDate date] timeIntervalSince1970] * 1000];
    self.isLiveWebView = isLive;
    self.performanceDic.isLive = isLive;
    self.performanceDic.bdwm_loadStartTS = [IESLiveMonitorUtils formatedTimeInterval];
    
    if (!self.hasInjectedMonitor) {
        [IESLiveWebViewMonitor installMonitorOnWKWebView:self];
        self.hasInjectedMonitor = YES;
    }
}

- (IESLiveWebViewPerformanceDictionary *)performanceDic {
    IESLiveWebViewPerformanceDictionary *dic = objc_getAssociatedObject(self, _cmd);

    if (self.bdwm_disableMonitor) {
        return nil;
    }
    
    if (!dic) {
        dic = [[IESLiveWebViewPerformanceDictionary alloc] initWithSettingModel:[IESLiveWebViewMonitorSettingModel settingModelForWebView:self.class] webView:self];
        objc_setAssociatedObject(self, _cmd, dic, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    
    return dic;
}

- (void)collectDataBeforeLeave {
    if (![IESLiveWebViewMonitorSettingModel switchStatusForKey:kBDWMWebCollectBackAction webViewClass:self.class]) {
        // 开关控制
        return;
    }
    
    if ([UIApplication sharedApplication].applicationState != UIApplicationStateActive) {
        // 非前台执行js疑似会卡顿，此时尝试不获取数据
        return;
    }
    
    NSMutableDictionary *nativeBaseDic = [[self.performanceDic getNativeCommonInfo] mutableCopy];
    [self evaluateJavaScript:@"if (window.SlardarHybrid){const performance = SlardarHybrid('getLatestPerformance');const resource = SlardarHybrid('getLatestResource');const url = location.href;JSON.stringify({performance:performance, resource:resource, url:url})}" completionHandler:^(id _Nullable result, NSError * _Nullable error) {
        
        // 2020.12.24
        //低版本，尤其是iOS11.4.1时会触发异常，原因是webview在白屏的时候会触发resetState清理js的callback，此时会调用callback，传入error对象，此处被清理的时候会释放self，同时又会调用到resetState，再次进入清理callback，这个时候同一个栈中，这个callback就野了，因此需要把此处的释放放到下一个runloop流程中，就不会触发野指针问题了。
        
        if ([IESLiveWebViewMonitorSettingModel switchStatusForKey:kBDWMWebCollectAsyncAction webViewClass:self.class]) {
            // 开启异步回捞
            [BDMonitorThreadManager dispatchForceAsyncOnMainThread:^{
                [self handleCollectResult:result error:error nativeBase:nativeBaseDic];
            }];
        } else {
            [self handleCollectResult:result error:error nativeBase:nativeBaseDic];
        }
    }];
}

- (void)handleCollectResult:(id)result error:(NSError *)error nativeBase:(NSMutableDictionary *)nativeBaseDic {
    if (!error && result && [result isKindOfClass:[NSString class]]) {
        NSData *data = [result dataUsingEncoding:NSUTF8StringEncoding];
        if (data) {
            NSDictionary* dic = (NSDictionary*)[NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
            if ([dic isKindOfClass:[NSDictionary class]]) {
                nativeBaseDic[kBDWebViewMonitorURL] = dic[kBDWebViewMonitorURL] ?: nativeBaseDic[kBDWebViewMonitorURL];
                NSDictionary *performanceDic = dic[@"performance"];
                if ([performanceDic isKindOfClass:[NSDictionary class]]) {
                    [self.performanceDic coverWithDic:performanceDic nativeCommon:nativeBaseDic];
                }
                NSDictionary *resourceDic = dic[@"resource"];
                if ([resourceDic isKindOfClass:[NSDictionary class]]) {
                    [self.performanceDic reportDirectlyWithDic:resourceDic nativeCommon:nativeBaseDic];
                }
            }
        }
    } else {
        // 哪怕失败了也需要把nativeBase给带上去
        if ([nativeBaseDic isKindOfClass:[NSDictionary class]]) {
            [self.performanceDic coverWithDic:@{} nativeCommon:nativeBaseDic];
        }
    }
}

- (void)resetPerfExts {
    self.performanceDic.bdwm_isPreload = 0;
    self.performanceDic.bdwm_isPrefetch = 0;
    self.performanceDic.bdwm_isOffline = 0;
}

#pragma mark - progress
static IMP ORIGWKRenderingProgressDidChange = nil;
static void ieslive_wkRenderingProgressDidChange(id slf, SEL sel, WKWebView *webView, int progressEvents) {
    if (ORIGWKRenderingProgressDidChange) {
        ((void(*)(id, SEL, WKWebView* ,int))ORIGWKRenderingProgressDidChange)(slf, sel, webView, progressEvents);
    }
    
    // bdwm_disableMonitor时hasInjectedMonitor自然是false，所以不用判断
    if (webView.hasInjectedMonitor) {
        NSArray *events = @[@"first_layout", @"first_non_empty_layout", @"first_paint_significant_area", @"reach_tree_threshold", @"first_layout_after_suppressed", @"first_paint_after_suppressed", @"first_paint", @"render_significant", @"first_meaningful_paint"];
        long now = [IESLiveMonitorUtils formatedTimeInterval];
        NSUInteger size = [events count];
        
        for (NSInteger i = 0; i < size; ++i) {
            NSInteger mask = 1 << i;
            
            if ((progressEvents & mask) > 0) {
                [webView.performanceDic coverClientParams:@{events[i]: @(now)}];
                
                if (i == 6) { //_WKRenderingProgressEventFirstPaint
                    [webView evaluateJavaScript:[NSString stringWithFormat:@"if(window.bdPerformance && window.bdPerformance.setFirstPaintTiming){window.bdPerformance.setFirstPaintTiming(%ld)}", now] completionHandler:nil];
                } else if (i == 8) { // _WKRenderingProgressEventFirstMeaningfulPaint
                    [webView evaluateJavaScript:[NSString stringWithFormat:@"if(window.bdPerformance && window.bdPerformance.setFirstMeaningfulPaintTiming){window.bdPerformance.setFirstMeaningfulPaintTiming(%ld)}", now] completionHandler:nil];
                }
            }
        }
    }
}

static void bdwm_forward_wkRenderingProgressDidChange(id slf, SEL sel, WKWebView *webView, int progressEvents) {
    if ([IESLiveMonitorUtils isSpecifiedClass:[slf class] confirmsToSel:@selector(forwardInvocation:)]) {
        NSString *selStr = [NSString stringWithFormat:@"%@%@%@", @"_webView:ren", @"deringProgress", @"DidChange:"];
        SEL sel = NSSelectorFromString(selStr);
        NSMethodSignature *signature = [slf methodSignatureForSelector:sel];
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
        invocation.selector = sel;
        if ([signature numberOfArguments] == 4) { //为了避免获取的是_objc_msgForward对象，因此需要判断一下参数个数，为4的时候才是正常的回调。
            [invocation setArgument:&webView atIndex:2];
            [invocation setArgument:&progressEvents atIndex:3];
        }
        [slf forwardInvocation:invocation];
    } else {
//        NSCAssert(NO, @"proxy should overide forwardInvocation to cover all navigation delegate methods");
    }
}

static void monitorRendering(WKWebView *slf, SEL sel, id<WKNavigationDelegate>delegate) {
    NSString *progressSelStr = [NSString stringWithFormat:@"%@%@%@",@"_webView:ren",@"deringProgress",@"DidChange:"];
    SEL progressSel = NSSelectorFromString(progressSelStr); //@"_webView:renderingProgressDidChange:"
    
    IMP imp = class_getMethodImplementation([delegate class], progressSel);
    const char*description = "v28@0:8@16i24";
    if (!imp || imp == _objc_msgForward) {
        class_addMethod([delegate class], progressSel, bdwm_forward_wkRenderingProgressDidChange, description);
    }
    
    [IESLiveMonitorUtils addMethodToClass:[delegate class]
                                   selStr: progressSelStr
                                  funcPtr:(IMP*)&ORIGWKRenderingProgressDidChange
                               hookMethod:(IMP)ieslive_wkRenderingProgressDidChange
                                     desp:description];
}

+ (void)hookProgressMethod {
    [BDWebViewDelegateRegister insertIMP2WKSetNavigationDelegate:(IMP)monitorRendering forCls:self.class];
}

- (void)addRenderEventListener {
    NSString *selStr = [NSString stringWithFormat:@"%@%@%@", @"_setOb", @"servedRendering", @"ProgressEvents:"];
    SEL sel = NSSelectorFromString(selStr);
    IMP imp = [[self class] instanceMethodForSelector:sel];
    NSMethodSignature *signature = [self methodSignatureForSelector:sel];
    if (signature && imp) {
        ((void(*)(WKWebView*, SEL, int))imp)(self, sel, 0xffff);
    }
}

@end

