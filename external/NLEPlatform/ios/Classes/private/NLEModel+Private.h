//
//  NLEModel+Private.h
//  NLEPlatform
//
//  Created by bytedance on 2020/12/7.
//

#import <Foundation/Foundation.h>
#import "NLESequenceNode.h"
#import "NLECommit.h"
#import "NLEEditor.h"
#import "NLETrack+iOS.h"
#import "NLETrackMV+iOS.h"
#import "NLETrackAlgorithm+iOS.h"
#import "NLESegment+iOS.h"
#import "NLESegmentMV+iOS.h"
#import "NLETrackSlot+iOS.h"
#import "NLECommit+iOS.h"
#import "NLEModel+iOS.h"
#import "NLEResourceNode+iOS.h"
#import "NLENode+iOS.h"
#import "NLEEditor+iOS.h"
#import "NLEMVExternalAlgorithmResult+iOS.h"
#import "NLESegmentTextTemplate+iOS.h"
#import "NLETextTemplateClip+iOS.h"
#import "NLEChromaChannel+iOS.h"
#import "NLEEffect+iOS.h"
#import "NLEFilter+iOS.h"
#import "NLEMask+iOS.h"
#import "NLEResourceAV+iOS.h"
#import "NLEResourceNode+iOS.h"
#import "NLEResourceSynchronizerImpl+iOS.h"
#import "NLESegmentAudio+iOS.h"
#import "NLESegmentChromaChannel+iOS.h"
#import "NLESegmentComposerFilter+iOS.h"
#import "NLESegmentEffect+iOS.h"
#import "NLESegmentEmojiSticker+iOS.h"
#import "NLESegmentFilter+iOS.h"
#import "NLESegmentImage+iOS.h"
#import "NLESegmentImageSticker+iOS.h"
#import "NLESegmentMask+iOS.h"
#import "NLESegmentPlay+iOS.h"
#import "NLESegmentSticker+iOS.h"
#import "NLESegmentSubtitleSticker+iOS.h"
#import "NLESegmentTextSticker+iOS.h"
#import "NLESegmentTimeEffect+iOS.h"
#import "NLESegmentTransition+iOS.h"
#import "NLESegmentVideo+iOS.h"
#import "NLESegmentVideoAnimation+iOS.h"
#import "NLESegmentInfoSticker+iOS.h"
#import "NLESegmentAudioLoudnessBalanceFilter+iOS.h"
#import "NLESegmentAudioVolumeFilter+iOS.h"
#import "NLEStyCanvas+iOS.h"
#import "NLEStyCrop+iOS.h"
#import "NLEStyleText+iOS.h"
#import "NLEStyStickerAnimation+iOS.h"
#import "NLETimeEffect+iOS.h"
#import "NLETimeSpaceNode+iOS.h"
#import "NLETimeSpaceNodeGroup+iOS.h"
#import "NLEVideoAnimation+iOS.h"
#import "NLESegmentImageVideoAnimation+iOS.h"
#import "NLESegmentHDRFilter+iOS.h"
#import "NLEResourceSynchronizerImpl+iOS.h"
#import "NLEResourceSynchronizerImpl.h"
#import "NLEStyClip+iOS.h"
#import "NLEStyle.h"

@interface NLEEditor_OC ()

@property (nonatomic, assign) std::shared_ptr<cut::model::NLEEditor> cppEditor;

- (instancetype)initWithCPPNode:(std::shared_ptr<cut::model::NLEEditor>)cppEditor;

@end

@interface NLEModel_OC ()

@property (nonatomic, assign) std::shared_ptr<cut::model::NLEModel> cppValue;

- (instancetype)initWithCPPNode:(std::shared_ptr<cut::model::NLEModel>)cppModel;

- (void)clearOCObjectCache;

/*
 存储 stage model
 */
+ (instancetype)stageModelWithCppModel:(std::shared_ptr<const cut::model::NLEModel>)model;
- (BOOL)isStage;
- (std::shared_ptr<const cut::model::NLEModel>)stageCppModel;

