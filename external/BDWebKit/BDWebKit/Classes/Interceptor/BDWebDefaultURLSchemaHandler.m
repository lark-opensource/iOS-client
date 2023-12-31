//
//  BDWebDefaultURLSchemaHandler.m
//  BDWebKit
//
//  Created by li keliang on 2020/4/3.
//

#import "BDWebDefaultURLSchemaHandler.h"

#import "QNSURLSessionDemux.h"
#import "BDWebKitUtil.h"
#import <BDWebKit/BDWebKitSettingsManger.h>
#import <ByteDanceKit/ByteDanceKit.h>
#import <BDWebKit/BDWebResourceMonitorEventType.h>
#import <objc/runtime.h>

static NSString * const kRecursiveRequestFlagProperty = @"com.byted.BDWebSchemaHandler";

@interface BDWebDefaultURLSchemaHandler()<NSURLSessionDataDelegate>

@property (atomic) id<BDWebURLSchemeTask>   schemaTask;
@property (atomic) NSURLSessionDataTask     *task;
@property (nonatomic, assign) NSTimeInterval httpTaskStartTime;

@end

@implementation BDWebDefaultURLSchemaHandler

+ (QNSURLSessionDemux *)sharedDemux
{
    static dispatch_once_t      sOnceToken;
    static QNSURLSessionDemux * sDemux;
    dispatch_once(&sOnceToken, ^{
        NSURLSessionConfiguration *config;
        config = [NSURLSessionConfiguration defaultSessionConfiguration];
        // You have to explicitly configure the session to use your own protocol subclass here
        // otherwise you don't see redirects <rdar://problem/17384498>.
        sDemux = [[QNSURLSessionDemux alloc] initWithConfiguration:config];
    });
    return sDemux;
}

+ (dispatch_queue_t)sharedCallbackQueue
{
    static dispatch_once_t      sOnceToken;
    static dispatch_queue_t     sCallbackQueue;
    dispatch_once(&sOnceToken, ^{
        dispatch_queue_attr_t attr = dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_CONCURRENT, QOS_CLASS_USER_INITIATED, 0);
        sCallbackQueue = dispatch_queue_create("com.byted.BDWebDefaultCallbackDispatcherQueue", attr);
    });
    return sCallbackQueue;
}

- (instancetype)initWithWebView:(WKWebView *)webView schemeTask:(nonnull id<BDWebURLSchemeTask>)schemaTask
{
    self = [super init];
    if (self) {
        _schemaTask = schemaTask;
    }
    return self;
}

