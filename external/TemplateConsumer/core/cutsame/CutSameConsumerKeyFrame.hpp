//
// Created by Steven on 2021/2/7.
//

#ifndef TEMPLATECONSUMERAPP_CUTSAMECONSUMERKEYFRAME_H
#define TEMPLATECONSUMERAPP_CUTSAMECONSUMERKEYFRAME_H

#include "model.hpp"
#include "CutSameConsumerConst.hpp"
#include "CutSameConsumerHelper.hpp"
#include "ConvertUtils.h"
#include "CutsameConvertUtils.h"

#if __V_IPHONE_PLATFORM__
#include <NLEPlatform/NLEResourceNode.h>
#include <NLEPlatform/NLESequenceNode.h>
#include <NLEPlatform/NLEResType.h>
#else

#include <NLEResourceNode.h>
#include <NLESequenceNode.h>
#include <NLEResType.h>

#endif

using namespace CutSame;
using namespace cut::model;
using namespace TemplateConsumer;

static bool isTmKeyFrameInvalid(const std::shared_ptr<Keyframe> &keyFrame) {
    return keyFrame == nullptr || keyFrame->get_id().empty();
}

// todo 优化查找 做map
template<typename T>
static std::shared_ptr<T> getTMKeyFrame(const std::shared_ptr<TemplateModel> &tModel,
                                        const std::string &keyFrameId) {
    const auto &keyFrames = tModel->get_keyframes();
    for (const auto &keyFrame : keyFrames->get_videos()) {
        if (keyFrameId == keyFrame->get_id()) {
            return std::dynamic_pointer_cast<T>(keyFrame);
        }
    }
    for (const auto &keyFrame : keyFrames->get_audios()) {
        if (keyFrameId == keyFrame->get_id()) {
            return std::dynamic_pointer_cast<T>(keyFrame);
        }
    }
    for (const auto &keyFrame : keyFrames->get_stickers()) {
        if (keyFrameId == keyFrame->get_id()) {
            return std::dynamic_pointer_cast<T>(keyFrame);
        }
    }
    for (const auto &keyFrame : keyFrames->get_texts()) {
        if (keyFrameId == keyFrame->get_id()) {
            return std::dynamic_pointer_cast<T>(keyFrame);
        }
    }
    for (const auto &keyFrame : keyFrames->get_filters()) {
        if (keyFrameId == keyFrame->get_id()) {
            return std::dynamic_pointer_cast<T>(keyFrame);
        }
    }
    for (const auto &keyFrame : keyFrames->get_adjusts()) {
        if (keyFrameId == keyFrame->get_id()) {
            return std::dynamic_pointer_cast<T>(keyFrame);
        }
    }
    LOGGER->w("TMNLEC: keyframe not found");
    return std::make_shared<T>();
}
static int32_t tmVideoChromaKeyframeToNLE(const std::shared_ptr<VideoKeyframe> &videoKeyFrame,
                                        std::shared_ptr<NLETrackSlot> &nVideoKeyFrameSlot) {
    auto nChroma = std::make_shared<NLEChromaChannel>();
    auto keyFrameSegChroma = std::make_shared<NLESegmentChromaChannel>();
    keyFrameSegChroma->setIntensity(videoKeyFrame->get_chroma_intensity());
    keyFrameSegChroma->setShadow(videoKeyFrame->get_chroma_shadow());
    nChroma->setSegment(keyFrameSegChroma);
    nVideoKeyFrameSlot->addChromaChannel(nChroma);

    return CONVERT_RESULT_SUCCESS;
}

static int32_t tmVideoMaskKeyframeToNLE(const std::shared_ptr<VideoKeyframe> &videoKeyFrame,
                                          std::shared_ptr<NLETrackSlot> &nVideoKeyFrameSlot) {
    auto nMask = std::make_shared<NLEMask>();
    auto keyFrameSegMask = std::make_shared<NLESegmentMask>();
    const auto maskConfig = videoKeyFrame->get_mask_config();
    keyFrameSegMask->setCenterX((float) maskConfig->get_center_x());
    keyFrameSegMask->setCenterY((float) maskConfig->get_center_y());
    keyFrameSegMask->setWidth((float) maskConfig->get_width()); // todo re calculate width height
    keyFrameSegMask->setHeight((float) maskConfig->get_height());
    keyFrameSegMask->setFeather((float) maskConfig->get_feather());
    keyFrameSegMask->setRoundCorner((float) maskConfig->get_round_corner());
    keyFrameSegMask->setRotation((float) maskConfig->get_rotation());//透传Effect 不需要转换
    nMask->setSegment(keyFrameSegMask);
    nVideoKeyFrameSlot->addMask(nMask);

    return CONVERT_RESULT_SUCCESS;
}

