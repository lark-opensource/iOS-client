//
//  VEEditorSession+ACCAudioEffect.h
//  CameraClient
//
//  Created by haoyipeng on 2020/8/18.
//

#import <TTVideoEditor/VEEditorSession.h>

NS_ASSUME_NONNULL_BEGIN

@interface VEEditorSession (ACCAudioEffect)

@property (nonatomic, strong, nullable) AVAsset *acc_bgmAsset; // 背景音乐assets，用于音量设定

@property (nonatomic, assign) BOOL acc_isEffectPreprocessing;//变声音效运用是同步的

@property (nonatomic, assign) BOOL acc_hadRecoveredVoiceEffect;//播放器恢复了变声音效-拍摄、编辑的播放器可能不是同一个

- (void)acc_applyAudioEffectWithVideoData:(HTSVideoData *)videoData
                          audioEffectInfo:(IESMMEffectStickerInfo *)info
                         inPreProcessInfo:(nullable NSString *)infoData
                                  inBlock:(void (^)(NSString *str, NSError *outErr))block;


- (float)acc_bgmVolume;
- (void)acc_setVolumeForVideo:(float)volume videoData:(HTSVideoData *)videoData;
- (void)acc_setVolumeForVideoSubTrack:(float)volume videoData:(HTSVideoData *)videoData;
- (void)acc_setVolumeForAudio:(float)volume videoData:(HTSVideoData *)videoData;

@end

NS_ASSUME_NONNULL_END
