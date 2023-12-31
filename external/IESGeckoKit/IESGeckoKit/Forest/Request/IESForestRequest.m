// Copyright 2022. The Cross Platform Authors. All rights reserved.

#import "IESForestRequest.h"
#import "IESForestRemoteParameters.h"
#import "IESForestQueryParameters.h"
#import "IESForestFetcherProtocol.h"
#import "IESForestKit+private.h"

#import <ByteDanceKit/NSString+BTDAdditions.h>
#import <ByteDanceKit/NSDictionary+BTDAdditions.h>
#import <ByteDanceKit/NSObject+BTDAdditions.h>
#import <ByteDanceKit/BTDMacros.h>

@implementation IESForestPerformanceMetrics

- (nonnull id)copyWithZone:(nullable NSZone *)zone {
    IESForestPerformanceMetrics *copy = [[[self class] allocWithZone:zone] init];
    copy.loadStart = _loadStart;
    copy.loadFinish = _loadFinish;
    copy.parseStart = _parseStart;
    copy.parseFinish = _parseFinish;
    copy.memoryStart = _memoryStart;
    copy.memoryFinish = _memoryFinish;
    copy.geckoStart = _geckoStart;
    copy.geckoFinish = _geckoFinish;
    copy.geckoUpdateStart = _geckoUpdateStart;
    copy.geckoUpdateFinish = _geckoUpdateFinish;
    copy.cdnCacheStart = _cdnCacheStart;
    copy.cdnCacheFinish = _cdnCacheFinish;
    copy.cdnStart = _cdnStart;
    copy.cdnFinish = _cdnFinish;
    copy.builtinStart = _builtinStart;
    copy.builtinFinish = _builtinFinish;
    return copy;
}

@end

@implementation NSString (iesForestRequest)

- (BOOL)ies_forestEnableRequestReuse
{
    return [[self btd_getAttachedObjectForKey:@"ies_forestEnableRequestReuse"] boolValue];
}

- (void)setIes_forestEnableRequestReuse:(BOOL)ies_forestEnableRequestReuse
{
    [self btd_attachObject:@(ies_forestEnableRequestReuse) forKey: @"ies_forestEnableRequestReuse"];
}

@end

#pragma mark -- IESForestRequest

@interface IESForestRequest ()

@property (nonatomic, strong) IESForestQueryParameters *queryParameters;
@property (nonatomic, strong) IESForestRemoteParameters *remoteParameters;

@end

@implementation IESForestRequest

- (instancetype)initWithUrl:(NSString *)url
               forestConfig:(IESForestConfig *)forestConfig
          requestParameters:(IESForestRequestParameters *)requestParameters
{
    self = [super init];
    if (self) {
        _url = url;
        _forestConfig = forestConfig ?: [IESForestConfig new];
        _requestParameters = requestParameters;
        _metrics = [[IESForestPerformanceMetrics alloc] init];

        _remoteParameters = [IESForestRemoteParameters remoteParametersWithURLString:_url defaultPrefixToAccessKey:forestConfig.defaultPrefixToAccessKey];

        _queryParameters = [[IESForestQueryParameters alloc] initWithURLString:url];
        _accessKey = [self extractAccessKey];
        _channel = [self extractChannel];
        _bundle = [self extractBundle];
        
        _disableGecko = [self extractDisableGecko];
        _disableBuiltin = [self extractDisableBuiltin];
        _disableCDN = [self extractDisableCDN];
        _disableCDNCache = [self extractDisableCDNCache];
        _enableMemoryCache = [self extractEnableMemoryCache];

        _waitGeckoUpdate = [self extractWaitGeckoUpdate];
        _onlyLocal = [self extractOnlyLocal];
        _onlyPath = [self extractOnlyPath];
        _isPreload = [self extractIsPreload];
        _enableRequestReuse = [self extractEnableRequestReuse];
        _completionQueue = [self extractCompletionQueue];
        _extraInfo = [[NSMutableDictionary alloc] init];
        
        _runWorkflowInGlobalQueue = [self extractRunWorkflowInGlobalQueue];
        
        _sessionId = [self extractSessionID];
    }
    return self;
}

