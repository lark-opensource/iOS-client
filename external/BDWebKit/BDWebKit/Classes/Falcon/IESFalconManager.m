//
//  IESFalconManager.m
//  IESWebKit
//
//  Created by li keliang on 2018/10/9.
//

#import "IESFalconManager.h"
#import "IESFalconURLProtocol.h"
#import "NSURLProtocol+WebKitSupport.h"
#import "IESFalconStatRecorder.h"
#import "IESFalconDebugLogger.h"
#import "BDWebInterceptor.h"
#import "BDWebFalconURLSchemaHandler.h"
#import <BDWebKit/BDWebViewSchemeTaskHandler.h>
#import <BDWebKit/BDWebKitSettingsManger.h>
#import <BDWebKit/BDWebResourceMonitorEventType.h>
#import <objc/runtime.h>
#import <BDAlogProtocol/BDAlogProtocol.h>
#import <ByteDanceKit/ByteDanceKit.h>
#import "NSObject+BDWRuntime.h"

#if __has_include(<IESGeckoKit/IESGeckoKit.h>)
#import "IESFalconGurdInterceptor.h"
#import <IESGeckoKit/IESGurdDelegateDispatcher.h>
#define IESFalconGurdInterceptorEnable  1
#endif

#import "IESFalconFileInterceptor.h"
#import "IWKFalconPluginObject.h"
#import <BDWebCore/WKWebView+Plugins.h>
#import "BDWebKitUtil.h"
#import "WKWebView+BDPrivate.h"
#import "BDWebKitMainFrameModel.h"

#ifndef IESFalconLog
#define IESFalconLog(...) BDALOG_PROTOCOL_TAG(kLogLevelInfo, @"Falcon", __VA_ARGS__);
#endif

static NSMutableArray * kGeckoCustomInterceptors = nil;

// 用于falcon对齐RL埋点规范,增加版本信息
static NSString *const kFalconResLoaderVersion = @"1.1.1";

#if IESFalconGurdInterceptorEnable
static IESFalconGurdInterceptor *kFalconGurdInterceptor = nil;
#endif
static IESFalconFileInterceptor *kFalconFileInterceptor = nil;

@interface IESFalconSimpleMetaData : NSObject<IESFalconMetaData>
@end
@implementation IESFalconSimpleMetaData
@synthesize falconData = _falconData;
@synthesize statModel = _statModel;
@end

@implementation IESFalconManager

+ (void)initialize
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        kGeckoCustomInterceptors = [NSMutableArray new];
    });
}

+ (void)registerPattern:(NSString *)pattern forSearchPath:(NSString *)searchPath
{
    [self createFileInterceptorIfNeeded];
    [kFalconFileInterceptor registerPattern:pattern forSearchPath:searchPath];
}

+ (void)registerPatterns:(NSArray <NSString *> *)patterns forSearchPath:(NSString *)searchPath
{
    [self createFileInterceptorIfNeeded];
    [kFalconFileInterceptor registerPatterns:patterns forSearchPath:searchPath];
}

+ (void)registerPattern:(NSString *)pattern forGurdAccessKey:(NSString *)accessKey
{
#if IESFalconGurdInterceptorEnable
    [self createGurdInterceptorIfNeeded];
    [kFalconGurdInterceptor registerPattern:pattern forGurdAccessKey:accessKey];
#endif
}

+ (void)registerPatterns:(NSArray <NSString *> *)patterns forGurdAccessKey:(NSString *)accessKey
{
#if IESFalconGurdInterceptorEnable
    [self createGurdInterceptorIfNeeded];
    [kFalconGurdInterceptor registerPatterns:patterns forGurdAccessKey:accessKey];
#endif
}

+ (void)unregisterPatterns:(NSArray <NSString *> *)patterns
{
#if IESFalconGurdInterceptorEnable
    [kFalconGurdInterceptor unregisterPatterns:patterns];
#endif
    [kFalconFileInterceptor unregisterPatterns:patterns];
}

+ (void)registerCustomInterceptor:(id<IESFalconCustomInterceptor>)interceptor
{
    NSCParameterAssert(interceptor);
    @synchronized (self) {
        NSUInteger insertIndex = [self _findCustomInterceptionInsertIndex:interceptor
                                                         mutableContainer:kGeckoCustomInterceptors];
        [kGeckoCustomInterceptors insertObject:interceptor atIndex:insertIndex];
    }
}

+ (void)unregisterCustomInterceptor:(id<IESFalconCustomInterceptor>)interceptor
{
    NSCParameterAssert(interceptor);
    @synchronized (self) {
        [kGeckoCustomInterceptors removeObject:interceptor];
    }
}

#pragma mark - Falcon

+ (BOOL)shouldInterceptForRequest:(NSURLRequest *)request
{
    return [self shouldInterceptForRequest:request
                                   webView:nil];
}

