//
//  IESGurdAppLogger.m
//  IESGurdKit
//
//  Created by li keliang on 2019/3/13.
//

#import "IESGurdAppLogger.h"
#import "IESGeckoResourceManager.h"
#import "IESGeckoAPI.h"
#import "IESGeckoKit+Private.h"
#import "IESGeckoDefines+Private.h"
#import "IESGurdKitUtil.h"
#import "UIDevice+IESGeckoKit.h"
#import "IESGurdChannelBlocklistManager.h"
#import "IESGurdRegisterManager.h"

NS_INLINE BOOL IESGurdParamIsArray (id object)
{
    return [object isKindOfClass:[NSArray class]];
}

NS_INLINE BOOL IESGurdParamIsDictionary (id object)
{
    return [object isKindOfClass:[NSDictionary class]];
}

NS_INLINE NSString *IESGurdParamConvertJSONObjectToString(id JSONObject)
{
    if (!JSONObject) {
        return @"";
    }
    NSData *data = [NSJSONSerialization dataWithJSONObject:JSONObject options:0 error:NULL];
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

static dispatch_queue_t IESGurdTrackEventQueue (void)
{
    static dispatch_queue_t trackEventQueue = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        trackEventQueue = IESGurdKitCreateSerialQueue("com.IESGurdKit.TrackEventQueue");
    });
    return trackEventQueue;
}

#define CHECKIF_APPLOG_ENABLED  \
if (![self isAppLogEnable]) {   \
    return;                     \
}                               \

@implementation IESGurdAppLogger

#pragma mark - Public

+ (void)recordCleanStats:(IESGurdStatsType)type
               accessKey:(NSString *)accessKey
                 channel:(NSString *)channel
               packageID:(uint64_t)packageID
                   extra:(nullable NSDictionary *)extra
{
    CHECKIF_APPLOG_ENABLED
    
    dispatch_queue_async_safe(IESGurdTrackEventQueue(), (^{
        NSDictionary *commonParams = IESGurdClientBasicParams();
        NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:commonParams];
        
        [params addEntriesFromDictionary:@{ @"id" : @(packageID),
                                            @"stats_type": @(type),
                                            @"channel": channel ? : @"",
                                            @"access_key": accessKey ? : @"" }];
        
        if (extra.count > 0) {
            NSMutableDictionary *extraParams = [NSMutableDictionary dictionaryWithCapacity:extra.count];
            [extra enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
                if (IESGurdParamIsArray(obj) || IESGurdParamIsDictionary(obj)) {
                    extraParams[key] = IESGurdParamConvertJSONObjectToString(obj);
                } else {
                    extraParams[key] = obj;
                }
            }];
            [params addEntriesFromDictionary:[extraParams copy]];
        }
        
        [self trackEvent:@"geckosdk_clean_stats" params:[params copy]];
    }));
}

+ (void)recordUpdateStats:(nullable NSDictionary *)extra {
    CHECKIF_APPLOG_ENABLED
    
    dispatch_queue_async_safe(IESGurdTrackEventQueue(), (^{
        NSDictionary *commonParams = IESGurdClientBasicParams();
        NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:commonParams];
        
        if (extra.count > 0) {
            NSMutableDictionary *extraParams = [NSMutableDictionary dictionaryWithCapacity:extra.count];
            [extra enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
                if (IESGurdParamIsArray(obj) || IESGurdParamIsDictionary(obj)) {
                    extraParams[key] = IESGurdParamConvertJSONObjectToString(obj);
                } else {
                    extraParams[key] = obj;
                }
            }];
            [params addEntriesFromDictionary:[extraParams copy]];
            if (self.lastestQueryPkgsLogid && ![self.lastestQueryPkgsLogid isEqualToString:extra[@"x_tt_logid"]]) {
                params[@"x_tt_logid_latest"] = self.lastestQueryPkgsLogid;
            }
        }
        [self trackEvent:@"geckosdk_update_aggr_stats" params:[params copy]];
    }));
}

