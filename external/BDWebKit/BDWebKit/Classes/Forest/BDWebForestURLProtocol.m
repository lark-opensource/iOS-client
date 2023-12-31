#import "BDWebForestURLProtocol.h"

#import <IESForestKit/IESForestKit.h>
#import <IESForestKit/IESForestResponse.h>
#import <IESForestKit/IESForestEventTrackData.h>
#import <BDWebKit/BDWebURLSchemeTaskHandler.h>
#import <BDWebKit/BDWebKitUtil.h>

@implementation BDWebForestURLProtocol

+ (BOOL)canInitWithSchemeTask:(id<BDWebURLSchemeTask>)schemeTask
{
    NSURLRequest *request = [schemeTask bdw_request];
    // only handle GET request
    if (![request.HTTPMethod isEqualToString:@"GET"]) {
        return NO;
    }
    
    // only handle http, https request
    if (![request.URL.scheme isEqualToString:@"http"] && ![request.URL.scheme isEqualToString:@"https"]) {
        return NO;
    }
    
    IESForestRequestParameters *parameters = [IESForestRequestParameters new];
    parameters.onlyLocal = @(YES);
    parameters.skipMonitor = YES;
    IESForestResponse *response = [[IESForestKit sharedInstance] fetchResourceSync:request.URL.absoluteString parameters:parameters];

    // add track data
    if (response && response.eventTrackData) {
        NSMutableDictionary *monitorData = [[NSMutableDictionary alloc] init];
        [monitorData addEntriesFromDictionary:response.eventTrackData.loaderInfo];
        [monitorData addEntriesFromDictionary:response.eventTrackData.resourceInfo];
        [monitorData addEntriesFromDictionary:response.eventTrackData.metricInfo];
        [monitorData addEntriesFromDictionary:response.eventTrackData.errorInfo];
        // previous data has higher priority
        [monitorData addEntriesFromDictionary:schemeTask.bdw_rlProcessInfoRecord];

        schemeTask.bdw_rlProcessInfoRecord = monitorData;
    }

    if (!response || !response.data || response.data.length <= 0) {
        return NO;
    }
    
    [[[self class] sharedCache] setObject:response forKey:request.URL.absoluteString];

    return YES;
}

+ (BOOL)canInitWithRequest:(NSURLRequest *)request
{
    // only handle GET request
    if (![request.HTTPMethod isEqualToString:@"GET"]) {
        return NO;
    }
    
    // only handle http, https request
    if (![request.URL.scheme isEqualToString:@"http"] && ![request.URL.scheme isEqualToString:@"https"]) {
        return NO;
    }
    
    IESForestRequestParameters *parameters = [IESForestRequestParameters new];
    parameters.onlyLocal = @(YES);
    IESForestResponse *response = [[IESForestKit sharedInstance] fetchResourceSync:request.URL.absoluteString parameters:parameters];
    if (!response || !response.data || response.data.length <= 0) {
        return NO;
    }
    
    [[[self class] sharedCache] setObject:response forKey:request.URL.absoluteString];

    return YES;
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request
{
    return request;
}

- (void)startLoading
{
    if (self.request.URL.absoluteString.length == 0) {
        [self.client URLProtocol:self didFailWithError:[NSError errorWithDomain:@"BDWebKitEmptyURLError" code:0 userInfo:nil]];
        return;
    }
    
    id <IESForestResponseProtocol> forestResponse = [[[self class] sharedCache] objectForKey:self.request.URL.absoluteString];
    
    if (forestResponse) {
        [[[self class] sharedCache] removeObjectForKey:self.request.URL.absoluteString];
    } else {
        IESForestRequestParameters *parameters = [IESForestRequestParameters new];
        parameters.onlyLocal = @(YES);
        forestResponse = [[IESForestKit sharedInstance] fetchResourceSync:self.request.URL.absoluteString parameters:parameters];
    }
    
    if (!forestResponse || !forestResponse.data || forestResponse.data.length <= 0) {
        [self.client URLProtocol:self didFailWithError:[NSError errorWithDomain:@"BDWebKitOfflineDataDisappeared" code:0 userInfo:nil]];
        return;
    }
    
    [[[self class] sharedCache] removeObjectForKey:self.request.URL.absoluteString];

    NSMutableDictionary *headerFields = [@{@"Access-Control-Allow-Origin" : @"*"} mutableCopy];

    NSString *extension = [self.request.URL pathExtension];
    NSString *contentType = [BDWebKitUtil contentTypeOfExtension:extension];
    if (contentType) {
        headerFields[@"Content-Type"] = contentType;
    }
    
    // process mp4 range request
    BOOL requestHeaderForMp4RangeFile = NO;
    NSData *rangeVideoData = nil;
    if ([self.request.URL.pathExtension isEqualToString:@"mp4"]) {
        rangeVideoData = [BDWebKitUtil rangeDataForVideo:forestResponse.data withRequest:self.request withResponseHeaders:headerFields];
        if (rangeVideoData && (rangeVideoData.length > 0)) {
            requestHeaderForMp4RangeFile = YES;
        }
    }

    NSURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:self.request.URL
                                                          statusCode:(requestHeaderForMp4RangeFile ? 206 : 200)
                                                         HTTPVersion:nil
                                                        headerFields:headerFields];
    [self.client URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageAllowed];
    [self.client URLProtocol:self didLoadData:(requestHeaderForMp4RangeFile ? rangeVideoData : forestResponse.data)];
    [self.client URLProtocolDidFinishLoading:self];
}

/// don't need to stop
- (void)stopLoading
{
}

#pragma mark - private

+ (NSCache *)sharedCache
{
    static dispatch_once_t onceToken;
    static NSCache *cache = nil;
    dispatch_once(&onceToken, ^{
        cache = [[NSCache alloc] init];
    });
    return cache;
}

@end
