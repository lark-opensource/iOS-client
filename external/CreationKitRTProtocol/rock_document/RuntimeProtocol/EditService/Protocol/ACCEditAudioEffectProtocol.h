//
//  ACCEditAudioEffectProtocol.h
//  CameraClient
//
//  Created by Me55a on 2020/9/7.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

#import "ACCEditWrapper.h"

NS_ASSUME_NONNULL_BEGIN

@class IESMMEffectStickerInfo, IESMMAudioFilter, AVAsset, IESEffectModel, IESMMTranscodeRes, IESMMAudioDetectionConfig;

@protocol ACCEditAudioEffectProtocol <ACCEditWrapper>

@property (nonatomic, strong, nullable) AVAsset *bgmAsset; // Background music assets for volume setting
@property (nonatomic, assign) BOOL isEffectPreprocessing;// The use of variable sound effect is synchronous
@property (nonatomic, assign) BOOL hadRecoveredVoiceEffect;// The player has restored the sound effect of changing sound - the player you shot and edited may not be the same

// Music Clip
- (void)refreshAudioPlayer;
- (void)setAudioClipRange:(IESMMVideoDataClipRange *_Nonnull)range forAudioAsset:(AVAsset *_Nonnull)asset;
- (void)hotAppendAudioAsset:(AVAsset *_Nonnull)asset withRange:(IESMMVideoDataClipRange *_Nonnull)clipRange;
- (void)hotRemoveAudioAssests:(NSArray<AVAsset *> *_Nonnull)assets;


// Volume
- (float)bgmVolume;
- (void)setVolumeForVideo:(float)volume;
- (void)setVolumeForVideoMainTrack:(float)volume;
- (void)setVolumeForVideoSubTrack:(float)volume;
- (void)setVolumeForCutsameVideo:(float)volume;
- (void)setVolumeForAudio:(float)volume;
- (void)setVolume:(float)volume;

- (void)setVolume:(CGFloat)volume forAudioAssets:(NSArray<AVAsset *> *_Nonnull)assets;
- (void)setVolume:(CGFloat)volume forVideoAssets:(NSArray<AVAsset *> *_Nonnull)assets;
- (void)mute:(BOOL)mute;

- (void)setAudioFilter:(IESMMAudioFilter *_Nullable)filter forAudioAssets:(NSArray<AVAsset *> *_Nonnull)assets;
- (void)setAudioFilter:(IESMMAudioFilter *_Nullable)filter forVideoAssets:(NSArray<AVAsset *> *_Nonnull)assets;

//BGM
- (void)removeBGM;

- (void)setBGM:(NSURL *)newBGMAssetURL
          start:(NSTimeInterval)startTime
       duration:(NSTimeInterval)duration
    repeatCount:(NSInteger)repeatCount
     completion:(void(^)(AVAsset * _Nullable ))completion;

- (void)setBGM:(NSURL *_Nonnull)url
           startTime:(NSTimeInterval)startTime
        clipDuration:(NSTimeInterval)clipDuration
         repeatCount:(NSInteger)repeatCount;

// single segment voice change
- (void)applyAudioEffectWithEffectPath:(nullable NSString *)effectPath
                      inPreProcessInfo:(nullable NSString *)infoData
                               inBlock:(void (^)(NSString *str, NSError *outErr))block;

// multi segment voice change
- (void)startAudioFilterPreview:(IESEffectModel *)filter completion:(void (^)(void))completion;

- (void)stopFiltersPreview;

- (void)updateAudioFilters:(NSArray<IESMMAudioFilter *> *)infos withEffects:(NSArray <IESEffectModel *> *)effects forVideoAssetsWithcompletion:(void (^)(void))completion;

@optional

@property (nonatomic, strong) NSArray<AVAsset *> *dubAssets;

- (void)setVolumeForStichVideo:(float)volume;
- (void)setBGMWithNewAsset:(AVAsset *)newBgmAsset
                  oldAsset:(AVAsset *)oldBgmAsset
                  start:(NSTimeInterval)startTime
               duration:(NSTimeInterval)duration
            repeatCount:(NSInteger)repeatCount;

@end

NS_ASSUME_NONNULL_END