+ (BOOL)shouldInterceptForRequest:(NSURLRequest*)request
                          webView:(WKWebView * _Nullable)webview
{
    __block BOOL result = NO;
    [webview.bdw_customFalconInterceptors enumerateObjectsUsingBlock:^(id<IESFalconCustomInterceptor> obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj respondsToSelector:@selector(shouldInterceptForRequest:)]) {
            if([obj shouldInterceptForRequest:request]){
                result = YES;
                *stop = YES;
            }
        }
    }];
    
    if(result){
        return result;
    }
    
    if (webview.bdw_disableGlobalFalconIntercetors) {
        return NO;
    }
    
    @synchronized (self) {
        
        [kGeckoCustomInterceptors enumerateObjectsUsingBlock:^(id<IESFalconCustomInterceptor> obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj respondsToSelector:@selector(shouldInterceptForRequest:)]) {
                if([obj shouldInterceptForRequest:request]){
                    result = YES;
                    *stop = YES;
                }
            }
        }];
        
        if(result){
            return result;
        }
        return [kFalconGurdInterceptor shouldInterceptForRequest:request];
    }
}

+ (id<IESFalconMetaData>)falconMetaDataForURLRequest:(NSURLRequest *)request
{
    return [self falconMetaDataForURLRequest:request
                                     webView:nil];
}

+ (id<IESFalconMetaData> _Nullable)falconMetaDataForURLRequest:(NSURLRequest *)request
                                                       webView:(WKWebView *)webview
{
    NSCParameterAssert(request.URL);
    NSDate *startDate = [NSDate date];
    if (![request.HTTPMethod isEqualToString:@"GET"]) {
        IESFalconLog(@"Skip %@: %@", request.HTTPMethod, request.URL.absoluteString);
        @synchronized (self) {
            for(NSObject<IESFalconMonitorInterceptor> *interceptor in IESFalconManager.monitorInterceptors) {
                if([interceptor respondsToSelector:@selector(didGetMetaData:forRequest:isGetMethod:isCustomInterceptor:)]) {
                    [interceptor didGetMetaData:nil forRequest:request isGetMethod:NO isCustomInterceptor:NO];
                }
            }
        }
        return nil;
    }
    
    [request bdw_initFalconProcessInfoRecord];
    BOOL falconRequestForMainFrame = NO;
    if (webview == nil) {
        // try get webview by user agent
        NSString *userAgent = request.allHTTPHeaderFields[@"User-Agent"];
        webview = [self __webviewWithUserAgent:userAgent];
        IESFalconLog(@"get webview from user agent, success:%@, ua:%@ url:%@", @(webview!=nil), userAgent, request.URL.absoluteString);
    }
    
    NSMutableDictionary *falconProcessInfoDic = request.bdw_falconProcessInfoRecord;
    if (falconProcessInfoDic == nil) {
        falconProcessInfoDic = [[NSMutableDictionary alloc] init];
        request.bdw_falconProcessInfoRecord = falconProcessInfoDic;
    }
    falconProcessInfoDic[kBDWebviewResLoadStartKey] = @(startDate.timeIntervalSince1970 * 1000);
    
    NSString *webURL = @"";
    if (webview) {
        if ([NSThread isMainThread]) {
            webURL = webview.URL.absoluteString ?: request.URL.absoluteString;
        } else {
            webURL = webview.bdw_mainFrameModelRecord.latestWebViewURLString ?: @""; // update by decidePolicyForNavigationAction
        }
    }
    if (!BTD_isEmptyString(webURL)) {
        falconProcessInfoDic[kBDWebviewResSceneKey] = @"web_child_resource";
        if ([webURL isEqualToString:request.URL.absoluteString]) {
            falconRequestForMainFrame = YES;
            falconProcessInfoDic[kBDWebviewResSceneKey] = @"web_main_document";
        }
    }
    
    if (!IESFalconManager.interceptionInstanceLevelEnable) {
        webview = nil;
    }
    
    id<IESFalconMetaData> metaData = [self _customInterceptionFalconMetaDataForURLRequest:request
                                                                   additionalInterceptors:webview.bdw_customFalconInterceptors
                                                                disableGlobalInterceptors:webview.bdw_disableGlobalFalconIntercetors];
    BOOL hasData = (metaData.falconData.length > 0);
    if (!hasData && !webview.bdw_disableGlobalFalconIntercetors) {
        // Record falcon fetcher list
        NSString *fetcherList = request.bdw_falconProcessInfoRecord[kBDWebviewFetcherListKey];
        NSMutableString *interceptorRecord = [[NSMutableString alloc] init];
#if IESFalconGurdInterceptorEnable
        [interceptorRecord appendString:@"IESFalconGurdInterceptor,"];
#endif
        [interceptorRecord appendString:@"IESFalconFileInterceptor"];
        if (BTD_isEmptyString(fetcherList)) {
            falconProcessInfoDic[kBDWebviewFetcherListKey] = [interceptorRecord copy];
        } else {
            falconProcessInfoDic[kBDWebviewFetcherListKey] = [NSString stringWithFormat:@"%@, %@", fetcherList, interceptorRecord];
        }
        
        metaData = [self _defaultInterceptionFalconMetaDataForURLRequest:request];
    }
    if(metaData.falconData.length > 0) {
        metaData.statModel.offlineDuration = (NSInteger)([[NSDate date] timeIntervalSinceDate:startDate] * 1000);
        metaData.statModel.resourceURLString = request.URL.absoluteString;
    }
    @synchronized (self) {
        for(NSObject<IESFalconMonitorInterceptor> *interceptor in IESFalconManager.monitorInterceptors) {
            if([interceptor respondsToSelector:@selector(didGetMetaData:forRequest:isGetMethod:isCustomInterceptor:)]) {
                [interceptor didGetMetaData:metaData forRequest:request isGetMethod:YES isCustomInterceptor:hasData];
            }
        }
    }
    
    falconProcessInfoDic[kBDWebviewResLoadFinishKey] = @([NSDate date].timeIntervalSince1970 * 1000);
    
    NSString *finalFetcherList = falconProcessInfoDic[kBDWebviewFetcherListKey];
    falconProcessInfoDic[kBDWebviewFetcherListKey] = [NSString stringWithFormat:@"[%@]", finalFetcherList];
    if (metaData.falconData.length > 0) {
        falconProcessInfoDic[kBDWebviewResStateKey] = @"success";
    }
    [self recordFalconMetaData:metaData forRequest:request];
    IESFalconLog(@"get offline data %@: %@", (metaData.falconData.length > 0) ? @"Found" : @"Not found", request.URL.absoluteString);
    return metaData;
}

