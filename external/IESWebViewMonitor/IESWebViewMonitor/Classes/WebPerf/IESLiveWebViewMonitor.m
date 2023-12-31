//
//  IESLiveWebViewMonitor.m
//
//  Created by renpengcheng on 2019/5/13.
//  Copyright © 2019 renpengcheng. All rights reserved.
//

#import "IESLiveWebViewMonitor.h"
#import "IESLiveMonitorUtils.h"
#import "IESLiveWebViewMonitor+Private.h"
#import "IESLiveWebViewPerformanceDictionary.h"
#import "IESLiveWebViewNavigationMonitor.h"
#import "IESLiveWebViewOfflineMonitor.h"
#import "IESLiveWebViewMonitorSettingModel.h"
#import "IESLiveDefaultSettingModel.h"
#import "BDWebView+BDWebViewMonitor.h"
#import <WebKit/WebKit.h>
#import <objc/runtime.h>
#import "BDWebViewMonitorFileProvider.h"
#import "BDApplicationStat.h"
#import "BDMonitorThreadManager.h"
#import "BDHybridCoreReporter.h"
#import "BDHybridMonitorDefines.h"

static NSMutableDictionary<Class, NSMutableDictionary<NSString*, NSValue*>*> *ORIGImpDic = nil;
static NSMutableDictionary<Class, Class> *monitorDict = nil;

static BOOL pLiveMonitorIsRunning = NO;
static BOOL pMonitorIsRunning = NO;
static IMP pWKWebViewLiveLoadRequestIMP = nil;
static IMP pWKWebViewLoadRequestIMP = nil;
static IMP pWKWebViewRemoveFromSuperviewIMP = nil;
static IMP pWKWebViewGoBackIMP = nil;
static IMP pWKWebViewInitIMP = nil;
static IMP pWKWebViewWillMoveWindowIMP = nil;

NSString *const IESLiveWebViewClassesKey = @"classes";
NSString *const IESLiveWebViewConfigKey = @"config";

static void prepareDicForClass(Class cls) {
    if (![ORIGImpDic objectForKey:cls]) {
        ORIGImpDic[(id<NSCopying>)cls] = [[NSMutableDictionary alloc] init];
    }
}

static void unHookMethod(Class cls, SEL sel) {
    IMP ORIGImp = [ORIGImpDic[cls][NSStringFromSelector(sel)] pointerValue];
    if (ORIGImp) {
        [IESLiveMonitorUtils unHookMethod:cls sel:sel imp:ORIGImp];
        [ORIGImpDic[cls] removeObjectForKey:NSStringFromSelector(sel)];
        if (!ORIGImpDic[cls].count) {
            [ORIGImpDic removeObjectForKey:cls];
        }
    }
}

@interface IESLiveWebViewMonitor ()<WKScriptMessageHandler>

@end

@implementation IESLiveWebViewMonitor

+ (void)setStopUpdateBrowser:(BOOL)stop {
    [[NSUserDefaults standardUserDefaults] setBool:stop forKey:kBDWMShouldStopUpdateJS];
}

+ (NSString *)emptyScriptForWebView:(id)webView {
    return @"window.iesiOSEmptyWebViewInjection = {}";
}

+ (NSString *)slardarConfigForWebView:(id)webView {
    IESLiveWebViewPerformanceDictionary *performanceDic = [(WKWebView *)webView performanceDic];
    IESLiveWebViewMonitorSettingModel *model = [IESLiveWebViewMonitorSettingModel settingModelForWebView:[webView class]];
    model.pid = performanceDic.pid;
    model.bid = performanceDic.bid;
    return [model jsonDescription];
}

