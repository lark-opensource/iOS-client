//
//  MODSettingsImpl.m
//  Modeo
//
//  Created by liyingpeng on 2020/12/29.
//

#import "MODSettingsImpl.h"

@implementation MODSettingsImpl

#pragma mark - int value

- (int64_t)httpRetryCount
{
    return -1;
}

- (int64_t)infoStickerMaxCount
{
    return 30;
}

- (int64_t)textStickerMaxCount
{
    return 30;
}

- (int64_t)localVideoCacheMaxAge
{
    return 60 * 24 * 3;
}

- (int64_t)localVideoCacheMaxLength
{
    return 150;
}

- (ACCReactMicStatus)reactMicStatus
{
    return ACCReactMicOn;
}

- (int64_t)maxFansCount
{
    return 100000;
}

- (int64_t)stickerLockDuration
{
    return 5;
}

- (BOOL)enableAudioStreamPlay
{
    return NO;
}

- (int64_t)autoEffectCacheCleanThreshold
{
    return 360;
}

- (int64_t)targetEffectCacheCleanThreshold
{
    return 180;
}

- (int64_t)exposedPropCount
{
    return 20;
}

- (int64_t)exposedPropBubbleCount
{
    return 20;
}

- (int64_t)directShootReuseMusicDuration
{
    return 15;
}

- (int64_t)directShootReuseMusicUseCout
{
    return 50;
}

- (int64_t)duoshanToastFrequency
{
    return 0;
}

- (int64_t)publishTagRecommendTimeout
{
    return 1;
}

- (int64_t)userPublishActiveness
{
    return 3;
}

#pragma mark -  float value

- (Float64)identificationAsMaleThreshold
{
    return 0.8;
}

- (Float64)videoCommit
{
    return 0;
}

- (Float64)videoCompose
{
    return 0;
}

- (Float64)httpRetryInterval
{
    return -1.f;
}

- (Float64)storyPictureDuration
{
    return 5.0;
}

#pragma mark - bool value

- (BOOL)uploadOriginanlAudioTrack
{
    return NO;
}

- (BOOL)closeUploadOriginanlFrames
{
    return NO;
}

- (BOOL)useTTEffectPlatformSDK
{
    return YES;
}

- (BOOL)useTTNetForTTFileUploadClient
{
    return YES;
}

- (BOOL)enableLargeMattingDetectModel
{
    return NO;
}

- (BOOL)enableLargeHandDetectModel
{
    return NO;
}

- (BOOL)enableWatermarkBackground
{
    return NO;
}

- (BOOL)enableHQVFrame
{
    return NO;
}

- (BOOL)enableBeautifyEffectsFromPlatform
{
    return NO;
}

- (BOOL)showTitleInVideoCamera
{
    return YES;
}

- (BOOL)forbidLocalWatermark
{
    return NO;
}

- (BOOL)forbidVoiceChangeButtonOnEditPage
{
    return NO;
}

- (BOOL)enableMojiUpdateResources {
    return YES;
}

- (BOOL)enable1080PPhotoToVideo
{
    return NO;
}

- (BOOL)enable1080PCutSameVideo
{
    return NO;
}

- (BOOL)enable1080PMomentsVideo
{
    return NO;
}

- (BOOL)enableMV1080P
{
    return NO;
}

- (BOOL)showXSEntrance
{
    return NO;
}

- (BOOL)cancelShowPhotoToVideoBubbleToast
{
    return NO;
}

- (BOOL)use1080PdefaultValue {
    return NO;
}

- (BOOL)enableNewStylePublishLiveRecord
{
    return NO;
}

- (BOOL)shouleShieldiPhoneSEInmulti
{
    return NO;
}

- (BOOL)enableStudioSpecialPlusButton
{
    return YES;
}

#pragma mark - array value

- (NSArray *)effectColors
{
    return @[@"#F33636", @"#9CCB65", @"#29B5F6", @"#F36836", @"#67BB6B", @"#426DF4", @"#F38F36", @"#2DC184", @"#554BBC",@"#F9A725", @"#25A69A", @"#6330E4",@"#FFCA27", @"#26C6DA", @"#7F57C2", @"#FFEE58", @"#E92747", @"#AB47BC", @"#D4E157", @"#EC3F7A"];
}

- (NSArray *)stickerFonts
{
    return nil;
}

- (NSArray *)videoRecordSize
{
    // muse 没有下发
    return nil;
}

- (NSArray *)videoRecordBitrate
{
    // muse 没有下发
    return nil;
}

- (NSArray *)videoUploadSize
{
    // muse 没有下发
    return nil;
}

