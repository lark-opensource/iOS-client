//
//  VENativeWrapper+Audio.h
//  NLEPlatform-Pods-Aweme
//
//  Created by bytedance on 2021/2/9.
//

#import "VENativeWrapper.h"

NS_ASSUME_NONNULL_BEGIN

@interface VENativeWrapper (Audio)

/// 音频
/// @param changeInfos std::vector<SlotChangeInfo>
- (void)syncAudios:(std::vector<SlotChangeInfo> &)changeInfos;

- (nullable IESMMAudioEffectConfig *)pitchConfigV2ForSegment:(std::shared_ptr<cut::model::NLEFilter>)filter;

- (void)removeAudioFilterForSlot:(std::shared_ptr<cut::model::NLETrackSlot>)slot type:(IESAudioFilterType)type;

- (IESMMAudioFilter *)p_applySoundFilterForAsset:(AVAsset *)asset
                                            type:(IESAudioFilterType)type
                                          config:(IESMMAudioEffectConfig *)config
                                         isVideo:(BOOL)isVideo;

@end

NS_ASSUME_NONNULL_END
