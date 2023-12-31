// Copyright 2022. The Cross Platform Authors. All rights reserved.

#import "IESForestCDNFetcher.h"

#import "IESForestKit.h"
#import "IESForestKit+private.h"
#import "IESForestRequest.h"
#import "IESForestResponse.h"
#import "IESForestError.h"

#import <IESGeckoKit/IESGurdLogProxy.h>

#import <ByteDanceKit/NSString+BTDAdditions.h>
#import <ByteDanceKit/NSDictionary+BTDAdditions.h>
#import <ByteDanceKit/BTDMacros.h>

#import <TTNetworkManager/TTNetworkManager.h>
#import <TTNetworkManager/TTHttpResponse.h>

static NSString * const kHttpResponseHeaders = @"http_response_headers";

@interface IESForestCDNErrorMessage : NSObject
@property (nonatomic, copy) NSString* url;
@property (nonatomic, copy) NSString* detail;
@end

@implementation IESForestCDNErrorMessage

- (instancetype)initWithURL:(NSString *)url detail:(NSString *)detail
{
    if (self = [super init]) {
        _url = url;
        _detail = detail;
    }
    return self;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"%@: %@", self.url, self.detail];
}

@end

@interface IESForestCDNFetcher ()

+ (NSSet *)canRetryStatusCode;
+ (NSSet *)trackResponseHeaders;

@property (nonatomic, assign) double startTime;
@property (nonatomic, strong) NSMutableArray *debugMessages;
@property (nonatomic, strong) TTHttpTask *ttHttpTask;

@end

@implementation IESForestCDNFetcher

+ (NSString *)fetcherName
{
    return @"CDN";
}

- (NSString *)name
{
    return @"CDN";
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _debugMessages = [NSMutableArray new];
    }
    return self;
}

- (void)fetchResourceWithRequest:(IESForestRequest *)request
                      completion:(IESForestFetcherCompletionHandler)completion
{
    request.metrics.cdnStart = [[NSDate date] timeIntervalSince1970] * 1000;
    NSString *sourceURL = request.url;

    if (BTD_isEmptyString(sourceURL)) {
        self.request.cdnError = @"URL is empty!";
        completion(nil, [IESForestError errorWithCode:IESForestErrorCDNURLEmpty message:self.request.cdnError]);
        return;
    }
    
    if (![sourceURL hasPrefix:@"http://"] && ![sourceURL hasPrefix:@"https://"]) {
        self.request.cdnError = @"Invalid URL - only support http(s)!";
        completion(nil, [IESForestError errorWithCode:IESForestErrorCDNURLInvalid message:self.request.cdnError]);
        return;
    }
    
    NSURLComponents *urlComponents = [NSURLComponents componentsWithString:sourceURL];
    NSMutableArray<NSString *> *shuffledURLs = [[NSMutableArray alloc] init];

    [[self.request shuffleDomains] enumerateObjectsUsingBlock:^(NSString *domain, NSUInteger idx, BOOL *stop) {
        if (!BTD_isEmptyString(domain)) {
            [urlComponents setHost:domain];
            [shuffledURLs addObject:urlComponents.URL.absoluteString];
        }
    }];
    // If there's no shuffled urls, use original url to fetch resource.
    if (shuffledURLs.count == 0) {
        [shuffledURLs addObject:sourceURL];
    }

    [self fetchResourceWithURLs:shuffledURLs completion:completion];
}

