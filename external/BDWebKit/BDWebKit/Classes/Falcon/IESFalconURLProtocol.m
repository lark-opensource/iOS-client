//
//  IESFalconURLProtocol.m
//  IESGeckoKit
//
//  Created by li keliang on 2018/10/9.
//

#import "IESFalconURLProtocol.h"
#import "IESFalconManager.h"
#import "IESFalconManager+InterceptionDelegate.h"
#import "IESFalconStatRecorder.h"
#import "NSURLProtocol+WebKitSupport.h"
#import "NSData+ETag.h"
#import "QNSURLSessionDemux.h"
#import "IESFalconDebugLogger.h"
#import "BDWebKitUtil.h"
#import <TTNetworkManager/TTNetworkManager.h>
#import <TTNetworkManager/TTHttpResponseChromium.h>
#import <TTNetworkManager/NSURLRequest+WebviewInfo.h>
#import <ByteDanceKit/ByteDanceKit.h>
#import <BDWebKit/BDWebKitSettingsManger.h>
#import "WKWebView+BDPrivate.h"
#import "IESFalconWebURLProtocolTask.h"
#import "BDWebURLSchemeProtocolClass.h"
#import "BDWebKitMainFrameModel.h"
#import <BDWebKit/BDWebResourceMonitorEventType.h>
#import <BDWebKit/BDWebURLSchemeTaskHandler.h>

#import <BDPreloadSDK/BDWebViewPreloadTask.h>
#import <BDPreloadSDK/BDWebViewPreloadManager.h>


#if __has_include("IESWebPRepresentation.h")
#import "IESWebPRepresentation.h"
#endif

#define dispatch_main($block) ([NSThread isMainThread] ? $block() : dispatch_sync(dispatch_get_main_queue(), $block))

@implementation NSURL (HttpScheme)

- (BOOL)ies_isHttpURL
{
    return [self.scheme isEqualToString:@"http"] || [self.scheme isEqualToString:@"https"];
}

@end

static NSString * const kFalconRecursiveRequestFlagProperty = @"com.byted.IESFalconURLProtocol";
static NSString * const kFalconTTPUserAgentParam = @"TTP_H5_URLPROTOCOL";

@interface IESFalconURLProtocol () <NSURLSessionDataDelegate, BDWebURLSchemeProtocolClass>

@property (nonatomic, strong) TTHttpTask *httpTask;
@property (nonatomic, readwrite, copy) NSURLRequest *fixedRequest;
@property (nonatomic, assign) BOOL hasReceivedData;
@property (atomic) id<BDWebURLProtocolTask> urlProtocolTask;
@property (nonatomic, assign) NSTimeInterval httpTaskStartTime;
@property (nonatomic, strong) BDWebViewPreloadTask *preloadTask;

@property (atomic) NSURLSessionDataTask *task;
@property (atomic, copy) NSArray        *modes;

@property (atomic) NSDate *onlineStartDate;
@property (atomic) IESFalconStatModel *onlineStatModel;

@end

@implementation IESFalconURLProtocol

+ (QNSURLSessionDemux *)sharedDemux
{
    static dispatch_once_t      sOnceToken;
    static QNSURLSessionDemux * sDemux;
    dispatch_once(&sOnceToken, ^{
        NSURLSessionConfiguration *config;
        config = [NSURLSessionConfiguration defaultSessionConfiguration];
        // You have to explicitly configure the session to use your own protocol subclass here
        // otherwise you don't see redirects <rdar://problem/17384498>.
        config.protocolClasses = @[ self ];
        sDemux = [[QNSURLSessionDemux alloc] initWithConfiguration:config];
    });
    return sDemux;
}

+ (NSMutableDictionary *)temporaryResponseDataHash
{
    static NSMutableDictionary *temporaryResponseDataHash;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        temporaryResponseDataHash = [NSMutableDictionary new];
    });
    return temporaryResponseDataHash;
}

#pragma mark - TTNet

- (BOOL)_willCallLoadingFailedWithResponse:(TTHttpResponse *)response withError:(NSError *)error {
    if (error) {
        // TTNet 内部会把非 2xx 的返回认为是 error，导致 WebView 加载失败
        if (error.code == NSURLErrorBadServerResponse && [error.localizedDescription containsString:@"is not 2xx"]) {
            if (self.hasReceivedData) {
                return NO;
            }
            
            if (response.statusCode == 304) {
                return NO;
            }
        }
        
        return YES;
    } else {
        // 如果ttnet连建立连接都失败了,会直接返回-1状态码,但此时error为空
        if (response.statusCode == -1) {
            return YES;
        }
    }
    
    return NO;
}

- (void)handleTTNetworkHeaderResponse:(TTHttpResponse *)response {
    if (self.hasReceivedData) {
        return;
    }
    NSHTTPURLResponse *nsResponse = [[NSHTTPURLResponse alloc] initWithURL:response.URL statusCode:response.statusCode HTTPVersion:@"HTTP/1.1" headerFields:response.allHeaderFields];
    [self.client URLProtocol:self didReceiveResponse:nsResponse cacheStoragePolicy:NSURLCacheStorageAllowed];
    
    if (self.urlProtocolTask) {
        [IESFalconManager bdw_URLProtocolTask:self.urlProtocolTask didReceiveResponse:nsResponse];
    }
}

- (void)handleTTNetworkDataResponse:(NSData *)data {
    self.hasReceivedData = YES;
    @try {
        [self.client URLProtocol:self didLoadData:data];
        
        if (self.urlProtocolTask) {
            [IESFalconManager bdw_URLProtocolTask:self.urlProtocolTask didLoadData:data];
        }
    } @catch (NSException *exception) {
        NSString *exceptionStr = exception.description?exception.description:@"";
        IESFalconDebugLog(@"【URLProtocol】handleTTNetworkDataResponse error【exception => %@】", exceptionStr);
    }
}

