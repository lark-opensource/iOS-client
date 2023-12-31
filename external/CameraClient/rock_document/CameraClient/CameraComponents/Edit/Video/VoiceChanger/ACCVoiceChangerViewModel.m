//
//  ACCVoiceChangerViewModel.m
//  Pods
//
//  Created by haoyipeng on 2020/8/9.
//

#import "ACCVoiceChangerViewModel.h"
#import "ACCConfigKeyDefines.h"

#import <CreationKitArch/ACCRepoDuetModel.h>
#import <CameraClient/AWERepoVideoInfoModel.h>
#import <CreationKitArch/ACCRepoContextModel.h>
#import <CreationKitArch/ACCRepoUploadInfomationModel.h>
#import <CreativeKit/ACCMacros.h>
#import <CameraClientModel/ACCVideoCanvasType.h>

@interface ACCVoiceChangerViewModel ()

@property (nonatomic, assign) BOOL shouldCheckChangeVoiceButtonDisplay;

@property (nonatomic, strong, readwrite) RACSubject *cleanVoiceEffectSubject;

@end

@implementation ACCVoiceChangerViewModel

#pragma mark - lifeCycle

- (void)dealloc
{
    [self.cleanVoiceEffectSubject sendCompleted];
}

#pragma mark - Public

- (void)setNeedCheckChangeVoiceButtonDisplay
{
    self.shouldCheckChangeVoiceButtonDisplay = YES;
}

- (void)forceCleanVoiceEffect
{
    [self.cleanVoiceEffectSubject sendNext:nil];
}

- (void)cleanVoiceEffectIfNeeded
{
    if (self.repository.repoDuet.isDuet && self.repository.repoVideoInfo.videoMuted) {
        [self.cleanVoiceEffectSubject sendNext:nil];
    }
}

- (BOOL)shouldShowEntrance {
    if (self.shouldCheckChangeVoiceButtonDisplay) {//涉及到版权的场景 settings 控制变声入口
        if (ACCConfigBool(kConfigBool_forbid_voice_change_on_edit_page)) {
            return NO;
        }
    }
    
    if (self.repository.repoVideoInfo.canvasType == ACCVideoCanvasTypeRePostVideo ||
        self.repository.repoVideoInfo.canvasType == ACCVideoCanvasTypeShareAsStory) {
        return NO;
    }
    
    //不支持变速
    if (self.repository.repoVideoInfo.video.videoTimeScaleInfo.allValues.count > 0) {
        BOOL timeScaled = NO;
        for (NSNumber *timescale in self.repository.repoVideoInfo.video.videoTimeScaleInfo.allValues) {
            if (!ACC_FLOAT_EQUAL_TO(timescale.floatValue, 1.0)) {
                timeScaled = YES;
                return NO;
            }
        }
    }

    // 无配音，并且并不是每一段视频都存在音轨
    BOOL emptyVideo = ACC_isEmptyArray([self.repository.repoVideoInfo.video videoAssets]);
    if (emptyVideo) {
        return NO;
    }
    
    if (![self.repository.repoVideoInfo.video videoAssetsAllHaveAudioTrack]) {
        return NO;
    }
    
    if (self.repository.repoDuet.isDuet) {
        //new duet that support layout have voice show change button
        return (!self.repository.repoVideoInfo.videoMuted);
    }
    
    if (self.repository.repoDuet.isDuet ||
        self.repository.repoContext.isMVVideo ||
        self.repository.repoContext.videoType == AWEVideoTypePhotoMovie ||
        (self.repository.repoContext.videoType == AWEVideoTypeNormal && self.repository.repoVideoInfo.videoMuted) ||
        ([self.repository.repoUploadInfo isAIVideoClipMode] && !ACCConfigBool(kConfigBool_enable_new_clips))) {
        return NO;
    }

    return YES;
}

#pragma mark - Getter

- (RACSignal *)cleanVoiceEffectSignal
{
    return self.cleanVoiceEffectSubject;
}

- (RACSubject *)cleanVoiceEffectSubject
{
    if (!_cleanVoiceEffectSubject) {
        _cleanVoiceEffectSubject = [RACSubject subject];
    }
    return _cleanVoiceEffectSubject;
}

@end