// 视频关键帧中的调节信息
static int32_t tmVideoAdjustKeyframeToNLE(const std::shared_ptr<VideoKeyframe> &videoKeyFrame,
                                          std::shared_ptr<NLETrackSlot> &nVideoKeyFrameSlot) {
    auto nAdjustBrightness = std::make_shared<NLEFilter>();
    auto keyFrameSegAdjustBrightness = std::make_shared<NLESegmentFilter>();
    keyFrameSegAdjustBrightness->setFilterName(TM_MATERIAL_TYPE_BRIGHTNESS);
    keyFrameSegAdjustBrightness->setIntensity(videoKeyFrame->get_brightness_value());
    nAdjustBrightness->setSegment(keyFrameSegAdjustBrightness);
    nVideoKeyFrameSlot->addFilter(nAdjustBrightness);

    auto nAdjustContrast = std::make_shared<NLEFilter>();
    auto keyFrameSegAdjustContrast = std::make_shared<NLESegmentFilter>();
    keyFrameSegAdjustContrast->setFilterName(TM_MATERIAL_TYPE_CONTRAST);
    keyFrameSegAdjustContrast->setIntensity(videoKeyFrame->get_contrast_value());
    nAdjustContrast->setSegment(keyFrameSegAdjustContrast);
    nVideoKeyFrameSlot->addFilter(nAdjustContrast);

    auto nAdjustSaturation = std::make_shared<NLEFilter>();
    auto keyFrameSegAdjustSaturation = std::make_shared<NLESegmentFilter>();
    keyFrameSegAdjustSaturation->setFilterName(TM_MATERIAL_TYPE_SATURATION);
    keyFrameSegAdjustSaturation->setIntensity(videoKeyFrame->get_saturation_value());
    nAdjustSaturation->setSegment(keyFrameSegAdjustSaturation);
    nVideoKeyFrameSlot->addFilter(nAdjustSaturation);

    auto nAdjustSharpen = std::make_shared<NLEFilter>();
    auto keyFrameSegAdjustSharpen = std::make_shared<NLESegmentFilter>();
    keyFrameSegAdjustSharpen->setFilterName(TM_MATERIAL_TYPE_SHARPENING);
    keyFrameSegAdjustSharpen->setIntensity(videoKeyFrame->get_sharpen_value());
    nAdjustSharpen->setSegment(keyFrameSegAdjustSharpen);
    nVideoKeyFrameSlot->addFilter(nAdjustSharpen);

    auto nAdjustHighlight = std::make_shared<NLEFilter>();
    auto keyFrameSegAdjustHighlight = std::make_shared<NLESegmentFilter>();
    keyFrameSegAdjustHighlight->setFilterName(TM_MATERIAL_TYPE_HIGHLIGHT);
    keyFrameSegAdjustHighlight->setIntensity(videoKeyFrame->get_highlight_value());
    nAdjustHighlight->setSegment(keyFrameSegAdjustHighlight);
    nVideoKeyFrameSlot->addFilter(nAdjustHighlight);

    auto nAdjustShadow = std::make_shared<NLEFilter>();
    auto keyFrameSegAdjustShadow = std::make_shared<NLESegmentFilter>();
    keyFrameSegAdjustShadow->setFilterName(TM_MATERIAL_TYPE_SHADOW);
    keyFrameSegAdjustShadow->setIntensity(videoKeyFrame->get_shadow_value());
    nAdjustShadow->setSegment(keyFrameSegAdjustShadow);
    nVideoKeyFrameSlot->addFilter(nAdjustShadow);

    auto nAdjustTemperature = std::make_shared<NLEFilter>();
    auto keyFrameSegAdjustTemperature = std::make_shared<NLESegmentFilter>();
    keyFrameSegAdjustTemperature->setFilterName(TM_MATERIAL_TYPE_COLOR_TEMPERATURE);
    keyFrameSegAdjustTemperature->setIntensity(videoKeyFrame->get_mut_temperature_value());
    nAdjustTemperature->setSegment(keyFrameSegAdjustTemperature);
    nVideoKeyFrameSlot->addFilter(nAdjustTemperature);

    auto nAdjustTone = std::make_shared<NLEFilter>();
    auto keyFrameSegAdjustTone = std::make_shared<NLESegmentFilter>();
    keyFrameSegAdjustTone->setFilterName(TM_MATERIAL_TYPE_HUE);
    keyFrameSegAdjustTone->setIntensity(videoKeyFrame->get_tone_value());
    nAdjustTone->setSegment(keyFrameSegAdjustTone);
    nVideoKeyFrameSlot->addFilter(nAdjustTone);

    auto nAdjustFade = std::make_shared<NLEFilter>();
    auto keyFrameSegAdjustFade = std::make_shared<NLESegmentFilter>();
    keyFrameSegAdjustFade->setFilterName(TM_MATERIAL_TYPE_FADE);
    keyFrameSegAdjustFade->setIntensity(videoKeyFrame->get_fade_value());
    nAdjustFade->setSegment(keyFrameSegAdjustFade);
    nVideoKeyFrameSlot->addFilter(nAdjustFade);

    auto nAdjustLightSensation = std::make_shared<NLEFilter>();
    auto keyFrameSegAdjustLightSensation = std::make_shared<NLESegmentFilter>();
    keyFrameSegAdjustLightSensation->setFilterName(TM_MATERIAL_TYPE_LIGHT_SENSATION);
    keyFrameSegAdjustLightSensation->setIntensity(videoKeyFrame->get_light_sensation_value());
    nAdjustLightSensation->setSegment(keyFrameSegAdjustLightSensation);
    nVideoKeyFrameSlot->addFilter(nAdjustLightSensation);

    auto nAdjustVignetting = std::make_shared<NLEFilter>();
    auto keyFrameSegAdjustVignetting = std::make_shared<NLESegmentFilter>();
    keyFrameSegAdjustVignetting->setFilterName(TM_MATERIAL_TYPE_VIGNETTING);
    keyFrameSegAdjustVignetting->setIntensity(videoKeyFrame->get_vignetting_value());
    nAdjustVignetting->setSegment(keyFrameSegAdjustVignetting);
    nVideoKeyFrameSlot->addFilter(nAdjustVignetting);

    auto nAdjustParticle = std::make_shared<NLEFilter>();
    auto keyFrameSegAdjustParticle = std::make_shared<NLESegmentFilter>();
    keyFrameSegAdjustParticle->setFilterName(TM_MATERIAL_TYPE_PARTICLE);
    keyFrameSegAdjustParticle->setIntensity(videoKeyFrame->get_particle_value());
    nAdjustParticle->setSegment(keyFrameSegAdjustParticle);
    nVideoKeyFrameSlot->addFilter(nAdjustParticle);

    return CONVERT_RESULT_SUCCESS;
}

