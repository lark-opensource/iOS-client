//
//  ACCRecordFlowComponentKaraokePlugin.m
//  CameraClient-Pods-CameraClient
//
//  Created by xiafeiyu on 2021/04/16.
//

#import "ACCRecordFlowComponentKaraokePlugin.h"

#import <TTVideoEditor/HTSVideoData.h>
#import <CreationKitInfra/ACCConfigManager.h>
#import <CameraClient/ACCConfigKeyDefines.h>
#import <CreativeKit/ACCMacros.h>

#import "ACCRecordFlowComponent.h"
#import "ACCLightningStyleRecordFlowComponent.h"
#import <CreationKitArch/ACCRecordSwitchModeService.h>
#import "ACCKaraokeService.h"
#import <CameraClient/AWERepoDraftModel.h>
#import <CameraClient/AWERepoContextModel.h>
#import <CreationKitInfra/ACCGroupedPredicate.h>

@interface ACCRecordFlowComponentKaraokePlugin () <ACCKaraokeServiceSubscriber, ACCRecordSwitchModeServiceSubscriber>

@property (nonatomic, strong, readonly) ACCRecordFlowComponent *hostComponent;

@property (nonatomic, weak) id<ACCKaraokeService> karaokeService;
@property (nonatomic, strong) id<ACCRecordFlowService> flowService;
@property (nonatomic, strong) id<ACCRecordSwitchModeService> switchModeService;
@property (nonatomic, strong) BOOL(^predicate)(id  _Nullable input, __autoreleasing id * _Nullable output);

#pragma mark - Saved Data

@property (nonatomic, assign) BOOL savedForbidUserPause;

@end

@implementation ACCRecordFlowComponentKaraokePlugin

@synthesize component = _component;

#pragma mark - ACCFeatureComponentPlugin

+ (id)hostIdentifier
{
    return (ACCConfigBool(kConfigBool_enable_story_tab_in_recorder) && ACCConfigBool(kConfigBool_enable_lightning_style_record_button)) ? ACCLightingStyleRecordFlowComponent.class : ACCRecordFlowComponent.class;
}

- (void)bindServices:(id<IESServiceProvider>)serviceProvider
{
    self.karaokeService = IESAutoInline(serviceProvider, ACCKaraokeService);
    [self.karaokeService addSubscriber:self];
    self.flowService = IESAutoInline(serviceProvider, ACCRecordFlowService);
    self.switchModeService = IESAutoInline(serviceProvider, ACCRecordSwitchModeService);
    [self.switchModeService addSubscriber:self];
    
    AWERepoDraftModel *draftModel = self.hostComponent.repository.repoDraft;
    AWERepoContextModel *contextModel = self.hostComponent.repository.repoContext;
    if ((draftModel.isDraft || draftModel.isBackUp) && contextModel.isKaraokeAudio) {
        // It's expected to set up duration calculator when karaoke service changes its record mode to audio. But in the case of recovering drafts/backups, the nofitying message `karaokeService:inKaraokeRecordPageDidChangeFrom:to:` would be executed later than hostComponent's recovering of video segments and marked times，so we need to set up duration calculator earlier.
        [self setupAudioModeDurationCalculator];
    }
}

- (void)karaokeService:(id<ACCKaraokeService>)service inKaraokeRecordPageDidChangeFrom:(BOOL)prevState to:(BOOL)state
{
    if (state) {
        self.savedForbidUserPause = self.hostComponent.captureButtonAnimationView.forbidUserPause;
        @weakify(self);
        self.predicate = ^BOOL(id  _Nullable input, __autoreleasing id * _Nullable output) {
            @strongify(self);
            if (self.switchModeService.currentRecordMode.modeId != ACCRecordModeKaraoke) {
                return YES;
            }
            return !self.karaokeService.isCountingDown;
        };
        [self.hostComponent.shouldShowCaptureAnimationView addPredicate:self.predicate with:self];
        [self.hostComponent showRecordButtonIfShould:YES animated:NO];
        [self.hostComponent closeVolumnButtonTriggersTheShoot];
    } else {
        self.flowService.totalDurationCalculator = nil;
        self.flowService.segmentDurationEnumerator = nil;
        self.hostComponent.captureButtonAnimationView.forbidUserPause = self.savedForbidUserPause;
        [self.hostComponent.shouldShowCaptureAnimationView removePredicate:self.predicate];
        [self.hostComponent openVolumnButtonTriggersTheShoot];
    }
}

- (void)karaokeService:(id<ACCKaraokeService>)service recordModeDidChangeFrom:(ACCKaraokeRecordMode)prevMode to:(ACCKaraokeRecordMode)mode
{
    if (mode == ACCKaraokeRecordModeAudio) {
        [self setupAudioModeDurationCalculator];
    } else {
        [self resetAudioModeDurationCalculator];
    }
}

- (void)karaokeService:(id<ACCKaraokeService>)service isCountingDownDidChangeFrom:(BOOL)prevState to:(BOOL)state
{
    ACCLog(@"isCountingDown %d", state);
    self.hostComponent.captureButtonAnimationView.forbidUserPause = state;
    [self.hostComponent showRecordButtonIfShould:!state animated:NO];
}

- (void)karaokeService:(id<ACCKaraokeService>)service musicDidChangeFrom:(id<ACCMusicModelProtocol>)prevMusic to:(id<ACCMusicModelProtocol>)music musicSourceDidChangeFrom:(ACCKaraokeMusicSource)prevSource to:(ACCKaraokeMusicSource)source
{
    [self.hostComponent showRecordButtonIfShould:YES animated:NO];
}

- (void)setupAudioModeDurationCalculator
{
    @weakify(self);
    self.flowService.totalDurationCalculator = ^NSTimeInterval(HTSVideoData * video) {
        @strongify(self);
        return MAX(self.flowService.currentDuration, [video totalBGAudioDuration]);
    };
    self.flowService.segmentDurationEnumerator = ^(HTSVideoData * video, void (^enumerateBlock)(CMTime)) {
        [video.bgAudioAssets enumerateObjectsUsingBlock:^(AVAsset *obj, NSUInteger idx, BOOL *stop) {
            IESMMVideoDataClipRange *clipRange = video.audioTimeClipInfo[obj];
            enumerateBlock(CMTimeMakeWithSeconds(clipRange.durationSeconds, 600));
        }];
    };
}

- (void)resetAudioModeDurationCalculator
{
    self.flowService.totalDurationCalculator = nil;
    self.flowService.segmentDurationEnumerator = nil;
}

#pragma mark - Properties

- (ACCRecordFlowComponent *)hostComponent
{
    return self.component;
}

@end
