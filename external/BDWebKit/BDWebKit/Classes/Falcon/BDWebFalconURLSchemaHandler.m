//
//  BDWebFalconURLSchemaHandler.m
//  BDWebKit
//
//  Created by li keliang on 2020/4/3.
//

#import "BDWebFalconURLSchemaHandler.h"

#import "IESFalconManager.h"
#import "IESFalconManager+InterceptionDelegate.h"
#import "IESFalconStatRecorder.h"
#import "NSData+ETag.h"
#import "QNSURLSessionDemux.h"
#import "IESFalconDebugLogger.h"
#import "BDWebKitUtil.h"
#import <objc/runtime.h>

static NSString * const kFalconRecursiveRequestFlagProperty = @"com.byted.IESFalconSchemaHandler";

@interface BDWebFalconURLSchemaHandler()<NSURLSessionDataDelegate>

@property (atomic) id<BDWebURLSchemeTask>   schemaTask;
@property (atomic) NSURLSessionDataTask     *task;

@property (atomic) NSDate *onlineStartDate;
@property (atomic) IESFalconStatModel *onlineStatModel;
@property (atomic, weak) WKWebView *webview;

@end

@implementation BDWebFalconURLSchemaHandler

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

- (instancetype)initWithWebView:(WKWebView *)webView schemeTask:(nonnull id<BDWebURLSchemeTask>)schemaTask
{
    self = [super init];
    if (self) {
        _schemaTask = schemaTask;
        _webview = webView;
    }
    return self;
}

#pragma mark - Helper

+ (NSURLRequest *)falconFixedRequest:(NSURLRequest *)request
{
    NSMutableURLRequest *mutableRequest = [request mutableCopy];
    [NSURLProtocol setProperty:@(YES) forKey:kFalconRecursiveRequestFlagProperty inRequest:mutableRequest];
    return mutableRequest;
}

#pragma mark - BDWebURLSchemeTaskHandler

+ (BOOL)bdw_canHandleRequest:(NSURLRequest *)request
{
    return [self bdw_canHandleRequest:request
                              webview:nil];
}

+ (BOOL)bdw_canHandleRequest:(NSURLRequest *)request
                     webview:(nullable WKWebView *)webview
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
    
    id<IESFalconMetaData> metaData = [IESFalconManager falconMetaDataForURLRequest:request
                                                                           webView:webview];
    BOOL found = (metaData.falconData.length > 0);
    if (!found) {
        [IESFalconManager callingOutFalconInterceptedRequest:request willLoadFromCache:NO];
        
        IESFalconStatModel *statModel = metaData.statModel;
        statModel.resourceURLString = request.URL.absoluteString;
        [IESFalconStatRecorder recordFalconStat:[statModel statDictionary]];
    }
    return found;
}

