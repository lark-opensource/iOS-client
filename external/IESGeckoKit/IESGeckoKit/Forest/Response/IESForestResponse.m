// Copyright 2022. The Cross Platform Authors. All rights reserved.

#import "IESForestResponse.h"
#import "IESForestRequest.h"
#import "IESForestEventTrackData.h"
#import "IESForestFetcherProtocol.h"
#import "IESForestKit.h"

@implementation IESForestResponse

+ (instancetype)responseWithResponse:(id<IESForestResponseProtocol>)response
{
    if ([response isKindOfClass:[IESForestResponse class]]) {
        return response;
    }
    IESForestResponse *newResponse = [[IESForestResponse alloc] init];
    newResponse.sourceUrl = response.sourceUrl;
    newResponse.accessKey = response.accessKey;
    newResponse.channel = response.channel;
    newResponse.bundle = response.bundle;
    newResponse.version = response.version;
    newResponse.absolutePath = response.absolutePath;
    newResponse.data = response.data;
    newResponse.expiredDate = response.expiredDate;
    newResponse.fetcher = response.fetcher;
    newResponse.debugInfo = response.debugInfo;
    return newResponse;
}

- (instancetype)initWithRequest:(IESForestRequest *)request
{
    if (self = [super init]) {
        self.accessKey = request.accessKey;
        self.channel = request.channel;
        self.bundle = request.bundle;
        self.sourceUrl = request.url;
    }
    return self;
}

- (instancetype)copyWithZone:(NSZone *)zone
{
    IESForestResponse *copy = [[[self class] allocWithZone:zone] init];
    copy.sourceUrl = [_sourceUrl copy];
    copy.accessKey = [_accessKey copy];
    copy.channel = [_channel copy];
    copy.bundle = [_bundle copy];
    copy.version = _version;
    copy.data = [_data copy];
    copy.sourceType = _sourceType;
    copy.absolutePath = [_absolutePath copy];
    copy.expiredDate = _expiredDate;
    copy.fetcher = [_fetcher copy];
    copy.debugInfo = [_debugInfo copy];
    copy.cacheKey = [_cacheKey copy];
    return copy;
}

- (NSString *)sourceTypeDescription
{
    NSString *description = nil;
    switch(self.sourceType) {
        case IESForestDataSourceTypeGeckoLocal:
            description = @"gecko";
            break;
        case IESForestDataSourceTypeGeckoUpdate:
            description = @"gecko_update";
            break;
        case IESForestDataSourceTypeCDNOnline:
            description = @"cdn";
            break;
        case IESForestDataSourceTypeCDNCache:
            description = @"cdn_cache";
            break;
        case IESForestDataSourceTypeBuiltin:
            description = @"bultin";
            break;
        case IESForestDataSourceTypeOther:
            description = @"other";
            break;
        default:
            description = @"missing";
    }
    return description;
}

- (BOOL)isSuccess
{
    return self.absolutePath || (self.data && self.data.length > 0);
}

- (NSString *)resolvedURL
{
    if (self.absolutePath && self.absolutePath.length > 0) {
        return [NSURL fileURLWithPath:self.absolutePath].absoluteString;
    }

    if (self.request.disableCDN && ([self.sourceUrl hasPrefix:@"http://"] || [self.sourceUrl hasPrefix:@"https://"])) {
        return nil;
    }

    return [IESForestKit addCommonParamsForCDNMultiVersionURLString:self.sourceUrl];
}

- (IESForestEventTrackData *)eventTrackData
{
    return [[IESForestEventTrackData alloc] initWithRequest:self.request response:self];
}

@end