- (void)fetchResourceWithURLs:(NSMutableArray *)urls
                   completion:(IESForestFetcherCompletionHandler)completion
{
    NSString *url = [urls firstObject];
    if (url) {
        [urls removeObjectAtIndex:0];
    }
    
    @weakify(self);
    IESForestCompletionHandler wrapCompletion = ^(IESForestResponse *response, NSError *error) {
        @strongify(self);
        if (self.isCanceled) {
            return;
        }
        if (error) {
            [self appendDebugMessage:url error:error];
            if (urls.count != 0) {
                [self fetchResourceWithURLs:urls completion:completion];
            } else {
                if (completion) {
                    self.request.metrics.cdnFinish = [[NSDate date] timeIntervalSince1970] * 1000;
                    IESGurdLogInfo(@"Forest - CDN: reqeust [%@], error: %@", self.request.url, [error localizedDescription]);
                    completion(nil, error);
                }
            }
        } else {
            if (completion) {
                [self appendDebugMessage:url error:nil];
                self.request.metrics.cdnFinish = [[NSDate date] timeIntervalSince1970] * 1000;
                response.fetcher = [[self class] fetcherName];
//                IESGurdLogInfo(@"Forest - CDN: reqeust [%@] success", self.request.url);
                completion(response, nil);
            }
        }
    };
    
    [self _fetchResourceWithSourceURL:url retryTimes:self.request.cdnRetryTimes.integerValue completion:wrapCompletion];
}

- (void)_fetchResourceWithSourceURL:(NSString *)sourceURL
                         retryTimes:(NSInteger)retryTimes
                         completion:(IESForestCompletionHandler)completion
{
    @weakify(self);
    TTNetworkObjectFinishBlockWithResponse ttNetCallback = ^(NSError *error, id data, TTHttpResponse *ttResponse) {
        @strongify(self);
        if (error) {
            if (retryTimes > 0 && ttResponse && [[[self class] canRetryStatusCode] containsObject:@(ttResponse.statusCode)]) {
                [self _fetchResourceWithSourceURL:sourceURL retryTimes:retryTimes - 1 completion:completion];
            } else {
                IESGurdLogInfo(@"Forest - CDNFetcher error: %@, response headers: %@", error, ttResponse.allHeaderFields);
                self.request.cdnError = [error localizedDescription];
                self.request.httpStatusCode = ttResponse.statusCode;
                self.request.ttNetErrorCode = error.code;
                self.request.extraInfo[kHttpResponseHeaders] = [self responseHeadersTrackData:ttResponse];
                completion(nil, [IESForestError errorWithCode:IESForestErrorCDNNetworkError message:self.request.cdnError]);
            }
        } else {
            if (data) {
                IESForestResponse *response = [[IESForestResponse alloc] initWithRequest:self.request];
                response.sourceType = ttResponse.timinginfo.isCached ? IESForestDataSourceTypeCDNCache : IESForestDataSourceTypeCDNOnline;
                response.data = data;
                response.version = [ttResponse.allHeaderFields btd_integerValueForKey:@"x-gecko-proxy-pkgid"];
                response.fetcher = [[self class] fetcherName];
                response.expiredDate = [self extractExpiredDateFrom:ttResponse];
                self.request.extraInfo[kHttpResponseHeaders] = [self responseHeadersTrackData:ttResponse];
                completion(response, nil);
            } else {
                self.request.cdnError = @"Invalid data!";
                completion(nil, [IESForestError errorWithCode:IESForestErrorCDNDataEmpty message:self.request.cdnError]);
            }
        }
    };

    self.request.url = [IESForestKit addCommonParamsForCDNMultiVersionURLString:sourceURL];
    [[TTNetworkManager shareInstance] requestForBinaryWithResponse:self.request.url
                                                            params:nil
                                                            method:@"GET"
                                                  needCommonParams:NO
                                                       headerField:nil
                                                   enableHttpCache:!self.request.disableCDNCache
                                                 requestSerializer:nil
                                                responseSerializer:nil
                                                          progress:nil
                                                          callback:ttNetCallback
                                              callbackInMainThread:NO];
}

- (NSString *)debugMessage
{
    NSString *message = [self.debugMessages componentsJoinedByString:@", "];
    return [NSString stringWithFormat:@"{%@}", message];
}

- (void)cancelFetch
{
    self.isCanceled = YES;
    if (self.ttHttpTask) {
        [self.ttHttpTask cancel];
    }
}

#pragma mark -- private

