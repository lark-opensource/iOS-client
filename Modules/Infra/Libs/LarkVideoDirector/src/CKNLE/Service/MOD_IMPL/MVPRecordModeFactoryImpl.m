//
//  MVPRecordModeFactoryImpl.m
//  MVP
//
//  Created by liyingpeng on 2020/12/30.
//

#import <CameraClient/AWERepoStickerModel.h>
#import "MVPRecordModeFactoryImpl.h"

#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/NSArray+ACCAdditions.h>
#import <CreativeKit/ACCLanguageProtocol.h>
#import <CreativeKit/ACCCacheProtocol.h>
#import <CreationKitInfra/NSDictionary+ACCAddition.h>
#import <CreationKitArch/ACCRecordMode.h>
#import <CreationKitInfra/ACCModuleService.h>

#import <CreationKitArch/ACCVideoConfigProtocol.h>
#import <CreationKitArch/ACCUserServiceProtocol.h>

#import <CreationKitArch/ACCRepoDuetModel.h>
#import <CreationKitArch/ACCRepoContextModel.h>
#import <CameraClient/AWERepoDraftModel.h>
#import <CameraClient/AWERecordInformationRepoModel.h>
#import <CreationKitArch/ACCRepoReshootModel.h>
#import <CameraClient/ACCRepoQuickStoryModel.h>
#import <CreationKitArch/ACCRepoStickerModel.h>
#import <CameraClient/AWERepoMusicModel.h>
#import <CreationKitArch/ACCRepoFlowControlModel.h>
#import <CreationKitArch/ACCRepoPropModel.h>
#import <CameraClient/AWERepoTrackModel.h>
#import <CameraClient/ACCConfigKeyDefines.h>
#import <CameraClient/AWEStudioDefines.h>
#import <CameraClientModel/AWEVideoRecordButtonType.h>
#import "LarkVideoDirector/LarkVideoDirector-Swift.h"
#import "MVPBaseServiceContainer.h"

@interface MVPRecordModeFactoryImpl()

@property (nonatomic, copy) NSDictionary <NSValue *,ACCRecordMode *>*modeMapDictionary;

@end

@implementation MVPRecordModeFactoryImpl

#pragma mark - public

- (NSMutableArray <ACCRecordMode *>*)displayModesArray
{
    NSMutableArray *modesArray = [NSMutableArray array];

    // 判断具体相机类型可以在这里添加判断 定制数组
    LVDCameraType cameraType = [MVPBaseServiceContainer sharedContainer].cameraType;

    if (cameraType == LVDCameraTypeSupportPhotoAndVideo ||
        cameraType == LVDCameraTypeOnlySupportPhoto) {
        ACCRecordMode *photoMode = [self modeWithIdentifier:ACCRecordModeTakePicture];
        photoMode.isInitial = YES;
        [modesArray addObject:photoMode];
    }

    if (cameraType == LVDCameraTypeSupportPhotoAndVideo ||
        cameraType == LVDCameraTypeOnlySupportVideo) {
        ACCRecordMode *combinedMode = [self modeWithIdentifier:ACCRecordModeCombined];
        [modesArray addObject:combinedMode];
    }
    return modesArray;
}

- (ACCRecordMode *)modeWithIdentifier:(NSInteger)identifier {
    return [[self modeMapDictionary] acc_objectForKey:@(identifier) ofClass:[ACCRecordMode class]];
}

- (ACCRecordMode *)modeWithLength:(ACCRecordLengthMode)length
{
   ACCRecordMode *mode = [[self modeMapDictionary].allValues acc_match:^BOOL(ACCRecordMode * _Nonnull item) {
        return item.lengthMode == length;
    }];

    return mode;
}

- (ACCRecordMode *)modeWithButtonType:(AWEVideoRecordButtonType)buttonType
{
   ACCRecordMode *mode = [[self modeMapDictionary].allValues acc_match:^BOOL(ACCRecordMode * _Nonnull item) {
        return item.buttonType == buttonType;
    }];

    return mode;
}