+ (void)recordFalconMetaData:(id<IESFalconMetaData>)metaData forRequest:(NSURLRequest *)request
{
    NSMutableDictionary *falconProcessInfoDic = request.bdw_falconProcessInfoRecord;
    if (falconProcessInfoDic == nil) {
        falconProcessInfoDic = [[NSMutableDictionary alloc] init];
        request.bdw_falconProcessInfoRecord = falconProcessInfoDic;
    }
    
    BOOL hasOfflineData = (metaData.falconData.length > 0);
    IESFalconStatModel *model = metaData.statModel;
    if (!model) {
        if (hasOfflineData) {
            falconProcessInfoDic[kBDWebviewResStateKey] = @"success";
            falconProcessInfoDic[kBDWebviewResFromKey] = @"offline";
        } else {
            falconProcessInfoDic[kBDWebviewResStateKey] = @"failed";
        }
        return;
    }
    
    if (hasOfflineData) {
        falconProcessInfoDic[kBDWebviewResStateKey] = @"success";
        // if accesskey&channel exist, treat as gecko
        BOOL useGeckoData = (model.accessKey.length > 0 && model.channel.length > 0);
        if (useGeckoData) {
            falconProcessInfoDic[kBDWebviewResFromKey] = @"gecko";
            falconProcessInfoDic[kBDWebviewGeckoAccessKeyKey] = model.accessKey;
            falconProcessInfoDic[kBDWebviewGeckoChannelKey] = model.channel;
            falconProcessInfoDic[kBDWebviewGeckoBundleKey] = model.bundles.count > 0 ? [model.bundles componentsJoinedByString:@","] : @"";
        } else {
            falconProcessInfoDic[kBDWebviewResFromKey] = @"offline";
        }
    } else {
        falconProcessInfoDic[kBDWebviewResStateKey] = @"failed";
        falconProcessInfoDic[kBDWebviewResLoaderErrorCodeKey] = @(model.errorCode);
        falconProcessInfoDic[kBDWebviewResErrorMsgKey] = model.errorMessage;
    }
}

+ (NSData * _Nullable)falconDataForURLRequest:(NSURLRequest *)request
{
    return [self falconMetaDataForURLRequest:request].falconData;
}

+ (NSData *)falconDataForURLRequest:(NSURLRequest *)request
                            webView:(WKWebView *)webview
{
    return [self falconMetaDataForURLRequest:request
                                     webView:webview].falconData;
}

+ (id<IESFalconMetaData> _Nullable)_defaultInterceptionFalconMetaDataForURLRequest:(NSURLRequest *)request
{
    id<IESFalconMetaData> metaData = nil;
#if IESFalconGurdInterceptorEnable
    metaData = [kFalconGurdInterceptor falconMetaDataForURLRequest:request];
    BOOL hasData = (metaData.falconData.length > 0);
    if (hasData) {
        IESFalconLog(@"get offline data from kFalconGurdInterceptor, url:%@", request.URL);
        return metaData;
    }
#endif
    metaData = [kFalconFileInterceptor falconMetaDataForURLRequest:request];
    if (metaData.falconData.length > 0) {
        IESFalconLog(@"get offline data from kFalconFileInterceptor, url:%@", request.URL);
    }
    return metaData;
}

