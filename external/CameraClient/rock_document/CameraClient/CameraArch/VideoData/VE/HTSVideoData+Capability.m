//
//  HTSVideoData+Capability.m
//  CameraClient-Pods-Aweme
//
//  Created by raomengyun on 2021/4/27.
//

#import "HTSVideoData+Capability.h"
#import "ACCEditVideoDataDowngrading.h"

@implementation HTSVideoData (Capability)

#pragma mark - effectOperationManager 封装

- (void)acc_addVideoAssetDict:(AVAsset *)asset
                fromVideoData:(ACCEditVideoData *)videoData
{
    acc_videodata_downgrading(videoData, ^(HTSVideoData *videoData) {
        [self addVideoAssetDict:asset fromVideoData:videoData];
    }, ^(ACCNLEEditVideoData *videoData) {
        NSAssert(NO, @"不存在这个路径");
    });
}

- (void)acc_addAudioAssetDict:(AVAsset *)asset
                fromVideoData:(ACCEditVideoData *)videoData
{
    acc_videodata_downgrading(videoData, ^(HTSVideoData *videoData) {
        [self addAudioAssetDict:asset fromVideoData:videoData];
    }, ^(ACCNLEEditVideoData *videoData) {
        NSAssert(NO, @"不存在这个路径");
    });
}

- (void)acc_replaceVideoAssetAtIndex:(NSInteger)index
                           withAsset:(AVAsset *)asset
                       fromVideoData:(ACCEditVideoData *)videoData
{
    acc_videodata_downgrading(videoData, ^(HTSVideoData *videoData) {
        [self replaceVideoAssetAtIndex:index withAsset:asset fromVideoData:videoData];
    }, ^(ACCNLEEditVideoData *videoData) {
        NSAssert(NO, @"不存在这个路径");
    });
}

- (void)acc_replaceVideoAssetsInRange:(NSRange)range
                           withAssets:(NSArray<AVAsset *> *)assets
                        fromVideoData:(ACCEditVideoData *)videoData
{
    acc_videodata_downgrading(videoData, ^(HTSVideoData *videoData) {
        [self replaceVideoAssetsInRange:range withAssets:assets fromVideoData:videoData];
    }, ^(ACCNLEEditVideoData *videoData) {
        NSAssert(NO, @"不存在这个路径");
    });
}

#pragma mark - effectOperationManager 封装

- (HTSPlayerTimeMachineType)effect_timeMachineType
{
    return self.effectOperationManager.currTimeMachineType;
}

- (void)setEffect_timeMachineType:(HTSPlayerTimeMachineType)effect_timeMachineType
{
    self.effectOperationManager.currTimeMachineType = effect_timeMachineType;
}

- (AVAsset *)effect_reverseAsset
{
    return self.timeMachine.reverseAsset;
}

- (void)setEffect_reverseAsset:(AVAsset *)effect_reverseAsset
{
    self.timeMachine.reverseAsset = effect_reverseAsset;
}

- (NSArray<IESMMEffectTimeRange *> *)effect_timeRange
{
    return [self.effectOperationManager.effectiveTimeRange copy];
}

- (NSArray<IESMMEffectTimeRange *> *)effect_operationTimeRange
{
    return [self.effectOperationManager.operationTimeRange copy];
}

- (void)setEffect_operationTimeRange:(NSArray<IESMMEffectTimeRange *> *)effect_operationTimeRange
{
    self.effectOperationManager.operationTimeRange = [effect_operationTimeRange mutableCopy];
}

- (CGFloat)effect_timeMachineBeginTime
{
    return [self.effectOperationManager timeMachineBeginTime];
}

- (void)setEffect_timeMachineBeginTime:(CGFloat)effect_timeMachineBeginTime
{
    self.effectOperationManager.timeMachineBeginTime = effect_timeMachineBeginTime;
}

- (CGFloat)effect_newTimeMachineDuration
{
    return [self.effectOperationManager newTimeMachineDuration];
}

- (void)setEffect_newTimeMachineDuration:(CGFloat)effect_newTimeMachineDuration
{
    self.effectOperationManager.newTimeMachineDuration = effect_newTimeMachineDuration;
}

- (CGFloat)effect_videoDuration
{
    return [self.effectOperationManager videoDuration];
}

- (NSDictionary *)effect_dictionary
{
    return [self.effectOperationManager getDictionary];
}

- (void)effect_cleanOperation
{
    [self.effectOperationManager cleanOperation];
}

- (void)effect_reCalculateEffectiveTimeRange
{
    [self.effectOperationManager reCalculateEffectiveTimeRange];
}

- (CGFloat)effect_currentTimeMachineDurationWithType:(HTSPlayerTimeMachineType)timeMachineType
{
    return [self.timeMachine currentTimeMachineDurationWithType:timeMachineType];
}

@end