// 关键帧 视频
static int32_t tmVideoKeyFrameToNLE(const std::shared_ptr<TemplateModel> &tModel,
                                    const std::shared_ptr<Segment> &tSeg,
                                    std::shared_ptr<NLETrack> nTrack,
                                    std::shared_ptr<NLETrackSlot> nSlot,
                                    const std::shared_ptr<MaterialVideo> &materialVideo) {
    for (const auto &keyFrameId: tSeg->get_keyframe_refs()) {
        const auto videoKeyFrame = getTMKeyFrame<VideoKeyframe>(tModel, keyFrameId);
        if (isTmKeyFrameInvalid(videoKeyFrame)) continue;

        const auto tMatMask = getTemplateModelRefMaterial<MaterialMask>(tModel,
                                                                    tSeg->get_extra_material_refs());
        if (!isTmMaterialInvalid(tMatMask)) {
            // todo 效果不对暂时关掉，应该是视频真实宽高获取错误，这块逻辑看来还是要Android/iOS分开写
            if (tMatMask->get_resource_type() == "geometric_shape") {
//                TemplateConsumer::ConvertUtils::processMaskConfig(tSeg, videoKeyFrame->get_mask_config(), materialVideo);
            }
        }

        auto keyFrameSlot = std::make_shared<NLETrackSlot>();
        keyFrameSlot->setStartTime(
                ((videoKeyFrame->get_time_offset() - tSeg->get_source_timerange()->get_start()) /
                 tSeg->get_avg_speed() + tSeg->get_target_timerange()->get_start()) * CutsameConvertUtils::cutsameToUs(1));
        // 视频关键帧的坐标需要*2，其他类型关键帧不需要，应该是历史遗留问题
        keyFrameSlot->setTransformX((float) videoKeyFrame->get_position()->get_x() * 2);
        keyFrameSlot->setTransformY((float) videoKeyFrame->get_position()->get_y() * 2);
        keyFrameSlot->setScale((float) videoKeyFrame->get_scale()->get_x());
        keyFrameSlot->setRotation(ConvertUtils::getRotation(videoKeyFrame->get_rotation()));

        const auto keyFrameSegVideo = std::make_shared<NLESegmentVideo>();
        keyFrameSegVideo->setAlpha((float) videoKeyFrame->get_alpha());
        keyFrameSegVideo->setVolume((float) videoKeyFrame->get_volume());

        tmVideoMaskKeyframeToNLE(videoKeyFrame, keyFrameSlot);
        tmVideoAdjustKeyframeToNLE(videoKeyFrame, keyFrameSlot);
        tmVideoChromaKeyframeToNLE(videoKeyFrame, keyFrameSlot);

        keyFrameSlot->setMainSegment(keyFrameSegVideo);
        auto list = nSlot->getKeyframesUUIDList();
        list.push_back(keyFrameSlot->getUUID());
        nSlot->setKeyframesUUIDList(list);
        nTrack->addKeyframeSlot(keyFrameSlot);
    }
    return CONVERT_RESULT_SUCCESS;
}