+ (id<IESFalconMetaData> _Nullable)_customInterceptionFalconMetaDataForURLRequest:(NSURLRequest *)request
{
    return [self _customInterceptionFalconMetaDataForURLRequest:request
                                         additionalInterceptors:nil
                                      disableGlobalInterceptors:NO];
}

+ (id<IESFalconMetaData> _Nullable)_customInterceptionFalconMetaDataForURLRequest:(NSURLRequest *)request
                                                           additionalInterceptors:(NSArray<id<IESFalconCustomInterceptor>> *)additionalInterceptors
                                                        disableGlobalInterceptors:(BOOL)disableGlobalInterceptors
{
    __block id<IESFalconMetaData> metaData = nil;
    if (additionalInterceptors) {
        [additionalInterceptors enumerateObjectsUsingBlock:^(id<IESFalconCustomInterceptor> obj, NSUInteger idx, BOOL * _Nonnull stop) {
            metaData = [self _metaDataWithRequest:request
                                      interceptor:obj];
            
            BOOL hasData = (metaData.falconData.length > 0);
            *stop = hasData;
            if (hasData) {
                IESFalconLog(@"get offline data from %@(local), url:%@", [obj class], request.URL);
            }
        }];
        
        if (metaData) {
            return metaData;
        }
    }
    
    if (disableGlobalInterceptors) {
        return nil;
    }
    
    @synchronized (self) {
        [kGeckoCustomInterceptors enumerateObjectsUsingBlock:^(id<IESFalconCustomInterceptor> obj, NSUInteger idx, BOOL * _Nonnull stop) {
            metaData = [self _metaDataWithRequest:request
                                      interceptor:obj];
            
            BOOL hasData = (metaData.falconData.length > 0);
            if (hasData) {
                IESFalconLog(@"get offline data from %@(global), url:%@", [obj class], request.URL);
            }
            *stop = hasData;
        }];
        return metaData;
    }
}

+ (id<IESFalconMetaData>)_metaDataWithRequest:(NSURLRequest *)request
                                  interceptor:(id<IESFalconCustomInterceptor>)interceptor
{
    // Record for falcon process info
    NSString *fetcherList = request.bdw_falconProcessInfoRecord[kBDWebviewFetcherListKey];
    if (BTD_isEmptyString(fetcherList)) {
        request.bdw_falconProcessInfoRecord[kBDWebviewFetcherListKey] = [NSString stringWithFormat:@"%@", [interceptor class]];
    } else {
        request.bdw_falconProcessInfoRecord[kBDWebviewFetcherListKey] = [NSString stringWithFormat:@"%@, %@", fetcherList, [interceptor class]];
    }
    
    id<IESFalconMetaData> metaData = nil;
    if ([interceptor respondsToSelector:@selector(falconMetaDataForURLRequest:)]) {
        metaData = [interceptor falconMetaDataForURLRequest:request];
    } else if ([interceptor respondsToSelector:@selector(falconDataForURLRequest:)]) {
        NSData *falconData = [interceptor falconDataForURLRequest:request];
        if (falconData.length > 0) {
            metaData = [[IESFalconSimpleMetaData alloc] init];
            metaData.falconData = falconData;
        }
    }
    return metaData;
}

#pragma mark - Helpers

+ (void)createFileInterceptorIfNeeded
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        kFalconFileInterceptor = [[IESFalconFileInterceptor alloc] init];
    });
}

#if IESFalconGurdInterceptorEnable
+ (void)createGurdInterceptorIfNeeded
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        kFalconGurdInterceptor = [[IESFalconGurdInterceptor alloc] init];
    });
}
#endif

+ (NSUInteger)_findCustomInterceptionInsertIndex:(id<IESFalconCustomInterceptor>)interceptor
                                mutableContainer:(NSArray<id<IESFalconCustomInterceptor>> *)mutableContainer
{
    NSUInteger(^interceptionPriorityBlk)(id) = ^(id<IESFalconCustomInterceptor> interception){
        NSUInteger priority = 0;
        if ([interception respondsToSelector:@selector(falconPriority)]) {
            priority = [interception falconPriority];
        }
        return priority;
    };
    
    NSInteger priority = interceptionPriorityBlk(interceptor);
    __block NSInteger insertIndex = 0;
    @synchronized (self) {
        [mutableContainer enumerateObjectsUsingBlock:^(id<IESFalconCustomInterceptor> interception, NSUInteger idx, BOOL * _Nonnull stop) {
            if (priority >= interceptionPriorityBlk(interception)) {
                *stop = YES;
                return;
            }
            insertIndex = idx;
        }];
    }
    return insertIndex;
}

#pragma mark - Accessors

