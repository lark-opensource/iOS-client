// Copyright 2022. The Cross Platform Authors. All rights reserved.

#import "IESForestCDNDownloaderFetcher.h"

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
#import <TTNetworkDownloader/TTDownloadApi.h>

static NSString * const kHttpResponseHeaders = @"http_response_headers";

@interface IESForestCDNDownloaderFetcher ()

+ (NSSet *)trackResponseHeaders;

@property (nonatomic, assign) double startTime;
@property (nonatomic, strong) NSString *downloadKey;

@property (nonatomic, strong) DownloadGlobalParameters *downloadParams;

@end

@implementation IESForestCDNDownloaderFetcher

+ (NSString *)fetcherName
{
    return @"CDNDownloader";
}

- (NSString *)name
{
    return @"CDNDownloader";
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self initDownloadParams];
    }
    return self;
}

- (void)initDownloadParams
{
    DownloadGlobalParameters *params = [DownloadGlobalParameters new];
    params.isCheckCacheValid = YES;
    params.retryTimeoutInterval = 1;
    params.sliceMaxRetryTimes = 3;
    params.contentLengthWaitMaxInterval = 1;
    params.isHttps2HttpFallback = YES;
    params.queuePriority = QUEUE_PRIORITY_HIGH;
    params.insertType = QUEUE_HEAD;
    self.downloadParams = params;
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
            [shuffledURLs addObject:[IESForestKit addCommonParamsForCDNMultiVersionURLString:urlComponents.URL.absoluteString]];
        }
    }];
    // use shuffled url first
    [shuffledURLs addObject:[IESForestKit addCommonParamsForCDNMultiVersionURLString:sourceURL]];
    
    // set retry times
    self.downloadParams.urlRetryTimes = self.request.cdnRetryTimes.integerValue;
        
    @weakify(self);
    TTDownloadResultBlock resultBlock = ^(DownloadResultNotification *result) {
        @strongify(self);
        if (result.downloadedFilePath) {
            IESForestResponse *response = [[IESForestResponse alloc] initWithRequest:self.request];
            response.sourceType = result.code == ERROR_FILE_DOWNLOADED ? IESForestDataSourceTypeCDNCache : IESForestDataSourceTypeCDNOnline;
            response.absolutePath = result.downloadedFilePath;
            // FIXME: response.version || response.exporedDate
            response.fetcher = [[self class] fetcherName];
            self.request.metrics.cdnFinish = [[NSDate date] timeIntervalSince1970] * 1000;
            completion(response, nil);
        } else {
            IESGurdLogWarning(@"Forest - CDNDownloadFetcher error - code:%ld, message: %@", (unsigned long)result.code, result.downloaderLog);
            self.request.cdnError = result.downloaderLog;
            self.request.ttNetErrorCode = result.code;
            NSArray *responses = result.httpResponseArray;
            if (responses && responses.count > 0) {
                id obj = result.httpResponseArray[0];
                if (obj && [obj isKindOfClass:TTHttpResponse.class]) {
                    TTHttpResponse *response = (TTHttpResponse *)obj;
                    self.request.httpStatusCode = response.statusCode;
                    self.request.extraInfo[kHttpResponseHeaders] = [self responseHeadersTrackData:response];
                }
            }
            self.request.metrics.cdnFinish = [[NSDate date] timeIntervalSince1970] * 1000;
            completion(nil, [IESForestError errorWithCode:IESForestErrorCDNNetworkError message:self.request.cdnError]);
        }
    };
    
    TTDownloadProgressBlock processBlock = ^(DownloadProgressInfo *progressInfo) {
        // we don't need process info
    };

    NSString *downloadKey = [self downloadFilePath:self.request];
    [[TTDownloadApi shareInstance] startDownloadWithKey:downloadKey
                                               fileName:downloadKey
                                               md5Value:nil
                                               urlLists:shuffledURLs
                                               progress:processBlock
                                                 status:resultBlock
                                         userParameters:self.downloadParams];
    self.downloadKey = downloadKey;
}

- (void)cancelFetch
{
    self.isCanceled = YES;
    if (self.downloadKey) {
        [[TTDownloadApi shareInstance] cancelTaskSync:self.downloadKey];
    }
}

#pragma mark -- private

- (NSString *)downloadFilePath:(IESForestRequest *)request
{
    NSString *pathExtension = [request.url pathExtension];
    return [[self.request.identity btd_md5String] stringByAppendingPathExtension:pathExtension];
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

@end