- (void)recordTTNetResponse:(TTHttpResponse *)response withError:(NSError *)error
{
    NSTimeInterval httpTaskFinishTime = [NSDate date].timeIntervalSince1970 * 1000;
    self.urlProtocolTask.bdw_falconProcessInfoRecord[kBDWebviewCDNStartKey] = @(self.httpTaskStartTime);
    self.urlProtocolTask.bdw_falconProcessInfoRecord[kBDWebviewCDNFinishKey] = @(httpTaskFinishTime);
    self.urlProtocolTask.bdw_falconProcessInfoRecord[kBDWebviewResFromKey] = @"cdn";
    self.urlProtocolTask.bdw_falconProcessInfoRecord[kBDWebviewResSizeKey] = @(response.timinginfo.totalReceivedBytes);
    self.urlProtocolTask.bdw_falconProcessInfoRecord[kBDWebviewResLoadFinishKey] = @(httpTaskFinishTime);
    self.urlProtocolTask.bdw_falconProcessInfoRecord[kBDWebviewResStateKey] = @"success";
    if (error) {
        NSString *errorDescription = error.localizedDescription ? : @"unknown";
        NSString *oldErrorMsg = self.urlProtocolTask.bdw_falconProcessInfoRecord[kBDWebviewResErrorMsgKey];
        if (BTD_isEmptyString(oldErrorMsg)) {
            self.urlProtocolTask.bdw_falconProcessInfoRecord[kBDWebviewResErrorMsgKey] = errorDescription;
        } else {
            self.urlProtocolTask.bdw_falconProcessInfoRecord[kBDWebviewResErrorMsgKey] = [NSString stringWithFormat:@"%@  {%@}", oldErrorMsg, errorDescription];
        }
        
        self.urlProtocolTask.bdw_falconProcessInfoRecord[kBDWebviewResStateKey] = @"failed";
    }
    
    if (BTD_isEmptyString(self.urlProtocolTask.bdw_falconProcessInfoRecord[kBDWebviewResLoaderNameKey])) {
        self.urlProtocolTask.bdw_falconProcessInfoRecord[kBDWebviewResLoaderNameKey] = @"IESFalconURLProtocol";
    }
    
    // res version from gecko cdn response
    self.urlProtocolTask.bdw_falconProcessInfoRecord[kBDWebviewResVersionKey] = @([response.allHeaderFields btd_integerValueForKey:@"x-gecko-proxy-pkgid"]);
    
    if (!self.urlProtocolTask.bdw_falconProcessInfoRecord[kBDWebviewExtraKey] || [self.urlProtocolTask.bdw_falconProcessInfoRecord[kBDWebviewExtraKey] isKindOfClass:[NSDictionary class]]) {
        self.urlProtocolTask.bdw_falconProcessInfoRecord[kBDWebviewExtraKey] = [[NSMutableDictionary alloc] init];
    }
    NSDictionary *headerDict = [IESFalconURLProtocol ttnetResponseHeaders:response];
    self.urlProtocolTask.bdw_falconProcessInfoRecord[kBDWebviewExtraKey][kBDWebviewExtraHTTPResponseHeadersKey] = [IESFalconURLProtocol responseHeaderStringFromDic:headerDict];
    
    self.urlProtocolTask.bdw_ttnetResponseTimingInfoRecord = [IESFalconURLProtocol ttnetResponseTimingInfo:response];
    
    if (self.urlProtocolTask.willRecordForMainFrameModel) {
        [self webView:self.urlProtocolTask.bdw_webView willRecordMainFrameModel:self.urlProtocolTask];
    }
}

- (void)handleTTNetworkFinishResponse:(TTHttpResponse *)response withObj:(id)obj withError:(NSError *)error {
    if ([self _willCallLoadingFailedWithResponse:response withError:error]) {
        if (!error) {
            // -106为Chromium网络断开连接错误码
            NSMutableDictionary *userInfo = [[NSMutableDictionary alloc] init];
            NSURL *url = response.URL;
            NSString *description = @"ERR_ESTABLISH_CONNECTION";
            [userInfo setValue:url forKey:NSURLErrorFailingURLErrorKey];
            [userInfo setValue:description forKey:NSLocalizedDescriptionKey];
            [userInfo setValue:@"-106" forKey:@"error_num"];
            error = [[NSError alloc] initWithDomain:kTTNetworkErrorDomain code:-106 userInfo:userInfo];
        }
        [self.client URLProtocol:self didFailWithError:error];
        
        if (self.urlProtocolTask) {
            [self recordTTNetResponse:response withError:error];
            [IESFalconManager bdw_URLProtocolTask:self.urlProtocolTask didFailWithError:error];
        }
    } else {
        [self.client URLProtocolDidFinishLoading:self];
        
        if (self.urlProtocolTask) {
            [self recordTTNetResponse:response withError:error];
            [IESFalconManager bdw_URLProtocolTaskDidFinishLoading:self.urlProtocolTask];
        }
    }
}

- (void)handleTTNetworkRedrectResponse:(TTHttpResponse *)old_repsonse withNewLocation:(NSString *)new_location {
    if (self.hasReceivedData) {
        return;
    }
    
    if (old_repsonse.isInternalRedirect) {
        // TTNet 内部做多机房调度时,模拟重定向实现的,因此上层需要忽略该类型的重定向
        return;
    }

    NSURL *newURL = [NSURL URLWithString:new_location];
    NSMutableURLRequest *newRequest = self.fixedRequest.mutableCopy;
    newRequest.URL = newURL;
    NSHTTPURLResponse *oldResponse = [[NSHTTPURLResponse alloc] initWithURL:old_repsonse.URL statusCode:old_repsonse.statusCode HTTPVersion:@"HTTP/1.1" headerFields:old_repsonse.allHeaderFields];
    [self.client URLProtocol:self wasRedirectedToRequest:newRequest redirectResponse:oldResponse];
    
    if (self.urlProtocolTask) {
        [IESFalconManager bdw_URLProtocolTask:self.urlProtocolTask didPerformRedirection:oldResponse newRequest:newRequest];
    }
}

#pragma mark - BDWebURLSchemeProtocolClass

