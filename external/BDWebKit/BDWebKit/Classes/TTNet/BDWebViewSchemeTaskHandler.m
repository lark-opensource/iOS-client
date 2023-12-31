//
//  BDWebViewSchemeTaskHandler.m
//  ByteWebView
//
//  Created by Lin Yong on 2019/2/27.
//

#import <objc/runtime.h>
#import <objc/message.h>

#import "BDWebViewSchemeTaskHandler.h"
#import "BDWebViewURLProtocolClient.h"
#import "WKWebView+BDPrivate.h"
#import "NSObject+BDWRuntime.h"
#import "BDFixWKWebViewCrash.h"
#import "BDWebKitSettingsManger.h"
#import "BDTTNetAdapter.h"
#import "BDWebViewTTNetUtil.h"
#import "WKWebView+TTNet.h"
#import "BDWebViewDebugKit.h"
#import <TTNetworkManager/TTNetworkManager.h>
#import <TTNetworkManager/NSURLRequest+WebviewInfo.h>
#import <BDTrackerProtocol/BDTrackerProtocol.h>
#import <BDAlogProtocol/BDAlogProtocol.h>

#import <BDPreloadSDK/BDWebViewPreloadTask.h>
#import <BDPreloadSDK/BDWebViewPreloadManager.h>

#import <ByteDanceKit/ByteDanceKit.h>
#import "WKWebView+BDWebServerTrust.h"
#import "BDTTNetPrefetch.h"
#import "BDWebKitUtil.h"
#import "BDWebURLSchemeProtocolClass.h"
#import "BDWebResourceMonitorEventType.h"

#define dispatch_main($block) ([NSThread isMainThread] ? $block() : dispatch_sync(dispatch_get_main_queue(), $block))
#define KReleaseSchemeTaskOnMainThread dispatch_main(^(){ self.schemeTask = nil; });

static NSString * const TAG = @"BDWebView.SchemeHandler";

static NSString * const kBDWebViewTTNetOrigin = @"Origin";
static NSString * const kBDWebViewTTNetOriginLowCase = @"origin";
static NSString * const kBDWebViewTTNetContentType = @"Content-Type";
static NSString * const kBDWebViewTTNetContentTypeLowCase = @"content-type";
static NSString * const kBDWebViewTTNetReferer = @"Referer";
static NSString * const kBDWebViewTTNetRefererLowCase = @"referer";
static NSString * const kBDWebViewTTNetAccessControlAllowOrigin = @"Access-Control-Allow-Origin";
static NSString * const kBDWebViewTTNetAccessControlAllowOriginLowCase = @"access-control-allow-origin";
static NSString * const kBDWebViewTTNetAccessControlAllowHeaders = @"Access-Control-Allow-Headers";
static NSString * const kBDWebViewTTNetAccessControlAllowHeadersLowCase = @"access-control-allow-headers";

API_AVAILABLE(ios(11.0))
@interface BDWebViewSchemeTaskHandler ()
@property (nonatomic, strong) BDWebURLSchemeTask *schemeTask;
@property (nonatomic, weak) WKWebView *webView;
@property (nonatomic, strong) TTHttpTask *httpTask;
@property (nonatomic, strong) BDTTNetPrefetchTask *prefetchTask;
@property (nonatomic, strong) BDWebViewPreloadTask *preloadTask;
@property (nonatomic, strong) NSURLProtocol *urlProtocol;
@property (nonatomic, assign) BOOL isStopped;
@property (nonatomic, assign) BOOL hasReceivedData;
@property (nonatomic, strong) NSOperationQueue *handleQueue;
@property (nonatomic, strong) NSMutableDictionary *hostMap;
@property (nonatomic, assign) BOOL isSkipSSLError;
@property (nonatomic, strong) NSURL *webViewURL;
@property (nonatomic, assign) NSTimeInterval ttnetTaskStartTime;

@end

@implementation BDWebViewSchemeTaskHandler

- (void)dealloc {
    
}

#pragma mark - Public

- (instancetype)initWithWebView:(WKWebView *)webView schemeTask:(id<BDWebURLSchemeTask>)schemeTask {
    self = [super init];
    if (self) {
        BOOL (*allowsWeakReference)(id, SEL) =
            (BOOL(*)(id, SEL))
            class_getMethodImplementation([webView class],
                                           @selector(allowsWeakReference));
        __unsafe_unretained WKWebView *tmpWebView = webView;
        if (allowsWeakReference && (IMP)allowsWeakReference != _objc_msgForward) {
            BOOL deallocating =
                ! (*allowsWeakReference)(webView, @selector(allowsWeakReference));
            // 尝试修复webView在deallocating中被赋值给weak指针的问题
            if (deallocating) {
                tmpWebView = nil;
            }
        }
        _webView = tmpWebView;
        _webViewURL = webView.URL;
        _schemeTask = schemeTask;
        _schemeTask.bdw_request.useURLProtocolOnlyLocal = YES;
        _handleQueue = creat_handle_queue();
        _hostMap = [NSMutableDictionary dictionary];
    }
    return self;
}