// 关键帧 音频
static int32_t tmKeyFrameAudioToNLE(const std::shared_ptr<TemplateModel> &tModel,
                                    const std::shared_ptr<Segment> &tSeg,
                                    std::shared_ptr<NLETrack> nTrack,
                                    std::shared_ptr<NLETrackSlot> nSlot) {
    for (const auto &keyFrameId: tSeg->get_keyframe_refs()) {
        const auto audioKeyFrame = getTMKeyFrame<AudioKeyframe>(tModel, keyFrameId);
        if (isTmKeyFrameInvalid(audioKeyFrame)) continue;

        auto keyFrameSlot = std::make_shared<NLETrackSlot>();
        keyFrameSlot->setStartTime(
                ((audioKeyFrame->get_time_offset() - tSeg->get_source_timerange()->get_start()) /
                 tSeg->get_avg_speed() + tSeg->get_target_timerange()->get_start()) * CutsameConvertUtils::cutsameToUs(1));

        const auto keyFrameSegAudio = std::make_shared<NLESegmentAudio>();
        keyFrameSegAudio->setVolume((float) audioKeyFrame->get_volume());
        keyFrameSlot->setMainSegment(keyFrameSegAudio);
        auto list = nSlot->getKeyframesUUIDList();
        list.push_back(keyFrameSlot->getUUID());
        nSlot->setKeyframesUUIDList(list);
        nTrack->addKeyframeSlot(keyFrameSlot);
    }
    return CONVERT_RESULT_SUCCESS;
}

// 关键帧 贴纸
static int32_t tmKeyFrameStickerToNLE(const std::shared_ptr<TemplateModel> &tModel,
                                      const std::shared_ptr<Segment> &tSeg,
                                      std::shared_ptr<NLETrack> nTrack,
                                      std::shared_ptr<NLETrackSlot> nSlot) {
    for (const auto &keyFrameId: tSeg->get_keyframe_refs()) {
        const auto stickerKeyFrame = getTMKeyFrame<StickerKeyframe>(tModel, keyFrameId);
        if (isTmKeyFrameInvalid(stickerKeyFrame)) continue;

        auto keyFrameSlot = std::make_shared<NLETrackSlot>();
        auto nStickerSeg = std::make_shared<NLESegmentSticker>();
        keyFrameSlot->setStartTime(
                ((stickerKeyFrame->get_time_offset() - tSeg->get_source_timerange()->get_start()) /
                 tSeg->get_avg_speed() + tSeg->get_target_timerange()->get_start()) * CutsameConvertUtils::cutsameToUs(1));
        keyFrameSlot->setTransformX((float) stickerKeyFrame->get_position()->get_x());
        keyFrameSlot->setTransformY((float) stickerKeyFrame->get_position()->get_y());
        keyFrameSlot->setRotation(ConvertUtils::getRotation(stickerKeyFrame->get_rotation()));
        keyFrameSlot->setScale((float) stickerKeyFrame->get_scale()->get_x());
        keyFrameSlot->setMainSegment(nStickerSeg);

        auto list = nSlot->getKeyframesUUIDList();
        list.push_back(keyFrameSlot->getUUID());
        nSlot->setKeyframesUUIDList(list);
        nTrack->addKeyframeSlot(keyFrameSlot);
    }
    return CONVERT_RESULT_SUCCESS;
}