+ (BOOL)canInitWithSchemeTask:(id<BDWebURLSchemeTask>)schemeTask
{
    // only check local data and request is http&https, no about:waitfix
    NSURLRequest *request = [schemeTask bdw_request];
    
    if ([[NSURLProtocol propertyForKey:kFalconRecursiveRequestFlagProperty inRequest:request] boolValue]) {
        return NO;
    }
    
    if ([request.URL.absoluteString isEqualToString:@"about:blank"]) {
        // skip about:blank
        return NO;
    }
    
    if (![request.HTTPMethod isEqualToString:@"GET"]) {
        // only handle GET request
        return NO;
    }
    
    if (request.URL.ies_isHttpURL) {
        // adapt to UIWebView
        id<IESFalconMetaData> metaData = [IESFalconManager falconMetaDataForURLRequest:request webView:schemeTask.bdw_webView];
        BOOL found = (metaData.falconData.length > 0);
        
        if (request.bdw_falconProcessInfoRecord) {
            NSMutableDictionary *falconData = [[NSMutableDictionary alloc] init];
            [falconData addEntriesFromDictionary:[request.bdw_falconProcessInfoRecord copy]];
            // previous data has higher priority
            [falconData addEntriesFromDictionary:schemeTask.bdw_rlProcessInfoRecord];
            schemeTask.bdw_rlProcessInfoRecord = falconData;
        }
        
        if (found) {
            return YES;
        }
    }
    
    [IESFalconManager callingOutFalconInterceptedRequest:request willLoadFromCache:NO];
    return NO;
}

#pragma mark - NSURLProtocol

