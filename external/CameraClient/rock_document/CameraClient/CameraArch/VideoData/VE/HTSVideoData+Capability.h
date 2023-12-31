//
//  HTSVideoData+Capability.h
//  CameraClient-Pods-Aweme
//
//  Created by raomengyun on 2021/4/27.
//

#import <TTVideoEditor/HTSVideoData+Reshoot.h>
#import <TTVideoEditor/HTSVideoData+MD5.h>
#import <TTVideoEditor/HTSVideoData+CacheDirPath.h>
#import <TTVideoEditor/HTSVideoData+InfoSticker.h>
#import "HTSVideoData+AWEAIVideoClipInfo.h"
#import "HTSVideoData+AWEMute.h"
#import "HTSVideoData+AWEAddtions.h"
#import "HTSVideoData+AudioTrack.h"

NS_ASSUME_NONNULL_BEGIN

@interface HTSVideoData (Capability)

#pragma mark - effectOperationManager 封装

- (void)acc_addVideoAssetDict:(AVAsset *)asset
                fromVideoData:(ACCEditVideoData *)videoData;

- (void)acc_addAudioAssetDict:(AVAsset *)asset
                fromVideoData:(ACCEditVideoData *)videoData;

- (void)acc_replaceVideoAssetAtIndex:(NSInteger)index
                           withAsset:(AVAsset *)asset
                       fromVideoData:(ACCEditVideoData *)videoData;

- (void)acc_replaceVideoAssetsInRange:(NSRange)range
                           withAssets:(NSArray<AVAsset *> *)assets
                        fromVideoData:(ACCEditVideoData *)videoData;

#pragma mark - effectOperationManager 封装

@property (nonatomic, assign) HTSPlayerTimeMachineType effect_timeMachineType;
@property (nonatomic, strong, nullable) AVAsset *effect_reverseAsset;
@property (nonatomic, copy, readonly, nullable) NSArray<IESMMEffectTimeRange *> *effect_timeRange;
@property (nonatomic, copy, nullable) NSArray<IESMMEffectTimeRange *> * effect_operationTimeRange;
@property (nonatomic, assign) CGFloat effect_timeMachineBeginTime;
@property (nonatomic, assign) CGFloat effect_newTimeMachineDuration; //新的时间特效新增，可以更改时间特效作用时长
@property (nonatomic, assign, readonly) CGFloat effect_videoDuration;
@property (nonatomic, copy, readonly, nullable) NSDictionary *effect_dictionary;

- (void)effect_cleanOperation;
- (void)effect_reCalculateEffectiveTimeRange;
- (CGFloat)effect_currentTimeMachineDurationWithType:(HTSPlayerTimeMachineType)timeMachineType;

@end

NS_ASSUME_NONNULL_END