static BOOL kWebpDecodeEnable = NO;
+ (BOOL)webpDecodeEnable
{
    return kWebpDecodeEnable;
}

+ (void)setWebpDecodeEnable:(BOOL)webpDecodeEnable
{
    kWebpDecodeEnable = webpDecodeEnable;
}

static BOOL kInterceptionDisableWKHttpScheme = NO;
+ (BOOL)interceptionDisableWKHttpScheme
{
    return kInterceptionDisableWKHttpScheme;
}

+ (void)setInterceptionDisableWKHttpScheme:(BOOL)interceptionDisableWKHttpScheme
{
    kInterceptionDisableWKHttpScheme = interceptionDisableWKHttpScheme;
    if (interceptionDisableWKHttpScheme && self.interceptionEnable && self.interceptionWKHttpScheme) {
        [NSURLProtocol wk_unregisterScheme:@"http"];
        [NSURLProtocol wk_unregisterScheme:@"https"];
    }
}

static BOOL kInterceptionWKHttpScheme = NO;
+ (BOOL)interceptionWKHttpScheme
{
    return kInterceptionWKHttpScheme;
}

+ (void)setInterceptionWKHttpScheme:(BOOL)interceptionWKHttpScheme
{
    if (self.interceptionLock && interceptionWKHttpScheme) {
        return;
    }
    if (self.interceptionDisableWKHttpScheme) {
        return;
    }
    kInterceptionWKHttpScheme = interceptionWKHttpScheme;
}

static BOOL kInterceptionLock = NO;
+ (BOOL)interceptionLock
{
    return kInterceptionLock;
}

+ (void)setInterceptionLock:(BOOL)interceptionLock
{
    kInterceptionLock = interceptionLock;
}

static NSHashTable * _monitorInterceptors;
+ (NSHashTable *)monitorInterceptors {
    if (!_monitorInterceptors) {
        _monitorInterceptors = [NSHashTable weakObjectsHashTable];
    }
    return _monitorInterceptors;
}

+ (void)addInterceptor:(id<IESFalconMonitorInterceptor>)interceptor {
    @synchronized (self) {
        [IESFalconManager.monitorInterceptors addObject:interceptor];
    }
}

+ (void)removeInterceptor:(id<IESFalconMonitorInterceptor>)interceptor {
    @synchronized (self) {
        [IESFalconManager.monitorInterceptors removeObject:interceptor];
    }
}

+ (void)webView:(WKWebView *)webView
    loadRequest:(NSURLRequest *)request
       metaData:(id<IESFalconMetaData> _Nullable)metaData
{
    id<IESFalconMetaData> customMetaData = [self _customInterceptionFalconMetaDataForURLRequest:request
                                                                         additionalInterceptors:webView.bdw_customFalconInterceptors
                                                                      disableGlobalInterceptors:webView.bdw_disableGlobalFalconIntercetors];
    BOOL hasData = (customMetaData.falconData.length > 0);
    @synchronized (self) {
        for(NSObject<IESFalconMonitorInterceptor> *interceptor in IESFalconManager.monitorInterceptors) {
            if([interceptor respondsToSelector:@selector(webView:loadRequest:metaData:isCustomInterceptor:)]) {
                [interceptor webView:webView loadRequest:request metaData:metaData isCustomInterceptor:hasData];
            }
        }
    }
}

+ (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    @synchronized (self) {
        for(NSObject<IESFalconMonitorInterceptor> *interceptor in IESFalconManager.monitorInterceptors) {
            if([interceptor respondsToSelector:@selector(webView:didFinishNavigation:)]) {
                [interceptor webView:webView didFinishNavigation:navigation];
            }
        }
    }
}

static id<IESFalconInterceptionDelegate> kInterceptionDelegate;
+ (id<IESFalconInterceptionDelegate>)interceptionDelegate
{
    return kInterceptionDelegate;
}

+ (void)setInterceptionDelegate:(id<IESFalconInterceptionDelegate>)interceptionDelegate
{
    kInterceptionDelegate = interceptionDelegate;
}

static BOOL kInterceptionEnable = NO;
+ (BOOL)interceptionEnable
{
    return kInterceptionEnable;
}

static BOOL kInterceptionUseFalconURLSchemaHandle = YES;
+ (void)setInterceptionUseFalconURLSchemaHandle:(BOOL)interceptionUseFalconURLSchemaHandle {
    kInterceptionUseFalconURLSchemaHandle = interceptionUseFalconURLSchemaHandle;
}

+ (BOOL)interceptionUseFalconURLSchemaHandle {
    return kInterceptionUseFalconURLSchemaHandle;
}