- (BOOL)hasValidGeckoInfo
{
    return !BTD_isEmptyString(self.channel) && !BTD_isEmptyString(self.bundle) && !BTD_isEmptyString(self.accessKey);
}

- (NSArray<NSNumber *> *)fetcherSequence
{
    if (_fetcherSequence) {
        return _fetcherSequence;
    }
    if (self.remoteParameters.fetcherSequence) {
        return [self.remoteParameters.fetcherSequence copy];
    }
    if (self.requestParameters.fetcherSequence) {
        return [self.requestParameters.fetcherSequence copy];
    }
    return [self.forestConfig.fetcherSequence copy];
}

- (nullable NSArray<NSString *> *)shuffleDomains
{
    return self.remoteParameters.shuffleDomains;
}

- (nullable NSNumber *)cdnRetryTimes
{
    if (self.remoteParameters.cdnRetryTimes.integerValue > 0) {
        return self.remoteParameters.cdnRetryTimes;
    }
    if (self.requestParameters.cdnRetryTimes > 0) {
        return @(self.requestParameters.cdnRetryTimes);
    }
    return nil;
}

- (NSString *)geckoConfigSource
{
    if (!self.hasValidGeckoInfo) {
        return nil;
    }
    if (!_remoteParameters) {
        return @"client_config";
    }
    if (!_remoteParameters.fromCustomConfig) {
        return @"remote_setting";
    }
    return @"custom_config";
}

- (NSTimeInterval)memoryExpiredTime
{
    if (self.requestParameters.memoryExpiredTime) {
        return self.requestParameters.memoryExpiredTime.doubleValue;
    }
    return 60 * 5; // 5 mins
}

- (IESForestResourceScene)resourceScene
{
    return self.requestParameters.resourceScene;
}

- (NSString *)resourceSceneDescription
{
    switch (self.resourceScene) {
        case IESForestResourceSceneLynxTemplate:
            return @"lynx_template";
        case IESForestResourceSceneLynxChildResource:
            return @"lynx_child_resource";
        case IESForestResourceSceneLynxComponent:
            return @"lynx_component";
        case IESForestResourceSceneLynxSVG:
            return @"lynx_svg";
        case IESForestResourceSceneLynxFont:
            return @"lynx_font";
        case IESForestResourceSceneLynxI18n:
            return @"lynx_i18n";
        case IESForestResourceSceneLynxImage:
            return @"lynx_image";
        case IESForestResourceSceneLynxLottie:
            return @"lynx_lottie";
        case IESForestResourceSceneLynxVideo:
            return @"lynx_video";
        case IESForestResourceSceneLynxExternalJS:
            return @"lynx_external_js";
        case IESForestResourceSceneWebMainResource:
            return @"web_main_resource";
        case IESForestResourceSceneWebChildResource:
            return @"web_child_resource";
        default: // IESForestResourceSceneOther or other values
            return @"other";
    }
}

- (NSString *)groupId
{
    NSString *groupId = self.requestParameters.groupId;
    /// be compatible with container's previous way to set containerId method
    if (!groupId) {
        groupId = [self.requestParameters.customParameters btd_stringValueForKey: @"rl_container_uuid" default:@"null"];
    }
    return groupId;
}

- (BOOL)skipMonitor
{
    return self.requestParameters.skipMonitor;
}

- (NSDictionary *)customParameters
{
    return self.requestParameters.customParameters;
}

# pragma mark - private init methods
- (NSString *)extractAccessKey
{
    if (!BTD_isEmptyString(self.remoteParameters.accessKey)) {
        return self.remoteParameters.accessKey;
    }
    if (!BTD_isEmptyString(self.requestParameters.accessKey)) {
        return self.requestParameters.accessKey;
    }
    return self.forestConfig.accessKey;
}

- (NSString *)extractChannel
{
    if (!BTD_isEmptyString(self.remoteParameters.channel)) {
        return self.remoteParameters.channel;
    }
    if (!BTD_isEmptyString(self.requestParameters.channel)) {
        return self.requestParameters.channel;
    }
    return nil;
}

