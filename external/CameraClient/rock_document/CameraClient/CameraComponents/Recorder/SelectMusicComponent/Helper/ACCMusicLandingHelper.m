//
//  ACCMusicLandingHelper.m
//  CameraClient-Pods-Aweme
//
//  Created by liujinze on 2021/4/25.
//

#import "ACCMusicLandingHelper.h"
#import "ACCConfigKeyDefines.h"

@implementation ACCMusicLandingHelper

+ (BOOL)useMusicShootLandingWithMusicDuration:(CGFloat)musicDuration videoDuration:(CGFloat)videoDuration
{
    if (ACCConfigEnum(kConfigInt_music_shoot_landing_submode_type, ACCMusicShootLandingType) == ACCMusicShootLandingTypeDefault) {
        return NO;
    }

    if (ACCConfigEnum(kConfigInt_music_shoot_landing_submode_type, ACCMusicShootLandingType) == ACCMusicShootLandingTypeMusicRecordableTime){
        if (musicDuration > 15) {
            return YES;
        } else {
            return NO;
        }
    } else {
        if (musicDuration > 15 && videoDuration > 15) {
            return YES;
        } else if (musicDuration > 15 && videoDuration == 0){
            return YES;
        } else {
            return NO;
        }
    }
/*
 未命中实验组、草稿恢复路径、不执行优化
 实验组一 可拍音乐时长存在且大于15s进行优化
 实验组二三 有视频时长 且 有可拍音乐时长，二者最小值大于15s进行优化  无视频时长 但有可拍音乐时长 可拍音乐时长大于15s
 */
}

+ (NSInteger)defaultIndexOfCombinedMode:(CGFloat)musicDuration videoDuration:(CGFloat)videoDuration
{
    if ([self useMusicShootLandingWithMusicDuration:musicDuration videoDuration:videoDuration]) {
        //这里保证了两个数都大于15秒
        CGFloat varTimeDuration = 0.0;
        if (ACCConfigEnum(kConfigInt_music_shoot_landing_submode_type, ACCMusicShootLandingType) == ACCMusicShootLandingTypeMusicRecordableTime) {
            varTimeDuration = musicDuration;
        } else {
            if (videoDuration == 0) {
                varTimeDuration = musicDuration;
            } else {
                varTimeDuration = MIN(musicDuration, videoDuration);
            }
        }
        if (varTimeDuration > 60.0) {
            return 0;//(60,) landing至3min
        } else {
            return 1;//(15,60] landing至60s
        }
    }
    return 2;
}

+ (CGFloat)recordModeDuration:(CGFloat)musicDuration videoDuration:(CGFloat)videoDuration
{
    NSInteger index = [self defaultIndexOfCombinedMode:musicDuration videoDuration:videoDuration];
    if (index == 0) {
        return 180;
    } else if (index == 1){
        return 60;
    } else {
        return 15;
    }
}

@end