- (NSArray *)videoUploadBitrate
{
    // muse 没有下发
    return nil;
}

- (NSArray *)aiRecommendMusicListDefaultURLLists
{
    return nil;
}

#pragma mark - string value

- (NSString *)goodsOrderShareIntroH5URL
{
    return nil;
}

- (NSString *)aiRecommendMusicListDefaultURI
{
    return nil;
}

- (NSString *)freeFlowCardStickerUrl
{
    return nil;
}

- (NSString *)javisChannel
{
    return @"94349537798";
}

- (NSString *)requestDomain
{
    return @"";
}

- (NSString *)captureAuthorizationHelpURL
{
    return @"";
}

- (NSString *)effectJsonConfig {
    return @"";
}

- (NSString *)recordModeStatusTabKey {
    return @"creation_shoot_tab_text";
}

- (NSString *)statusLottieUrl
{
    return nil;
}

- (NSString *)publishVideoDefaultDescription
{
    return @"";
}

- (NSArray *)superEntranceEffectIDArray
{
    return nil;
}

- (NSString *)superEntranceEffectApplyedBubbleString
{
    return nil;
}

#pragma mark - Dictionary
- (NSDictionary *)huoshanAppIcon
{
    return nil;
}

#pragma mark - activity

- (int64_t)tabToastDuration {
    return 5;
}

- (NSString *)bonusText {
    return @"";
}

- (NSString *)bonusButtonTitle {
    return @"";
}

- (NSString *)mvDecoratorResource {
    return @"";
}

- (NSArray *)activityStickerIDArray {
    return @[];
}

- (NSArray *)activityMVids {
    return @[];
}

- (NSArray *)bonusStickers {
    return @[];
}

- (NSDictionary *)bonusShootDic {
    return nil;
}

- (NSString *)storyRecordModeText
{
    return nil;
}

- (NSString *)quickPublishText
{
    return @"发日常";
}

- (NSString *)editPublishOneButtonText
{
    return @"发日常 · 1天可见";
}

- (NSString *)publishStoryTTLActionText
{
    return @"creation_edit_post_diary";
}

- (NSString *)disableEditNextToast
{
    return @"story_disable_edit_next";
}

- (NSString *)MV1080pBitrate
{
    return @"1080p_mv_ve_synthesis_settings";
}

- (NSString *)MV720pBitrate
{
    return @"720p_mv_ve_synthesis_settings";
}

- (NSString *)lightningDiaryTitle
{
    return @"creation_edit_post_diary";
}

- (NSString *)lightningDiarySubtitle
{
    return @"lightning_checkbox_subtitle_normal";
}

- (NSString *)lightningDiaryPublishButton
{
    return @"creation_edit_post_diary";
}

- (NSString *)photoToVideo1080pBitrate
{
    return @"1080p_photos_ve_synthesis_settings";
}

- (NSString *)photoToVideo720pBitrate
{
    return @"720p_photos_ve_synthesis_settings";
}

- (NSString *)huoshanAppName
{
    return @"火山小视频";
}

- (NSString *)cutSame720pBitrate
{
    return @"720p_cut_same_ve_synthesis_settings";
}

- (NSString *)cutSame1080pBitrate
{
    return @"1080p_cut_same_ve_synthesis_settings";
}

- (NSString *)moments720pBitrate
{
    return @"720p_moments_ve_synthesis_settings";
}

- (NSString *)moments1080pBitrate
{
    return @"1080p_moments_ve_synthesis_settings";
}

// moments
- (NSDictionary *)momentsInfo
{
    return nil;
}

- (NSDictionary *)textReadConfigs
{
    return nil;
}

- (BOOL)enableMomentsScanMutilThread
{
    return YES;
}

- (BOOL)enableNewCapturePhotoAutoSaveWatermarkImage
{
    return YES;
}

- (NSUInteger)lightningFilterIdentifier
{
    return 0;
}

- (NSString *)lightningFilterBubbleTitle
{
    return @"";
}

- (NSDictionary *)builtinEffectCovers
{
    return nil;
}

- (NSString *)feConfigCollectionMusicFaqSchema
{
    return nil;
}

- (BOOL)shouldShowMusicFeedbackEntrance
{
    return NO;
}

- (NSDictionary *)poiDefaultStyleInfo
{
    return nil;
}

- (int64_t)recommendedMusicVideosMode {
    
    return 0;
}

- (BOOL)needReportSourceInfo
{
    return YES;
}

- (NSArray *)cacheCleanExclusionList
{
    return @[@"com.apple.dyld"];
}
@end