- (NSString *)extractBundle
{
    if (!BTD_isEmptyString(self.remoteParameters.bundle)) {
        return self.remoteParameters.bundle;
    }
    if (!BTD_isEmptyString(self.requestParameters.bundle)) {
        return self.requestParameters.bundle;
    }
    return nil;
}

- (BOOL)extractDisableGecko
{
    if (self.queryParameters.onlyOnline.boolValue) {
        return YES;
    }
    if (self.requestParameters.disableGecko) {
        return self.requestParameters.disableGecko.boolValue;
    }
    if (self.forestConfig.disableGecko) {
        return self.forestConfig.disableGecko.boolValue;
    }
    return NO;
}

- (BOOL)extractDisableBuiltin
{
    if (self.queryParameters.onlyOnline.boolValue) {
        return YES;
    }
    if (self.requestParameters.disableBuiltin) {
        return self.requestParameters.disableBuiltin.boolValue;
    }
    if (self.forestConfig.disableBuiltin) {
        return self.forestConfig.disableBuiltin.boolValue;
    }
    return NO;
}

- (BOOL)extractDisableCDN
{
    if (self.queryParameters.onlyOnline.boolValue) {
        return NO;
    }
    if (self.requestParameters.disableCDN) {
        return self.requestParameters.disableCDN.boolValue;
    }
    return NO;
}

- (BOOL)extractDisableCDNCache
{
    if (self.queryParameters.onlyOnline.boolValue) {
        return YES;
    }
    if (self.remoteParameters.disableCdnCache) {
        return self.remoteParameters.disableCdnCache.boolValue;
    }
    if (self.requestParameters.disableCDNCache) {
        return self.requestParameters.disableCDNCache.boolValue;
    }
    return NO;
}

- (BOOL)extractEnableMemoryCache
{
    if (self.queryParameters.onlyOnline.boolValue) {
        return NO;
    }
    // Don't cache response, when data is not required
    if (self.requestParameters.onlyPath.boolValue) {
        return NO;
    }
    if (self.requestParameters.enableRequestReuse.boolValue) {
        return YES;
    }
    if (self.requestParameters.enableMemoryCache) {
        return self.requestParameters.enableMemoryCache.boolValue;
    }
    if (self.forestConfig.enableMemoryCache) {
        return self.forestConfig.enableMemoryCache.boolValue;
    }
    return NO;
}

- (BOOL)extractWaitGeckoUpdate
{
    if (self.queryParameters.waitGeckoUpdate) {
        return self.queryParameters.waitGeckoUpdate.boolValue;
    }
    // 0, 3 == waitGeckoUpdate = NO
    // 1, 2 == waitGeckoUpdate = YES
    if (self.queryParameters.dynamic) {
        return [self.queryParameters.dynamic intValue] == 1 || [self.queryParameters.dynamic intValue] == 2;
    }

    if (self.remoteParameters.waitGeckoUpdate) {
        return self.remoteParameters.waitGeckoUpdate.boolValue;
    }

    if (self.requestParameters.waitGeckoUpdate) {
        return self.requestParameters.waitGeckoUpdate.boolValue;
    }

    return NO;
}

- (BOOL)extractOnlyLocal
{
    if (self.requestParameters.onlyLocal) {
        return self.requestParameters.onlyLocal.boolValue;
    }
    return NO;
}

- (BOOL)extractOnlyPath
{
    if (self.requestParameters.onlyPath) {
        return self.requestParameters.onlyPath.boolValue;
    }
    return NO;
}

- (NSString *)extractSessionID
{
    if (self.requestParameters.sessionId) {
        return self.requestParameters.sessionId;
    }
    return nil;
}

- (BOOL)extractIsPreload
{
    if (self.requestParameters.isPreload) {
        return self.requestParameters.isPreload.boolValue;
    }
    return NO;
}

- (BOOL)extractEnableRequestReuse
{
    if (self.requestParameters.enableRequestReuse) {
        return self.requestParameters.enableRequestReuse.boolValue;
    }
    if ([self.url ies_forestEnableRequestReuse]) {
        return YES;
    }
    return NO;
}

- (BOOL)extractRunWorkflowInGlobalQueue
{
    if (self.requestParameters.runWorkflowInGlobalQueue) {
        return self.requestParameters.runWorkflowInGlobalQueue.boolValue;
    }
    if (self.forestConfig.runWorkflowInGlobalQueue) {
        return self.forestConfig.runWorkflowInGlobalQueue.boolValue;
    }
    return YES;
}

