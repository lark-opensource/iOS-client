//
//  ACCAudioAuthUtils.m
//  CameraClient-Pods-Aweme
//
//  Created by Zhihao Zhang on 2020/7/13.
//

#import "ACCAudioAuthUtils.h"
#import <CreationKitArch/AWEVideoPublishViewModel+Repository.h>
#import <CreationKitArch/ACCRepoVideoInfoModel.h>
#import "ACCRepoAudioModeModel.h"

@implementation ACCAudioAuthUtils

+ (BOOL)shouldStartAudio:(id<ACCPublishRepository>)repository
{
    ACCRepoVideoInfoModel *videoInfo = [repository extensionModelOfClass:ACCRepoVideoInfoModel.class];
    if (videoInfo.videoMuted) {
        return NO;
    }
    return YES;
}

+ (BOOL)shouldStopAudioCaptureWhenPause:(id<ACCPublishRepository>)repository
{
    ACCRepoVideoInfoModel *videoInfo = [repository extensionModelOfClass:ACCRepoVideoInfoModel.class];
    ACCRepoAudioModeModel *audioModeModel = [repository extensionModelOfClass:ACCRepoAudioModeModel.class];
    if (videoInfo.videoMuted && audioModeModel.isAudioMode == NO) {
        //录制时就没开启采集 所以不需要暂停时调用stop 如果VE没有兜底 会使得小点短暂出现一下
        return NO;
    }
    if (audioModeModel.isAudioMode == YES){
        //音频模式下 非录制状态下一定是不开启采集的 录制时候再开
        return YES;
    }
    return YES;
}

+ (BOOL)shouldStartAudioCaptureWhenApplyProp:(id<ACCPublishRepository>)repository
{
    ACCRepoVideoInfoModel *videoInfo = [repository extensionModelOfClass:ACCRepoVideoInfoModel.class];
    ACCRepoAudioModeModel *audioModeModel = [repository extensionModelOfClass:ACCRepoAudioModeModel.class];
    if (videoInfo.videoMuted) {
        return NO;
    }
    if (audioModeModel.isAudioMode) {
        return NO;
    }
    return YES;
}



@end