+ (BOOL)bdw_canHandleRequest:(NSURLRequest *)request {
    if (@available(iOS 11.0, *)) {
        return YES;
    } else {
        return NO;
    }
}

- (void)bdw_startURLSchemeTask {
    self.isSkipSSLError = [self.webView.bdw_serverTrustChallengeHandler shouldSkipSSLCertificateError];
    if (BDTTNetAdapter.isAsyncWhenHandleSchemeTask) {
        NSBlockOperation *operation = [NSBlockOperation blockOperationWithBlock:^{
            [self handleStartSchemeTask];
        }];
        [self.handleQueue addOperation:operation];
    } else {
        [self handleStartSchemeTask];
    }
}

- (void)handleStartSchemeTask {

    if ([self.webView.bdw_networkDelegate respondsToSelector:@selector(webView:willStartLoadURL:)]) {
        [self.webView.bdw_networkDelegate webView:self.webView willStartLoadURL:self.schemeTask.bdw_request.URL];
    }

    if (self.isStopped || ![self.webView bd_isPageValid]) {
        KReleaseSchemeTaskOnMainThread
        return;
    }

    if (nil == self.schemeTask.bdw_request.URL) {
        [BDTrackerProtocol eventV3:@"scheme_task_exception" params:@{@"exception":@"schemeTask.request.URL is nil"}];
        KReleaseSchemeTaskOnMainThread
        return;
    }
    
    BOOL isHandled = [self _tryHandleWebView:self.webView];
    if (isHandled) {
        KReleaseSchemeTaskOnMainThread
        return;
    }
    
    self.ttnetTaskStartTime = [NSDate date].timeIntervalSince1970 * 1000;
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
                NSURL *url = [NSURL btd_URLWithString:errorUrl];
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

    self.schemeTask.taskFinishWithTTNet = YES;
    NSMutableURLRequest *request = [self.schemeTask.bdw_request mutableCopy];
    NSMutableDictionary *header = [request.allHTTPHeaderFields mutableCopy];
    header[@"X-TT-Web-Proxy"] = @"TTNet";
    if (self.webView.bdw_enableFreeFlow) {
        header[@"X-TTNet-Proxy"] = @"enable";
    }
    
    if([self.webView.bdw_networkDelegate respondsToSelector:@selector(webview:extraHeaderDictionaryForRequest:)]){
        NSDictionary* extraHeader = [self.webView.bdw_networkDelegate webview:self.webView extraHeaderDictionaryForRequest:request];
        [header addEntriesFromDictionary:extraHeader];
    }
    
    if([BDWebKitSettingsManger bdAddAcceptLanguageHeaderIfNeeded]){
        if(![header objectForKey:@"Accept-Language"] && [[NSLocale preferredLanguages] firstObject]){
            header[@"Accept-Language"] = [[NSLocale preferredLanguages] firstObject];
        }
    }
    
    request.allHTTPHeaderFields = header;
    
    // add associated object for webview info
    request.webviewInfo = [self.schemeTask.bdw_additionalInfo copy];
    request.needCommonParams = self.schemeTask.useTTNetCommonParams;
    
    BDTTNetPrefetchTask *prefetchTask = [BDTTNetPrefetch.shared dequeuePrefetchTaskWithRequest:request];
    BOOL shouldUsePrefetch = YES;
    if (prefetchTask
        && [self.webView.bdw_networkDelegate respondsToSelector:@selector(webView:shouldUsePrefetchResponse:withRequest:)]) {
        TTHttpResponse *response = prefetchTask.response;
        NSHTTPURLResponse *nsResponse = nil;
        if (response) {
            NSMutableDictionary *headers = [[self fixCORSHeaderWithResponse:response] mutableCopy];
            nsResponse = [[NSHTTPURLResponse alloc] initWithURL:response.URL
                                                     statusCode:response.statusCode
                                                    HTTPVersion:@"HTTP/1.1"
                                                   headerFields:headers];
        }
        shouldUsePrefetch = [self.webView.bdw_networkDelegate webView:self.webView
                                            shouldUsePrefetchResponse:nsResponse
                                                          withRequest:prefetchTask.request];
    }
    
    BDWebViewPreloadTask *preloadTask;
    self.schemeTask.bdw_rlProcessInfoRecord[kBDWebviewEnableRequestReuseKey] = @(self.schemeTask.bdw_shouldUseNetReuse);
    if (prefetchTask && shouldUsePrefetch) {
        prefetchTask.hitPrefetch = YES;
        self.prefetchTask = prefetchTask;
        prefetchTask.headerCallback = headerCB;
        prefetchTask.dataCallback = dataCB;
        prefetchTask.redirectCallback = redirectCB;
        prefetchTask.callbackWithResponse = finishCB;
        [prefetchTask resume];
        
        NSMutableDictionary *params = @{}.mutableCopy;
        params[@"opitimize"] = @(prefetchTask.opitimizeMillSecond);
        [BDTrackerProtocol eventV3:@"bd_prefetch" params:params];
    } else if (self.schemeTask.bdw_shouldUseNetReuse && (preloadTask = [BDWebViewPreloadManager.sharedInstance taskForURLString:self.schemeTask.bdw_request.URL.absoluteString])) {
        self.preloadTask = preloadTask;
        preloadTask.headerCallback = headerCB;
        preloadTask.dataCallback = dataCB;
        preloadTask.redirectCallback = redirectCB;
        preloadTask.callbackWithResponse = finishCB;
        self.schemeTask.bdw_rlProcessInfoRecord[kBDWebviewResLoaderNameKey] = @"bdpreloader";
        self.schemeTask.bdw_rlProcessInfoRecord[kBDWebviewIsRequestReusedKey] = @(1);
        [preloadTask reResume];
        BDALOG_PROTOCOL_ERROR_TAG(TAG, @"Start Use Net Reuse. URL: %@", request.URL);
    } else {
        BOOL willEnableTTNetCacheControl = [BDWebKitSettingsManger bdTTNetCacheControlEnable];
        if (self.schemeTask.taskHttpCachePolicy != BDWebHTTPCachePolicyUseAppSetting) {
            willEnableTTNetCacheControl = self.schemeTask.taskHttpCachePolicy == BDWebHTTPCachePolicyEnableCache ? YES : NO;
        }
        self.httpTask = [[TTNetworkManager shareInstance] requestForWebview:request
                                                                   autoResume:NO
                                                              enableHttpCache:willEnableTTNetCacheControl
                                                               headerCallback:headerCB
                                                                 dataCallback:dataCB
                                                         callbackWithResponse:finishCB
                                                             redirectCallback:redirectCB];
        self.httpTask = [self configHttpTask:self.httpTask];
        self.httpTask.enableCustomizedCookie = self.schemeTask.ttnetEnableCustomizedCookie;
        if ([self.webView.bdw_networkDelegate respondsToSelector:@selector(webView:priorityForRequest:)]) {
            float priority = [self.webView.bdw_networkDelegate webView:self.webView priorityForRequest:request];
            if (priority>=0&&priority<=1) {
                [self.httpTask setPriority:priority];
            }
        }
        [self.httpTask resume];
    }
    
    if ([self.webView.bdw_networkDelegate respondsToSelector:@selector(webView:didStartLoadURL:)]) {
        [self.webView.bdw_networkDelegate webView:self.webView didStartLoadURL:self.schemeTask.bdw_request.URL];
    }
}

