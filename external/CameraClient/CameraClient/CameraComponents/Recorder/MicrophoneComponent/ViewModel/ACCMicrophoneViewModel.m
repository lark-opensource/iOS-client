//
//  ACCMicrophoneViewModel.m
//  CameraClient-Pods-Aweme
//
//  Created by liujinze on 2021/3/18.
//

#import "ACCMicrophoneViewModel.h"

#import <CreationKitArch/ACCMusicModelProtocol.h>
#import <CreationKitArch/ACCRecordSwitchModeService.h>
#import <CreationKitRTProtocol/ACCCameraService.h>
#import <CreativeKit/ACCTrackProtocol.h>
#import <ReactiveObjC/ReactiveObjC.h>

#import "ACCConfigKeyDefines.h"
#import <CreationKitArch/ACCRepoContextModel.h>
#import <CreationKitArch/ACCRepoTrackModel.h>
#import <CreationKitArch/ACCRepoMusicModel.h>
#import <CreationKitArch/ACCRepoDraftModel.h>
#import <CreationKitArch/ACCRepoContextModel.h>
#import <CreationKitArch/ACCMusicModelProtocol.h>
#import <CreationKitArch/IESEffectModel+ACCSticker.h>

#import <CreativeKit/ACCTrackProtocol.h>
#import "AWERepoVideoInfoModel.h"
#import "AWERepoDuetModel.h"
#import "ACCRecordFlowService.h"
#import "ACCRecordPropService.h"

@interface ACCMicrophoneViewModel () <ACCRecordFlowServiceSubscriber>

@property (nonatomic, assign) BOOL isSupportedMode;

@property (nonatomic, strong) id<ACCCameraService> cameraService;
@property (nonatomic, strong) id<ACCRecordSwitchModeService> switchModeService;
@property (nonatomic, strong) id<ACCRecordFlowService> flowService;
@property (nonatomic, assign, readwrite) ACCMicrophoneBarState currentMicBarState;

@property (nonatomic, strong) RACSubject *micStateSubject;

@end

@implementation ACCMicrophoneViewModel

IESAutoInject(self.serviceProvider, cameraService, ACCCameraService)
IESAutoInject(self.serviceProvider, switchModeService, ACCRecordSwitchModeService)
IESAutoInject(self.serviceProvider, flowService, ACCRecordFlowService)

- (void)dealloc
{
    [_micStateSubject sendCompleted];
}

#pragma mark - public

- (void)setUpSession
{
    self.isSupportedMode = self.switchModeService.currentRecordMode.isVideo;
}

- (void)trackClickMicButton
{
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params[@"content_type"] = @"video";
    params[@"to_status"] = self.repository.repoVideoInfo.videoMuted ? @"off" : @"on";
    params[@"shoot_way"] = self.repository.repoTrack.referString;
    params[@"enter_from"] = @"video_shoot_page";
    params[@"music_id"] = self.repository.repoMusic.music.musicID;
    if (self.repository.repoTrack.referExtra) {
        [params addEntriesFromDictionary:self.repository.repoTrack.referExtra];
    }
    if (self.repository.repoDraft.isDraft) {
        params[@"enter_method"] = @"click_draft";
    }
    if (self.repository.repoContext.recordSourceFrom == AWERecordSourceFromUnknown) {
        [ACCTracker() trackEvent:@"mute_microphone" params:params needStagingFlag:NO];
    }
}

- (void)setSupportedMode:(BOOL)isSupportedMode
{
    self.isSupportedMode = isSupportedMode;
}

#pragma mark - mic state

- (BOOL)shouldShowMicroBar
{
    if (!self.isSupportedMode) {
        return NO;
    }
    id<ACCRecordPropService> propService = IESAutoInline(self.serviceProvider, ACCRecordPropService);
    if ([propService.prop isTypeAudioGraph] && ![propService.prop audioGraphMicSource]) {
        // audio graph 道具未配置 mic 字段时，强制关闭麦克风，且不展示 button
        return NO;
    }
	if (self.repository.repoDuet.isDuetSing) { // 合唱强制开启麦克风，且不显示icon（不允许用户关闭）
        return NO;
    }
    if (self.repository.repoDuet.isDuet) {
        return YES;
    }
    if (self.repository.repoMusic.music != nil) {
        return YES;
    }
    return NO;
}

- (void)updateAcousticAlgorithmConfig
{
    self.repository.repoVideoInfo.microphoneBarState = self.currentMicBarState;
    [self.micStateSubject sendNext:nil];
}

#pragma mark - private

- (ACCMicrophoneBarState)currentMicBarState
{
    ACCMicrophoneBarState microphoneBarState = ACCMicrophoneBarStateHidden;
    if ([self shouldShowMicroBar]) {
        microphoneBarState = self.repository.repoVideoInfo.videoMuted ? ACCMicrophoneBarStateSetOff : ACCMicrophoneBarStateSetOn;
    }
    return microphoneBarState;
}

#pragma mark - Getters

- (RACSubject *)micStateSubject
{
    if (!_micStateSubject) {
        _micStateSubject = [RACSubject subject];
    }
    return _micStateSubject;
}

- (RACSignal *)micStateSignal
{
    return self.micStateSubject;
}

@end
