//
//  AWEVideoPublishResponseModel.m
//  Aweme
//
//  Created by Quan Quan on 16/8/19.
//  Copyright © 2016年 Bytedance. All rights reserved.
//

#import "AWEVideoPublishResponseModel.h"

static const NSInteger kDefaultUploadMaxFailTime = 120;

@implementation AWEVideoUploadSpeedModel

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
        @"enableSpeed" : @"enable_upload_speed_probe",
        @"enableRoute" : @"enable_upload_route_select",
        @"routeMode" : @"route_mode",
        @"routeWeight" : @"route_weight",
        @"speedThreshold" : @"speed_threshold",
        @"singleHostTotalTimeout": @"single_host_total_timeout",
        @"fileSize" : @"file_size",
        @"retryCount" : @"retry_count",
        @"cacheExpired" : @"cache_expired_time"
    };
}

@end


@implementation AWEPhotoUploadParametersResponseModel

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{@"appKey" : @"appKey",
             @"fileHostName" : @"fileHostName",
             @"imageHostName" : @"imageHostName",
             @"fileRetryCount" : @"fileRetryCount",
             @"rwTimeout" : @"rwTimeout",
             @"socketNumber" : @"socketNumber",
             @"authorization" : @"authorization",
             @"authorization2" : @"authorization2",
             @"maxFailTime" : @"maxFailTime",
             @"maxFailTimeEnabled" : @"maxFailTimeEnabled",
             @"enableHttps" : @"enableHttps",
             @"userStoreRegion" : @"userStoreRegion",
             };
}

//For backward compatibility
- (NSNumber *)maxFailTime
{
    if (_maxFailTime == nil || [_maxFailTime integerValue] == 0) {
        return @(kDefaultUploadMaxFailTime);
    }
    return _maxFailTime;
}
@end

@implementation AWEFrameUploadParametersResponseModel

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{@"appKey" : @"appKey",
             @"fileHostName" : @"fileHostName",
             @"imageHostName" : @"imageHostName",
             @"fileRetryCount" : @"fileRetryCount",
             @"rwTimeout" : @"rwTimeout",
             @"socketNumber" : @"socketNumber",
             @"authorization" : @"authorization",
             @"authorization2" : @"authorization2",
             @"maxFailTime" : @"maxFailTime",
             @"maxFailTimeEnabled" : @"maxFailTimeEnabled",
             @"enableHttps" : @"enableHttps",
             @"userStoreRegion" : @"userStoreRegion",
             };
}

//For backward compatibility
- (NSNumber *)maxFailTime
{
    if (_maxFailTime == nil || [_maxFailTime integerValue] == 0) {
        return @(kDefaultUploadMaxFailTime);
    }
    return _maxFailTime;
}
@end

@implementation AWEVideoUploadParametersResponseModel

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{@"appKey" : @"appKey",
             @"captionAppKey" : @"captionAppKey",
             @"fileHostName" : @"fileHostName",
             @"videoHostName" : @"videoHostName",
             @"authorization" : @"authorization",
             @"authorization2" : @"authorization2",
             @"captionAuthorization" : @"captionAuthorization",
             @"captionAuthorization2" : @"captionAuthorization2",
             @"sliceTimeout" : @"sliceTimeout",
             @"sliceRetryCount" : @"sliceRetryCount",
             @"fileRetryCount" : @"fileRetryCount",
             @"sliceSize" : @"sliceSize",
             @"coverTime" : @"coverTime",
             @"maxFailTime" : @"maxFailTime",
             @"maxFailTimeEnabled" : @"maxFailTimeEnabled",
             @"socketNumber" : @"socketNumber",
             @"fileTryHttpsEnable" : @"fileTryHttpsEnable",
             @"enableHttps" : @"enableHttps",
             @"aliveMaxFailTime" : @"aliveMaxFailTime",
             @"enablePostMethod" : @"enablePostMethod",
             @"openTimeOut" : @"openTimeOut",
             @"enableTTNet" : @"enableExternNet",
             @"ttnetConfigValue" : @"ttnetConfigValue",
             @"enableQuic" : @"enableQuic",
             @"isStreamUploadEnable" : @"is_stream_upload_enable",
             @"mainNetworkType" : @"upload_main_network_type",
             @"backupNetworkType" : @"upload_backup_network_type",
             @"userStoreRegion" : @"userStoreRegion",
             @"speedModel" : @"studio_publish_upload_speed_probe_info",
             @"redPacketAppKey" : @"redPacketAppKey",
             @"redPacketAuthorization" : @"redPacketAuthorization",
             @"redPacketAuthorization2" : @"redPacketAuthorization2",
             };
}