// for override
- (TTHttpTask *)configHttpTask:(TTHttpTask *)task {
    task.skipSSLCertificateError = self.isSkipSSLError;
    task.timeoutInterval = [BDWebKitSettingsManger bdFixTTNetTimeout];
    return task;
}

- (void)bdw_stopURLSchemeTask {
    self.isStopped = YES;
    if (self.urlProtocol) {
        ((BDWebViewURLProtocolClient *)self.urlProtocol.client).isStopped = YES;
        [self.urlProtocol stopLoading];
    } else if (self.httpTask) {
        [self.httpTask cancel];
    } else if (self.prefetchTask) {
        [self.prefetchTask cancel];
    } else if (self.preloadTask) {
        [self.preloadTask cancel];
        self.preloadTask = nil;
    }
}

#pragma mark - TTNet Response
- (void)handleTTNetworkHeaderResponse:(TTHttpResponse *)response {
    if (self.isStopped || ![self.webView bd_isPageValid]) {
        return;
    }
    if (self.hasReceivedData) {
        BDALOG_PROTOCOL_ERROR_TAG(TAG, @"webView: %p receive response after receive data, scheme task: %@", self.webView, self.schemeTask.bdw_request.URL);
        return;
    }
    BDALOG_PROTOCOL_INFO_TAG(TAG, @"webView: %p receive response scheme task: %@", self.webView, self.schemeTask.bdw_request.URL);
    
    if (response.statusCode != 200 && response.statusCode != 204) {
        
        [BDTrackerProtocol eventV3:@"bdwebview_ttnet_response_status_report" params:[self _ttnetParmWithResponse:response]];
        
        if ([BDWebKitSettingsManger bdTTNetAutoBlockListEnable]) {
            NSArray *autoBlackErrors = [BDWebKitSettingsManger bdTTNetAutoBlockListErrorStatusCode];
            if ([autoBlackErrors containsObject:@(response.statusCode)]) {
                NSURL *webViewReqURL = self.webViewURL;
                NSString *webViewURLStr = [NSString stringWithFormat:@"%@://%@%@",webViewReqURL.scheme ,webViewReqURL.host, webViewReqURL.path];
                [BDWebViewTTNetUtil addTTNetBlockList:webViewURLStr];
            }
        }
    } else if ([self.schemeTask.bdw_request.HTTPMethod.uppercaseString isEqualToString:@"POST"] &&
               self.schemeTask.bdw_request.HTTPBodyStream) {
        BDWDebugLog(@"webView(%p) TTNet detected request to upload file %@ ", self.webView, self.schemeTask.bdw_request.URL);
        NSMutableDictionary *ttnetParm = [self _ttnetParmWithResponse:response];
        [ttnetParm setValue:@"blob" forKey:@"type"];
        [BDTrackerProtocol eventV3:@"bdwebview_ttnet_response_status_report" params:ttnetParm];
        if ([BDWebKitSettingsManger bdTTNetBlobAutoBlackEnable]) {
            NSURL *webViewReqURL = self.webViewURL;
            NSString *webViewURLStr = [NSString stringWithFormat:@"%@://%@%@",webViewReqURL.scheme ,webViewReqURL.host, webViewReqURL.path];
            [BDWebViewTTNetUtil addTTNetBlockList:webViewURLStr];
        }
    }
    
    NSDictionary *headers = [self fixCORSHeaderWithResponse:response];

    if (headers[@"Content-Type"] == nil && headers[@"content-type"] == nil) {
        NSString *extension = [response.URL.absoluteString pathExtension];
        NSString *contentType = [BDWebKitUtil contentTypeOfExtension:extension];
        if(contentType){
            NSMutableDictionary *newHeaders = [[NSMutableDictionary alloc] initWithDictionary:headers];
            newHeaders[@"Content-Type"] = contentType;
            headers = [newHeaders copy];
        }
    }
    
    NSHTTPURLResponse *nsResponse = [[NSHTTPURLResponse alloc] initWithURL:response.URL statusCode:response.statusCode HTTPVersion:@"HTTP/1.1" headerFields:headers];
    @try {
        [self.schemeTask bdw_didReceiveResponse:nsResponse];
        if ([self.webView.bdw_networkDelegate respondsToSelector:@selector(webView:didReceiveResponse:)]) {
            [self.webView.bdw_networkDelegate webView:self.webView didReceiveResponse:nsResponse];
        }
    } @catch (NSException *exception) {
        NSString *exceptionStr = exception.description?exception.description:@"";
        [BDTrackerProtocol eventV3:@"scheme_task_exception" params:@{@"exception":exceptionStr}];
    }
}

