// Copyright 2022. The Cross Platform Authors. All rights reserved.

#import "IESForestRemoteParameters.h"
#import "IESForestKit.h"

#import <IESGeckoKit/IESGurdLogProxy.h>
#import <IESGeckoKit/IESGurdKit+ResourceLoader.h>
#import <ByteDanceKit/NSArray+BTDAdditions.h>
#import <ByteDanceKit/NSDictionary+BTDAdditions.h>
#import <ByteDanceKit/BTDMacros.h>

@interface IESForestRemoteParameters ()

- (instancetype)initWithAccessKey:(NSString *)accessKey channel:(NSString *)channel bundle:(NSString *)bundle;
- (nullable NSNumber *)dynamicToWaitGeckoUpdate: (nullable NSNumber *)dynamic;
- (BOOL)isValid;
- (void)appendInfoFromResourceMeta:(IESGurdSettingsResourceMeta *)resourceMeta;
@end

@implementation IESForestRemoteParameters

- (instancetype)initWithAccessKey:(NSString *)accessKey channel:(NSString *)channel bundle:(NSString *)bundle
{
    if (self = [super init]) {
        _accessKey = accessKey;
        _channel = channel;
        _bundle = bundle;
    }
    return self;
}

+ (nullable instancetype)remoteParametersWithURLString:(NSString *)urlString defaultPrefixToAccessKey:(NSDictionary *)defaultPrefixToAccessKey
{
    NSDictionary *detail = [self extractGeckoInfoFormURL:urlString];
    NSString *prefix = [detail btd_stringValueForKey:@"prefix"];
    NSString *channel = [detail btd_stringValueForKey:@"channel"];
    NSString *bundle = [detail btd_stringValueForKey:@"bundle"];
    if (BTD_isEmptyString(prefix) || BTD_isEmptyString(channel) || BTD_isEmptyString(bundle)) {
        return nil;
    }

    IESGurdSettingsResourceMeta *resourceMeta = [[IESGeckoKit settingsResponse] resourceMeta];
    NSString *accessKey = [resourceMeta.appConfig.prefixToAccessKeyDictionary btd_stringValueForKey:prefix];
    IESGurdLogInfo(@"Forest - remoteParameter - accessKey: %@ for url: %@", accessKey, urlString);

    if (!BTD_isEmptyString(accessKey)) {
        IESForestRemoteParameters *instance = [[self alloc] initWithAccessKey:accessKey channel:channel bundle:bundle];
        [instance appendInfoFromResourceMeta:resourceMeta];
        return instance;
    }

    accessKey = [defaultPrefixToAccessKey btd_stringValueForKey:prefix];
    IESGurdLogInfo(@"Forest - match AccessKey by default - accessKey: %@", accessKey);
    if (!BTD_isEmptyString(accessKey)) {
        IESForestRemoteParameters *instance = [[self alloc] initWithAccessKey:accessKey channel:channel bundle:bundle];
        instance.fromCustomConfig = YES;
        return instance;
    }

    return nil;
}

+ (nullable NSDictionary *)extractGeckoInfoFormURL:(NSString *)urlString
{
    if (BTD_isEmptyString(urlString)) {
        return nil;
    }

    NSURL *url = [NSURL URLWithString:urlString];
    NSString *path = url.path;
    if (BTD_isEmptyString(path)) {
        return nil;
    }
    NSArray<NSString *> *pathComponents = [url.path componentsSeparatedByString:@"/"];
    // prefix: 6, channel: 1, bundle: >= 1  => >= 8
    if (pathComponents.count < 8) {
        return nil;
    }

    NSString *prefix = [[pathComponents subarrayWithRange:NSMakeRange(0, 6)] componentsJoinedByString:@"/"];
    NSString *channel = [[pathComponents subarrayWithRange:NSMakeRange(6, 1)] componentsJoinedByString:@"/"];
    NSString *bundle = [[pathComponents subarrayWithRange:NSMakeRange(7, pathComponents.count - 7)] componentsJoinedByString:@"/"];
    if (BTD_isEmptyString(prefix) || BTD_isEmptyString(channel) || BTD_isEmptyString(bundle)) return nil;

    return @{@"prefix": prefix, @"channel": channel, @"bundle": bundle};
}

- (NSString *)description
{
    NSMutableArray *descArray = [[NSMutableArray alloc] init];
    [descArray addObject:[NSString stringWithFormat:@"accessKey: %@", _accessKey]];
    [descArray addObject:[NSString stringWithFormat:@"channel: %@", _channel]];
    [descArray addObject:[NSString stringWithFormat:@"bundle: %@", _bundle]];
    [descArray addObject:[NSString stringWithFormat:@"fetchers: %@", [self fetchersDescription]]];
    [descArray addObject:[NSString stringWithFormat:@"waitGeckoUpdate: %@", _waitGeckoUpdate]];
    [descArray addObject:[NSString stringWithFormat:@"disableCDNCache: %@", _disableCdnCache]];
    return [NSString stringWithFormat:@"{%@}", [descArray componentsJoinedByString:@", "]];
}

#pragma mark -- private