@end

@interface NLETrack_OC ()

@property (nonatomic, assign) std::shared_ptr<cut::model::NLETrack> cppValue;

- (instancetype)initWithCPPNode:(std::shared_ptr<cut::model::NLETrack>)cppTrack;

@end

@interface NLETrackMV_OC ()

@property (nonatomic, assign) std::shared_ptr<cut::model::NLETrackMV> cppValue;

- (instancetype)initWithCPPNode:(std::shared_ptr<cut::model::NLETrackMV>)cppTrack;

@end

@interface NLETrackAlgorithm_OC ()

@property (nonatomic, assign) std::shared_ptr<cut::model::NLETrackAlgorithm> cppValue;

- (instancetype)initWithCPPNode:(std::shared_ptr<cut::model::NLETrackAlgorithm>)cppTrackAlgorithm;

@end

@interface NLESegment_OC ()

@property (nonatomic, assign) std::shared_ptr<cut::model::NLESegment> cppValue;

- (instancetype)initWithCPPNode:(std::shared_ptr<cut::model::NLESegment>)cppSegment;

@end

@interface NLESegmentMV_OC ()

@property (nonatomic, assign) std::shared_ptr<cut::model::NLESegmentMV> cppValue;

- (instancetype)initWithCPPNode:(std::shared_ptr<cut::model::NLESegmentMV>)cppSegment;

@end

@interface NLETrackSlot_OC ()

@property (nonatomic, assign) std::shared_ptr<cut::model::NLETrackSlot> cppValue;

- (instancetype)initWithCPPNode:(std::shared_ptr<cut::model::NLETrackSlot>)cppTrackSlot;

@end

@interface NLECommit_OC ()

@property (nonatomic, assign) std::shared_ptr<cut::model::NLECommit> cppValue;

- (instancetype)initWithCPPNode:(std::shared_ptr<cut::model::NLECommit>)cppCommit;

@end

@interface NLEResourceNode_OC ()

@property (nonatomic, assign) std::shared_ptr<cut::model::NLEResourceNode> cppValue;

- (instancetype)initWithCPPNode:(std::shared_ptr<cut::model::NLEResourceNode>)cppResourceNode;

@end

@interface NLENode_OC ()

@property (nonatomic, assign) std::shared_ptr<cut::model::NLENode> cppValue;

- (instancetype)initWithCPPNode:(std::shared_ptr<cut::model::NLENode>)cppNode;

@end

@interface NLEMVExternalAlgorithmResult_OC ()

@property (nonatomic, assign) std::shared_ptr<cut::model::NLEMVExternalAlgorithmResult> cppValue;

- (instancetype)initWithCPPNode:(std::shared_ptr<cut::model::NLEMVExternalAlgorithmResult>)cppValue;

@end


@interface NLESegmentTextTemplate_OC ()

@property (nonatomic, assign) std::shared_ptr<cut::model::NLESegmentTextTemplate> cppValue;

- (instancetype)initWithCPPNode:(std::shared_ptr<cut::model::NLESegmentTextTemplate>)cppTextTemplate;

@end


@interface NLETextTemplateClip_OC ()

@property (nonatomic, assign) std::shared_ptr<cut::model::NLETextTemplateClip> cppValue;

- (instancetype)initWithCPPNode:(std::shared_ptr<cut::model::NLETextTemplateClip>)cppTextClip;

@end

@interface NLEChromaChannel_OC ()

@property (nonatomic, assign) std::shared_ptr<cut::model::NLEChromaChannel> cppValue;

- (instancetype)initWithCPPNode:(std::shared_ptr<cut::model::NLEChromaChannel>)cppChromaChannel;

@end

@interface NLEEffect_OC ()

@property (nonatomic, assign) std::shared_ptr<cut::model::NLEVideoEffect> cppValue;