- (void)handleTTNetworkDataResponse:(NSData *)data {
    if (self.isStopped || ![self.webView bd_isPageValid]) {
        return;
    }
    BDALOG_PROTOCOL_INFO_TAG(TAG, @"webView: %p receive data scheme task: %@", self.webView, self.schemeTask.bdw_request.URL);
    self.hasReceivedData = YES;
    @try {
        [self.schemeTask bdw_didLoadData:data];
        if ([self.webView.bdw_networkDelegate respondsToSelector:@selector(webView:didReceiveData:forURL:)]) {
            [self.webView.bdw_networkDelegate webView:self.webView
                                       didReceiveData:data
                                               forURL:self.schemeTask.bdw_request.URL];
        }
    } @catch (NSException *exception) {
        NSString *exceptionStr = exception.description?exception.description:@"";
        [BDTrackerProtocol eventV3:@"scheme_task_exception" params:@{@"exception":exceptionStr}];
    }
}

- (void)handleTTNetworkFinishResponse:(TTHttpResponse *)response withObj:(id)obj withError:(NSError *)error {
    if (self.isStopped || ![self.webView bd_isPageValid]) {
        return;
    }
    //修复无网状态下不走fail回调的问题
    BOOL establishConnectionFail = NO;
    if([BDWebKitSettingsManger bdTTNetAvoidNoResponseException]) {
        establishConnectionFail = (response.statusCode == -1 ? YES : NO);
    }
    BDALOG_PROTOCOL_INFO_TAG(TAG, @"webView: %p finish scheme task: %@ %@", self.webView, self.schemeTask.bdw_request.URL, @(response.statusCode));
    BDWDebugLog(@"webView(%p) TTNet request %@ %@", self.webView, self.schemeTask.bdw_request.URL,error ?: @"Succeeded" );
    @try {
        
        if ([self _willCallLoadingFailedWithResponse:response withError:error] || establishConnectionFail) {
            if ([error.localizedDescription hasPrefix:@"ERR_CERT_"]) {// 暂时通过这个来判断处理
                BDALOG_PROTOCOL_INFO_TAG(TAG, @"webView: %p ssl error: %@", self.webView, error);
                __weak typeof(self)weakSelf = self;
                [self.webView.bdw_serverTrustChallengeHandler handleSSLError:response.URL WithComplete:^(BOOL trustSSL) {
                    __strong __typeof(weakSelf)strongSelf = weakSelf;
                    if (trustSSL) {
                        // 证书相关错误，这类错误本地实测不会返回data和response，所以可以直接重试
                        BDALOG_PROTOCOL_INFO_TAG(TAG, @"webView: %p retry", strongSelf.webView);
                        [strongSelf bdw_startURLSchemeTask];
                    } else {
                        [strongSelf.schemeTask bdw_didFailWithError:error];
                        if ([strongSelf.webView.bdw_networkDelegate respondsToSelector:@selector(webView:didFailLoadURL:withError:)]) {
                             [strongSelf.webView.bdw_networkDelegate webView:strongSelf.webView
                                                    didFailLoadURL:strongSelf.schemeTask.bdw_request.URL
                                                         withError:error];
                        }
                    }
                }];
                return;
            }
            if(error == nil && establishConnectionFail) {
                // -106为Chromium网络断开连接错误码,establishConnectionFail代表建连失败
                NSMutableDictionary *userInfo = [[NSMutableDictionary alloc] init];
                NSURL *url = response.URL;
                NSString *description = @"ERR_ESTABLISH_CONNECTION";
                [userInfo setValue:url forKey:NSURLErrorFailingURLErrorKey];
                [userInfo setValue:description forKey:NSLocalizedDescriptionKey];
                [userInfo setValue:@"-106" forKey:@"error_num"];
                error = [[NSError alloc] initWithDomain:kTTNetworkErrorDomain code:-106 userInfo:userInfo];
            }
            [self recordTTNetResponseInfo:response withError:error];
            [self.schemeTask bdw_didFailWithError:error];
            if ([self.webView.bdw_networkDelegate respondsToSelector:@selector(webView:didFailLoadURL:withError:)]) {
                 [self.webView.bdw_networkDelegate webView:self.webView
                                        didFailLoadURL:self.schemeTask.bdw_request.URL
                                             withError:error];
            }
        } else {
            [self recordTTNetResponseInfo:response withError:nil];
            [self.schemeTask bdw_didFinishLoading];
            if ([self.webView.bdw_networkDelegate respondsToSelector:@selector(webView:didFinishLoadURL:)]) {
               [self.webView.bdw_networkDelegate webView:self.webView
                                    didFinishLoadURL:self.schemeTask.bdw_request.URL];
            }
        }
    } @catch (NSException *exception) {
        NSString *exceptionStr = exception.description?exception.description:@"";
        [BDTrackerProtocol eventV3:@"scheme_task_exception" params:@{@"exception":exceptionStr}];
    }
    self.schemeTask = nil;
}