+ (void)setInterceptionEnable:(BOOL)interceptionEnable
{
    if (self.interceptionLock && !interceptionEnable) {
        return;
    }
    if (interceptionEnable) {
        IESFalconDebugLog(@"Enable falcon interception");
        [NSURLProtocol unregisterClass:IESFalconURLProtocol.class];
        [NSURLProtocol wk_unregisterScheme:@"about"];
        [NSURLProtocol wk_unregisterScheme:@"http"];
        [NSURLProtocol wk_unregisterScheme:@"https"];
        
        if (@available(iOS 9.0, *)) {
            static dispatch_once_t onceToken;
            dispatch_once(&onceToken, ^{
                IESFalconDebugLog(@"Load falcon plugins");
                [WKWebView IWK_loadPlugin:IWKFalconPluginObject.new];
            });
        }
        
        if(self.interceptionUseFalconURLSchemaHandle){
            if (@available(iOS 12.0, *)) {
                if ([BDWebKitSettingsManger useTTNetForFalcon]) {
                    [[BDWebInterceptor sharedInstance] registerCustomURLSchemaHandler:BDWebViewSchemeTaskHandler.class];
                }
                [[BDWebInterceptor sharedInstance] registerCustomURLSchemaHandler:BDWebFalconURLSchemaHandler.class];
            }
        }
        
        [NSURLProtocol registerClass:IESFalconURLProtocol.class];
        [NSURLProtocol wk_registerScheme:@"about"];
        [WKWebView bdw_updateURLProtocolInterceptionStatus:BDWebKitURLProtocolInterceptionStatusAbout];
        
        if (IESFalconManager.interceptionWKHttpScheme && !IESFalconManager.interceptionDisableWKHttpScheme) {
            IESFalconDebugLog(@"Register http、https scheme");
            [NSURLProtocol wk_registerScheme:@"http"];
            [NSURLProtocol wk_registerScheme:@"https"];
            [WKWebView bdw_updateURLProtocolInterceptionStatus:BDWebKitURLProtocolInterceptionStatusHTTP];
        }
    } else {
        IESFalconDebugLog(@"Disable falcon interception");
        [NSURLProtocol unregisterClass:IESFalconURLProtocol.class];
        [NSURLProtocol wk_unregisterScheme:@"about"];
        [NSURLProtocol wk_unregisterScheme:@"http"];
        [NSURLProtocol wk_unregisterScheme:@"https"];
        [WKWebView bdw_updateURLProtocolInterceptionStatus:BDWebKitURLProtocolInterceptionStatusNone];
    }
    kInterceptionEnable = interceptionEnable;
}

+ (NSArray<id<IESFalconCustomInterceptor>> *)customInterceptors
{
    return kGeckoCustomInterceptors.copy;
}

+ (BOOL)willBlockRequest:(NSURLRequest *)request
{
    return [BDWebInterceptor willBlockRequest:request];
}

+ (NSURLRequest *)willDecorateRequest:(NSURLRequest *)request
{
    return [BDWebInterceptor willDecorateRequest:request];
}

+ (void)willDecorateURLProtocolTask:(id<BDWebURLProtocolTask>)urlProtocolTask
{
    [BDWebInterceptor willDecorateURLProtocolTask:urlProtocolTask];
}

+ (NSHashTable *)fetchGlobalMonitorsFromWebInterceptor
{
    return [BDWebInterceptor bdw_globalInterceptorMonitors];
}

+ (void)bdw_URLProtocolTask:(id<BDWebURLProtocolTask>)urlProtocolTask didReceiveResponse:(NSURLResponse *)response
{
    NSHashTable *globalMonitors = [BDWebInterceptor bdw_globalInterceptorMonitors];
    for (NSObject<BDWebInterceptorMonitor> *monitor in globalMonitors) {
        if ([monitor respondsToSelector:@selector(bdw_URLProtocolTask:didReceiveResponse:)]) {
            [monitor bdw_URLProtocolTask:urlProtocolTask didReceiveResponse:response];
        }
    }
}

+ (void)bdw_URLProtocolTask:(id<BDWebURLProtocolTask>)urlProtocolTask didLoadData:(NSData *)data
{
    NSHashTable *globalMonitors = [BDWebInterceptor bdw_globalInterceptorMonitors];
    for (NSObject<BDWebInterceptorMonitor> *monitor in globalMonitors) {
        if ([monitor respondsToSelector:@selector(bdw_URLProtocolTask:didLoadData:)]) {
            [monitor bdw_URLProtocolTask:urlProtocolTask didLoadData:data];
        }
    }
}

+ (void)bdw_URLProtocolTaskDidFinishLoading:(id<BDWebURLProtocolTask>)urlProtocolTask
{
    NSHashTable *globalMonitors = [BDWebInterceptor bdw_globalInterceptorMonitors];
    for (NSObject<BDWebInterceptorMonitor> *monitor in globalMonitors) {
        if ([monitor respondsToSelector:@selector(bdw_URLProtocolTaskDidFinishLoading:)]) {
            [monitor bdw_URLProtocolTaskDidFinishLoading:urlProtocolTask];
        }
    }
}