#pragma mark - PiperContextInjection
- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
    if ([message.name isEqualToString:@"iesLiveWebViewLog"]) {
        //        NSLog(@"%@", message.body);
    } else if ([message.name isEqualToString:@"iesLiveCalculateInitTime"]) {
        [self p_handleMonitorCalculateInitTime:message];
    } else if ([message.name isEqualToString:@"iesLiveTimingMonitorCover"]) {
        [self p_handleMonitorCoverMessage:message];
    } else if ([message.name isEqualToString:@"iesLiveTimingMonitorAccumulate"]) {
        [message.webView.performanceDic accumulateWithDic:message.body];
    } else if ([message.name isEqualToString:@"iesLiveTimingMonitorReportDirectly"]) {
        [message.webView.performanceDic reportDirectlyWithDic:message.body];
    } else if ([message.name isEqualToString:@"iesLiveTimingMonitorAverage"]) {
        [message.webView.performanceDic mergeDicToCalAverage:message.body];
    } else if ([message.name isEqualToString:@"iesLiveTimingMonitorReportCustom"]) {
        [message.webView.performanceDic reportCustomWithDic:message.body webView:message.webView];
    } else if ([message.name isEqualToString:@"iesLiveTimingMonitorReportStage"]) {
        [message.webView.performanceDic reportPVWithStageDic:message.body];
    } else if ([message.name isEqualToString:@"iesLiveTimingMonitorInjectJsTime"]) {
        [self p_handleInjectJSTimeMessage:message];
    } else if ([message.name isEqualToString:@"iesLiveTimingMonitorBatch"]) {
        [message.webView.performanceDic reportBatchWithDic:message.body webView:message.webView];
    }
}

+ (instancetype)sharedMonitor {
    static IESLiveWebViewMonitor *s;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        s = [[IESLiveWebViewMonitor alloc] init];
    });
    return s;
}

#pragma mark - js bridge
- (void)p_handleInjectJSTimeMessage:(WKScriptMessage *)message {
    if ([message.frameInfo isMainFrame]) {
        NSMutableDictionary *mutableBody = [message.body mutableCopy];
        [message.webView.performanceDic coverClientParams:mutableBody];
    }
}

- (void)p_handleMonitorCoverMessage:(WKScriptMessage *)message {
    NSMutableDictionary *nativeBaseDic = [[message.webView.performanceDic getNativeCommonInfo] mutableCopy];
    [message.webView.performanceDic coverWithDic:message.body nativeCommon:nativeBaseDic];
    
    if (message.webView.performanceDic.bdwm_reportTime == BDWebViewMonitorPerfReportTime_JSPerfReady) {
        NSDictionary *coverDic = (NSDictionary *)message.body;
        if ([coverDic isKindOfClass:NSDictionary.class] && [IESLiveWebViewPerformanceDictionary canReportInCover:coverDic[@"jsInfo"]]) {
            [message.webView.performanceDic reportCurrentNavigationPagePerf];
        }
    }
}

- (void)p_handleMonitorCalculateInitTime:(WKScriptMessage *)message {
    if (message.webView.requestStartTime > 0) {
        NSInteger nativeDuration = (NSInteger)([[NSDate date] timeIntervalSince1970] * 1000 - message.webView.requestStartTime);
        NSMutableDictionary *mutableBody = [message.body mutableCopy];
        NSInteger jsDuration = [mutableBody[@"duration"] integerValue];
        [mutableBody setObject:@(nativeDuration - jsDuration) forKey:@"init_time"];
        [mutableBody removeObjectForKey:@"duration"];
        [message.webView.performanceDic coverClientParams:mutableBody];
    }
}

#pragma mark - public api

+ (void)setUpGurdEnvWithAppId:(NSString *)appId appVersion:(NSString *)appVersion cacheRootDirectory:(NSString *)directory deviceId:(NSString *)deviceId {
    [BDWebViewMonitorFileProvider setUpGurdEnvWithAppId:appId appVersion:appVersion cacheRootDirectory:directory deviceId:deviceId];
}

+ (void)startMonitor {
    IESLiveDefaultSettingModel *settingModel = [IESLiveDefaultSettingModel defaultModel];
    NSMutableSet *classSet = [NSMutableSet set];
    if (NSClassFromString(@"_BDInternalWKWebView")) {
        [classSet addObject:NSClassFromString(@"_BDInternalWKWebView")];
    }
    
    [self startWithClasses:classSet settings:[settingModel toDic]];
}