- (void)handleTTNetworkRedrectResponse:(TTHttpResponse *)old_repsonse withNewLocation:(NSString *)new_location {
    if (self.isStopped || ![self.webView bd_isPageValid]) {
        return;
    }
    if (self.hasReceivedData) {
        BDALOG_PROTOCOL_ERROR_TAG(TAG, @"webView: %p redirect after receive data, scheme task: %@", self.webView, self.schemeTask.bdw_request.URL);
        return;
    }
    if (old_repsonse.isInternalRedirect) {
        // TTNet 内部做多机房调度时,模拟重定向实现的,因此上层需要忽略该类型的重定向
        return;
    }
    
    // https <-> http，ttnet会触发重定向，这种情况无需告知Webkit
    NSURL *newURL = [NSURL btd_URLWithString:new_location];
    if (!newURL) {
        [BDTrackerProtocol eventV3:@"scheme_task_exception" params:@{@"exception":@"error_redirect_location", @"error_location":new_location?:@"empty location"}];
    }
    NSString *origin = self.schemeTask.bdw_request.allHTTPHeaderFields[@"Origin"];
    NSString *contentType = self.schemeTask.bdw_request.allHTTPHeaderFields[@"Content-Type"];
    // ajax 请求告诉WebKit重定向,会丢失Origin
    BOOL bypassOrigin = [BDWebKitSettingsManger bdTTNetOriginOpitimise] && origin.length > 0 && [contentType isEqualToString:@"application/x-www-form-urlencoded"];
    
    if ([BDWebKitSettingsManger bdTTNetFixRedirect]) {// https <-> http
        if (old_repsonse.statusCode == 307 || bypassOrigin) {
            if (old_repsonse.URL.host && [old_repsonse.URL.host isKindOfClass:[NSString class]]) {
                self.hostMap[old_repsonse.URL.host] = newURL.host;
            }
            return;
        }
    } else {// https <-> http
        NSString *newUrlStr = [NSString stringWithFormat:@"%@%@%@",newURL.host,newURL.path,newURL.query];
        NSString *oldUrlStr = [NSString stringWithFormat:@"%@%@%@",old_repsonse.URL.host,old_repsonse.URL.path,old_repsonse.URL.query];
        BOOL isSamePath = [newUrlStr isEqualToString:oldUrlStr] && ![newURL.scheme isEqualToString:old_repsonse.URL.scheme];
        if (isSamePath || bypassOrigin) {
            return;
        }
    }
    
    SEL sel = @selector(URLSchemeTask:didPerformRedirection:newRequest:);
    if ([self.schemeTask.delegate respondsToSelector:sel]) {
        NSMutableURLRequest *newRequest = self.schemeTask.bdw_request.mutableCopy;
        
        //fix 跨域问题
        if ([BDWebKitSettingsManger bdTTNetFixCors] && ![newRequest.URL.host isEqualToString:newURL.host] && [self.hostMap.allValues containsObject:newURL.host]) {
            NSString *corsDomain = [NSString stringWithFormat:@"%@://%@",newURL.scheme,newURL.host];
            NSString *oldDomain = [NSString stringWithFormat:@"%@://%@",newRequest.URL.scheme,newRequest.URL.host];
            NSString *corsNewURLStr = [newURL.absoluteString stringByReplacingOccurrencesOfString:corsDomain withString:oldDomain];
            NSURL *corsNewURL = [NSURL btd_URLWithString:corsNewURLStr];
            newRequest.URL = corsNewURL;
        } else {
            newRequest.URL = newURL;
        }

        NSHTTPURLResponse *oldResponse = [[NSHTTPURLResponse alloc] initWithURL:old_repsonse.URL statusCode:old_repsonse.statusCode HTTPVersion:@"HTTP/1.1" headerFields:old_repsonse.allHeaderFields];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        @try {
            [self.schemeTask.delegate URLSchemeTask:self.schemeTask didPerformRedirection:oldResponse newRequest:newRequest];
            if ([self.webView.bdw_networkDelegate respondsToSelector:@selector(webView:didPerformRedirection:newRequest:)]) {
                [self.webView.bdw_networkDelegate webView:self.webView
                                didPerformRedirection:oldResponse
                                           newRequest:newRequest];
            }
        } @catch (NSException *exception) {
            NSString *exceptionStr = exception.description?exception.description:@"";
            [BDTrackerProtocol eventV3:@"scheme_task_exception" params:@{@"exception":exceptionStr}];
        }
#pragma clang diagnostic pop
    }
}