// 关键帧 文本
static int32_t tmKeyFrameTextToNLE(const std::shared_ptr<TemplateModel> &tModel,
                                   const std::shared_ptr<Segment> &tSeg,
                                   std::shared_ptr<NLETrack> nTrack,
                                   std::shared_ptr<NLETrackSlot> nSlot) {
    for (const auto &keyFrameId: tSeg->get_keyframe_refs()) {
        const auto textKeyFrame = getTMKeyFrame<TextKeyframe>(tModel, keyFrameId);
        if (isTmKeyFrameInvalid(textKeyFrame)) continue;

        auto keyFrameSlot = std::make_shared<NLETrackSlot>();
        keyFrameSlot->setStartTime(
                ((textKeyFrame->get_time_offset() - tSeg->get_source_timerange()->get_start()) /
                 tSeg->get_avg_speed() + tSeg->get_target_timerange()->get_start()) * CutsameConvertUtils::cutsameToUs(1));
        keyFrameSlot->setTransformX((float) textKeyFrame->get_position()->get_x());
        keyFrameSlot->setTransformY((float) textKeyFrame->get_position()->get_y());
        keyFrameSlot->setRotation(ConvertUtils::getRotation(textKeyFrame->get_rotation()));
        keyFrameSlot->setScale((float) textKeyFrame->get_scale()->get_x());
        
        std::shared_ptr<NLEStyText> styText = std::make_shared<NLEStyText>();
        uint32_t textAlpha = (int) (textKeyFrame->get_text_alpha() * 255);
        if (textAlpha > 255) {
            textAlpha = 255;
        }
        styText->setOutlineWidth((float) textKeyFrame->get_border_width());
        styText->setShadowSmoothing((float) textKeyFrame->get_shadow_smoothing());
        styText->setShadowOffsetX((float) textKeyFrame->get_shadow_point()->get_x());
        styText->setShadowOffsetY((float) textKeyFrame->get_shadow_point()->get_y());

        uint32_t textColor = ConvertUtils::getColorArgb(textKeyFrame->get_text_color(), ConvertUtils::WHITE());
        styText->setTextColor(textColor & 0x00FFFFFF | (textAlpha << 24));

        uint32_t outlineColor = ConvertUtils::getColorArgb(textKeyFrame->get_border_color(), ConvertUtils::TRANSPARENT());
        styText->setOutlineColor(outlineColor & 0x00FFFFFF | (textAlpha << 24));

        uint32_t bgColor = ConvertUtils::getColorArgb(textKeyFrame->get_background_color(), ConvertUtils::TRANSPARENT());
        uint32_t bgColorAlpha = (int) (textKeyFrame->get_background_alpha() * 255);
        if (bgColorAlpha > 255) {
            bgColorAlpha = 255;
        }
        styText->setBackgroundColor(bgColor & 0x00FFFFFF | (bgColorAlpha << 24));

        uint32_t shadowColor = ConvertUtils::getColorArgb(textKeyFrame->get_shadow_color(), ConvertUtils::TRANSPARENT());
        uint32_t shadowAlpha = (int) (textKeyFrame->get_shadow_alpha() * textAlpha) << 24;
        styText->setShadowColor(shadowColor & 0x00FFFFFF | shadowAlpha);

        std::shared_ptr<NLESegmentTextSticker> textStickerSeg = std::make_shared<NLESegmentTextSticker>();
        textStickerSeg->setStyle(styText);
        
        keyFrameSlot->setMainSegment(textStickerSeg);

        auto list = nSlot->getKeyframesUUIDList();
        list.push_back(keyFrameSlot->getUUID());
        nSlot->setKeyframesUUIDList(list);
        nTrack->addKeyframeSlot(keyFrameSlot);
    }
    return CONVERT_RESULT_SUCCESS;
}

