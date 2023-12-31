//
//  ACCVideoDataProtocol.h
//  CameraClient-Pods-Aweme
//
//  Created by yangying on 2021/6/11.
//

#ifndef ACCVideoDataProtocol_h
#define ACCVideoDataProtocol_h

#import <TTVideoEditor/IESMMBaseDefine.h>
#import <CoreMedia/CMTime.h>

@class IESMMEffectTimeRange, IESMMTranscoderParam;

@protocol ACCVideoDataProtocol <NSObject>

- (nonnull NSArray<AVAsset *> *)videoAssets;

- (BOOL)hasRecordAudio;

- (void)resetVideoTimeClipInfo;

- (HTSPlayerTimeMachineType)effect_timeMachineType;

- (NSArray<IESMMEffectTimeRange *> *)effect_timeRange;

- (NSArray<IESInfoSticker *> *)infoStickers;

- (nonnull NSDictionary<AVAsset *, NSURL *> *) photoAssetsInfo;

- (nonnull IESMMTranscoderParam *) transParam;

- (CGFloat)totalVideoDuration;

- (CMTime)getVideoDuration:(AVAsset *_Nonnull)asset;

- (nonnull NSArray<AVAsset *> *)audioAssets;

- (void)removeAudioWithAssets:(NSArray<AVAsset *> *)asset;

- (void)removeAudioTimeClipInfoWithAsset:(AVAsset *)asset;

- (CGFloat)effect_timeMachineBeginTime;

- (NSDictionary *)effect_dictionary;
@end

#endif /* ACCVideoDataProtocol_h */