+ (BOOL)canInitWithRequest:(NSURLRequest *)request
{
    if ([[NSURLProtocol propertyForKey:kFalconRecursiveRequestFlagProperty inRequest:request] boolValue]) {
        return NO;
    }
    
    if ([request.URL.absoluteString isEqualToString:@"about:blank"]) {
        // skip about:blank
        return NO;
    }
    
    if (![request.HTTPMethod isEqualToString:@"GET"]) {
        // only handle GET request
        return NO;
    }
    
    if (request.URL.ies_isHttpURL) {
        // adapt to UIWebView
        id<IESFalconMetaData> metaData = [IESFalconManager falconMetaDataForURLRequest:request];
        BOOL found = (metaData.falconData.length > 0);
        if (!found) {
            [IESFalconManager callingOutFalconInterceptedRequest:request willLoadFromCache:NO];
            
            IESFalconStatModel *statModel = metaData.statModel;
            statModel.resourceURLString = request.URL.absoluteString;
            [IESFalconStatRecorder recordFalconStat:[statModel statDictionary]];

            if (request.useURLProtocolOnlyLocal){
                return NO;
            }
            
            // get UserAgent, check if 'TTP_H5' exist
            NSDictionary *headersFields = request.allHTTPHeaderFields;
            NSString *userAgentValue = [headersFields btd_stringValueForKey:@"User-Agent"];
            if (userAgentValue && [userAgentValue isKindOfClass:[NSString class]] && (userAgentValue.length > 0)) {
                if ([userAgentValue containsString:kFalconTTPUserAgentParam]) {
                    return YES;
                }
            }
        }
        return found;
    }
    
    if (IESFalconManager.webpDecodeEnable && [request.URL.pathExtension isEqualToString:@"webp"]) {
        return YES;
    }
    
    if (request.mainDocumentURL && ([request.URL.scheme isEqualToString:@"about"] &&
        [request.URL.resourceSpecifier hasPrefix:@"wk"])) {
        // adapt to WKWebView and new UIWebView
        return YES;
    }
    
    [IESFalconManager callingOutFalconInterceptedRequest:request willLoadFromCache:NO];
    return NO;
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request
{
    // get UserAgent, check if 'TTP_H5' exist
    NSDictionary *headersFields = request.allHTTPHeaderFields;
    NSString *userAgentValue = [headersFields btd_stringValueForKey:@"User-Agent"];
    if (userAgentValue && [userAgentValue isKindOfClass:[NSString class]] && (userAgentValue.length > 0)) {
        if ([userAgentValue containsString:kFalconTTPUserAgentParam]) {
            return [IESFalconManager willDecorateRequest:request];
        }
    }
    return request;
}

+ (NSURLRequest *)falconFixedRequest:(NSURLRequest *)request
{
    NSMutableURLRequest *mutableRequest = [request mutableCopy];
    
    if (request.URL.ies_isHttpURL) {
        [NSURLProtocol setProperty:@(YES) forKey:kFalconRecursiveRequestFlagProperty inRequest:mutableRequest];
        return mutableRequest;
    }
    
    NSString *theRealScheme = @"https";
    // trim prefix about:
    NSString *trimSchemeURLString = [request.URL.absoluteString substringFromIndex:request.URL.scheme.length + 1];
    
    if ([request.URL.resourceSpecifier hasPrefix:@"wk?:"] && request.mainDocumentURL) {
        trimSchemeURLString = [trimSchemeURLString stringByReplacingOccurrencesOfString:@"wk?" withString:@"wkx" options:0 range:NSMakeRange(0, 3)];
        theRealScheme = mutableRequest.mainDocumentURL.scheme;
    } else if ([request.URL.resourceSpecifier hasPrefix:@"wks:"]) {
        theRealScheme = @"https";
    } else if ([request.URL.resourceSpecifier hasPrefix:@"wk:"]) {
        theRealScheme = @"http";
    } else {
        NSAssert(NO, @"Unknown request scheme with url %@", request.URL);
    }
    if (trimSchemeURLString.length == 0) {
        // fix +[NSURLComponents componentsWithString:nil] crash
        return request;
    }
    
    NSURL *fixedURL = (NSURL *)({
        NSURLComponents *fixedComponents = [NSURLComponents componentsWithString:trimSchemeURLString];
        fixedComponents.scheme = theRealScheme;
        fixedComponents.URL;
    });
    mutableRequest.URL = fixedURL;
    [NSURLProtocol setProperty:@(YES) forKey:kFalconRecursiveRequestFlagProperty inRequest:mutableRequest];
    
    return mutableRequest;
}

- (void)startLoading
{
    [self startLoadingWithWebView:nil];
}

- (void)startLoadingWithWebView:(WKWebView *)webView
{
    NSParameterAssert(self.task == nil);
    
    if (self.request.URL.absoluteString.length == 0) {
        [self.client URLProtocol:self didFailWithError:[NSError errorWithDomain:@"BDWebKitEmptyURLError" code:0 userInfo:nil]];
        return;
    }
    
    NSDate *startDate = [NSDate date];
    BOOL useURLProtocolOnlyLocal = self.request.useURLProtocolOnlyLocal;
    IESFalconWebURLProtocolTask *webTask = nil;
    
    NSURLRequest *fixedRequest = [self.class falconFixedRequest:self.request];
    
    if (!useURLProtocolOnlyLocal) {
        webTask = [[IESFalconWebURLProtocolTask alloc] init];
        webTask.bdw_request = fixedRequest;
        webTask.taskFinishWithLocalData = NO;
        webTask.taskFinishWithTTNet = NO;
        webTask.taskFromHookAjax = NO;
        webTask.ttnetEnableCustomizedCookie = NO;
        webTask.bdw_falconProcessInfoRecord = [[NSMutableDictionary alloc] init];
        
        if (webView) {
            webTask.bdw_webView = webView;
        } else {
            NSDictionary *headerFields = fixedRequest.allHTTPHeaderFields;
            NSString *uaStr = [headerFields btd_stringValueForKey:@"User-Agent"];
            if (uaStr && [uaStr isKindOfClass:[NSString class]] && (uaStr.length > 0)) {
                webTask.bdw_webView = [IESFalconManager webviewWithUserAgent:uaStr];
            }
        }
        
        NSString *webURL = @"";
        if (webTask.bdw_webView) {
            if ([NSThread isMainThread]) {
                webURL = webTask.bdw_webView.URL.absoluteString ?: fixedRequest.URL.absoluteString;
            } else {
                webURL = webTask.bdw_webView.bdw_mainFrameModelRecord.latestWebViewURLString ?: @""; // update by decidePolicyForNavigationAction
            }
        }
        if (!BTD_isEmptyString(webURL) && [webURL isEqualToString:fixedRequest.URL.absoluteString]) {
            webTask.willRecordForMainFrameModel = YES;
        }
    }

    id<IESFalconMetaData> metaData = [IESFalconManager falconMetaDataForURLRequest:fixedRequest
                                                                           webView:(webTask ? webTask.bdw_webView : webView)];
    
    NSData *falconData = metaData.falconData;
    
    NSDictionary *allHeaderFields = nil;
    if ([metaData respondsToSelector:@selector(allHeaderFields)]) {
        allHeaderFields = metaData.allHeaderFields;
    }
    
    NSInteger statusCode = 0;
    if ([metaData respondsToSelector:@selector(statusCode)]) {
        statusCode = metaData.statusCode;
    }
    
    
    IESFalconStatModel *statModel = metaData.statModel;
    if (metaData) {
        statModel.resourceURLString = self.request.URL.absoluteString;
    }
    
    [IESFalconManager callingOutFalconInterceptedRequest:fixedRequest willLoadFromCache:(falconData.length > 0)];
    
    if (webTask) {
        [IESFalconManager willDecorateURLProtocolTask:webTask];
        [webTask.bdw_falconProcessInfoRecord addEntriesFromDictionary:fixedRequest.bdw_falconProcessInfoRecord];
        webTask.bdw_falconProcessInfoRecord[kBDWebviewResSceneKey] = webTask.willRecordForMainFrameModel ? @"web_main_document" : @"web_child_resource";
        webTask.bdw_falconProcessInfoRecord[kBDWebviewResSrcKey] = fixedRequest.URL.absoluteString;
        
        self.urlProtocolTask = webTask;
    }
    
    if (falconData.length > 0) {
        IESFalconDebugLog(@"【URLProtocol】Start loading local resource【URL => %@】", self.request.URL.absoluteString);
        if (IESFalconManager.webpDecodeEnable && IESDataIsWebPFormat(falconData)) {
            NSError *error;
            NSData  *convertData = IESConvertDataWebP2APNG(falconData, &error);
            if (!error && convertData.length > 0) {
                falconData = convertData;
            }
        }
        
        if (self.urlProtocolTask) {
            self.urlProtocolTask.taskFinishWithLocalData = YES;
            NSString *resFrom = self.urlProtocolTask.bdw_falconProcessInfoRecord[kBDWebviewResFromKey];
            if (BTD_isEmptyString(resFrom)) {
                self.urlProtocolTask.bdw_falconProcessInfoRecord[kBDWebviewResFromKey] = @"offline";
            }
        }
        
        NSString *requestETag = fixedRequest.allHTTPHeaderFields[@"If-None-Match"];
        NSString *falconDataEtag = falconData.ies_eTag;
        NSParameterAssert(falconData.length > 0);
        
        NSMutableDictionary *headerFields = [(allHeaderFields ?: @{@"ETag":falconDataEtag, @"Access-Control-Allow-Origin" : @"*"}) mutableCopy];
        
        if (headerFields[@"Content-Type"] == nil && headerFields[@"content-type"] == nil) {
            NSString *extension = [self.request.URL pathExtension];
            if (extension == nil) {
                extension = [fixedRequest.URL pathExtension];
            }
            NSString *contentType = [BDWebKitUtil contentTypeOfExtension:extension];
            if (contentType) {
                headerFields[@"Content-Type"] = contentType;
            }
        }
        
        if (requestETag.length > 0 && [requestETag isEqualToString:falconDataEtag]) {
            NSURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:fixedRequest.URL statusCode:304 HTTPVersion:nil headerFields:headerFields];
            
            [self.client URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageAllowed];
            if (self.urlProtocolTask) {
                [IESFalconManager bdw_URLProtocolTask:self.urlProtocolTask didReceiveResponse:response];
            }
            
            [self.client URLProtocolDidFinishLoading:self];
            if (self.urlProtocolTask) {
                self.urlProtocolTask.bdw_falconProcessInfoRecord[kBDWebviewResLoadFinishKey] = @([[NSDate date] timeIntervalSince1970] * 1000);
                self.urlProtocolTask.bdw_falconProcessInfoRecord[kBDWebviewResStateKey] = @"success";
                if (self.urlProtocolTask.willRecordForMainFrameModel) {
                    [self webView:self.urlProtocolTask.bdw_webView willRecordMainFrameModel:self.urlProtocolTask];
                }
                
                [IESFalconManager bdw_URLProtocolTaskDidFinishLoading:self.urlProtocolTask];
            }
        } else {
            BOOL requestHeaderForMp4RangeFile = NO;
            if ([fixedRequest.URL.pathExtension isEqualToString:@"mp4"]) {
                NSData *rangeFalconData = [BDWebKitUtil rangeDataForVideo:falconData withRequest:fixedRequest withResponseHeaders:headerFields];
                if (rangeFalconData && (rangeFalconData.length > 0)) {
                    requestHeaderForMp4RangeFile = YES;
                    falconData = rangeFalconData;
                }
            }
            
            statusCode = requestHeaderForMp4RangeFile ? 206 : statusCode;
            NSURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:fixedRequest.URL statusCode:statusCode > 0 ? statusCode:200 HTTPVersion:nil headerFields:headerFields];
            
            [self.client URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageAllowed];
            if (self.urlProtocolTask) {
                [IESFalconManager bdw_URLProtocolTask:self.urlProtocolTask didReceiveResponse:response];
            }
            
            [self.client URLProtocol:self didLoadData:falconData];
            if (self.urlProtocolTask) {
                [IESFalconManager bdw_URLProtocolTask:self.urlProtocolTask didLoadData:falconData];
            }
            
            [self.client URLProtocolDidFinishLoading:self];
            if (self.urlProtocolTask) {
                self.urlProtocolTask.bdw_falconProcessInfoRecord[kBDWebviewResLoadFinishKey] = @([[NSDate date] timeIntervalSince1970] * 1000);
                self.urlProtocolTask.bdw_falconProcessInfoRecord[kBDWebviewResStateKey] = @"success";
                if (self.urlProtocolTask.willRecordForMainFrameModel) {
                    [self webView:self.urlProtocolTask.bdw_webView willRecordMainFrameModel:self.urlProtocolTask];
                }
                
                [IESFalconManager bdw_URLProtocolTaskDidFinishLoading:self.urlProtocolTask];
            }
        }
        
        statModel.offlineDuration = (NSInteger)([[NSDate date] timeIntervalSinceDate:startDate] * 1000);
        [IESFalconStatRecorder recordFalconStat:[statModel statDictionary]];
        
    } else {
        if ([IESFalconManager willBlockRequest:fixedRequest]) {
            // make response headers
            NSMutableDictionary *headerFields = [@{@"ETag":@"0000000000000000", @"Access-Control-Allow-Origin" : @"*"} mutableCopy];
            NSString *extension = [fixedRequest.URL pathExtension];
            NSString *contentType = [BDWebKitUtil contentTypeOfExtension:extension];
            if (contentType) {
                headerFields[@"Content-Type"] = contentType;
            }
            // make data
            NSData *data = [@"0000000000000000" dataUsingEncoding:NSUTF8StringEncoding];

            NSURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:fixedRequest.URL statusCode:200 HTTPVersion:nil headerFields:headerFields];
            [self.client URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageAllowed];
            [self.client URLProtocol:self didLoadData:data];
            [self.client URLProtocolDidFinishLoading:self];
            return;
        }

        self.httpTaskStartTime = [NSDate date].timeIntervalSince1970 * 1000;
        BOOL isWebPRequest = IESFalconManager.webpDecodeEnable && [self.request.URL.pathExtension isEqualToString:@"webp"];
        if (!isWebPRequest && [BDWebKitSettingsManger useTTNetForFalcon]) {
            // use ttnet request
            IESFalconDebugLog(@"【URLProtocol】Fallback to online(ttnet) resource【URL => %@】", self.request.URL.absoluteString);
            
            __weak typeof(self)weakSelf = self;
            TTNetworkChunkedDataHeaderBlock headerCB = ^(TTHttpResponse *response) {
                dispatch_main(^(){
                    __strong __typeof(weakSelf)strongSelf = weakSelf;
                    [strongSelf handleTTNetworkHeaderResponse:response];
                });
            };
            
            TTNetworkChunkedDataReadBlock dataCB = ^(NSData *data) {
                dispatch_main(^(){
                    __strong __typeof(weakSelf)strongSelf = weakSelf;
                    [strongSelf handleTTNetworkDataResponse:data];
                });
            };
            
            TTNetworkObjectFinishBlockWithResponse finishCB = ^(NSError *error, id obj, TTHttpResponse *response) {
                dispatch_main(^(){
                    __strong __typeof(weakSelf)strongSelf = weakSelf;
                    
                    NSMutableDictionary *userInfo = [error.userInfo mutableCopy];
                    id errorUrl = [userInfo objectForKey:NSURLErrorFailingURLErrorKey];
                    if ([errorUrl isKindOfClass:NSString.class]) {
                        NSURL *url = [NSURL URLWithString:errorUrl];
                        [userInfo setValue:url forKey:NSURLErrorFailingURLErrorKey];
                        NSError *mError = [NSError errorWithDomain:error.domain code:error.code userInfo:userInfo];
                        [strongSelf handleTTNetworkFinishResponse:response withObj:obj withError:mError];
                    } else {
                        [strongSelf handleTTNetworkFinishResponse:response withObj:obj withError:error];
                    }
                });
            };

            TTNetworkURLRedirectBlock redirectCB = ^(NSString *new_location, TTHttpResponse *old_repsonse) {
                dispatch_main(^(){
                    __strong __typeof(weakSelf)strongSelf = weakSelf;
                    [strongSelf handleTTNetworkRedrectResponse:old_repsonse withNewLocation:new_location];
                });
            };

            if (self.urlProtocolTask) {
                self.urlProtocolTask.taskFinishWithTTNet = YES;
            }
            
            BDWebViewPreloadTask *preloadTask = nil;
            self.urlProtocolTask.bdw_falconProcessInfoRecord[kBDWebviewEnableRequestReuseKey] = @(self.urlProtocolTask.bdw_shouldUseNetReuse);
            if (self.urlProtocolTask && self.urlProtocolTask.bdw_shouldUseNetReuse
                && (preloadTask = [BDWebViewPreloadManager.sharedInstance taskForURLString:self.urlProtocolTask.bdw_request.URL.absoluteString])) {
                self.preloadTask = preloadTask;
                preloadTask.headerCallback = headerCB;
                preloadTask.dataCallback = dataCB;
                preloadTask.redirectCallback = redirectCB;
                preloadTask.callbackWithResponse = finishCB;
                self.urlProtocolTask.bdw_falconProcessInfoRecord[kBDWebviewResLoaderNameKey] = @"bdpreloader";
                self.urlProtocolTask.bdw_falconProcessInfoRecord[kBDWebviewIsRequestReusedKey] = @(1);
                [preloadTask reResume];
            } else {
              
            NSMutableURLRequest *request = [fixedRequest mutableCopy];
            NSMutableDictionary *header = [request.allHTTPHeaderFields mutableCopy];
            header[@"X-TT-Web-Proxy"] = @"TTNet";
            request.allHTTPHeaderFields = header;
            self.fixedRequest = [request mutableCopy];
            
            // add associated object for webview info
            if (self.urlProtocolTask) {
                request.webviewInfo = [self.urlProtocolTask.bdw_additionalInfo copy];
                request.needCommonParams = self.urlProtocolTask.useTTNetCommonParams;
            }
            
            BOOL willEnableTTNetCacheControl = NO;
            if (self.urlProtocolTask && (self.urlProtocolTask.taskHttpCachePolicy != BDWebHTTPCachePolicyUseAppSetting)) {
                willEnableTTNetCacheControl = self.urlProtocolTask.taskHttpCachePolicy == BDWebHTTPCachePolicyEnableCache ? YES : NO;
            }
            
            self.httpTask = [[TTNetworkManager shareInstance] requestForWebview:request
                                                                       autoResume:NO
                                                                  enableHttpCache:willEnableTTNetCacheControl
                                                                   headerCallback:headerCB
                                                                     dataCallback:dataCB
                                                             callbackWithResponse:finishCB
                                                                 redirectCallback:redirectCB];
            self.httpTask.skipSSLCertificateError = YES;
            self.httpTask.timeoutInterval = [BDWebKitSettingsManger bdFixTTNetTimeout];
            if (self.urlProtocolTask) {
                self.httpTask.enableCustomizedCookie = self.urlProtocolTask.ttnetEnableCustomizedCookie;
            }
            [self.httpTask resume];
                
            }
        } else {
            NSParameterAssert(self.task  == nil);
            NSParameterAssert(self.modes == nil);
            
            IESFalconDebugLog(@"【URLProtocol】Fallback to online resource【URL => %@】", self.request.URL.absoluteString);
            
            if (metaData) {
                self.onlineStartDate = [NSDate date];
                self.onlineStatModel = statModel;
            }
            
            NSMutableArray *calculatedModes = [NSMutableArray array];
            [calculatedModes addObject:NSDefaultRunLoopMode];
            NSRunLoopMode currentMode = [[NSRunLoop currentRunLoop] currentMode];
            if ((currentMode != nil) && ! [currentMode isEqual:NSDefaultRunLoopMode] ) {
                [calculatedModes addObject:currentMode];
            }
            
            self.modes = calculatedModes;
            NSParameterAssert(self.modes.count > 0);
            
            self.task = [[[self class] sharedDemux] dataTaskWithRequest:fixedRequest delegate:self modes:self.modes];
            NSParameterAssert(self.task);
            
            [self.task resume];
        }
    }
}

