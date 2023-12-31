//
// Created by bytedance on 2020/9/28.
//

#ifndef NLEPLATFORM_NLEMANIFEST_H
#define NLEPLATFORM_NLEMANIFEST_H

#include "NLESequenceNode.h"
#include "NLEResourceNode.h"
#include "NLEStyle.h"
#include "NLECommit.h"

using namespace cut::model;

namespace cut::model {

    class NLEManifest {
    public:
        static void registerNLEModelClass() {
            static bool hasRegister = false;
            if (hasRegister) return;

            NLETimeSpaceNode::registerCreateFunc();

            NLECommit::registerCreateFunc();
            NLEModel::registerCreateFunc();
            NLETrack::registerCreateFunc();
            NLETrackSlot::registerCreateFunc();
            NLEFilter::registerCreateFunc();
            NLETimeEffect::registerCreateFunc();
            NLECherEffect::registerCreateFunc();
            NLEVideoEffect::registerCreateFunc();
            NLEVideoAnimation::registerCreateFunc();
            NLEMask::registerCreateFunc();
            NLEChromaChannel::registerCreateFunc();
            NLEVideoFrameModel::registerCreateFunc();

            NLESegmentSticker::registerCreateFunc();
            NLESegmentSubtitleSticker::registerCreateFunc();
            NLESegmentTextSticker::registerCreateFunc();
            NLESegmentImageSticker::registerCreateFunc();
            NLESegmentInfoSticker::registerCreateFunc();
            NLESegmentEmojiSticker::registerCreateFunc();

            NLESegmentSticker::registerCreateFunc();
            NLESegmentTextTemplate::registerCreateFunc();
            NLETextTemplateClip::registerCreateFunc();

            NLESegmentVideo::registerCreateFunc();
            NLESegmentImage::registerCreateFunc();
            NLESegmentAudio::registerCreateFunc();
            NLESegmentAudioLoudnessBalanceFilter::registerCreateFunc();
            NLESegmentAudioVolumeFilter::registerCreateFunc();
            NLESegmentEffect::registerCreateFunc();
            NLEVideoEffect::registerCreateFunc();
            NLESegmentMask::registerCreateFunc();
            NLESegmentTimeEffect::registerCreateFunc();
            NLESegmentCherEffect::registerCreateFunc();
            NLESegmentFilter::registerCreateFunc();
            NLESegmentComposerFilter::registerCreateFunc();
            NLESegmentHDRFilter::registerCreateFunc();
            NLESegmentPlay::registerCreateFunc();
            NLESegmentTransition::registerCreateFunc();
            NLESegmentVideoAnimation::registerCreateFunc();
            NLESegmentImageVideoAnimation::registerCreateFunc();
            NLESegmentChromaChannel::registerCreateFunc();
            NLESegmentMV::registerCreateFunc();
            NLESegmentTextTemplate::registerCreateFunc();
            NLETextTemplateClip::registerCreateFunc();
            NLETrackMV::registerCreateFunc();
            NLETrackAlgorithm::registerCreateFunc();
            NLENoiseReduction::registerCreateFunc();
            NLEMVExternalAlgorithmResult::registerCreateFunc();

            NLEResourceAV::registerCreateFunc();
            NLEResourceNode::registerCreateFunc();

            NLEStyCanvas::registerCreateFunc();
            NLEStyCrop::registerCreateFunc();
            NLEStyClip::registerCreateFunc();
            NLEStyStickerAnim::registerCreateFunc();
            NLEStyText::registerCreateFunc();

            NLEPoint::registerCreateFunc();
            NLEStringFloatPair::registerCreateFunc();
            NLEStyClip::registerCreateFunc();

            NLESegmentBrickEffect::registerCreateFunc();
            hasRegister = true;
        }
    };

}

#endif //NLEPLATFORM_NLEMANIFEST_H