+ (void)startWithClassNames:(NSSet<NSString *>*)classNames
               settingModel:(id<IESMonitorSettingModelProtocol>)settingModel {
    if (classNames.count<=0) {
        return;
    }
    NSMutableSet *classes = [[NSMutableSet alloc] init];
    [classNames enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, BOOL * _Nonnull stop) {
        if (obj.length >0) {
            Class class = NSClassFromString(obj);
            if (class) {
                [classes addObject:class];
            }
        }
    }];
    [self startWithClasses:classes settingModel:settingModel];
}

+ (void)startWithClasses:(NSSet<Class>*)classes
            settingModel:(id<IESMonitorSettingModelProtocol>)settingModel {
    [self startWithClasses:classes settings:[settingModel toDic]];
}

+ (void)startWithClasses:(NSSet<Class>*)classes
                settings:(NSDictionary*)settings {
    pMonitorIsRunning = YES;
    [self p_startWithClasses:classes
                    settings:settings
                      isLive:NO];
}

+ (NSDictionary*)dicWithDefaultValue:(NSDictionary*)onlineSettings {
    NSMutableDictionary *mutableDic = [onlineSettings ?: @{} mutableCopy];
    mutableDic[kBDWMOfflineMonitor] = onlineSettings[kBDWMOfflineMonitor] ?: @(YES);
    mutableDic[kBDWMInjectBrowser] = onlineSettings[kBDWMInjectBrowser] ?: @(YES);
    return [mutableDic copy];
}

+ (void)p_startWithClasses:(NSSet<Class>*)monitorClasses
                  settings:(nullable NSDictionary *)settings
                    isLive:(BOOL)isLive {
    // 由入口统一把控class
    NSMutableSet *classes = [NSMutableSet set];
    for (Class cls in monitorClasses) {
        if (class_isMetaClass(object_getClass(cls))) {
            [classes addObject:cls];
        }
    }
    settings = [self dicWithDefaultValue:settings];
    
    NSSet<Class> *filterClasses = [IESLiveWebViewMonitorSettingModel filterStartedClass:[classes copy]];
    [IESLiveWebViewMonitorSettingModel setConfig:settings forClasses:filterClasses];
    
    [BDApplicationStat startCollectUpdatedClick];
    
    [self hookWebViewMethodsWithClasses:filterClasses
                               settings:settings
                                 isLive:isLive];
    
    [self hookProgressWithClasses:filterClasses
                         settings:settings
                           isLive:isLive];
    
    [IESLiveWebViewOfflineMonitor startMonitorWithClasses:filterClasses
                                                  setting:settings];
   
    // 新增检测工具时，记得通过bdwm_disableMonitor判断「实例」是否需要忽略监控逻辑
    [IESLiveWebViewMonitor startMonitorItem:@"IESLiveWebViewNavigationMonitor"
                                    classes:filterClasses
                                    setting:settings];
    
    [IESLiveWebViewMonitor startMonitorItem:@"BDWebViewMonitorFileProvider"
                                    classes:filterClasses
                                    setting:settings];
    
    [IESLiveWebViewMonitor startMonitorItem:@"BDWebViewBlankDetectListener"
                                    classes:filterClasses
                                    setting:settings];

    [IESLiveWebViewMonitor startMonitorItem:@"BDWebViewJSBMonitor"
                                    classes:filterClasses
                                    setting:settings];
    [IESLiveWebViewMonitor startMonitorItem:@"BDWebViewFalconMonitor"
                                    classes:filterClasses
                                    setting:settings];
}

+ (BOOL)startMonitorItem:(NSString *)monitorName classes:(NSSet *)classes setting:(NSDictionary *)setting {
    Class monitorClass = NSClassFromString(monitorName);
    if (monitorClass && [monitorClass respondsToSelector:@selector(startMonitorWithClasses:setting:)]) {
        [monitorClass startMonitorWithClasses:classes setting:setting];
    }
    return NO;
}