- (void)appendInfoFromResourceMeta:(IESGurdSettingsResourceMeta *)resourceMeta {
    if (!self.isValid || !resourceMeta) {
        return;
    }

    IESGurdSettingsAccessKeyResourceMeta *accessKeyResourceMeta = resourceMeta[self.accessKey];
    IESGurdSettingsResourceBaseConfig *channelResourceMeta = accessKeyResourceMeta[self.channel];
    
    NSArray<IESGurdSettingsResourceConfigPipelineItem *> *fetchers = nil;
    IESGurdSettingsResourceConfigCDNFallBack *cdnFallback = nil;
    
    if (channelResourceMeta) {
        if ([channelResourceMeta pipelineItemsArray].count > 0) {
            fetchers = [channelResourceMeta pipelineItemsArray];
        }
        cdnFallback = [channelResourceMeta CDNFallBack];
    }

    if (accessKeyResourceMeta.accessKeyConfig) {
        if (fetchers == nil && [accessKeyResourceMeta.accessKeyConfig pipelineItemsArray].count > 0) {
            fetchers = [accessKeyResourceMeta.accessKeyConfig pipelineItemsArray];
        }
        if (cdnFallback == nil) {
            cdnFallback = [accessKeyResourceMeta.accessKeyConfig CDNFallBack];
        }
    }

    if (resourceMeta.appConfig) {
        if (fetchers == nil) {
            fetchers = [resourceMeta.appConfig pipelineItemsArray];
        }
        if (cdnFallback == nil) {
            cdnFallback = [resourceMeta.appConfig CDNFallBack];
        }
    }

    NSMutableArray *fetcherSequence = [NSMutableArray new];
    [fetchers enumerateObjectsUsingBlock:^(IESGurdSettingsResourceConfigPipelineItem *line, __unused NSUInteger idx, __unused BOOL * _Nonnull stop) {
        switch (line.type) {
            case IESGurdSettingsPipelineTypeGurd:
                [fetcherSequence btd_addObject:@(IESForestFetcherTypeGecko)];
                break;
            case IESGurdSettingsPipelineTypeCDN:
                [fetcherSequence btd_addObject:@(IESForestFetcherTypeCDN)];
                break;
            case IESGurdSettingsPipelineTypeBuiltin:
                [fetcherSequence btd_addObject:@(IESForestFetcherTypeBuiltin)];
                break;
        }
    }];
    self.fetcherSequence = [fetcherSequence copy];

    __block NSNumber *dynamic = nil;
    [fetchers enumerateObjectsUsingBlock:^(IESGurdSettingsResourceConfigPipelineItem *line, __unused NSUInteger idx, BOOL * _Nonnull stop) {
        if (line.type == IESGurdSettingsPipelineTypeGurd) { /// GECKO
            dynamic = @(line.updatePolicy);
            *stop = YES;
        }
    }];
    self.waitGeckoUpdate = [self dynamicToWaitGeckoUpdate:dynamic];

    __block NSNumber *disableCdnCache = nil;
    [fetchers enumerateObjectsUsingBlock:^(IESGurdSettingsResourceConfigPipelineItem *line, __unused NSUInteger idx, BOOL * _Nonnull stop) {
        if (line.type == IESGurdSettingsPipelineTypeCDN) { /// CDN
            disableCdnCache = @(line.disableCache);
            *stop = YES;
        }
    }];
    self.disableCdnCache = disableCdnCache;

    if (cdnFallback.domainsArray && cdnFallback.shuffle) {
        self.shuffleDomains = [cdnFallback.domainsArray copy];
    }

    if (cdnFallback.maxAttempts > 0) {
        self.cdnRetryTimes = @(cdnFallback.maxAttempts);
    }
}

- (BOOL)isValid
{
    return !BTD_isEmptyString(self.bundle) && !BTD_isEmptyString(self.channel) && !BTD_isEmptyString(self.accessKey);
}

- (nullable NSNumber *)dynamicToWaitGeckoUpdate: (nullable NSNumber *)dynamic
{
    if (!dynamic) {
        return nil;
    }
    if ([dynamic intValue] == 0 || [dynamic intValue] == 3) {
        return @(NO);
    }
    if ([dynamic intValue] == 1 || [dynamic intValue] == 2) {
        return @(YES);
    }
    return nil;
}

- (NSString *)fetchersDescription
{
    if (_fetcherSequence == nil || _fetcherSequence.count == 0) {
        return @"[]";
    }
    NSMutableArray* fetchers = [[NSMutableArray alloc] init];

    for (NSNumber *type in _fetcherSequence) {
        switch (type.integerValue) {
            case IESForestFetcherTypeGecko:
                [fetchers addObject: @"gecko"];
                break;
            case IESForestFetcherTypeBuiltin:
                [fetchers addObject: @"builtin"];
                break;
            case IESForestFetcherTypeCDN:
                [fetchers addObject: @"cdn"];
                break;
            default: {
                IESGurdLogWarning(@"Forest - Unexpected fetcher type from gecko settings: %@", type);
            }
        }
    }

    return [NSString stringWithFormat:@"[%@]", [fetchers componentsJoinedByString:@", "]];
}

@end