+ (void)bdw_URLProtocolTask:(id<BDWebURLProtocolTask>)urlProtocolTask didFailWithError:(NSError *)error
{
    NSHashTable *globalMonitors = [BDWebInterceptor bdw_globalInterceptorMonitors];
    for (NSObject<BDWebInterceptorMonitor> *monitor in globalMonitors) {
        if ([monitor respondsToSelector:@selector(bdw_URLProtocolTask:didFailWithError:)]) {
            [monitor bdw_URLProtocolTask:urlProtocolTask didFailWithError:error];
        }
    }
}

+ (void)bdw_URLProtocolTask:(id<BDWebURLProtocolTask>)urlProtocolTask didPerformRedirection:(NSURLResponse *)response newRequest:(NSURLRequest *)request
{
    NSHashTable *globalMonitors = [BDWebInterceptor bdw_globalInterceptorMonitors];
    for (NSObject<BDWebInterceptorMonitor> *monitor in globalMonitors) {
        if ([monitor respondsToSelector:@selector(bdw_URLProtocolTask:didPerformRedirection:newRequest:)]) {
            [monitor bdw_URLProtocolTask:urlProtocolTask didPerformRedirection:response newRequest:request];
        }
    }
}

static BOOL kInterceptionInstanceLevelEnable = YES;
+ (void)setInterceptionInstanceLevelEnable:(BOOL)interceptionInstanceLevelEnable
{
    kInterceptionInstanceLevelEnable = interceptionInstanceLevelEnable;
}

+ (BOOL)interceptionInstanceLevelEnable
{
    return kInterceptionInstanceLevelEnable;
}

#pragma mark - WebView With UserAgent

static NSString * const kFalconUAPrefix = @"FalconTag/";
static NSString *(^_defaultUABlock)(void);

+ (void)setDefaultUABlock:(NSString * _Nonnull (^)(void))defaultUABlock
{
    _defaultUABlock = [defaultUABlock copy];
}

+ (NSString * _Nonnull (^)(void))defaultUABlock
{
    return _defaultUABlock;
}

+ (BOOL)decorateFalconWebView:(WKWebView *)webview withUUID:(NSString *)uuid
{
    if (BDWK_isEmptyString(uuid)) {
        return NO;
    }
    return [self __decoratedWebView:webview withUUID:uuid];
}

+ (void)decoratedFalconUserAgentWithWebView:(WKWebView *)webview
{
    if (![self interceptionInstanceLevelEnable]) {
        return;
    }
    NSString *uuid = [[NSUUID UUID] UUIDString];
    [self __decoratedWebView:webview withUUID:uuid];
}

+ (BOOL)__decoratedWebView:(WKWebView *)webview withUUID:(NSString *)uuid
{
    NSString *currentUA = webview.customUserAgent;
    if (currentUA.length == 0 && [self defaultUABlock]) {
        currentUA = [self defaultUABlock]();
    }
    if (currentUA.length == 0) {
        currentUA = [[NSUserDefaults standardUserDefaults] stringForKey:@"UserAgent"];
    }
    if (currentUA.length == 0) {
        currentUA = [[NSUserDefaults standardUserDefaults] stringForKey:@"User-Agent"];
    }
    if (BDWK_isEmptyString(currentUA) || [currentUA containsString:kFalconUAPrefix]) {
        return NO;
    }
    NSString *prefix = @" ";
    if ([currentUA hasSuffix:prefix]) {
        prefix = @"";
    }
    NSString *newUA = [currentUA stringByAppendingFormat:@"%@%@%@ ", prefix, kFalconUAPrefix, uuid];
    webview.customUserAgent = newUA;
    IESFalconLog(@"append UA with falcon tag:%@", newUA);
    [[self __weakWebViewTable] setObject:webview forKey:uuid];
    return YES;
}

+ (NSMapTable<NSString*, WKWebView *> *)__weakWebViewTable
{
    static NSMapTable * _table = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _table = [NSMapTable strongToWeakObjectsMapTable];
    });
    return _table;
}

+ (WKWebView *)webviewWithUserAgent:(NSString *)userAgent
{
    return [self __webviewWithUserAgent:userAgent];
}

+ (WKWebView *)__webviewWithUserAgent:(NSString *)userAgent
{
    NSString *uuid = [self __uuidFromUserAgent:userAgent withPrefix:kFalconUAPrefix];
    if (!uuid) {
        return nil;
    }
    return [[self __weakWebViewTable] objectForKey:uuid];
}

+ (NSString *)__uuidFromUserAgent:(NSString *)userAgent withPrefix:(NSString *)uaPrefix
{
    NSArray<NSString *> *componentsArray = [userAgent componentsSeparatedByString:@" "];
    NSString *uaTag = nil;
    for (NSString *component in componentsArray) {
        if ([component containsString:uaPrefix]) {
            uaTag = component;
            break;
        }
    }
    if (!uaTag) {
        return nil;
    }
    
    NSString *uuid = [uaTag stringByReplacingOccurrencesOfString:kFalconUAPrefix
                                                          withString:@""];
    return uuid;
}