+ (void)recordQueryPkgsStats:(NSDictionary *)extra
{
    CHECKIF_APPLOG_ENABLED
    
    dispatch_queue_async_safe(IESGurdTrackEventQueue(), (^{
        NSMutableDictionary *params = [NSMutableDictionary dictionary];
        [params addEntriesFromDictionary:IESGurdClientBasicParams()];
        [params addEntriesFromDictionary:extra];
        if (self.lastestQueryPkgsLogid && !extra[@"x_tt_logid"]) {
            params[@"x_tt_logid_latest"] = self.lastestQueryPkgsLogid;
        }
        [self trackEvent:@"geckosdk_query_pkgs" params:[params copy]];
    }));
}

+ (void)recordStatsWithSyncStatusType:(NSInteger)syncStatusType
                               taskId:(NSInteger)taskId
                             taskType:(NSInteger)taskType
{
    CHECKIF_APPLOG_ENABLED
    
    dispatch_queue_async_safe(IESGurdTrackEventQueue(), (^{
        NSMutableDictionary *trackParams = [NSMutableDictionary dictionary];
        trackParams[@"sync_stats_type"] = @(syncStatusType);
        trackParams[@"sync_task_id"] = @(taskId);
        trackParams[@"sync_task_type"] = @(taskType);
        
        [trackParams addEntriesFromDictionary:IESGurdClientBasicParams()];
        
        [self trackEvent:@"geckosdk_bytesync_stats" params:[trackParams copy]];
    }));
}

+ (void)recordEventWithType:(IESGurdAppLogEventType)eventType
                    subtype:(IESGurdAppLogEventSubtype)subtype
                     params:(nullable NSDictionary *)params
                  extraInfo:(nullable NSString *)extraInfo
               errorMessage:(nullable NSString *)errorMessage
{
    [self recordEventWithType:eventType subtype:subtype params:params extraInfo:extraInfo errorMessage:errorMessage accessKey:nil channels:nil];
}

+ (void)recordEventWithType:(IESGurdAppLogEventType)eventType
                    subtype:(IESGurdAppLogEventSubtype)subtype
                     params:(nullable NSDictionary *)params
                  extraInfo:(nullable NSString *)extraInfo
               errorMessage:(nullable NSString *)errorMessage
                  accessKey:(nullable NSString *)accessKey
                   channels:(nullable NSString *)channels
{
    CHECKIF_APPLOG_ENABLED
    
    dispatch_queue_async_safe(IESGurdTrackEventQueue(), (^{
        NSMutableDictionary *trackParams = [NSMutableDictionary dictionary];
        trackParams[@"event_type"] = @(eventType);
        trackParams[@"sub_type"] = @(subtype);
        trackParams[@"extra"] = extraInfo ? : @"";
        trackParams[@"err_msg"] = errorMessage ? : @"";
        if (accessKey) trackParams[@"access_key"] = accessKey;
        if (channels) trackParams[@"channels"] = channels;
        
        [trackParams addEntriesFromDictionary:params];
        
        [trackParams addEntriesFromDictionary:IESGurdClientBasicParams()];
        
        [self trackEvent:@"geckosdk_event_message" params:[trackParams copy]];
    }));
}