// 关键帧 调节
static int32_t tmKeyFrameAdjustToNLE(const std::shared_ptr<TemplateModel> &tModel,
                                     const std::shared_ptr<Segment> &tSeg,
                                     std::shared_ptr<NLETrack> nTrack,
                                     std::shared_ptr<NLETrackSlot> nSlot,
                                     std::shared_ptr<NLESegmentFilter> &nFilter) {
    for (const auto &keyFrameId: tSeg->get_keyframe_refs()) {
        const auto filterKeyFrame = getTMKeyFrame<AdjustKeyframe>(tModel, keyFrameId);
        if (isTmKeyFrameInvalid(filterKeyFrame)) continue;

        auto keyFrameSlot = std::make_shared<NLETrackSlot>();
        keyFrameSlot->setStartTime(
                ((filterKeyFrame->get_time_offset() - tSeg->get_source_timerange()->get_start()) /
                 tSeg->get_avg_speed() + tSeg->get_target_timerange()->get_start()) * CutsameConvertUtils::cutsameToUs(1));

        const auto keyFrameSegFilter = std::make_shared<NLESegmentFilter>();
        const auto nFilterName = nFilter->getFilterName();
        auto tFilterValue = 0.0f;
        if (nFilterName == NLEFilterName::BRIGHTNESS) {
            tFilterValue = filterKeyFrame->get_brightness_value();
        } else if (nFilterName == NLEFilterName::CONTRACT) {
            tFilterValue = filterKeyFrame->get_contrast_value();
        } else if (nFilterName == NLEFilterName::SATURATION) {
            tFilterValue = filterKeyFrame->get_saturation_value();
        } else if (nFilterName == NLEFilterName::SHARPEN) {
            tFilterValue = filterKeyFrame->get_sharpen_value();
        } else if (nFilterName == NLEFilterName::HIGHLIGHT) {
            tFilterValue = filterKeyFrame->get_highlight_value();
        } else if (nFilterName == NLEFilterName::SHADOW) {
            tFilterValue = filterKeyFrame->get_shadow_value();
        } else if (nFilterName == NLEFilterName::TEMPERATURE) {
            tFilterValue = filterKeyFrame->get_temperature_value();
        } else if (nFilterName == NLEFilterName::TONE) {
            tFilterValue = filterKeyFrame->get_tone_value();
        } else if (nFilterName == NLEFilterName::FADE) {
            tFilterValue = filterKeyFrame->get_fade_value();
        } else if (nFilterName == NLEFilterName::LIGHT_SENSATION) {
            tFilterValue = filterKeyFrame->get_light_sensation_value();
        } else if (nFilterName == NLEFilterName::VIGNETTING) {
            tFilterValue = filterKeyFrame->get_vignetting_value();
        } else if (nFilterName == NLEFilterName::PARTICLE) {
            tFilterValue = filterKeyFrame->get_particle_value();
        }
        keyFrameSegFilter->setFilterName(nFilterName);
        keyFrameSegFilter->setIntensity(tFilterValue);
        keyFrameSlot->setMainSegment(keyFrameSegFilter);

        auto list = nSlot->getKeyframesUUIDList();
        list.push_back(keyFrameSlot->getUUID());
        nSlot->setKeyframesUUIDList(list);
        nTrack->addKeyframeSlot(keyFrameSlot);
    }
    return CONVERT_RESULT_SUCCESS;
}

// 关键帧 滤镜
static int32_t tmFilterKeyFrameToNLE(const std::shared_ptr<TemplateModel> &tModel,
                                     const std::shared_ptr<Segment> &tSeg,
                                     const std::shared_ptr<MaterialEffect> &tMat,
                                     std::shared_ptr<NLETrack> nTrack,
                                     std::shared_ptr<NLETrackSlot> nSlot) {
    for (const auto &keyFrameId: tSeg->get_keyframe_refs()) {
        const auto filterKeyFrame = getTMKeyFrame<FilterKeyframe>(tModel, keyFrameId);
        if (isTmKeyFrameInvalid(filterKeyFrame)) continue;

        auto keyFrameSlot = std::make_shared<NLETrackSlot>();
        keyFrameSlot->setStartTime(
                ((filterKeyFrame->get_time_offset() - tSeg->get_source_timerange()->get_start()) /
                 tSeg->get_avg_speed() + tSeg->get_target_timerange()->get_start()) * CutsameConvertUtils::cutsameToUs(1));

        const auto keyFrameSegFilter = std::make_shared<NLESegmentFilter>();
        keyFrameSegFilter->setIntensity((float) filterKeyFrame->get_value());
        keyFrameSegFilter->setFilterName(tMat->get_type());
        keyFrameSlot->setMainSegment(keyFrameSegFilter);

        auto list = nSlot->getKeyframesUUIDList();
        list.push_back(keyFrameSlot->getUUID());
        nSlot->setKeyframesUUIDList(list);
        nTrack->addKeyframeSlot(keyFrameSlot);
    }
    return CONVERT_RESULT_SUCCESS;
}

#endif //TEMPLATECONSUMERAPP_CUTSAMECONSUMERKEYFRAME_H