+ (void)hookWebViewMethodsWithClasses:(NSSet<Class>*)classes
                             settings:(nullable NSDictionary *)settings
                               isLive:(BOOL)isLive {
    // 8系统不监控，因为不存在performance
    if ([UIDevice currentDevice].systemVersion.floatValue <= 8.9999f
        || [settings[kBDWMOnlyMonitorOffline] boolValue]) {
        return;
    }
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        ORIGImpDic = [NSMutableDictionary dictionary];
        pWKWebViewLoadRequestIMP = class_getMethodImplementation([WKWebView class], @selector(bdwm_LoadRequest:));
        pWKWebViewRemoveFromSuperviewIMP = class_getMethodImplementation([WKWebView class], @selector(bdwm_removeFromSuperview));
        pWKWebViewGoBackIMP = class_getMethodImplementation([WKWebView class], @selector(bdwm_goBack));
        pWKWebViewInitIMP = class_getMethodImplementation([WKWebView class], @selector(bdwm_initWithFrame:configuration:));
        pWKWebViewWillMoveWindowIMP = class_getMethodImplementation([WKWebView class], @selector(bdwm_willMoveToWindow:));
        monitorDict = [NSMutableDictionary dictionary];
    });
    for (Class cls in classes) {
        
        NSArray *selStrList = @[
            @"loadRequest:"
            , @"removeFromSuperview"
            , @"goBack"
            , @"initWithFrame:configuration:"
            , @"willMoveToWindow:"
        ];
        BOOL hookedBefore = NO;
        for (NSString *selStrItem in selStrList) {
            if (ORIGImpDic[cls][selStrItem]) {
    #if DEBUG
                NSLog(@"cannot re-hook");
    #endif
                hookedBefore = YES;
                break;;
            }
        }
        if (hookedBefore) {
            continue;
        }
        
        // 添加注册类的映射关系
        monitorDict[(id<NSCopying>)cls] = cls;
        if ([cls isKindOfClass:object_getClass([WKWebView class])]) {
            prepareDicForClass(cls);
            [IESLiveMonitorUtils hookMethod:cls
                                 fromSelStr:@"loadRequest:"
                                   toSelStr:@"bdwm_LoadRequest:"
                                  targetIMP:pWKWebViewLoadRequestIMP];
            [IESLiveMonitorUtils hookMethod:cls
                                 fromSelStr:@"removeFromSuperview"
                                   toSelStr:@"bdwm_removeFromSuperview"
                                  targetIMP:pWKWebViewRemoveFromSuperviewIMP];
            [IESLiveMonitorUtils hookMethod:cls
                                 fromSelStr:@"goBack"
                                   toSelStr:@"bdwm_goBack"
                                  targetIMP:pWKWebViewGoBackIMP];
            
            [IESLiveMonitorUtils hookMethod:cls
                                 fromSelStr:@"initWithFrame:configuration:"
                                   toSelStr:@"bdwm_initWithFrame:configuration:"
                                  targetIMP:pWKWebViewInitIMP];
            
            [IESLiveMonitorUtils hookMethod:cls
                                 fromSelStr:@"willMoveToWindow:"
                                   toSelStr:@"bdwm_willMoveToWindow:"
                                  targetIMP:pWKWebViewWillMoveWindowIMP];
            
            // 填充placeHolder
            for (NSString *selStrItem in selStrList) {
                ORIGImpDic[cls][selStrItem] = [NSValue valueWithPointer:prepareDicForClass];
            }
            
        } else { // OtherWebView 修改为运行时调用
            NSAssert(NO, @"cannot support classes which is not inherited from WKWebview");
        }
    }
}

+ (void)registerReportBlock:(void(^)(NSString *, NSDictionary*))reportBlock {
    [MonitorReporterInstance addGlobalReportBlock:reportBlock];
}