@end

#pragma mark - WKWebView+Falcon

@implementation WKWebView (Falcon)

- (NSArray<id<IESFalconCustomInterceptor>> *)bdw_customFalconInterceptors
{
    return [[self bdw_mutableFalconCustomInterceptors] copy];
}

- (NSMutableArray<id<IESFalconCustomInterceptor>> *)bdw_mutableFalconCustomInterceptors
{
    return objc_getAssociatedObject(self, @selector(bdw_mutableFalconCustomInterceptors));
}

- (BOOL)bdw_disableGlobalFalconIntercetors
{
    return [objc_getAssociatedObject(self, @selector(bdw_disableGlobalFalconIntercetors)) boolValue];
}

- (void)setBdw_disableGlobalFalconIntercetors:(BOOL)bdw_disableGlobalFalconIntercetors
{
    objc_setAssociatedObject(self, @selector(bdw_disableGlobalFalconIntercetors), @(bdw_disableGlobalFalconIntercetors), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)bdw_registerFalconCustomInterceptor:(id<IESFalconCustomInterceptor>)customInterceptor
{
    if (!customInterceptor) {
        return;
    }
    NSMutableArray *mutableArray = [self bdw_mutableFalconCustomInterceptors];
    if (!mutableArray) {
        mutableArray = [[NSMutableArray alloc] init];
        objc_setAssociatedObject(self, @selector(bdw_mutableFalconCustomInterceptors), mutableArray, OBJC_ASSOCIATION_RETAIN);
    }
    NSUInteger insertIndex = [IESFalconManager _findCustomInterceptionInsertIndex:customInterceptor
                                                                 mutableContainer:mutableArray];
    [mutableArray insertObject:customInterceptor
                       atIndex:insertIndex];
}

- (void)bdw_unregisterFalconCustomInterceptor:(id<IESFalconCustomInterceptor>)customInterceptor
{
    if (!customInterceptor) {
        return;
    }
    [[self bdw_mutableFalconCustomInterceptors] removeObject:customInterceptor];
}

@end

#pragma mark - NSURLRequest+IESFalconManager

@implementation NSURLRequest (IESFalconManager)

- (void)setBdw_falconProcessInfoRecord:(NSMutableDictionary *)bdw_falconProcessInfoRecord
{
    if (bdw_falconProcessInfoRecord) {
        NSMutableDictionary *mutableDict = bdw_falconProcessInfoRecord;
        if ([mutableDict isMemberOfClass:[NSDictionary class]]) {
            mutableDict = [NSMutableDictionary dictionaryWithDictionary:mutableDict];
        }
        [self bdw_attachObject:mutableDict forKey:@"BDW_FalconProcessInfoRecord"];
    }
}

- (NSMutableDictionary *)bdw_falconProcessInfoRecord
{
    if ([self bdw_getAttachedObjectForKey:@"BDW_FalconProcessInfoRecord"] == nil) {
        [self bdw_attachObject:[[NSMutableDictionary alloc] init] forKey:@"BDW_FalconProcessInfoRecord"];
    }
    
    return  [self bdw_getAttachedObjectForKey:@"BDW_FalconProcessInfoRecord"];
}

- (void)bdw_initFalconProcessInfoRecord
{
    NSMutableDictionary *falconProcessInfoDic = [[NSMutableDictionary alloc] init];
    
    falconProcessInfoDic[kBDWebviewResLoaderNameKey] = @"falcon";
    falconProcessInfoDic[kBDWebviewResLoaderVersionKey] = kFalconResLoaderVersion;
    falconProcessInfoDic[kBDWebviewResSrcKey] = self.URL.absoluteString;
    falconProcessInfoDic[kBDWebviewGeckoSyncUpdateKey] = @(NO);
    falconProcessInfoDic[kBDWebviewCDNCacheEnableKey] = @(NO);
    falconProcessInfoDic[kBDWebviewResSceneKey] = @"other";
    
    NSString *dataRequestType = [self.URL.path.pathExtension lowercaseString];
    falconProcessInfoDic[kBDWebviewResTypeKey] = BTD_isEmptyString(dataRequestType) ? @"falcon_intercept_request" : dataRequestType;
    
    falconProcessInfoDic[kBDWebviewResFromKey] = @"cdn";
    falconProcessInfoDic[kBDWebviewIsMemoryKey] = @(NO);
    falconProcessInfoDic[kBDWebviewResStateKey] = @"failed";
    falconProcessInfoDic[kBDWebviewGeckoConfigFromKey] = @"custom_config";
    
    self.bdw_falconProcessInfoRecord = falconProcessInfoDic;
}

@end