- (NSDictionary <NSValue *,ACCRecordMode *>*)modeMapDictionary
{
    if (_modeMapDictionary == nil) {
        _modeMapDictionary = @{
            @(ACCRecordModeTakePicture) : [self pictureMode],
            @(ACCRecordModeLive) : [self liveMode],
            @(ACCRecordModeMV) : [self MVMode],
            @(ACCRecordModeMixHoldTapRecord) : [self mixMode],
            @(ACCRecordModeMixHoldTap15SecondsRecord) : [self mix15SecondsMode],
            @(ACCRecordModeMixHoldTapLongVideoRecord) : [self mixLongVideoMode],
            @(ACCRecordModeStory) : [self storyMode],
            @(ACCRecordModeCombined) : [self combinedMode],
            @(ACCRecordModeMixHoldTap60SecondsRecord) : [self mix60SecondsMode],
            @(ACCRecordModeMixHoldTap3MinutesRecord) : [self mix3MinutesMode],
        };
    }

    return _modeMapDictionary;
}

#pragma mark - mode create

- (ACCRecordMode *)pictureMode
{
    ACCRecordMode *mode = [[ACCRecordMode alloc] init];
    mode.modeId = ACCRecordModeTakePicture;
    mode.isPhoto = YES;
    mode.autoComplete = YES;
    mode.trackIdentifier = @"photo";
    mode.serverMode = ACCServerRecordModePhoto;
    mode.tabConfig = [MVPRecordModeFactoryImpl tabConfigWithTitle:@"record_mode_shot" forMode:mode];
    return mode;
}

- (ACCRecordMode *)liveMode
{
    ACCRecordMode *mode = [[ACCRecordMode alloc] init];
    mode.modeId = ACCRecordModeLive;
    mode.trackIdentifier = @"live";
    mode.tabConfig = [MVPRecordModeFactoryImpl tabConfigWithTitle:ACCLocalizedString(@"com_mig_go_live_7fsgcy", @"开直播") forMode:mode];
    @weakify(self);
    mode.shouldShowBlock = ^BOOL{
        @strongify(self);
        return [self preconditionEnableLive];
    };
    return mode;
}

- (ACCRecordMode *)MVMode
{
    ACCRecordMode *mode = [[ACCRecordMode alloc] init];
    mode.modeId = ACCRecordModeMV;
    mode.trackIdentifier = @"mv";
    mode.tabConfig = [MVPRecordModeFactoryImpl tabConfigWithTitle:@"record_mode_mv" forMode:mode];
    return mode;
}

- (ACCRecordMode *)mixMode
{
    ACCRecordMode *mode = [[ACCRecordMode alloc] init];
    mode.modeId = ACCRecordModeMixHoldTapRecord;
    mode.isVideo = YES;
    mode.isMixHoldTapVideo = YES;
    mode.trackIdentifier = @"video";
    mode.buttonType = AWEVideoRecordButtonTypeMixHoldTap;
    mode.tabConfig = [MVPRecordModeFactoryImpl tabConfigWithTitle:ACCLocalizedString(@"com_mig_shoot_a_video_2rlslg", @"拍视频") forMode:mode];
    return mode;
}

- (ACCRecordMode *)mix15SecondsMode
{
    ACCRecordMode *mode = [[ACCRecordMode alloc] init];
    mode.modeId = ACCRecordModeMixHoldTap15SecondsRecord;
    mode.isVideo = YES;
    mode.isMixHoldTapVideo = YES;
    mode.trackIdentifier = @"video_15";
    mode.serverMode = ACCServerRecordModeCombine15;
    mode.lengthMode = ACCRecordLengthModeStandard;
    mode.buttonType = AWEVideoRecordButtonTypeMixHoldTap15Seconds;

    NSString *tabString = @"record_15_seconds_mode";
    mode.tabConfig = [MVPRecordModeFactoryImpl tabConfigWithTitle:tabString forMode:mode];
    return mode;
}

- (ACCRecordMode *)mixLongVideoMode
{
    ACCRecordMode *mode = [[ACCRecordMode alloc] init];
    mode.modeId = ACCRecordModeMixHoldTapLongVideoRecord;
    mode.isVideo = YES;
    mode.isMixHoldTapVideo = YES;
    mode.trackIdentifier = @"video_60";

    mode.serverMode = ACCServerRecordModeCombine60;
    mode.lengthMode = ACCRecordLengthModeLong;
    mode.buttonType = AWEVideoRecordButtonTypeMixHoldTapLongVideo;
    mode.tabConfig = [MVPRecordModeFactoryImpl tabConfigWithTitle:@"record_60_seconds_mode" forMode:mode];
    return mode;
}

