//
//  AWERepoVideoInfoModel+VideoData.m
//  CameraClient-Pods-Aweme
//
//  Created by yangying on 2021/6/11.
//

#import "AWERepoVideoInfoModel+VideoData.h"
#import "HTSVideoData+Capability.h"

@implementation AWERepoVideoInfoModel (VideoData)

- (HTSPlayerTimeMachineType)effect_timeMachineType {
    return self.video.effect_timeMachineType;
}

- (NSArray<IESMMEffectTimeRange *> *)effect_timeRange {
    return self.video.effect_timeRange;
}

- (BOOL)hasRecordAudio {
    return [self.video hasRecordAudio];
}

- (NSArray<IESInfoSticker *> *)infoStickers {
    return [self.video infoStickers];
}

- (nonnull NSDictionary<AVAsset *,NSURL *> *)photoAssetsInfo {
    return self.video.photoAssetsInfo;
}

- (void)resetVideoTimeClipInfo {
    self.video.videoTimeClipInfo = @{}.mutableCopy;
}

- (CGFloat)totalVideoDuration {
    return [self.video totalVideoDuration];
}

- (nonnull IESMMTranscoderParam *)transParam {
    return [self.video transParam];
}

- (nonnull NSArray<AVAsset *> *)videoAssets {
    return [self.video videoAssets];
}

- (CMTime)getVideoDuration:(AVAsset *)asset
{
    return [self.video getVideoDuration:asset];
}

- (NSArray<AVAsset *> *)audioAssets
{
    return [self.video audioAssets];
}

- (void)removeAudioTimeClipInfoWithAsset:(AVAsset *)asset
{
    [self.video removeAudioTimeClipInfoWithAsset:asset];
}

- (void)removeAudioWithAssets:(NSArray<AVAsset *> *)asset
{
    [self.video removeAudioWithAssets:asset];
}

- (NSDictionary *)effect_dictionary
{
    return [self.video effect_dictionary];
}

- (CGFloat)effect_timeMachineBeginTime
{
    return [self.video effect_timeMachineBeginTime];
}

@end