- (void)bdw_startURLSchemeTask
{
    id <BDWebURLSchemeTask> urlSchemeTask = self.schemaTask;
    
    if (urlSchemeTask.bdw_request.URL.absoluteString.length == 0) {
        [urlSchemeTask bdw_didFailWithError:[NSError errorWithDomain:@"BDWebKitEmptyURLError" code:0 userInfo:nil]];
        return;
    }
    
    NSDate *startDate = [NSDate date];
    NSURLRequest *fixedRequest = [self.class falconFixedRequest:urlSchemeTask.bdw_request];
    
    id<IESFalconMetaData> metaData = [IESFalconManager falconMetaDataForURLRequest:fixedRequest
                                                                           webView:self.webview];
    
    if (fixedRequest.bdw_falconProcessInfoRecord) {
        NSMutableDictionary *falconData = [[NSMutableDictionary alloc] init];
        [falconData addEntriesFromDictionary:[fixedRequest.bdw_falconProcessInfoRecord copy]];
        // previous data has higher priority
        [falconData addEntriesFromDictionary:urlSchemeTask.bdw_rlProcessInfoRecord];
        urlSchemeTask.bdw_rlProcessInfoRecord = falconData;
    }
    
    NSData *falconData = metaData.falconData;
    
    NSDictionary *additionalHeaderFields = nil;
    if ([metaData respondsToSelector:@selector(allHeaderFields)]) {
        additionalHeaderFields = metaData.allHeaderFields;
    }
    
    NSInteger statusCode = 0;
    if ([metaData respondsToSelector:@selector(statusCode)]) {
        statusCode = metaData.statusCode;
    }
    
    IESFalconStatModel *statModel = metaData.statModel;
    if (metaData) {
        statModel.resourceURLString = urlSchemeTask.bdw_request.URL.absoluteString;
    }
    
    [IESFalconManager callingOutFalconInterceptedRequest:fixedRequest willLoadFromCache:(falconData.length > 0)];
    
    if (falconData.length > 0) {
        IESFalconDebugLog(@"【SchemeHandler】Start loading local resource【URL => %@】", urlSchemeTask.bdw_request.URL.absoluteString);
        urlSchemeTask.taskFinishWithLocalData = YES;
        
        NSString *requestETag = fixedRequest.allHTTPHeaderFields[@"If-None-Match"];
        NSString *falconDataEtag = falconData.ies_eTag;
        
        NSParameterAssert(falconData.length > 0);
        
        NSMutableDictionary *headerFields = [@{@"ETag":falconDataEtag, @"Access-Control-Allow-Origin" : @"*"} mutableCopy];
        if (additionalHeaderFields) {
            [headerFields addEntriesFromDictionary:additionalHeaderFields];
        }
        
        if (headerFields[@"Content-Type"] == nil && headerFields[@"content-type"] == nil) {
            NSString *extension = [urlSchemeTask.bdw_request.URL pathExtension];
            NSString *contentType = [BDWebKitUtil contentTypeOfExtension:extension];
            if (contentType) {
                headerFields[@"Content-Type"] = contentType;
            }
        }
        
        BOOL requestHeaderForMp4RangeFile = NO;
        if ([fixedRequest.URL.pathExtension isEqualToString:@"mp4"]) {
            NSData *rangeFalconData = [BDWebKitUtil rangeDataForVideo:falconData withRequest:fixedRequest withResponseHeaders:headerFields];
            if (rangeFalconData && (rangeFalconData.length > 0)) {
                requestHeaderForMp4RangeFile = YES;
                falconData = rangeFalconData;
            }
        }
        
        if (requestETag.length > 0 && [requestETag isEqualToString:falconDataEtag]) {
            NSURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:fixedRequest.URL statusCode:304 HTTPVersion:nil headerFields:headerFields];
            
            [urlSchemeTask bdw_didReceiveResponse:response];
            [urlSchemeTask bdw_didFinishLoading];
        } else {
            statusCode = requestHeaderForMp4RangeFile ? 206 : statusCode;
            NSURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:fixedRequest.URL statusCode:statusCode > 0 ? statusCode:200 HTTPVersion:nil headerFields:headerFields];
            
            [urlSchemeTask bdw_didReceiveResponse:response];
            [urlSchemeTask bdw_didLoadData:falconData];
            [urlSchemeTask bdw_didFinishLoading];
        }
        
        statModel.offlineDuration = (NSInteger)([[NSDate date] timeIntervalSinceDate:startDate] * 1000);
        [IESFalconStatRecorder recordFalconStat:[statModel statDictionary]];
    } else {
        IESFalconDebugLog(@"【SchemeHandler】Fallback to online resource【URL => %@】", urlSchemeTask.bdw_request.URL.absoluteString);

        self.task = [[[self class] sharedDemux] dataTaskWithRequest:fixedRequest delegate:self modes:@[NSRunLoopCommonModes]];
        NSParameterAssert(self.task);
        [self.task resume];
    }
}

- (void)bdw_stopURLSchemeTask
{
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

#pragma mark - NSURLSessionDelegate

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)dataTask didCompleteWithError:(NSError *)error
{
    if (error) {
        NSString *URLString = dataTask.currentRequest.URL.absoluteString;
        NSString *errorDescription = error.localizedDescription ? : @"unknown";
        IESFalconDebugLog(@"【URLProtocol】Online request error【URL => %@】【description => %@】", URLString, errorDescription);
        [self.schemaTask bdw_didFailWithError:error];
    } else {
        [self.schemaTask bdw_didFinishLoading];
    }
    
    [self recordOnlineStatIfNeeded];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task willPerformHTTPRedirection:(NSHTTPURLResponse *)response newRequest:(NSURLRequest *)newRequest completionHandler:(void (^)(NSURLRequest *))completionHandler
{
    [self.schemaTask bdw_didPerformRedirection:response newRequest:newRequest];
    completionHandler(newRequest);
}


- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler
{
    [self.schemaTask bdw_didReceiveResponse:response];
    completionHandler(NSURLSessionResponseAllow);
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data
{
    [self.schemaTask bdw_didLoadData:data];
}


@end
