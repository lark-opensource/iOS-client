//
//  BDWebPreloadOfflineInterceptor.m
//  Aweme
//
//  Created by bytedance on 2022/6/22.
//

#import "BDWebPreloadOfflineInterceptor.h"

#import <BDWebKit/IESFalconManager.h>
#import <BDWebKit/BDWebContentPreloadManager.h>
#import <BDWebKit/BDWebResourceMonitorEventType.h>
#import <BDALogProtocol/BDALogProtocol.h>
#import <BDPreloadSDK/BDPreloadCachedResponse.h>
#import <WebKit/WKWebView.h>


static NSString * const kLogTag = @"ResourceLoaderInterceptor";


@interface BDXResourceLoaderPreloadMetaData : NSObject<IESFalconMetaData>
@property (nonatomic, assign) NSTimeInterval saveTime;
@property (nonatomic, assign) NSTimeInterval cacheDuration;

@property (nonatomic, readwrite) NSDictionary *allHeaderFields;
@property (nonatomic, readwrite) NSInteger    statusCode;
@end

@implementation BDXResourceLoaderPreloadMetaData

@synthesize falconData;
@synthesize statModel;
@synthesize statusCode = _statusCode;
@synthesize allHeaderFields = _allHeaderFields;

@end



@interface BDWebPreloadOfflineInterceptor () <IESFalconCustomInterceptor>

@property (nonatomic, weak) WKWebView *webview;

@end

@implementation BDWebPreloadOfflineInterceptor

+ (void)setupWithWebView:(WKWebView *)webview
{
    if (![webview isKindOfClass:[WKWebView class]]) {
        return;
    }
    
    BDWebPreloadOfflineInterceptor *interceptor = [[BDWebPreloadOfflineInterceptor alloc] init];
    [webview bdw_registerFalconCustomInterceptor:interceptor];
    interceptor.webview = webview;
    
    BDALOG_PROTOCOL_INFO_TAG(kLogTag, @"register BDWebPreloadOfflineInterceptor with %@", webview);
    return;
}

#pragma mark - Helper

+ (NSString *)webContainerId:(WKWebView *)webView {
    NSString *containerId = @"";
    if ([webView respondsToSelector:@selector(reactID)]) { // containerId in BDXWebView
        containerId = [webView performSelector:@selector(reactID)];
    } else if ([webView respondsToSelector:@selector(iwk_containerID)]) { // containerId in IESWKWebView
        containerId = [webView performSelector:@selector(iwk_containerID)];
    }
    
    if (![containerId isKindOfClass:[NSString class]] || containerId.length == 0) {
        containerId = [[NSUUID UUID] UUIDString]; // UUID 兜底
    }
    
    return containerId;
}

#pragma mark - IESFalconCustomInterceptor

- (id<IESFalconMetaData>)falconMetaDataForURLRequest:(NSURLRequest *)request {
    if ([request.URL.absoluteString hasPrefix:@"about://waitfix"]) {
        return nil;
    }
   
    double startTime = [[NSDate date] timeIntervalSince1970] * 1000;
    BDPreloadCachedResponse *response = [BDWebContentPreloadManager fetchWebResourceSync:request.URL.absoluteString];
    double endTime = [[NSDate date] timeIntervalSince1970] * 1000;
    if (response.data == 0) {
        BDALOG_PROTOCOL_INFO_TAG(kLogTag, @"BDWebPreloadOfflineInterceptor no offline resource for %@", request.URL);
        return nil;
    }
    
    BDXResourceLoaderPreloadMetaData *metaData = [BDXResourceLoaderPreloadMetaData new]; //BDPreloadCacheResponse为实现IESFalconMetaData协议。虽然参数名相同可以使用，但检查不过。故新增一个实例
    metaData.falconData = response.data;
    metaData.statusCode = response.statusCode;
    metaData.allHeaderFields = response.allHeaderFields;
    metaData.saveTime = response.saveTime;
    metaData.cacheDuration = response.cacheDuration;
    // 监控埋点
    NSMutableDictionary *record = [NSMutableDictionary dictionaryWithDictionary:request.bdw_falconProcessInfoRecord];
    record[kBDWebviewCDNCacheStartKey] = @(startTime);
    record[kBDWebviewCDNCacheFinishKey] = @(endTime);
    record[@"rl_container_uuid"] = [BDWebPreloadOfflineInterceptor webContainerId:self.webview];
    record[kBDWebviewResLoaderNameKey] = @"bdpreloader";
    record[kBDWebviewResSrcKey] = request.URL.absoluteString ?: @"";
    record[kBDWebviewCDNCacheEnableKey] = @(YES);
    record[kBDWebviewResSizeKey] = @(response.data.length);
    record[kBDWebviewResLoadStartKey] = @(startTime);
    record[kBDWebviewResLoadFinishKey] = @(endTime);
    record[kBDWebviewIsPreloadedKey] = @(1);
    request.bdw_falconProcessInfoRecord = record;
    
    BDALOG_PROTOCOL_INFO_TAG(kLogTag, @"BDWebPreloadOfflineInterceptor get offline resource for %@, from:%@", request.URL, @"web preload offline");
    return metaData;
}

- (NSUInteger)falconPriority
{
    return 10;
}

- (BOOL)shouldInterceptForRequest:(NSURLRequest*)request
{
    BOOL exist = [BDWebContentPreloadManager existPageCacheForURLString:request.URL.absoluteString];
    if (!exist) {
        BDALOG_PROTOCOL_INFO_TAG(kLogTag, @"BDWebPreloadOfflineInterceptor not offline resource for %@", request.URL);
        return NO;
    }

    BDALOG_PROTOCOL_INFO_TAG(kLogTag, @"BDWebPreloadOfflineInterceptor find offline resource for %@", request.URL);
    return YES;
}

@end