+ (Class)getNodeClassWithWebView:(Class)webViewClass {
    Class resultCls = webViewClass;
    if (monitorDict[webViewClass]) {
        return monitorDict[webViewClass];
    } else {
        resultCls = [webViewClass superclass];
        while (!monitorDict[resultCls] && resultCls != [NSObject class]) {
            resultCls = [resultCls superclass];
        }
        monitorDict[(id<NSCopying>)webViewClass] = resultCls;
        // 递归写法
//        Class resultCls = [self getNodeClassWithWebView:[webViewClass superclass]];
//        monitorDict[(id<NSCopying>)webViewClass] = result;
    }
    return resultCls;
}

#pragma mark - progress monitor
+ (void)hookProgressWithClasses:(NSSet<Class>*)classes
                       settings:(nullable NSDictionary *)settings
                         isLive:(BOOL)isLive {
    for (Class cls in classes) {
        if ([cls isKindOfClass:object_getClass([WKWebView class])]) {
            [cls performSelector:@selector(hookProgressMethod)];
        }
    };
}

@end

#pragma mark -

static NSMutableArray<Class> *wkLiveWebViewClsesOnMonitor = nil;

@implementation IESLiveWebViewMonitor (IESLive)

+ (void)startMonitorWithClasses:(NSSet *)classes setting:(NSDictionary *)setting {
    if (pLiveMonitorIsRunning) {
        [self stopLiveMonitor];
    }
    pLiveMonitorIsRunning = YES;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        wkLiveWebViewClsesOnMonitor = [NSMutableArray array];
    });
    [self p_startWithClasses:classes
                    settings:setting
                      isLive:YES];
    for (Class cls in classes) {
        if (class_isMetaClass(object_getClass(cls))) {
            if ([cls isKindOfClass:object_getClass([WKWebView class])]) {
                [wkLiveWebViewClsesOnMonitor addObject:cls];
            } else {
                Class pOtherWebViewMonitorClass =  NSClassFromString(@"BDOtherWebViewMonitor");
                SEL pOtherWebViewMonitorSel = NSSelectorFromString(@"startMonitorWithClass:");
                if ([pOtherWebViewMonitorClass respondsToSelector:pOtherWebViewMonitorSel]) {
                    Method pOtherWebViewMonitorMethod = class_getClassMethod(pOtherWebViewMonitorClass, pOtherWebViewMonitorSel);
                    IMP pOtherWebViewMonitorImp = method_getImplementation(pOtherWebViewMonitorMethod);
                    ((void(*)(Class, SEL, Class))pOtherWebViewMonitorImp)(pOtherWebViewMonitorClass, pOtherWebViewMonitorSel, cls);
                }
            }
        }
    }
}

+ (void)stopLiveMonitor {
    pLiveMonitorIsRunning = NO;
    if (wkLiveWebViewClsesOnMonitor.count) {
        [wkLiveWebViewClsesOnMonitor enumerateObjectsUsingBlock:^(Class cls, NSUInteger idx, BOOL * _Nonnull stop) {
            unHookMethod(cls,
                         NSSelectorFromString(@"loadRequest:"));
        }];
        [wkLiveWebViewClsesOnMonitor removeAllObjects];
    }
    // OtherWebView 相关逻辑修改为运行时执
    Class pOtherWebViewMonitorClass =  NSClassFromString(@"BDOtherWebViewMonitor");
    SEL pOtherWebViewMonitorSel = NSSelectorFromString(@"stopLiveMonitorWithHookBlock:");
    if ([pOtherWebViewMonitorClass respondsToSelector:pOtherWebViewMonitorSel]) {
        void (^unHook)(Class, SEL) = ^(Class cls, SEL sel){
            unHookMethod(cls, sel);
        };
       
       Method pOtherWebViewMonitorMethod = class_getClassMethod(pOtherWebViewMonitorClass, pOtherWebViewMonitorSel);
       IMP pOtherWebViewMonitorImp = method_getImplementation(pOtherWebViewMonitorMethod);
       ((void(*)(Class, SEL, id))pOtherWebViewMonitorImp)(pOtherWebViewMonitorClass, pOtherWebViewMonitorSel, unHook);
    }
}