- (instancetype)initWithCPPNode:(std::shared_ptr<cut::model::NLEVideoEffect>)cppEffect;

@end

@interface NLEFilter_OC ()

@property (nonatomic, assign) std::shared_ptr<cut::model::NLEFilter> cppValue;

- (instancetype)initWithCPPNode:(std::shared_ptr<cut::model::NLEFilter>)cppFilter;

@end

@interface NLEMask_OC ()

@property (nonatomic, assign) std::shared_ptr<cut::model::NLEMask> cppValue;

- (instancetype)initWithCPPNode:(std::shared_ptr<cut::model::NLEMask>)cppMask;

@end

@interface NLEResourceAV_OC()

@property (nonatomic, assign) std::shared_ptr<cut::model::NLEResourceAV> cppValue;

- (instancetype)initWithCPPNode:(std::shared_ptr<cut::model::NLEResourceAV>)cppResourceAV;

@end

@interface NLEResourceFetchCallbackImpl_OC ()

@property (nonatomic, assign)std::shared_ptr<nle::resource::NLEResourceFetchCallback> cppFetch;

- (instancetype)initWithCPPNode:(std::shared_ptr<nle::resource::NLEResourceFetchCallback> )cppFetch;

@end


@interface NLEResourceSynchronizerImpl_OC ()

@property (nonatomic, assign)std::shared_ptr<nle::resource::NLEResourceSynchronizerImpl> cppSynchronizer;

- (instancetype)initWithCPPNode:(std::shared_ptr<nle::resource::NLEResourceSynchronizerImpl> )cppSynchronizer;

@end

@interface NLESegmentAudio_OC ()

@property (nonatomic, assign) std::shared_ptr<cut::model::NLESegmentAudio> cppValue;

- (instancetype)initWithCPPNode:(std::shared_ptr<cut::model::NLESegmentAudio>)cppSegmentAudio;

@end

@interface NLESegmentChromaChannel_OC ()

@property (nonatomic, assign) std::shared_ptr<cut::model::NLESegmentChromaChannel> cppValue;

- (instancetype)initWithCPPNode:(std::shared_ptr<cut::model::NLESegmentChromaChannel>)cppSegmentChromaChannel;

@end

@interface NLESegmentComposerFilter_OC ()

@property (nonatomic, assign) std::shared_ptr<cut::model::NLESegmentComposerFilter> cppValue;

- (instancetype)initWithCPPNode:(std::shared_ptr<cut::model::NLESegmentComposerFilter>)cppSegmentComposerFilter;

@end

@interface NLESegmentEffect_OC ()

@property (nonatomic, assign) std::shared_ptr<cut::model::NLESegmentEffect> cppValue;

- (instancetype)initWithCPPNode:(std::shared_ptr<cut::model::NLESegmentEffect>)cppSegmentEffect;

@end

@interface NLESegmentEmojiSticker_OC ()

@property (nonatomic, assign) std::shared_ptr<cut::model::NLESegmentEmojiSticker> cppValue;

- (instancetype)initWithCPPNode:(std::shared_ptr<cut::model::NLESegmentEmojiSticker>)cppEmojiSticker;

@end

@interface NLESegmentFilter_OC ()

@property (nonatomic, assign) std::shared_ptr<cut::model::NLESegmentFilter> cppValue;

- (instancetype)initWithCPPNode:(std::shared_ptr<cut::model::NLESegmentFilter>)cppSegmentFilter;

@end

@interface NLESegmentImage_OC ()

@property (nonatomic, assign) std::shared_ptr<cut::model::NLESegmentImage> cppValue;

- (instancetype)initWithCPPNode:(std::shared_ptr<cut::model::NLESegmentImage>)cppSegmentImage;

@end

@interface NLESegmentImageSticker_OC ()

@property (nonatomic, assign) std::shared_ptr<cut::model::NLESegmentImageSticker> cppValue;

- (instancetype)initWithCPPNode:(std::shared_ptr<cut::model::NLESegmentImageSticker>)cppImageSticker;

