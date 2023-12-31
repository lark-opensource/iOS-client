//
//  BDWebResourceLoaderURLProtocol.m
//  Indexer
//
//  Created by pc on 2022/3/22.
//

#import "BDWebResourceLoaderURLProtocol.h"

#import <BDXResourceLoader/BDXResourceLoader.h>
#import <BDALogProtocol/BDALogProtocol.h>
#import <BDWebKit/BDWebURLSchemeTask.h>
#import <BDWebKit/BDWebKitUtil.h>
#import "BDResourceLoaderMetricHelper.h"

NSErrorDomain const BDWebRLUrlProtocolErrorDomain = @"ResourceLoaderURLProtocol";

static NSString * const kLogTag = @"ResourceLoaderURLProtocol";

@implementation BDWebResourceLoaderURLProtocol

#pragma mark - NSURLProtocol

+ (BOOL)canInitWithSchemeTask:(id<BDWebURLSchemeTask>)schemeTask {
    NSURLRequest *request = schemeTask.bdw_request;
    if (![request.HTTPMethod isEqualToString:@"GET"]) {
        return NO;
    }
    
    if (request.URL.absoluteString.length == 0) {
        return NO;
    }
    
    if (![request.URL.scheme isEqualToString:@"http"]
        && ![request.URL.scheme isEqualToString:@"https"]) {
        return NO;
    }
    
    NSError *error = nil;
    BDXResourceLoaderTaskConfig *taskConfig = [[BDXResourceLoaderTaskConfig alloc] init];
    taskConfig.callerPlatform = @(BDXRLMonitorPlatformWebView);
    
    id<BDXResourceProtocol> resource
    = [[BDXResourceLoader sharedInstance] fetchLocalResourceWithURL:request.URL.absoluteString
                                                         taskConfig:taskConfig
                                                              error:&error];
    BDALOG_PROTOCOL_INFO_TAG(kLogTag,
                             @"try get offline resource with url:%@",
                             request.URL);
    if (error || resource.resourceData.length == 0) {
        BDALOG_PROTOCOL_INFO_TAG(kLogTag,
                                 @"no offline resource with url:%@, error:%@",
                                 request.URL,
                                 error);
        if (error) {
            [schemeTask.bdw_rlProcessInfoRecord setValue:@(error.code) forKey:@"res_loader_error_code"];
            [schemeTask.bdw_rlProcessInfoRecord setValue:error.localizedDescription ?: @"" forKey:@"res_error_msg"];
        }
        return NO;
    }
    NSString *containerId = [BDResourceLoaderMetricHelper webContainerId:schemeTask.bdw_webView];
    NSDictionary *metricInfo = [BDResourceLoaderMetricHelper monitorDict:resource containerId:containerId];
    if (metricInfo) {
        [schemeTask.bdw_rlProcessInfoRecord addEntriesFromDictionary:metricInfo];
    }
    
    [[[self class] sharedCache] setObject:resource
                                   forKey:request.URL.absoluteString
                                     cost:resource.resourceData.length];

    return YES;
}


+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request
{
    return request;
}

- (void)startLoading
{
    id<BDXResourceProtocol> resource = [[[self class] sharedCache] objectForKey:self.request.URL.absoluteString];
    
    NSError *error = nil;
    if (resource) {
        [[[self class] sharedCache] removeObjectForKey:self.request.URL.absoluteString];
    } else {
        BDXResourceLoaderTaskConfig *taskConfig = [[BDXResourceLoaderTaskConfig alloc] init];
        taskConfig.callerPlatform = @(BDXRLMonitorPlatformWebView);
        
        resource = [[BDXResourceLoader sharedInstance] fetchLocalResourceWithURL:self.request.URL.absoluteString
                                                             taskConfig:taskConfig
                                                                  error:&error];
        BDALOG_PROTOCOL_INFO_TAG(kLogTag,
                                 @"startLoading: try get offline resource with url:%@",
                                 self.request.URL);
    }
    
    if (!resource || resource.resourceData.length == 0) {
        if (!error) {
            error =  [NSError errorWithDomain:BDWebRLUrlProtocolErrorDomain
                                         code:BDWebRLUrlProtocolLResourceMissingAfterCanInit
                                     userInfo:nil];
        }
        [self.client URLProtocol:self
                didFailWithError:error];
        BDALOG_PROTOCOL_ERROR_TAG(kLogTag,
                                 @" after canInit no offline resource with url:%@, error:%@",
                                 self.request.URL,
                                 error);
        return;
    }
    
    NSMutableDictionary *headerFields = [@{@"Access-Control-Allow-Origin" : @"*"} mutableCopy];
    
    // process mp4 range request
    BOOL requestHeaderForMp4RangeFile = NO;
    NSData *rangeVideoData = nil;
    if ([self.request.URL.pathExtension isEqualToString:@"mp4"]) {
        rangeVideoData = [BDWebKitUtil rangeDataForVideo:resource.resourceData withRequest:self.request withResponseHeaders:headerFields];
        if (rangeVideoData && (rangeVideoData.length > 0)) {
            requestHeaderForMp4RangeFile = YES;
        }
    }
    
    NSURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:self.request.URL
                                                          statusCode:(requestHeaderForMp4RangeFile ? 206 : 200)
                                                         HTTPVersion:nil
                                                        headerFields:headerFields];
    [self.client URLProtocol:self
          didReceiveResponse:response
          cacheStoragePolicy:NSURLCacheStorageNotAllowed];
    
    [self.client URLProtocol:self
                 didLoadData:(requestHeaderForMp4RangeFile ? rangeVideoData : resource.resourceData)];
    
    [self.client URLProtocolDidFinishLoading:self];
    
    BDALOG_PROTOCOL_INFO_TAG(kLogTag,
                             @"get offline resource with url:%@, from:%@",
                             self.request.URL,
                             @(resource.resourceType));
}

// must override
- (void)stopLoading
{
}

+ (NSCache<NSString *, id<BDXResourceProtocol>> *)sharedCache
{
    static dispatch_once_t onceToken;
    static NSCache *cache = nil;
    dispatch_once(&onceToken, ^{
        cache = [[NSCache alloc] init];
        cache.countLimit = 3;
        cache.totalCostLimit = 6 * 1024 * 1024;
    });
    return cache;
}

@end

