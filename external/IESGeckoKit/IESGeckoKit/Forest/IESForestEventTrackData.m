// Copyright 2022. The Cross Platform Authors. All rights reserved.

#import "IESForestEventTrackData.h"
#import "IESForestRequest.h"
#import "IESForestResponse.h"
#import "IESForestFetcherProtocol.h"
#import "IESForestError.h"
#import "IESForestImagePreloader.h"

#import <IESGeckoKit/IESGeckoKit.h>
#import <IESGeckoKit/IESGurdLogProxy.h>
#import <ByteDanceKit/NSDictionary+BTDAdditions.h>

@implementation IESForestEventTrackData

- (instancetype)initWithRequest:(IESForestRequest *)request response:(IESForestResponse *)response
{
    if (self = [super init]) {
        self.isTemplate = request.resourceScene == IESForestResourceSceneLynxTemplate || request.resourceScene == IESForestResourceSceneWebMainResource;
        self.isSuccess = response.isSuccess;
        self.loaderInfo = @{
            @"res_loader_name": @"forest",
            @"res_loader_version": IESGurdKitSDKVersion() ? : @"",
        };

        if (request.enableRequestReuse &&!request.isPreloaded && !request.isRequestReused) {
            NSString * resolvedURL = response.resolvedURL;
            request.isPreloaded = resolvedURL ? [IESForestImagePreloader hasCacheImageForKey:resolvedURL] : NO;
        }

        self.resourceInfo = @{
            @"res_src": request.url ?: @"",
            @"gecko_access_key": request.accessKey ?: @"",
            @"gecko_channel": request.channel ?: @"",
            @"gecko_bundle": request.bundle ?: @"",
            @"gecko_config_from": request.geckoConfigSource ?: @"",
            @"gecko_sync_update": request.waitGeckoUpdate ? @"true" : @"false",
            @"res_version": [NSString stringWithFormat:@"%llu", response.version],
            @"res_type": [self extractDataTypeFromURLString: request.url] ?: @"",
            @"res_from": response.sourceTypeDescription ?: @"",
            @"is_memory": @(request.isFromMemory),
            @"res_scene": request.resourceSceneDescription,
            @"res_state": response.isSuccess ? @"success" : @"failed",
            @"res_trace_id": request.groupId ?: @"",
            @"res_size": response.isSuccess ? @(response.data.length) : @(0),
            @"fetcher_list": request.fetcherNames ?: @"",
            @"is_preload": @(request.isPreload),
            @"is_preloaded": @(request.isPreloaded),
            @"is_request_reused": @(request.isRequestReused),
            @"enable_request_reuse": @(request.enableRequestReuse),
        };
        IESGurdLogInfo(@"Forest - EventTrack - resourceInfo: %@", _resourceInfo);

        self.errorInfo = @{
            @"res_loader_error_code": @(request.errorCode),
            @"net_library_error_code": @(request.ttNetErrorCode),
            @"http_status_code": @(request.httpStatusCode),
            @"gecko_error_code": [self monitorGeckoErrorCode:request.geckoErrorCode],
            @"res_error_msg": request.debugInfo ?: @"",
            @"gecko_error_msg": request.geckoError ?: @"",
            @"builtin_error_msg": request.builtinError ?: @"",
            @"cdn_error_msg": request.cdnError ?: @"",
            @"cdn_cache_error_msg": @"",
            // TODO: add gecko library related errorCode, errorMsg
        };
        IESGurdLogInfo(@"Forest - EventTrack - errorInfo: %@", _errorInfo);

        self.metricInfo = @{
            @"res_load_start": @(request.metrics.loadStart),
            @"res_load_finish": @(request.metrics.loadFinish),
            @"init_start": @(request.metrics.parseStart),
            @"init_finish": @(request.metrics.parseFinish),
            @"memory_start": @(request.metrics.memoryStart),
            @"memory_finish": @(request.metrics.memoryFinish),
            @"gecko_start": @(request.metrics.geckoStart),
            @"gecko_finish": @(request.metrics.geckoFinish),
            @"gecko_update_start": @(request.metrics.geckoUpdateStart),
            @"gecko_update_finish": @(request.metrics.geckoUpdateFinish),
            @"cdn_start": @(request.metrics.cdnStart),
            @"cdn_finish": @(request.metrics.cdnFinish),
            @"cdn_cache_start": @(request.metrics.cdnCacheStart),
            @"cdn_cache_finish": @(request.metrics.cdnCacheFinish),
            @"builtin_start": @(request.metrics.builtinStart),
            @"builtin_finish": @(request.metrics.builtinFinish),
        };
//        IESGurdLogInfo(@"Forest - EventTrack - metricInfo: %@", _metricInfo);

        NSMutableDictionary *extraInfo = [NSMutableDictionary dictionaryWithDictionary:request.customParameters];
        [extraInfo addEntriesFromDictionary:request.extraInfo];
        self.extraInfo = extraInfo;
    }

    return self;
}

- (NSString *)extractDataTypeFromURLString:(NSString *)urlString
{
    NSURL *url = [NSURL URLWithString:urlString];
    return [url.path.pathExtension lowercaseString];
}

- (NSNumber *)monitorGeckoErrorCode:(NSInteger)errorCode
{
    switch(errorCode) {
        case IESForestErrorGeckoDisabled:
            return @(1);
        case IESForestErrorGeckoAccessKeyEmpty:
            return @(2);
        case IESForestErrorGeckoChannelBundleEmpty:
            return @(3);
        case IESForestErrorGeckoUpdateFailed:
            return @(5);
        case IESForestErrorGeckoLocalFileNotFound:
            return @(6);
        default:
            return @(0);
    };
}

- (NSDictionary *)calculatedMetricInfo
{
    NSMutableDictionary *dict = [self.metricInfo mutableCopy];
    [self.metricInfo enumerateKeysAndObjectsUsingBlock:^(NSString* key, NSNumber* value, BOOL * _Nonnull stop) {
        if ([key hasSuffix:@"_finish"]) {
            NSString* startKey = [key stringByReplacingOccurrencesOfString:@"_finish" withString:@"_start"];
            NSString* durationKey = [key stringByReplacingOccurrencesOfString:@"_finish" withString:@""];
            NSNumber* duration = @([value doubleValue] - [[self.metricInfo btd_numberValueForKey:startKey default:@(0)] doubleValue]);
            [dict setObject:duration forKey:durationKey];
        }
    }];
    return [dict copy];
}

@end
