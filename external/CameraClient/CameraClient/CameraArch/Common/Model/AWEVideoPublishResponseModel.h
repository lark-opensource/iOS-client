//
//  AWEVideoPublishResponseModel.h
//  Aweme
//
//  Created by Quan Quan on 16/8/19.
//  Copyright © 2016年 Bytedance. All rights reserved.
//

#import <Mantle/Mantle.h>

@interface AWEVideoUploadSpeedModel : MTLModel<MTLJSONSerializing>

@property (nonatomic, assign) BOOL enableSpeed;
@property (nonatomic, assign) BOOL enableRoute;
@property (nonatomic, assign) NSInteger routeMode;
@property (nonatomic, assign) NSInteger routeWeight;
@property (nonatomic, assign) NSInteger speedThreshold;
@property (nonatomic, assign) NSInteger singleHostTotalTimeout;
@property (nonatomic, assign) NSInteger fileSize;
@property (nonatomic, assign) NSInteger retryCount;
@property (nonatomic, assign) NSInteger cacheExpired;

@end

@interface AWEVideoUploadParametersResponseModel : MTLModel<MTLJSONSerializing>
@property (nonatomic, strong) NSString *appKey;
@property (nonatomic, strong) NSString *captionAppKey;
@property (nonatomic, strong) NSString *fileHostName; // deprecated
@property (nonatomic, strong) NSString *videoHostName;
@property (nonatomic, strong) NSString *authorization;
@property (nonatomic, strong) NSDictionary *authorization2; // 新sdk -> 鉴权参数
@property (nonatomic, strong) NSString *captionAuthorization;
@property (nonatomic, strong) NSDictionary *captionAuthorization2; // 新sdk -> 鉴权参数
@property (nonatomic, strong) NSNumber *sliceTimeout; // 新sdk -> RWTimeout
@property (nonatomic, strong) NSNumber *sliceRetryCount;
@property (nonatomic, strong) NSNumber *fileRetryCount;
@property (nonatomic, strong) NSNumber *sliceSize;
@property (nonatomic, strong) NSNumber *coverTime; // 新sdk -> SnapshotTime
@property (nonatomic, strong) NSNumber *maxFailTime;
@property (nonatomic, strong) NSNumber *maxFailTimeEnabled; // 新sdk -> 没有了
@property (nonatomic, strong) NSNumber *socketNumber;
@property (nonatomic, strong) NSNumber *enableHttps;
@property (nonatomic, strong) NSNumber *fileTryHttpsEnable; // 新sdk -> 没有了
@property (nonatomic, strong) NSNumber *aliveMaxFailTime;
@property (nonatomic, strong) NSNumber *enablePostMethod; // 新sdk -> 没有了
@property (nonatomic, strong) NSNumber *openTimeOut;
@property (nonatomic, strong) NSNumber *enableTTNet; // 新sdk -> 内部适配
@property (nonatomic, strong) NSNumber *ttnetConfigValue; // 新sdk -> 内部适配
@property (nonatomic, strong) NSNumber *enableQuic; // 新sdk -> 下版本加
@property (nonatomic, strong) NSNumber *isStreamUploadEnable; // 新sdk -> 暂时不要
@property (nonatomic, strong) NSNumber *mainNetworkType; // 新sdk -> 设置主网络
@property (nonatomic, strong) NSNumber *backupNetworkType; // 新sdk -> 设置备选网络
@property (nonatomic, strong) NSString *userStoreRegion;
@property (nonatomic, strong) AWEVideoUploadSpeedModel *speedModel;

@property (nonatomic, copy, nullable) NSString *redPacketAppKey;
@property (nonatomic, strong, nullable) NSString *redPacketAuthorization;
@property (nonatomic, strong, nullable) NSDictionary *redPacketAuthorization2; // 新sdk -> 鉴权参数
@end

@interface AWEPhotoUploadParametersResponseModel : MTLModel<MTLJSONSerializing>
@property (nonatomic, strong) NSString *appKey;
@property (nonatomic, strong) NSString *fileHostName; // deprecated
@property (nonatomic, strong) NSString *imageHostName;
@property (nonatomic, strong) NSNumber *fileRetryCount;
@property (nonatomic, strong) NSNumber *rwTimeout;
@property (nonatomic, strong) NSNumber *socketNumber;
@property (nonatomic, strong) NSString *authorization;
@property (nonatomic, strong) NSDictionary *authorization2; // 新sdk -> 鉴权参数
@property (nonatomic, strong) NSNumber *maxFailTime;
@property (nonatomic, strong) NSNumber *maxFailTimeEnabled;
@property (nonatomic, strong) NSNumber *enableHttps;
@property (nonatomic, strong) NSString *userStoreRegion;
@end