#pragma mark - Private

- (BOOL)_tryHandleWebView:(WKWebView * _Nonnull)webView  API_AVAILABLE(ios(11.0)){
    __block BOOL isHandled = NO;
    NSArray *arrProtocol = webView.bdw_urlProtocols;
    if (arrProtocol.count > 0) {
        __weak typeof(self)weakSelf = self;
        [arrProtocol enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(id  _Nonnull protocolClass, NSUInteger idx, BOOL * _Nonnull stop) {
            __strong __typeof(weakSelf)strongSelf = weakSelf;
            BOOL canInit = NO;
            if ([protocolClass conformsToProtocol:@protocol(BDWebURLSchemeProtocolClass)]) {
                canInit = [protocolClass canInitWithSchemeTask:strongSelf.schemeTask];
            } else {
                canInit = [protocolClass canInitWithRequest:strongSelf.schemeTask.bdw_request];
            }
            if (canInit) {
                *stop = YES;
                isHandled = YES;
                if ([strongSelf.webView.bdw_networkDelegate respondsToSelector:@selector(webView:didStartLoadURL:)]) {
                    [strongSelf.webView.bdw_networkDelegate webView:strongSelf.webView didStartLoadURL:strongSelf.schemeTask.bdw_request.URL];
                }
                BDWebViewURLProtocolClient *client = [[BDWebViewURLProtocolClient alloc] initWithWebView:strongSelf.webView schemeTask:strongSelf.schemeTask];
                NSURLProtocol *protocol = [[protocolClass alloc] initWithRequest:strongSelf.schemeTask.bdw_request cachedResponse:nil client:client];
                strongSelf.urlProtocol = protocol;
                strongSelf.schemeTask.taskFinishWithLocalData = YES;
                BDWDebugLog(@"webView(%p) TTNet request hit the caches: %@, url: %@", strongSelf.webView, NSStringFromClass(protocolClass), strongSelf.schemeTask.bdw_request.URL);
                SEL selector = @selector(startLoadingWithWebView:);
                if ([protocol respondsToSelector:selector]) {
                    [protocol btd_performSelectorWithArgs:selector, webView];;
                } else {
                    [protocol startLoading];
                }
            }
        }];
    }
    return isHandled;
}

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
    }
    
    return NO;
}

- (NSMutableDictionary *)_ttnetParmWithResponse:(TTHttpResponse *)response {
    NSURL *respURL = response.URL;
    NSURL *reqURL = self.schemeTask.bdw_request.URL;
    NSURL *webViewReqURL = self.webViewURL;
    
    NSString *webViewURLStr = [NSString stringWithFormat:@"%@://%@%@",webViewReqURL.scheme ,webViewReqURL.host, webViewReqURL.path];
    NSString *reqURLStr = [NSString stringWithFormat:@"%@://%@%@",reqURL.scheme ,reqURL.host, reqURL.path];
    NSString *respURLStr = [NSString stringWithFormat:@"%@://%@%@",respURL.scheme ,respURL.host, respURL.path];
    
    NSMutableDictionary *ttnetParm = [[NSMutableDictionary alloc] init];
    if (webViewReqURL.host && [webViewReqURL.host isKindOfClass:[NSString class]]) {
        ttnetParm[@"webview_ref_host"] = self.hostMap[webViewReqURL.host];
    }
    ttnetParm[@"webview_host"] = webViewReqURL.host;
    ttnetParm[@"webview_url"] = webViewURLStr;
    ttnetParm[@"webview_req_url"] = reqURLStr;
    ttnetParm[@"webview_res_url"] = respURLStr;
    ttnetParm[@"webview_ttnet_status"] = @(response.statusCode);
    return ttnetParm;
}