+ (void)recordQuerySettingsWithResponse:(IESGurdNetworkResponse *)networkResponse {
    CHECKIF_APPLOG_ENABLED
    
    NSDictionary *params = networkResponse.requestParams;
    if (![params isKindOfClass:[NSDictionary class]]) {
        return;
    }
    
    dispatch_queue_async_safe(IESGurdTrackEventQueue(), (^{
        NSDictionary *commonInfo = params[kIESGurdNetworkCommonKey];
        NSMutableDictionary *trackParams = [NSMutableDictionary dictionaryWithDictionary:commonInfo];
        trackParams[@"api_version"] = IESGurdSettingsAPIVersion;
        [trackParams addEntriesFromDictionary:networkResponse.logInfo];
        
        NSInteger statusCode = networkResponse.statusCode;
        trackParams[@"http_status"] = @(statusCode);
        
        NSString *errorMessage = networkResponse.error.localizedDescription;
        if (statusCode != 200 && errorMessage.length > 0) {
            trackParams[@"err_msg"] = errorMessage;
        }
        
        if (statusCode == 200) {
            id responseObject = networkResponse.responseObject;
            NSDictionary *responseDictionary = nil;
            if ([responseObject isKindOfClass:[NSDictionary class]]) {
                responseDictionary = responseObject;
            } else if ([responseObject isKindOfClass:[NSData class]]) {
                responseDictionary = [NSJSONSerialization JSONObjectWithData:(NSData *)responseObject
                                                                     options:0
                                                                       error:NULL];
            }
            
            if ([responseDictionary isKindOfClass:[NSDictionary class]]) {
                NSInteger status = [responseDictionary[@"status"] integerValue];
                if (status == IESGurdStatusCodeSettingsAlreadyUpToDate) {
                    return;
                } else if (status != 0) {
                    trackParams[@"err_msg"] = responseDictionary[@"message"];
                    trackParams[@"err_code"] = @(status);
                }
            }
        }
        
        NSString *logId = networkResponse.allHeaderFields[@"x-tt-logid"];
        if (logId.length > 0) {
            trackParams[@"x_tt_logid"] = logId;
        } else {
            NSDictionary *settingsInfo = params[kIESGurdSettingsRequestKey];
            
            trackParams[@"settings_info"] = IESGurdParamConvertJSONObjectToString(settingsInfo);
        }
        
        [self trackEvent:@"geckosdk_query_settings" params:[trackParams copy]];
    }));
}

+ (void)recordResourceInfoWithAccessKey:(NSString *)accessKey
                 accessKeyResourceUsage:(NSInteger)accessKeyResourceUsage
                           channelCount:(int)channelCount
                geckoTotalResourceUsage:(NSInteger)geckoTotalResourceUsage
{
    CHECKIF_APPLOG_ENABLED
    
    dispatch_queue_async_safe(IESGurdTrackEventQueue(), (^{
        NSDictionary *commonParams = IESGurdClientBasicParams();
        NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:commonParams];
        NSUInteger blockCount = [[IESGurdChannelBlocklistManager sharedManager] getBlocklistCount:accessKey];
        
        IESGurdRegisterModel *registerModel = [[IESGurdRegisterManager sharedManager] registerModelWithAccessKey:accessKey];
        
        [params addEntriesFromDictionary:@{ @"access_key": accessKey ? : @"",
                                            @"access_key_resource_usage": @(accessKeyResourceUsage),
                                            @"channel_count": @(channelCount),
                                            @"gecko_total_resource_usage": @(geckoTotalResourceUsage),
                                            @"blocklist_count": @(blockCount),
                                            @"business_version": registerModel.version ? : IESGurdKitInstance.appVersion
                                         }];
        
        [self trackEvent:@"geckosdk_access_key_resource_info" params:[params copy]];
    }));
}

#pragma mark - Private

+ (BOOL)isAppLogEnable
{
    return [self.appLogDelegate respondsToSelector:@selector(trackEvent:params:)];
}

+ (void)trackEvent:(NSString *)event params:(NSDictionary *)params
{
    if ([self.appLogDelegate respondsToSelector:@selector(trackEvent:params:)]) {
        NSMutableDictionary *updatedParams = [NSMutableDictionary dictionaryWithDictionary:params];
        updatedParams[@"params_for_special"] = @"gecko";
        [self.appLogDelegate trackEvent:event params:[updatedParams copy]];
    }
}

#pragma mark - Accessor

static id<IESGurdAppLogDelegate> kIESGurdAppLogDelegate = nil;
+ (id<IESGurdAppLogDelegate>)appLogDelegate
{
    return kIESGurdAppLogDelegate;
}

+ (void)setAppLogDelegate:(id<IESGurdAppLogDelegate>)appLogDelegate
{
    kIESGurdAppLogDelegate = appLogDelegate;
}

static NSString *kLastestQueryPkgsLogid = nil;
+ (NSString *)lastestQueryPkgsLogid
{
    return kLastestQueryPkgsLogid;
}

+ (void)setLastestQueryPkgsLogid:(NSString *)logid
{
    kLastestQueryPkgsLogid = logid;
}

@end