- (ACCRecordMode *)mix60SecondsMode
{
    ACCRecordMode *mode = [[ACCRecordMode alloc] init];
    mode.modeId = ACCRecordModeMixHoldTap60SecondsRecord;
    mode.isVideo = YES;
    mode.isMixHoldTapVideo = YES;
    mode.trackIdentifier = @"video_60";
    mode.serverMode = ACCServerRecordModeCombine60;
    mode.lengthMode = ACCRecordLengthMode60Seconds;
    mode.buttonType = AWEVideoRecordButtonTypeMixHoldTap60Seconds;
    return mode;
}

- (ACCRecordMode *)mix3MinutesMode
{
    ACCRecordMode *mode = [[ACCRecordMode alloc] init];
    mode.modeId = ACCRecordModeMixHoldTap3MinutesRecord;
    mode.isVideo = YES;
    mode.isMixHoldTapVideo = YES;
    mode.trackIdentifier = @"video_180";
    mode.serverMode = ACCServerRecordModeCombine180;
    mode.lengthMode = ACCRecordLengthMode3Minutes;
    mode.buttonType = AWEVideoRecordButtonTypeMixHoldTap3Minutes;
    return mode;
}

- (ACCRecordMode *)storyMode
{
    ACCRecordMode *mode = [[ACCRecordMode alloc] init];
    mode.modeId = ACCRecordModeStory;
    mode.autoComplete = YES;
    mode.isVideo = YES;
    mode.trackIdentifier = @"fast_shoot";
    mode.serverMode = ACCServerRecordModeQuick;
    mode.buttonType = AWEVideoRecordButtonTypeStory;
    if (ACCConfigString(kConfigString_story_record_mode_text)) {
        mode.tabConfig = [MVPRecordModeFactoryImpl tabConfigWithTitle:ACCConfigString(kConfigString_story_record_mode_text) forMode:mode];
    }

    return mode;
}

- (ACCRecordMode *)combinedMode
{
    ACCRecordMode *mode = [[ACCRecordMode alloc] init];
    mode.modeId = ACCRecordModeCombined;
    mode.trackIdentifier = @"video_15";
    mode.isVideo = YES;
    mode.tabConfig = [MVPRecordModeFactoryImpl tabConfigWithTitle:ACCLocalizedString(@"creation_shoot_split", nil) forMode:mode];
    return mode;
}

+ (AWESwitchModeSingleTabConfig *)tabConfigWithTitle:(NSString *)title forMode:(ACCRecordMode *)recordMode
{
    AWESwitchModeSingleTabConfig *config = [[AWESwitchModeSingleTabConfig alloc] init];
    config.title = ACCLocalizedString(title, title);
    config.recordModeId = recordMode.modeId;
    return config;
}

#pragma mark - live tab show / hide

- (BOOL)preconditionEnableLive {
    // 是否能添加底部直播模式的前置条件
    if ([IESAutoInline(ACCBaseServiceProvider(), ACCUserServiceProtocol) isChildMode]) {
        return NO;
    }
    if (![IESAutoInline(ACCBaseServiceProvider(), ACCUserServiceProtocol) isLogin]) return NO;

    if (self.repository.repoDraft.originalDraft || self.repository.repoDraft.isDraft) return NO;

    if (self.repository.repoDraft.isBackUp) return NO;
    // TODO: @reaction
    if (self.repository.repoDuet.isDuet) return NO;
    if ([self.repository.repoTrack.referString isEqualToString:kAWEStudioReuseSticker]) return NO;
    if ([self.repository.repoTrack.referString isEqualToString:kAWEStudioPOI]) return NO;
    if ([self.repository.repoTrack.referString isEqualToString:@"poi_rate"]) return NO;
    if ([self.repository.repoTrack.referString isEqualToString:@"opensdk_capture"]) return NO;
    return YES;
}

@end