- (BOOL)isReqHostInSafeList:(NSString *)reqHost {
    BOOL rst = NO;
    for (NSString *host in BDTTNetAdapter.safeHostList) {
        if (host.length <= 0) {
            continue;
        }
        if ([host isEqualToString:reqHost]) {
            rst = YES;
            break;
        }
        if ([host hasPrefix:@"."]) {
            if ([reqHost hasSuffix:host]) {
                rst = YES;
                break;
            }
        } else if ([reqHost hasSuffix:[NSString stringWithFormat:@".%@", host]]) {
            rst = YES;
            break;
        }
    }
    return rst;
}

static NSOperationQueue *creat_handle_queue() {
#define MAX_QUEUE_COUNT 4
    static NSMutableArray* queues = nil;
    static dispatch_once_t onceToken;
    static int32_t counter = 0;
    dispatch_once(&onceToken, ^{
        queues = [NSMutableArray array];
        for (NSUInteger i = 0; i < MAX_QUEUE_COUNT; i++) {
            NSOperationQueue *queue = [[NSOperationQueue alloc] init];
            queue.name = @"tt_network_complete_handle_concurrent_queue";
            queue.maxConcurrentOperationCount = 1;
            queues[i] = queue;
        }
    });
    int32_t cur = counter ++;
    if (cur < 0) cur = -cur;
    return queues[(cur) % MAX_QUEUE_COUNT];
#undef MAX_QUEUE_COUNT
}

#pragma mark - header
// FIX 跨域问题：静态选路和部分异常case
- (NSDictionary *)fixCORSHeaderWithResponse:(TTHttpResponse *)response {
    NSDictionary *headers = response.allHeaderFields;
    
    NSURL *respURL = response.URL;
    NSURL *reqURL = self.schemeTask.bdw_request.URL;
    
    // 直接从referer或者origin获取最准确，比如iframe
    NSDictionary *reqHeaders = self.schemeTask.bdw_request.allHTTPHeaderFields;
    NSString *frameURLString = [self stringValueWithKey:kBDWebViewTTNetReferer headers:reqHeaders];
    if (BDWK_isEmptyString(frameURLString)) {
        frameURLString = [self stringValueWithKey:kBDWebViewTTNetOrigin headers:reqHeaders];
    }
    
    NSURL *frameURL = frameURLString ? [NSURL btd_URLWithString:frameURLString] : self.webViewURL;
    
    BOOL needHandleCORS = NO;
    if (![reqURL.host isEqualToString:respURL.host] && [self.hostMap.allValues containsObject:respURL.host]) {
        needHandleCORS = YES;
    }
    if (!needHandleCORS) {
        // https -> http
        needHandleCORS = [frameURL.scheme isEqualToString:@"https"] && ([reqURL.scheme isEqualToString:@"http"] || [respURL.scheme isEqualToString:@"http"]);
    }
    
    if (!needHandleCORS || ![self isReqHostInSafeList:self.webViewURL.host]) {// 非跨域，非白名单
        return headers;
    }
    
    NSMutableDictionary *allHeaders = [response.allHeaderFields mutableCopy];
    
    NSString *allowOrigin = [self stringValueWithKey:kBDWebViewTTNetAccessControlAllowOrigin headers:allHeaders];
    
    if (![allowOrigin isEqualToString:@"*"]) {
        [self setStringValue:[NSString stringWithFormat:@"%@://%@", frameURL.scheme, frameURL.host] forKey:kBDWebViewTTNetAccessControlAllowOrigin headers:allHeaders];
    }
    
    // 特殊处理AJAX请求
    NSString *allowHeader = [self stringValueWithKey:kBDWebViewTTNetAccessControlAllowHeaders headers:allHeaders];
    if (!BDWK_isEmptyString(allowHeader)) {
        allowHeader = [allowHeader stringByAppendingString:@","];
    } else {
        allowHeader = @"";
    }
    allowHeader = [allowHeader stringByAppendingString:@"Origin,X-Requested-With"];
    [self setStringValue:allowHeader forKey:kBDWebViewTTNetAccessControlAllowHeaders headers:allHeaders];
    
    return [allHeaders copy];
}
- (NSString *)headerLowCaseKeyWithNormalKey:(NSString *)key {
    if (BDWK_isEmptyString(key)) {
        return nil;
    }
    
    static NSDictionary *headersLowCaseKeyDict = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        headersLowCaseKeyDict = @{
            kBDWebViewTTNetOrigin : kBDWebViewTTNetOriginLowCase,
            kBDWebViewTTNetContentType : kBDWebViewTTNetContentTypeLowCase,
            kBDWebViewTTNetReferer : kBDWebViewTTNetRefererLowCase,
            kBDWebViewTTNetAccessControlAllowOrigin : kBDWebViewTTNetAccessControlAllowOriginLowCase,
            kBDWebViewTTNetAccessControlAllowHeaders : kBDWebViewTTNetAccessControlAllowHeadersLowCase,
        };
    });
    
    return headersLowCaseKeyDict[key];
}
- (NSString *)stringValueWithKey:(NSString *)key headers:(NSDictionary *)headers {
    if (BDWK_isEmptyString(key)) {
        return nil;
    }
    
    NSString *value = [headers btd_stringValueForKey:key];
    if (BDWK_isEmptyString(value)) {
        value = [headers btd_stringValueForKey:[self headerLowCaseKeyWithNormalKey:key]];
    }
    return value;
}
- (void)setStringValue:(NSString *)value forKey:(NSString *)key headers:(NSMutableDictionary *)headers {
    if (BDWK_isEmptyString(key)) {
        return;
    }
    
    headers[key] = value;
    NSString *lowCaseKey = [self headerLowCaseKeyWithNormalKey:key];
    if (!BDWK_isEmptyString(lowCaseKey)) {
        headers[lowCaseKey] = nil;
    }
}