@end

@interface NLESegmentMask_OC ()

@property (nonatomic, assign) std::shared_ptr<cut::model::NLESegmentMask> cppValue;

- (instancetype)initWithCPPNode:(std::shared_ptr<cut::model::NLESegmentMask>)cppSegmentMask;

@end

@interface NLESegmentPlay_OC ()

@property (nonatomic, assign) std::shared_ptr<cut::model::NLESegmentPlay> cppValue;

- (instancetype)initWithCPPNode:(std::shared_ptr<cut::model::NLESegmentPlay>)cppModel;

@end

@interface NLESegmentSticker_OC ()

@property (nonatomic, assign) std::shared_ptr<cut::model::NLESegmentSticker> cppValue;

- (instancetype)initWithCPPNode:(std::shared_ptr<cut::model::NLESegmentSticker>)cppSegmentSticker;

@end

@interface NLESegmentSubtitleSticker_OC ()

@property (nonatomic, assign) std::shared_ptr<cut::model::NLESegmentSubtitleSticker> cppValue;

- (instancetype)initWithCPPNode:(std::shared_ptr<cut::model::NLESegmentSubtitleSticker>)cppSubtitleSticker;

@end

@interface NLESegmentTextSticker_OC ()

@property (nonatomic, assign) std::shared_ptr<cut::model::NLESegmentTextSticker> cppValue;

- (instancetype)initWithCPPNode:(std::shared_ptr<cut::model::NLESegmentTextSticker>)cppTextSticker;

@end

@interface NLESegmentTimeEffect_OC ()

@property (nonatomic, assign) std::shared_ptr<cut::model::NLESegmentTimeEffect> cppValue;

- (instancetype)initWithCPPNode:(std::shared_ptr<cut::model::NLESegmentTimeEffect>)cppSegmentEffect;

@end

@interface NLESegmentTransition_OC ()

@property (nonatomic, assign) std::shared_ptr<cut::model::NLESegmentTransition> cppValue;

- (instancetype)initWithCPPNode:(std::shared_ptr<cut::model::NLESegmentTransition>)cppSegmentTransition;

@end

@interface NLESegmentVideo_OC ()

@property (nonatomic, assign) std::shared_ptr<cut::model::NLESegmentVideo> cppValue;

- (instancetype)initWithCPPNode:(std::shared_ptr<cut::model::NLESegmentVideo>)cppSegmentVideo;

@end

@interface NLESegmentVideoAnimation_OC ()

@property (nonatomic, assign) std::shared_ptr<cut::model::NLESegmentVideoAnimation> cppValue;

- (instancetype)initWithCPPNode:(std::shared_ptr<cut::model::NLESegmentVideoAnimation>)cppVideoAnimation;

// 类簇
+ (instancetype)videoAnimationCppVideoAnimation:(std::shared_ptr<cut::model::NLESegmentVideoAnimation>)cppVideoAnimation;

@end

@interface NLESegmentImageVideoAnimation_OC ()

@property (nonatomic, assign) std::shared_ptr<cut::model::NLESegmentImageVideoAnimation> cppValue;

- (instancetype)initWithCPPNode:(std::shared_ptr<cut::model::NLESegmentImageVideoAnimation>)cppImageVideoAnimation;

@end

@interface NLESegmentInfoSticker_OC ()

@property (nonatomic, assign) std::shared_ptr<cut::model::NLESegmentInfoSticker> cppValue;

- (instancetype)initWithCPPNode:(std::shared_ptr<cut::model::NLESegmentInfoSticker>)cppInfoSticker;

@end

@interface NLESegmentAudioLoudnessBalanceFilter_OC ()

@property (nonatomic, assign) std::shared_ptr<cut::model::NLESegmentAudioLoudnessBalanceFilter> cppValue;

- (instancetype)initWithCPPNode:(std::shared_ptr<cut::model::NLESegmentAudioLoudnessBalanceFilter>)cppFilter;