+ (NSDictionary *)hook_ORIGDic {
    return ORIGImpDic;
}

+ (void)setClass:(Class)cls sel:(NSString*)sel imp:(IMP)impPointer {
    ORIGImpDic[cls][sel] = [NSValue valueWithPointer:impPointer];
}

#pragma mark - WKScript
+ (void)installMonitorOnWKWebView:(WKWebView *)wkWebView {
    if (![wkWebView isKindOfClass:wkWebView.class]) {
        NSCAssert(NO, @"monitored object is not WKWebView!");
        return;
    }
    [wkWebView addRenderEventListener];
    
    __block BOOL injectionScriptBefore = NO;
    NSString *emptyScriptStr = [self emptyScriptForWebView:wkWebView];
    [wkWebView.configuration.userContentController.userScripts enumerateObjectsUsingBlock:^(WKUserScript * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj.source isEqualToString:emptyScriptStr]) {
            injectionScriptBefore = YES;
            *stop = YES;
        }
    }];
    
    if (!injectionScriptBefore) {
        WKUserScript *emptyScript = [[WKUserScript alloc] initWithSource:emptyScriptStr injectionTime:WKUserScriptInjectionTimeAtDocumentStart
                                                        forMainFrameOnly:NO];
        [wkWebView.configuration.userContentController addUserScript:emptyScript];
        
        NSDictionary *settingMap = [IESLiveWebViewMonitorSettingModel settingMapForWebView:[wkWebView class]];
        BOOL injectDomMonitor = [settingMap[@"injectDomMonitor"] boolValue];
        BOOL instanceDisableInject = [wkWebView.settings[kWebviewInstanceConfigDisableInjectBrowser] boolValue];
        if ([settingMap[kBDWMInjectBrowser] boolValue] && !instanceDisableInject) {
            WKUserScript *wkScript = [[WKUserScript alloc] initWithSource:[BDWebViewMonitorFileProvider scriptForTimingForWebView:wkWebView domMonitor:injectDomMonitor]
                                                            injectionTime:WKUserScriptInjectionTimeAtDocumentStart
                                                         forMainFrameOnly:NO];
            [wkWebView.configuration.userContentController addUserScript:wkScript];
            // 新版本不用这种方式配置，而是在bridge.js中注册，暂时注释掉看下情况
//            if (!injectDomMonitor) {
//                WKUserScript *slardarConfigScript = [[WKUserScript alloc] initWithSource:[self slardarConfigForWebView:wkWebView]
//                                                                           injectionTime:WKUserScriptInjectionTimeAtDocumentStart
//                                                                        forMainFrameOnly:NO];
//                [wkWebView.configuration.userContentController addUserScript:slardarConfigScript];
//            }
        }

        void (^addMessageHandler)(NSString*) = ^(NSString *name) {
            [wkWebView.configuration.userContentController
             addScriptMessageHandler:[IESLiveWebViewMonitor sharedMonitor]
             name:name];
        };
        addMessageHandler(@"iesLiveWebViewLog");
        addMessageHandler(@"iesLiveCalculateInitTime");
        addMessageHandler(@"iesLiveTimingMonitorCover");
        addMessageHandler(@"iesLiveTimingMonitorAccumulate");
        addMessageHandler(@"iesLiveTimingMonitorReportDirectly");
        addMessageHandler(@"iesLiveTimingMonitorAverage");
        addMessageHandler(@"iesLiveTimingMonitorReportCustom");
        addMessageHandler(@"iesLiveTimingMonitorReportStage");
        addMessageHandler(@"iesLiveTimingMonitorInjectJsTime");
        addMessageHandler(@"iesLiveTimingMonitorBatch");
    }
}

@end