//For backward compatibility
- (NSNumber *)maxFailTime
{
    if (_maxFailTime == nil || [_maxFailTime integerValue] == 0) {
        return @(kDefaultUploadMaxFailTime);
    }
    return _maxFailTime;
}

- (NSNumber *)socketNumber
{
    if (_socketNumber == nil || [_socketNumber integerValue] == 0) {
        return @(1);
    }
    return _socketNumber;
}

+ (NSValueTransformer *)speedModelJSONTransformer
{
    return [MTLJSONAdapter dictionaryTransformerWithModelClass:[AWEVideoUploadSpeedModel class]];
}

@end


@implementation ACCSettingsConfigItem

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
        @"enablePreUpload" : @"enable_pre_upload",
        @"preUploadEncryptionMode" : @"pre_upload_encryption_mode",
        @"publishCloseClientWatermark" : @"publish_close_client_watermark",
        @"dnsEnable" : @"dns_enable",
        @"dnsMainType" : @"dns_main_type",
        @"dnsBackType" : @"dns_back_type",
        @"dnsExpiredTime" : @"dns_expired_time",
        @"dnsOwnServer" : @"dns_own_server",
        @"dnsGoogleServer" : @"dns_google_server",
        @"livePreviewTime" : @"last_preview_time",
        @"hasLive" : @"has_live",
        @"downgradeErrorToast" : @"tc_error_downgrade_toast",
        @"liveStickerInfo" : @"preview_sticker_data"
    };
}

@end

@implementation AWEPublishActivityModel

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
             @"activityName" : @"activity_name",
             @"hashtagID" : @"hashtag_id",
             @"hashtagName" : @"hashtag_name",
             };
}

@end

@implementation AWEPublishActivityParametersResponseModel

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
             @"videoDurationLimit" : @"time_limit",
             @"activityInfo" : @"challenge_infos",
             };
}

+ (NSValueTransformer *)activityInfoJSONTransformer
{
    return [MTLJSONAdapter arrayTransformerWithModelClass:AWEPublishActivityModel.class];
}

@end

@implementation AWEPublishVideoSyncParametersResponseModel
+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
             @"hasClaimOriginPermission" : @"claim_origin_permission",
             @"isVideoExclusive" : @"is_video_exclusive",
             @"hasRewardProjectAuthorBenefit" : @"reward_project_author_benefit",
             };
}
@end

@implementation AWEResourceUploadParametersResponseModel

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
             @"videoUploadParameters" : @"video_config",
             @"photoUploadParameters" : @"img_config",
             @"frameUploadParameters" : @"vframe_config",
             @"settingsParameters" : @"settings_config",
             @"activityParameters" : @"multiple_platforms_post",
             @"mediumVideoPlanUserStatus" : @"mid_video_plan_config",
             @"videoSyncParameters": @"mid_video_plan_author_permission",
             };
}

+ (NSValueTransformer *)settingsParametersJSONTransformer
{
    return [MTLJSONAdapter dictionaryTransformerWithModelClass:ACCSettingsConfigItem.class];
}

+ (NSValueTransformer *)videoSyncParametersJSONTransformer
{
    return [MTLJSONAdapter dictionaryTransformerWithModelClass:AWEPublishVideoSyncParametersResponseModel.class];
}

@end