- (void)stopLoading
{
    if (self.httpTask) {
        [self.httpTask cancel];
        self.httpTask = nil;
    } else if (self.preloadTask) {
        [self.preloadTask cancel];
        self.preloadTask = nil;
    }
    if (self.task) {
        [self.task cancel];
        self.task = nil;
        
        self.onlineStartDate = nil;
        self.onlineStatModel = nil;
    }
}

#pragma mark - Private

- (void)recordOnlineStatIfNeeded
{
    if (!self.onlineStatModel) {
        return;
    }
    if (self.onlineStartDate) {
        self.onlineStatModel.onlineDuration = (NSInteger)([[NSDate date] timeIntervalSinceDate:self.onlineStartDate] * 1000);
        self.onlineStartDate = nil;
    }
    [IESFalconStatRecorder recordFalconStat:[self.onlineStatModel statDictionary]];
    self.onlineStatModel = nil;
}

#pragma mark - RecordHTTPResponse

+ (NSSet *)falconMonitorResponseHeaders
{
    static NSSet *headers = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        headers = [NSSet setWithArray: @[
            @"content-type", @"content-length", @"content-encoding", @"x-gecko-proxy-logid", @"x-gecko-proxy-pkgid",
            @"x-gecko-proxy-tvid", @"x-tos-version-id", @"x-bdcdn-cache-status", @"x-cache", @"x-response-cache",
            @"x-tt-trace-host", @"via"
        ]];
    });
    return headers;
}