@interface AWEFrameUploadParametersResponseModel : MTLModel<MTLJSONSerializing>
@property (nonatomic, strong) NSString *appKey;
@property (nonatomic, strong) NSString *fileHostName; // deprecated
@property (nonatomic, strong) NSString *imageHostName;
@property (nonatomic, strong) NSNumber *fileRetryCount;
@property (nonatomic, strong) NSNumber *rwTimeout;
@property (nonatomic, strong) NSNumber *socketNumber;
@property (nonatomic, strong) NSString *authorization;
@property (nonatomic, strong) NSDictionary *authorization2; // 新sdk -> 鉴权参数
@property (nonatomic, strong) NSNumber *maxFailTime;
@property (nonatomic, strong) NSNumber *maxFailTimeEnabled;
@property (nonatomic, strong) NSNumber *enableHttps;
@property (nonatomic, strong) NSString *userStoreRegion;
@end

@interface ACCSettingsConfigItem : MTLModel<MTLJSONSerializing>

@property (nonatomic, strong) NSNumber *enablePreUpload;
@property (nonatomic, strong) NSNumber *preUploadEncryptionMode;
@property (nonatomic, strong) NSNumber *publishCloseClientWatermark;
@property (nonatomic, strong) NSNumber *dnsEnable;
@property (nonatomic, strong) NSNumber *dnsMainType; // 新sdk -> 暂时不要
@property (nonatomic, strong) NSNumber *dnsBackType; // 新sdk -> 暂时不要
@property (nonatomic, strong) NSNumber *dnsExpiredTime; // 新sdk -> 暂时不要
@property (nonatomic, strong) NSString *dnsOwnServer; // 新sdk -> 暂时不要
@property (nonatomic, strong) NSString *dnsGoogleServer; // 新sdk -> 暂时不要

@property (nonatomic, strong) NSNumber *livePreviewTime;
@property (nonatomic, strong) NSNumber *hasLive;
@property (nonatomic, strong) NSString *downgradeErrorToast;
@property (nonatomic, copy) NSDictionary *liveStickerInfo;

@end

@interface AWEPublishActivityModel : MTLModel<MTLJSONSerializing>

@property (nonatomic, copy) NSString *activityName;
@property (nonatomic, copy) NSString *hashtagID;
@property (nonatomic, copy) NSString *hashtagName;

@end

@interface AWEPublishActivityParametersResponseModel : MTLModel<MTLJSONSerializing>

@property (nonatomic, assign) NSInteger videoDurationLimit;
@property (nonatomic, copy) NSArray<AWEPublishActivityModel *> *activityInfo;

@end

typedef enum : NSUInteger {
    AWEMediumVideoPlanUserStatusDefault = 0, // AWEMediumVideoPlanUserTypeNotJoin
    AWEMediumVideoPlanUserTypeHasJoined = 1,
    AWEMediumVideoPlanUserTypeInApplying = 2,
    AWEMediumVideoPlanUserTypeNotJoin = 3,
} AWEMediumVideoPlanUserStatus;

@interface AWEPublishVideoSyncParametersResponseModel : MTLModel<MTLJSONSerializing>
@property (nonatomic, assign) BOOL hasClaimOriginPermission;
@property (nonatomic, assign) BOOL isVideoExclusive;
@property (nonatomic, assign) BOOL hasRewardProjectAuthorBenefit;
@end

@interface AWEResourceUploadParametersResponseModel : MTLModel<MTLJSONSerializing>

@property (nonatomic, strong) AWEVideoUploadParametersResponseModel *videoUploadParameters;
@property (nonatomic, strong) AWEPhotoUploadParametersResponseModel *photoUploadParameters;
@property (nonatomic, strong) AWEFrameUploadParametersResponseModel *frameUploadParameters;
@property (nonatomic, strong) ACCSettingsConfigItem *settingsParameters;
@property (nonatomic, strong) AWEPublishActivityParametersResponseModel *activityParameters;
// 主发布器中视频1期增加mediumVideoPlanUserStatus，二期增加videoSyncParameters
@property (nonatomic, assign) AWEMediumVideoPlanUserStatus mediumVideoPlanUserStatus;
@property (nonatomic, strong) AWEPublishVideoSyncParametersResponseModel * _Nullable videoSyncParameters;

@end