- (void)recordTTNetResponseInfo:(TTHttpResponse *)response withError:(NSError *)error
{
    if (!self.schemeTask.bdw_rlProcessInfoRecord) {
        self.schemeTask.bdw_rlProcessInfoRecord = [[NSMutableDictionary alloc] init];
    }
    
    NSTimeInterval ttnetTaskFinishTime = [NSDate date].timeIntervalSince1970 * 1000;
    self.schemeTask.bdw_rlProcessInfoRecord[kBDWebviewCDNStartKey] = @(self.ttnetTaskStartTime);
    self.schemeTask.bdw_rlProcessInfoRecord[kBDWebviewCDNFinishKey] = @(ttnetTaskFinishTime);
    if (response.timinginfo.isCached) {
        self.schemeTask.bdw_rlProcessInfoRecord[kBDWebviewResFromKey] = @"cdn_cache";
        self.schemeTask.bdw_rlProcessInfoRecord[kBDWebviewCDNCacheStartKey] = @(self.ttnetTaskStartTime);
        self.schemeTask.bdw_rlProcessInfoRecord[kBDWebviewCDNCacheFinishKey] = @(ttnetTaskFinishTime);
    } else {
        self.schemeTask.bdw_rlProcessInfoRecord[kBDWebviewResFromKey] = @"cdn";
    }
    self.schemeTask.bdw_rlProcessInfoRecord[kBDWebviewResSizeKey] = @(response.timinginfo.totalReceivedBytes);
    
    self.schemeTask.bdw_rlProcessInfoRecord[kBDWebviewHttpStatusCodeKey] = @(response.statusCode);
    if (error) {
        self.schemeTask.bdw_rlProcessInfoRecord[kBDWebviewNetLibraryErrorCodeKey] = @(error.code);
        NSString *oldErrorMsg = self.schemeTask.bdw_rlProcessInfoRecord[kBDWebviewResErrorMsgKey];
        NSString *ttnetErrorMsg = error.description ? error.description : @"ttnet error happened";
        if (BTD_isEmptyString(oldErrorMsg)) {
            self.schemeTask.bdw_rlProcessInfoRecord[kBDWebviewResErrorMsgKey] = ttnetErrorMsg;
        } else {
            self.schemeTask.bdw_rlProcessInfoRecord[kBDWebviewResErrorMsgKey] = [NSString stringWithFormat:@"%@  {%@}", oldErrorMsg, ttnetErrorMsg];
        }
    }
    
    // res version from gecko cdn response
    self.schemeTask.bdw_rlProcessInfoRecord[kBDWebviewResVersionKey] = @([response.allHeaderFields btd_integerValueForKey:@"x-gecko-proxy-pkgid"]);
    
    if (BTD_isEmptyString(self.schemeTask.bdw_rlProcessInfoRecord[kBDWebviewResLoaderNameKey])) {
        self.schemeTask.bdw_rlProcessInfoRecord[kBDWebviewResLoaderNameKey] = @"WKSchemeHandler";
    }

    if (!self.schemeTask.bdw_rlProcessInfoRecord[kBDWebviewExtraKey] || [self.schemeTask.bdw_rlProcessInfoRecord[kBDWebviewExtraKey] isKindOfClass:[NSDictionary class]]) {
        self.schemeTask.bdw_rlProcessInfoRecord[kBDWebviewExtraKey] = [[NSMutableDictionary alloc] init];
    }

    self.schemeTask.bdw_rlProcessInfoRecord[kBDWebviewExtraKey][kBDWebviewExtraHTTPResponseHeadersKey] = [self responseHeadersMonitorData:response];
    
    self.schemeTask.bdw_ttnetResponseTimingInfoRecord = [BDWebViewTTNetUtil ttnetResponseTimingInfo:response];
}

/// extract some response headers into monitor data to help debug
- (NSString *)responseHeadersMonitorData:(TTHttpResponse *)response
{
    NSDictionary *dict = [BDWebViewTTNetUtil ttnetResponseHeaders:response];
    if (![NSJSONSerialization isValidJSONObject:dict]) {
        return [NSString stringWithFormat:@"%@", dict];
    }

    NSData *data = [NSJSONSerialization dataWithJSONObject:dict options:kNilOptions error:nil];
    return [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
}

@end
