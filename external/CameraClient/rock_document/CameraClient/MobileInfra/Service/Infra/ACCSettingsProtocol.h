//
//  ACCSettingsProtocol.h
//  Pods
//
//  Created by chengfei xiao on 2019/7/26.
//

#import <Foundation/Foundation.h>
#import <CreativeKit/ACCServiceLocator.h>

NS_ASSUME_NONNULL_BEGIN

// react麦克风状态
typedef NS_ENUM(NSInteger, ACCReactMicStatus) {
    ACCReactMicOn     = 1,    // 开启
    ACCReactMicOff    = 2,    // 关闭
    ACCReactMicForbid = 3     // 禁用
};

@protocol ACCSettingsProtocol <NSObject>

#pragma mark - int value

- (int64_t)httpRetryCount;

- (int64_t)infoStickerMaxCount;

- (int64_t)textStickerMaxCount;

- (int64_t)localVideoCacheMaxAge;

- (int64_t)localVideoCacheMaxLength;

- (ACCReactMicStatus)reactMicStatus;

- (int64_t)maxFansCount;

- (int64_t)autoEffectCacheCleanThreshold;

- (int64_t)targetEffectCacheCleanThreshold;

- (int64_t)directShootReuseMusicDuration;

- (int64_t)directShootReuseMusicUseCout;

- (int64_t)duoshanToastFrequency;

- (int64_t)publishTagRecommendTimeout;

#pragma mark - float value

- (Float64)httpRetryInterval;

- (Float64)identificationAsMaleThreshold;

- (Float64)storyPictureDuration;

#pragma mark - bool value

- (BOOL)uploadOriginanlAudioTrack;

- (BOOL)closeUploadOriginanlFrames;

- (BOOL)useTTEffectPlatformSDK;

- (BOOL)useTTNetForTTFileUploadClient;

- (BOOL)enableLargeMattingDetectModel;

- (BOOL)enableLargeHandDetectModel;

- (BOOL)enableWatermarkBackground;

- (BOOL)enableHQVFrame;

- (BOOL)showTitleInVideoCamera;

- (BOOL)forbidLocalWatermark;

- (BOOL)forbidVoiceChangeButtonOnEditPage;

- (BOOL)enable1080PPhotoToVideo;

- (BOOL)enable1080PCutSameVideo;

- (BOOL)enable1080PMomentsVideo;

- (BOOL)enableMV1080P;

- (BOOL)use1080PdefaultValue;

- (BOOL)enableAudioStreamPlay;

- (BOOL)enableNewStylePublishLiveRecord;

- (BOOL)enableStudioSpecialPlusButton;

- (BOOL)enableTagSearchOversea;

#pragma mark - array value

- (NSArray *)videoRecordSize;

- (NSArray *)videoRecordBitrate;

- (NSArray *)videoUploadSize;

- (NSArray *)videoUploadBitrate;

- (NSArray *)aiRecommendMusicListDefaultURLLists;

- (NSArray *)effectColors;

- (NSArray *)textModeBackgrounds;

#pragma mark - string value
- (NSString *)aiRecommendMusicListDefaultURI;

- (NSString *)captureAuthorizationHelpURL;

- (NSString *)effectJsonConfig;

- (NSString *)publishVideoDefaultDescription;

- (NSArray *)superEntranceEffectIDArray;

- (NSString *)superEntranceEffectApplyedBubbleString;

- (NSString *)javisChannel;

- (NSString *)requestDomain;

- (NSString *)storyRecordModeText;

- (NSString *)quickPublishText; // 编辑页底部双按钮时的“发布日常”

- (NSString *)editPublishOneButtonText; // 编辑页底部单按钮时的”发布日常“

- (NSString *)publishStoryTTLActionText;

- (NSString *)disableEditNextToast;

- (NSString *)MV1080pBitrate;

- (NSString *)MV720pBitrate;

- (NSString *)photoToVideo1080pBitrate;

- (NSString *)photoToVideo720pBitrate;

- (NSString *)staticCanvasPhotoBitrate;

- (NSString *)dynamicCanvasPhotoBitrate;

- (NSString *)textRecordTabName;

- (NSString *)cutSame720pBitrate;

- (NSString *)cutSame1080pBitrate;

- (NSString *)moments720pBitrate;

- (NSString *)moments1080pBitrate;

#pragma mark - activity

- (NSDictionary *)grootRecognitionPlaceholderUrl;

- (NSString *)mvDecoratorResource; /// <   影集说明图片（彩带）

- (NSArray *)activityStickerIDArray;

- (NSArray *)activityMVids; /// < mv影集ids

// moments
- (NSDictionary *)momentsInfo;

- (NSDictionary *)textReadConfigs;

- (BOOL)enableNewCapturePhotoAutoSaveWatermarkImage;
- (BOOL)enableMomentsScanMutilThread;

- (NSUInteger)lightningFilterIdentifier;

- (NSString *)lightningFilterBubbleTitle;

- (NSDictionary *)builtinEffectCovers;

- (NSString *)feConfigCollectionMusicFaqSchema;

- (BOOL)shouldShowMusicFeedbackEntrance;

- (NSDictionary *)poiDefaultStyleInfo;

// smart MV
- (NSArray *)smartMVLoadingAssets;

#pragma mark - draft
- (NSDictionary *)draftsFeedbackConfig;

- (BOOL)enableEditNLEDraft;

#pragma mark - Music
- (int64_t)recommendedMusicVideosMode;

- (BOOL)needReportSourceInfo;

- (NSArray *)cacheCleanExclusionList;

- (NSDictionary *)modernStickerPannelConfigs;

#pragma mark - Album Image
- (int64_t)albumImageMaxStickerCount;

@end

FOUNDATION_STATIC_INLINE id<ACCSettingsProtocol> ACCSetting() {
    return [ACCBaseServiceProvider() resolveObject:@protocol(ACCSettingsProtocol)];
}

NS_ASSUME_NONNULL_END