+ (NSDictionary *)ttnetResponseTimingInfo:(TTHttpResponse *)ttResponse
{
    if ([ttResponse isKindOfClass:[TTHttpResponseChromium class]]) {
        TTHttpResponseChromium *targetResponse = (TTHttpResponseChromium *)ttResponse;
        TTHttpResponseChromiumTimingInfo *timingInfo = targetResponse.timingInfo;
        
        // process request log
        NSDictionary *originRequestLogDic = [NSJSONSerialization JSONObjectWithData:[targetResponse.requestLog dataUsingEncoding:NSUTF8StringEncoding]
                                                                            options:0
                                                                              error:nil];
        NSMutableDictionary *processedRequestLogDic = [[NSMutableDictionary alloc] init];
        if ([originRequestLogDic isKindOfClass:[NSDictionary class]]) {
            if ([originRequestLogDic.allKeys containsObject:@"response"] && [originRequestLogDic[@"response"] isKindOfClass:[NSDictionary class]]) {
                processedRequestLogDic[@"response"] = [originRequestLogDic[@"response"] copy];
            }
            if ([originRequestLogDic.allKeys containsObject:@"timing"] && [originRequestLogDic[@"timing"] isKindOfClass:[NSDictionary class]]) {
                processedRequestLogDic[@"timing"] = [originRequestLogDic[@"timing"] copy];
            }
        }
        
        NSString *requestLogStr = nil;
        if ([NSJSONSerialization isValidJSONObject:processedRequestLogDic]) {
            NSData *data = [NSJSONSerialization dataWithJSONObject:processedRequestLogDic
                                                           options:kNilOptions
                                                             error:nil];
            requestLogStr = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
        }
        
        return @{
            @"ttnet_start" : @([timingInfo.start timeIntervalSince1970] * 1000),
            @"ttnet_proxy" : @(timingInfo.proxy),
            @"ttnet_dns" : @(timingInfo.dns),
            @"ttnet_connect" : @(timingInfo.connect),
            @"ttnet_ssl" : @(timingInfo.ssl),
            @"ttnet_send" : @(timingInfo.send),
            @"ttnet_wait" : @(timingInfo.wait),
            @"ttnet_receive" : @(timingInfo.receive),
            @"ttnet_total" : @(timingInfo.total),
            @"ttnet_receivedResponseContentLength" : @(timingInfo.receivedResponseContentLength),
            @"ttnet_totalReceivedBytes" : @(timingInfo.totalReceivedBytes),
            @"ttnet_isSocketReused" : @(timingInfo.isSocketReused),
            @"ttnet_isCached" : @(timingInfo.isCached),
            @"ttnet_isFromProxy" : @(timingInfo.isFromProxy),
            @"ttnet_requestLog" : requestLogStr
        };
    }
    return [[NSDictionary alloc] init];
}