- (dispatch_queue_t)extractCompletionQueue
{
    if (self.requestParameters.completionQueue) {
        return self.requestParameters.completionQueue;
    }
    if (self.forestConfig.completionQueue) {
        return self.forestConfig.completionQueue;
    }
    return nil;
}

- (NSString *)description
{
    NSMutableArray *descArray = [[NSMutableArray alloc] init];
    [descArray addObject:[NSString stringWithFormat:@"url: %@", _url]];
    [descArray addObject:[NSString stringWithFormat:@"accessKey: %@", _accessKey]];
    [descArray addObject:[NSString stringWithFormat:@"channel: %@", _channel]];
    [descArray addObject:[NSString stringWithFormat:@"bundle: %@", _bundle]];
    [descArray addObject:[NSString stringWithFormat:@"disableGecko: %d", _disableGecko]];
    [descArray addObject:[NSString stringWithFormat:@"disableBuiltin: %d", _disableBuiltin]];
    [descArray addObject:[NSString stringWithFormat:@"disableCDN: %d", _disableCDN]];
    [descArray addObject:[NSString stringWithFormat:@"disableCDNCache: %d", _disableCDNCache]];
    [descArray addObject:[NSString stringWithFormat:@"enableMemory: %d", _enableMemoryCache]];
    [descArray addObject:[NSString stringWithFormat:@"waitGeckoUpdate: %d", _waitGeckoUpdate]];
    [descArray addObject:[NSString stringWithFormat:@"onlyLocal: %d", _onlyLocal]];
    [descArray addObject:[NSString stringWithFormat:@"queryParams: %@", _queryParameters]];
    [descArray addObject:[NSString stringWithFormat:@"remoteParams: %@", _remoteParameters]];

    return [NSString stringWithFormat:@"%@", [descArray componentsJoinedByString:@", "]];
}

- (NSString *)identity
{
    NSMutableString *key = [NSMutableString string];
    if (!BTD_isEmptyString(self.accessKey) && !BTD_isEmptyString(self.channel) && !BTD_isEmptyString(self.bundle)) {
        [key appendString:[NSString stringWithFormat:@"%@-%@-%@", self.accessKey, self.channel, self.bundle]];
    } else {
        [key appendString:self.url ?: @""];
    }

    return key;
}

- (NSArray<NSNumber *> *)actualFetcherSequence
{
    if (BTD_isEmptyArray(self.fetcherSequence)) {
        return @[];
    }

    NSMutableArray<NSNumber *> *actualFetchers = [NSMutableArray array];
    for (NSNumber *fetcherType in self.fetcherSequence) {
        switch (fetcherType.integerValue) {
            case IESForestFetcherTypeGecko:
                if (!self.disableGecko) {
                    [actualFetchers addObject:@(IESForestFetcherTypeGecko)];
                }
                break;
            case IESForestFetcherTypeBuiltin:
                if (!self.disableBuiltin) {
                    [actualFetchers addObject:@(IESForestFetcherTypeBuiltin)];
                }
                break;
            case IESForestFetcherTypeCDN:
                if (!self.disableCDN && !self.onlyLocal) {
                    if (self.onlyPath) {
                        [actualFetchers addObject:@(IESForestFetcherTypeCDNDownloader)];
                    } else {
                        [actualFetchers addObject:@(IESForestFetcherTypeCDN)];
                    }
                }
                break;
            default: {
                NSString *key = [NSString stringWithFormat:@"%d", [fetcherType intValue]];
                Class<IESForestFetcherProtocol> clz = [[IESForestKit fetcherDictionary] valueForKey:key];
                if (clz && [clz conformsToProtocol:@protocol(IESForestFetcherProtocol)]) {
                    [actualFetchers addObject:fetcherType];
                }
            }
        }
    }

    if (actualFetchers.count > 0 && self.enableMemoryCache) {
        [actualFetchers insertObject:@(IESForestFetcherTypeMemory) atIndex:0];
    }

    return [actualFetchers copy];
}

@end
