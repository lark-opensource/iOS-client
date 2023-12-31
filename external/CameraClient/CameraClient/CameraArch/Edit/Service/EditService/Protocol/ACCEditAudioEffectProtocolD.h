//
//  ACCEditAudioEffectProtocolD.h
//  CameraClient
//
//  Created by raomengyun on 2021/9/24.
//

#ifndef ACCEditAudioEffectProtocolD_h
#define ACCEditAudioEffectProtocolD_h

#import <CreationKitRTProtocol/ACCEditAudioEffectProtocol.h>

typedef void (^ACCVoiceBlanceDetectCompletionBlock)(IESMMTranscodeRes *_Nullable result, NSMutableArray<IESMMAudioDetectionConfig *> *detectConfigs);

@protocol ACCEditAudioEffectProtocolD <ACCEditAudioEffectProtocol>

- (void)hotAppendTextReadAudioAsset:(AVAsset *_Nonnull)asset withRange:(IESMMVideoDataClipRange *_Nonnull)clipRange;

- (void)hotAppendKaraokeAudioAsset:(AVAsset *_Nonnull)asset withRange:(IESMMVideoDataClipRange *_Nonnull)clipRange;

// Karaoke
- (void)getVoiceBalanceDetectConfigForVideoAssets:(BOOL)forVideoAssets
                                       completion:(ACCVoiceBlanceDetectCompletionBlock)completion;

@end


#endif /* ACCEditAudioEffectProtocolD_h */