+ (NSDictionary *)ttnetResponseHeaders:(TTHttpResponse *)ttResponse
{
    NSDictionary *dict = [ttResponse.allHeaderFields btd_filter:^BOOL(id _Nonnull key, id  _Nonnull obj) {
        return [[[self class] falconMonitorResponseHeaders] containsObject: key];
    }];
    return [dict copy];
}

+ (NSDictionary *)httpURLResponseHeaders:(NSHTTPURLResponse *)httpResponse
{
    NSDictionary *dict = [httpResponse.allHeaderFields btd_filter:^BOOL(id _Nonnull key, id  _Nonnull obj) {
        return [[[self class] falconMonitorResponseHeaders] containsObject: key];
    }];
    return [dict copy];
}

+ (NSString *)responseHeaderStringFromDic:(NSDictionary *)dict
{
    if (![NSJSONSerialization isValidJSONObject:dict]) {
        return [NSString stringWithFormat:@"%@", dict];
    }

    NSData *data = [NSJSONSerialization dataWithJSONObject:dict options:kNilOptions error:nil];
    return [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
}

#pragma mark - NSURLSessionDelegate

- (void)recordURLSession:(NSURLSession *)session task:(NSURLSessionTask *)dataTask finishWithError:(NSError *)error
{
    NSTimeInterval httpTaskFinishTime = [NSDate date].timeIntervalSince1970 * 1000;
    self.urlProtocolTask.bdw_falconProcessInfoRecord[kBDWebviewCDNStartKey] = @(self.httpTaskStartTime);
    self.urlProtocolTask.bdw_falconProcessInfoRecord[kBDWebviewCDNFinishKey] = @(httpTaskFinishTime);
    self.urlProtocolTask.bdw_falconProcessInfoRecord[kBDWebviewResFromKey] = @"cdn";
    self.urlProtocolTask.bdw_falconProcessInfoRecord[kBDWebviewResSizeKey] = @(dataTask.countOfBytesReceived);
    self.urlProtocolTask.bdw_falconProcessInfoRecord[kBDWebviewResLoadFinishKey] = @(httpTaskFinishTime);
    self.urlProtocolTask.bdw_falconProcessInfoRecord[kBDWebviewResStateKey] = @"success";
    if (error) {
        NSString *errorDescription = error.localizedDescription ? : @"unknown";
        NSString *oldErrorMsg = self.urlProtocolTask.bdw_falconProcessInfoRecord[kBDWebviewResErrorMsgKey];
        if (BTD_isEmptyString(oldErrorMsg)) {
            self.urlProtocolTask.bdw_falconProcessInfoRecord[kBDWebviewResErrorMsgKey] = errorDescription;
        } else {
            self.urlProtocolTask.bdw_falconProcessInfoRecord[kBDWebviewResErrorMsgKey] = [NSString stringWithFormat:@"%@  {%@}", oldErrorMsg, errorDescription];
        }
        
        self.urlProtocolTask.bdw_falconProcessInfoRecord[kBDWebviewResStateKey] = @"failed";
    }
    
    if (BTD_isEmptyString(self.urlProtocolTask.bdw_falconProcessInfoRecord[kBDWebviewResLoaderNameKey])) {
        self.urlProtocolTask.bdw_falconProcessInfoRecord[kBDWebviewResLoaderNameKey] = @"IESFalconURLProtocol";
    }
    
    // res version from gecko cdn response
    if ([dataTask.response isKindOfClass:[NSHTTPURLResponse class]]) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)dataTask.response;
        self.urlProtocolTask.bdw_falconProcessInfoRecord[kBDWebviewResVersionKey] = @([httpResponse.allHeaderFields btd_integerValueForKey:@"x-gecko-proxy-pkgid"]);
        
        if (!self.urlProtocolTask.bdw_falconProcessInfoRecord[kBDWebviewExtraKey] || [self.urlProtocolTask.bdw_falconProcessInfoRecord[kBDWebviewExtraKey] isKindOfClass:[NSDictionary class]]) {
            self.urlProtocolTask.bdw_falconProcessInfoRecord[kBDWebviewExtraKey] = [[NSMutableDictionary alloc] init];
        }
        NSDictionary *headerDict = [IESFalconURLProtocol httpURLResponseHeaders:httpResponse];
        self.urlProtocolTask.bdw_falconProcessInfoRecord[kBDWebviewExtraKey][kBDWebviewExtraHTTPResponseHeadersKey] = [IESFalconURLProtocol responseHeaderStringFromDic:headerDict];
    }
    
    if (self.urlProtocolTask.willRecordForMainFrameModel) {
        [self webView:self.urlProtocolTask.bdw_webView willRecordMainFrameModel:self.urlProtocolTask];
    }
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)dataTask didCompleteWithError:(NSError *)error
{
    if (error) {
        NSString *URLString = dataTask.currentRequest.URL.absoluteString;
        NSString *errorDescription = error.localizedDescription ? : @"unknown";
        IESFalconDebugLog(@"【URLProtocol】Online request error【URL => %@】【description => %@】", URLString, errorDescription);
        
        [self.client URLProtocol:self didFailWithError:error];
        if (self.urlProtocolTask) {
            [self recordURLSession:session task:dataTask finishWithError:error];
            
            [IESFalconManager bdw_URLProtocolTask:self.urlProtocolTask didFailWithError:error];
        }
    } else {
        NSURL *cacheKey = dataTask.response.URL ?: [NSURL URLWithString:@"about:blank"];
        NSMutableData *responseData = IESFalconURLProtocol.temporaryResponseDataHash[cacheKey];
        if (responseData && IESDataIsWebPFormat(responseData)) {
            NSError *error;
            NSData *convertData = IESConvertDataWebP2APNG(responseData, &error);
            if (!error && convertData.length > 0) {
                [self.client URLProtocol:self didLoadData:convertData];
                if (self.urlProtocolTask) {
                    [IESFalconManager bdw_URLProtocolTask:self.urlProtocolTask didLoadData:convertData];
                }
                
                [self.client URLProtocolDidFinishLoading:self];
                if (self.urlProtocolTask) {
                    [self recordURLSession:session task:dataTask finishWithError:error];
                    
                    [IESFalconManager bdw_URLProtocolTaskDidFinishLoading:self.urlProtocolTask];
                }
            } else {
                NSError *webpError = [NSError errorWithDomain:@"IESWebKitWebPDecodeError" code:0 userInfo:nil];
                [self.client URLProtocol:self didFailWithError:webpError];
                if (self.urlProtocolTask) {
                    [self recordURLSession:session task:dataTask finishWithError:error];
                    
                    [IESFalconManager bdw_URLProtocolTask:self.urlProtocolTask didFailWithError:webpError];
                }
            }
            
        } else {
            if (responseData) {
                [self.client URLProtocol:self didLoadData:responseData];
                if (self.urlProtocolTask) {
                    [IESFalconManager bdw_URLProtocolTask:self.urlProtocolTask didLoadData:responseData];
                }
            }
            
            [self.client URLProtocolDidFinishLoading:self];
            if (self.urlProtocolTask) {
                [self recordURLSession:session task:dataTask finishWithError:error];
                
                [IESFalconManager bdw_URLProtocolTaskDidFinishLoading:self.urlProtocolTask];
            }
        }
        
        IESFalconURLProtocol.temporaryResponseDataHash[cacheKey] = nil;
    }
    
    [self recordOnlineStatIfNeeded];
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler
{
    if (IESFalconManager.webpDecodeEnable && ([response.MIMEType isEqualToString:@"image/webp"] || [response.MIMEType isEqualToString:@"application/octet-stream"] || [dataTask.originalRequest.allHTTPHeaderFields[@"Accept"] rangeOfString:@"image/"].location != NSNotFound)) {
        NSMutableData *responseData = IESFalconURLProtocol.temporaryResponseDataHash[response.URL] ?: [[NSMutableData alloc] init];
        IESFalconURLProtocol.temporaryResponseDataHash[response.URL] = responseData;
        [self.client URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageAllowedInMemoryOnly];
    } else {
        [self.client URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageAllowed];
    }
    
    if (self.urlProtocolTask) {
        [IESFalconManager bdw_URLProtocolTask:self.urlProtocolTask didReceiveResponse:response];
    }
    
    completionHandler(NSURLSessionResponseAllow);
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data
{
    NSMutableData *responseData = IESFalconURLProtocol.temporaryResponseDataHash[dataTask.response.URL];
    if ([responseData isKindOfClass:NSMutableData.class]) {
        [responseData appendData:data];
        return;
    }
    [self.client URLProtocol:self didLoadData:data];
    
    if (self.urlProtocolTask) {
        [IESFalconManager bdw_URLProtocolTask:self.urlProtocolTask didLoadData:data];
    }
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
                     willPerformHTTPRedirection:(NSHTTPURLResponse *)response
                                     newRequest:(NSURLRequest *)request
 completionHandler:(void (^)(NSURLRequest * _Nullable))completionHandler {
    [self.client URLProtocol:self wasRedirectedToRequest:request redirectResponse:response];
    
    if (self.urlProtocolTask) {
        [IESFalconManager bdw_URLProtocolTask:self.urlProtocolTask didPerformRedirection:response newRequest:request];
    }
}

#pragma mark - MainFrameRecorder

- (void)webView:(WKWebView *)webView willRecordMainFrameModel:(id<BDWebURLProtocolTask>)task
{
    btd_dispatch_async_on_main_queue(^{
        BDWebKitMainFrameModel *mainFrameModel = webView.bdw_mainFrameModelRecord;
        if (mainFrameModel == nil) {
            mainFrameModel = [[BDWebKitMainFrameModel alloc] init];
            webView.bdw_mainFrameModelRecord = mainFrameModel;
        }
        mainFrameModel.mainFrameStatus = BDWebKitMainFrameStatusUseFalconURLProtocol;
        mainFrameModel.loadFinishWithLocalData = task.taskFinishWithLocalData;
        mainFrameModel.mainFrameStatModel = [task.bdw_falconProcessInfoRecord copy];
        if (mainFrameModel.mainFramePerformanceTimingModel == nil) {
            mainFrameModel.mainFramePerformanceTimingModel = [[NSMutableDictionary alloc] init];
        }
        [mainFrameModel.mainFramePerformanceTimingModel addEntriesFromDictionary:[task.bdw_ttnetResponseTimingInfoRecord copy]];
    });
}

@end