+ (BOOL)useRecursiveRequestFlagCheck
{
    return [BDWebKitSettingsManger allowRecursiveRequestFlagForDefaultSchemaHandler];
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

#pragma mark - BDWebURLSchemeTaskHandler

+ (BOOL)bdw_canHandleRequest:(NSURLRequest *)request
{
    if ([BDWebDefaultURLSchemaHandler useRecursiveRequestFlagCheck]) {
        if ([[NSURLProtocol propertyForKey:kRecursiveRequestFlagProperty inRequest:request] boolValue]) {
            return NO;
        }
    }
    
    return YES;
}

- (void)bdw_startURLSchemeTask
{
    id <BDWebURLSchemeTask> urlSchemeTask = self.schemaTask;
    self.httpTaskStartTime = [[NSDate date] timeIntervalSince1970] * 1000;
    
    if (urlSchemeTask.bdw_request.URL.absoluteString.length == 0) {
        [urlSchemeTask bdw_didFailWithError:[NSError errorWithDomain:@"BDWebKitEmptyURLError" code:0 userInfo:nil]];
        return;
    }
    
    NSMutableURLRequest *mutableRequest = [urlSchemeTask.bdw_request mutableCopy];
    if ([BDWebDefaultURLSchemaHandler useRecursiveRequestFlagCheck]) {
        [NSURLProtocol setProperty:@(YES) forKey:kRecursiveRequestFlagProperty inRequest:mutableRequest];
    }
    self.task = [[[self class] sharedDemux] dataTaskWithRequest:mutableRequest delegate:self modes:@[NSRunLoopCommonModes]];
    NSParameterAssert(self.task);
    [self.task resume];
}

- (void)bdw_stopURLSchemeTask
{
    if (self.task) {
        [self.task cancel];
        self.task = nil;
    }
}

#pragma mark - NSURLSessionDelegate

- (void)recordURLSession:(NSURLSession *)session task:(NSURLSessionTask *)dataTask finishWithError:(NSError *)error
{
    NSTimeInterval httpTaskFinishTime = [NSDate date].timeIntervalSince1970 * 1000;
    self.schemaTask.bdw_rlProcessInfoRecord[kBDWebviewCDNStartKey] = @(self.httpTaskStartTime);
    self.schemaTask.bdw_rlProcessInfoRecord[kBDWebviewCDNFinishKey] = @(httpTaskFinishTime);
    self.schemaTask.bdw_rlProcessInfoRecord[kBDWebviewResFromKey] = @"cdn";
    self.schemaTask.bdw_rlProcessInfoRecord[kBDWebviewResSizeKey] = @(dataTask.countOfBytesReceived);
    self.schemaTask.bdw_rlProcessInfoRecord[kBDWebviewResLoadFinishKey] = @(httpTaskFinishTime);
    self.schemaTask.bdw_rlProcessInfoRecord[kBDWebviewResStateKey] = @"success";
    if (error) {
        NSString *errorDescription = error.localizedDescription ? : @"unknown";
        NSString *oldErrorMsg = self.schemaTask.bdw_rlProcessInfoRecord[kBDWebviewResErrorMsgKey];
        if (BTD_isEmptyString(oldErrorMsg)) {
            self.schemaTask.bdw_rlProcessInfoRecord[kBDWebviewResErrorMsgKey] = errorDescription;
        } else {
            self.schemaTask.bdw_rlProcessInfoRecord[kBDWebviewResErrorMsgKey] = [NSString stringWithFormat:@"%@  {%@}", oldErrorMsg, errorDescription];
        }
        
        self.schemaTask.bdw_rlProcessInfoRecord[kBDWebviewResStateKey] = @"failed";
    }
    
    if (BTD_isEmptyString(self.schemaTask.bdw_rlProcessInfoRecord[kBDWebviewResLoaderNameKey])) {
        self.schemaTask.bdw_rlProcessInfoRecord[kBDWebviewResLoaderNameKey] = @"IESFalconURLProtocol";
    }
    
    // res version from gecko cdn response
    if ([dataTask.response isKindOfClass:[NSHTTPURLResponse class]]) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)dataTask.response;
        self.schemaTask.bdw_rlProcessInfoRecord[kBDWebviewResVersionKey] = @([httpResponse.allHeaderFields btd_integerValueForKey:@"x-gecko-proxy-pkgid"]);
        
        if (!self.schemaTask.bdw_rlProcessInfoRecord[kBDWebviewExtraKey] || [self.schemaTask.bdw_rlProcessInfoRecord[kBDWebviewExtraKey] isKindOfClass:[NSDictionary class]]) {
            self.schemaTask.bdw_rlProcessInfoRecord[kBDWebviewExtraKey] = [[NSMutableDictionary alloc] init];
        }
        NSDictionary *headerDict = [BDWebDefaultURLSchemaHandler httpURLResponseHeaders:httpResponse];
        self.schemaTask.bdw_rlProcessInfoRecord[kBDWebviewExtraKey][kBDWebviewExtraHTTPResponseHeadersKey] = [BDWebDefaultURLSchemaHandler responseHeaderStringFromDic:headerDict];
    }
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)dataTask didCompleteWithError:(NSError *)error
{
    [self recordURLSession:session task:dataTask finishWithError:error];
    if (error) {
        [self.schemaTask bdw_didFailWithError:error];
    } else {
        [self.schemaTask bdw_didFinishLoading];
    }
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler
{
    // Check Response Set-Cookie for webview
    if ([BDWebKitSettingsManger bdSyncCookieForMainFrameResponse]) {
        if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
            NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
            NSArray<NSHTTPCookie *> *cookieArray = [NSHTTPCookie cookiesWithResponseHeaderFields:httpResponse.allHeaderFields forURL:httpResponse.URL];
            if (!BTD_isEmptyArray(cookieArray)) {
                btd_dispatch_async_on_main_queue(^{
                    for (NSHTTPCookie *cookie in cookieArray) {
                        if (@available(iOS 11.0, *)) {
                            [self.schemaTask.bdw_webView.configuration.websiteDataStore.httpCookieStore setCookie:cookie completionHandler:nil];
                        }
                    }
                });
            }
        }
    }
    
    [self.schemaTask bdw_didReceiveResponse:response];
    completionHandler(NSURLSessionResponseAllow);
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task willPerformHTTPRedirection:(NSHTTPURLResponse *)response newRequest:(NSURLRequest *)newRequest completionHandler:(void (^)(NSURLRequest *))completionHandler
{
    [self.schemaTask bdw_didPerformRedirection:response newRequest:newRequest];
    completionHandler(newRequest);
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data
{
    [self.schemaTask bdw_didLoadData:data];
}


@end