@end

@interface NLESegmentAudioVolumeFilter_OC ()

@property (nonatomic, assign) std::shared_ptr<cut::model::NLESegmentAudioVolumeFilter> cppValue;

- (instancetype)initWithCPPNode:(std::shared_ptr<cut::model::NLESegmentAudioVolumeFilter>)cppVolumeFilter;

@end

@interface NLEStyCanvas_OC ()

@property (nonatomic, assign) std::shared_ptr<cut::model::NLEStyCanvas> cppValue;

- (instancetype)initWithCPPNode:(std::shared_ptr<cut::model::NLEStyCanvas>)cppStyCanvas;

@end

@interface NLEStyCrop_OC ()

@property (nonatomic, assign) std::shared_ptr<cut::model::NLEStyCrop> cppValue;

- (instancetype)initWithCPPNode:(std::shared_ptr<cut::model::NLEStyCrop>)cppStyCrop;

@end

@interface NLEStyClip_OC ()

@property (nonatomic, assign) std::shared_ptr<cut::model::NLEStyClip> cppValue;

- (instancetype)initWithCPPNode:(std::shared_ptr<cut::model::NLEStyClip>)cppClip;

@end

@interface NLEStyleText_OC ()

@property (nonatomic, assign) std::shared_ptr<cut::model::NLEStyText> cppValue;

- (instancetype)initWithCPPNode:(std::shared_ptr<cut::model::NLEStyText>)cppStyleText;

@end

@interface NLEStyStickerAnimation_OC ()

@property (nonatomic, assign) std::shared_ptr<cut::model::NLEStyStickerAnim> cppValue;

- (instancetype)initWithCPPNode:(std::shared_ptr<cut::model::NLEStyStickerAnim>)cppStickerAnimation;

@end

@interface NLETimeEffect_OC ()

@property (nonatomic, assign) std::shared_ptr<cut::model::NLETimeEffect> cppValue;

- (instancetype)initWithCPPNode:(std::shared_ptr<cut::model::NLETimeEffect>)cppTimeEffect;

@end

@interface NLETimeSpaceNode_OC ()

@property (nonatomic, assign) std::shared_ptr<cut::model::NLETimeSpaceNode> cppValue;

- (instancetype)initWithCPPNode:(std::shared_ptr<cut::model::NLETimeSpaceNode>)cppTimeSpaceNode;

@end

@interface NLETimeSpaceNodeGroup_OC ()

//@property (nonatomic, assign) std::shared_ptr<cut::model::NLETimeSpaceNodeGroup> cppTimeSpaceNodeGroup;
//
//- (instancetype)initWithCPPNode:(std::shared_ptr<cut::model::NLETimeSpaceNodeGroup>)cppTimeSpaceNodeGroup;

@end

@interface NLEVideoAnimation_OC ()

@property (nonatomic, assign) std::shared_ptr<cut::model::NLEVideoAnimation> cppValue;

- (instancetype)initWithCPPNode:(std::shared_ptr<cut::model::NLEVideoAnimation>)cppVideoAnima;

@end


@interface NLESegmentHDRFilter_OC ()

@property (nonatomic, assign) std::shared_ptr<cut::model::NLESegmentHDRFilter>cppValue;

- (instancetype)initWithCPPNode:(std::shared_ptr<cut::model::NLESegmentHDRFilter>)cppNode;

@end

@interface NLEVideoFrameModel_OC ()

@property (nonatomic, assign) std::shared_ptr<cut::model::NLEVideoFrameModel> cppValue;

- (instancetype)initWithCPPModel:(std::shared_ptr<cut::model::NLEVideoFrameModel>)cppModel;

@end

@interface NLEBranch_OC ()

@property (nonatomic, assign) std::shared_ptr<cut::model::NLEBranch> cppValue;

- (instancetype)initWithCPPNode:(std::shared_ptr<cut::model::NLEBranch>)cppValue ;

@end

