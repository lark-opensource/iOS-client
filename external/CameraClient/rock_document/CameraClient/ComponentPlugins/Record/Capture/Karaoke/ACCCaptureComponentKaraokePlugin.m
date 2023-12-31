//
//  CaptureComponentKaraokePlugin.m
//  CameraClient-Pods-CameraClient
//
//  Created by xiafeiyu on 2021/05/01.
//

#import "ACCCaptureComponentKaraokePlugin.h"
#import "ACCCaptureComponent.h"

#import <CameraClient/AWERepoContextModel.h>
#import <CameraClient/AWERepoDraftModel.h>
#import <CameraClient/ACCRepoAudioModeModel.h>
#import <CreationKitArch/ACCRecordSwitchModeService.h>
#import <CreativeKit/ACCMacros.h>
#import "ACCKaraokeService.h"

@interface ACCCaptureComponentKaraokePlugin () <ACCKaraokeServiceSubscriber>

@property (nonatomic, strong, readonly) ACCCaptureComponent *hostComponent;

@property (nonatomic, weak) id<ACCKaraokeService> karaokeService;
@property (nonatomic, strong, nullable) BOOL(^willAppearPredicate)(id _Nullable input, id *_Nullable output);
@property (nonatomic, strong, nullable) BOOL(^authorizedPredicate)(id _Nullable input, id *_Nullable output);
@property (nonatomic, strong, nullable) BOOL(^samplingPredicate)(id _Nullable input, id *_Nullable output);

@end

@implementation ACCCaptureComponentKaraokePlugin

@synthesize component = _component;

#pragma mark - ACCFeatureComponentPlugin

+ (id)hostIdentifier
{
    return [ACCCaptureComponent class];
}

- (void)bindServices:(id<IESServiceProvider>)serviceProvider
{
    __weak id<ACCRecordSwitchModeService> switchModeService = IESAutoInline(serviceProvider, ACCRecordSwitchModeService);
    self.karaokeService = IESAutoInline(serviceProvider, ACCKaraokeService);
    [self.karaokeService addSubscriber:self];
    @weakify(self);
    BOOL(^predicate)(id _Nullable, __autoreleasing id * _Nullable) = ^BOOL(id  _Nullable input, __autoreleasing id * _Nullable output) {
        @strongify(self);
        /**
         * 1. 在K歌拍摄页让 AWEKaraokeComponent 自己管理音视频采集 音频模式下也不需要这里管理
         * 2. 在K歌选择页，无需音视频采集
         * 3. 特殊逻辑：
         *      - 草稿/backup 恢复，captureComponent didMount 时，karaokeService.inKaraokeRecordPage 还是 false，需要单独处理
         *      - 从外部直接带音乐K歌，captureComponent didMount 时 karaokeService.inKaraokeRecordPage 还是 false，需要单独处理
         */
        if (self.karaokeService.inKaraokeRecordPage) {
            return NO;
        }
        ACCRecordModeIdentifier modeID = switchModeService.currentRecordMode.modeId;
        BOOL inSelectMusicPage = modeID == ACCRecordModeKaraoke;
        BOOL inAudioRecordMode = modeID == ACCRecordModeAudio;
        if (inSelectMusicPage || inAudioRecordMode) {
            return NO;
        }
        AWERepoDraftModel *draftModel = self.hostComponent.repository.repoDraft;
        AWERepoContextModel *contextModel = self.hostComponent.repository.repoContext;
        if ((draftModel.isBackUp || draftModel.isDraft) && contextModel.videoType == AWEVideoTypeKaraoke) {
            return NO;
        }
        id<ACCRepoKaraokeModelProtocol> repoKaraoke = [self.hostComponent.repository extensionModelOfProtocol:@protocol(ACCRepoKaraokeModelProtocol)];
        return !repoKaraoke.enterWithMusic;
    };
    [self.hostComponent.startVideoCaptureOnWillAppearPredicate addPredicate:predicate with:self];
    [self.hostComponent.startAudioCaptureOnWillAppearPredicate addPredicate:predicate with:self];
    [self.hostComponent.startVideoCaptureOnAuthorizedPredicate addPredicate:predicate with:self];
    [self.hostComponent.startAudioCaptureOnAuthorizedPredicate addPredicate:predicate with:self];

    [self.hostComponent.shouldStartSamplingPredicate addPredicate:^BOOL(id  _Nullable input, __autoreleasing id * _Nullable output) {
        @strongify(self);
        if (self.hostComponent.repository.repoAudioMode.isAudioMode) {
            return NO;
        }
        if (!self.karaokeService.inKaraokeRecordPage) {
            return YES;
        }
        // 音频模式或倒计时的时候，不抽帧。
        return !self.karaokeService.isCountingDown && !(self.karaokeService.recordMode == ACCKaraokeRecordModeAudio);
    } with:self];
}


- (void)karaokeService:(id<ACCKaraokeService>)service isCountingDownDidChangeFrom:(BOOL)prevState to:(BOOL)state
{
    if (prevState && !state) {
        // 倒计时结束，触发抽帧；注意必须判断 prevState == YES，不然不一定是倒计时结束。
        [self.hostComponent startSamplingIfNeeded];
    }
}

#pragma mark - Properties

- (ACCCaptureComponent *)hostComponent
{
    return self.component;
}

@end