- (void)appendDebugMessage:(NSString *)urlString error:(NSError *)error
{
    NSString *detail = error ? [error localizedDescription] : @"Success";
    [self.debugMessages addObject:[[IESForestCDNErrorMessage alloc] initWithURL:urlString detail:detail]];
}

+ (NSSet *)canRetryStatusCode {
    static NSSet* codes = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        codes = [NSSet setWithArray:@[
            @(408), // Request timeout
            @(502), // Bad gateway
            @(503), // Server Unavailable - server is not ready to handle request
            @(504), // Gateway timeout
        ]];
    });
    return codes;
}

+ (NSSet *)trackResponseHeaders
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

- (nullable NSDate *)extractExpiredDateFrom:(TTHttpResponse *)response
{
    NSString *cacheControl = [response.allHeaderFields objectForKey:@"cache-control"];
    NSString *responseDate = [response.allHeaderFields objectForKey:@"date"];
    NSDate *expiredDate = [self extractExpiredDateFromCacheControl:cacheControl responseDateString:responseDate];
    if (expiredDate) {
        return expiredDate;
    }

    NSString *expiresString = [response.allHeaderFields objectForKey:@"expires"];
    expiredDate = [self dateFromGMTString:expiresString];
    if (expiredDate) {
        return expiredDate;
    }

    // return a expired date, so the response will not be cached
    return [NSDate date];
}

- (nullable NSDate *)extractExpiredDateFromCacheControl:(NSString *)cacheControl responseDateString:(NSString *)responseDateString
{
    if (BTD_isEmptyString(cacheControl) || BTD_isEmptyString(responseDateString)) {
        return nil;
    }

    // if exist no-cache, no-store, don't use cache
    NSString *noCahcePattern = @"no-cache|no-store";
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:noCahcePattern options:NSRegularExpressionCaseInsensitive error:nil];
    NSTextCheckingResult *match = [regex firstMatchInString:cacheControl options:0 range:NSMakeRange(0, [cacheControl length])];
    if (match) {
        return nil;
    }

    // check if max-age exist, use responseDate + max-age
    NSString *maxAgePattern = @"max-age=(\\d+)";
    NSRegularExpression *maxAgeRegex = [NSRegularExpression regularExpressionWithPattern:maxAgePattern options:NSRegularExpressionCaseInsensitive error:nil];
    NSTextCheckingResult *maxAgeMatch = [maxAgeRegex firstMatchInString:cacheControl options:0 range:NSMakeRange(0, [cacheControl length])];
    NSDate *responseDate = [self dateFromGMTString:responseDateString];
    if (!maxAgeMatch || !responseDate) {
        return nil;
    }

    NSRange maxAgeRange = [maxAgeMatch rangeAtIndex:1];
    NSString *maxAgeString = [cacheControl substringWithRange:maxAgeRange];
    NSInteger maxAge = [maxAgeString integerValue];
    return [NSDate dateWithTimeInterval:maxAge sinceDate:responseDate];
}

- (nullable NSDate *)dateFromGMTString:(NSString *)dateString
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    NSLocale *locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
    [dateFormatter setLocale:locale];
    [dateFormatter setDateFormat:@"EEE',' dd' 'MMM' 'yyyy HH':'mm':'ss zzz"];
    NSDate *date = [dateFormatter dateFromString:dateString];
    if (date) {
        return date;
    }

    return nil;
}

- (NSString *)responseHeadersTrackData:(TTHttpResponse *)response
{
    NSDictionary *dict = [response.allHeaderFields btd_filter:^BOOL(id  _Nonnull key, id  _Nonnull obj) {
        return [[[self class] trackResponseHeaders] containsObject: key];
    }];

    if (![NSJSONSerialization isValidJSONObject:dict]) {
        return [NSString stringWithFormat:@"%@", dict];
    }

    NSData *data = [NSJSONSerialization dataWithJSONObject:dict options:kNilOptions error:nil];
    return [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
}

@end
