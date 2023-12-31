//
// Created by Steven on 2021/2/7.
//

#ifndef TEMPLATECONSUMERAPP_CUTSAMECONSUMERCONVERT_H
#define TEMPLATECONSUMERAPP_CUTSAMECONSUMERCONVERT_H

#include "NLEFactory.h"
#include "ConvertUtils.h"
#include "CutsameConvertUtils.h"
#include "model.hpp"
#include "CutSameConsumerConst.hpp"
#include "CutSameConsumerKeyFrame.hpp"
#include "CutSameConsumerHelper.hpp"
#include "EffectLayerUtils.hpp"
#include "RGBConverterUtils.hpp"

#if __V_IPHONE_PLATFORM__
#include <NLEPlatform/NLEResourceNode.h>
#include <NLEPlatform/NLESequenceNode.h>
#include <NLEPlatform/NLEResType.h>
#else

#include <NLEResourceNode.h>
#include <NLESequenceNode.h>
#include <NLEResType.h>

#endif

using namespace TemplateConsumer;
using namespace CutSame;
using namespace cut::model;

// 速度 视频、音频
static int32_t tmSpeedToNLE(const std::shared_ptr<TemplateModel> &tModel,
                            const std::shared_ptr<Segment> &tSeg,
                            std::shared_ptr<NLESegmentAudio> &nSeg) {
    const auto tMat = getTemplateModelRefMaterial<MaterialSpeed>(tModel,
                                                                 tSeg->get_extra_material_refs());
    if (isTmMaterialInvalid(tMat)) {
        return CONVERT_RESULT_SUCCESS;
    }

    if (tMat->get_mode() == 1) { // 曲线变速
        const auto curves = tMat->get_curve_speed()->get_speed_points();
        auto curveX = std::vector<float>();
        auto curveY = std::vector<float>();

        for (const auto &point: curves) {
            curveX.push_back(point->get_x());
            curveY.push_back(point->get_y());
        }

        auto transCurveX = transferTrimPointXtoSeqPointX(curveX, curveY);
        float aveCurveSpeed = calculateAveCurveSpeedRatio(transCurveX, curveY);

        for (int i = 0; i < transCurveX.size(); i++) {
            auto nPoint = std::make_shared<NLEPoint>();
            nPoint->setX((float) transCurveX[i]);
            nPoint->setY((float) curveY[i]);
            nSeg->addCurveSpeedPoint(nPoint);
        }

        nSeg->setSpeed(aveCurveSpeed);
    } else { // // 常规变速
        nSeg->setSpeed((float) tMat->get_speed());
    }
    return CONVERT_RESULT_SUCCESS;
}

// 色度抠图
static int32_t tmVideoChromaToNLE(const std::shared_ptr<TemplateModel> &tModel,
                                  const std::shared_ptr<Segment> &tSeg,
                                  std::shared_ptr<NLETrackSlot> &nSlot) {
    const auto tMat = getTemplateModelRefMaterial<MaterialChroma>(tModel,
                                                                  tSeg->get_mut_extra_material_refs());
    if (isTmMaterialInvalid(tMat) || tMat->get_path().empty()) {
        return CONVERT_RESULT_SUCCESS;
    }
    auto nChroma = std::make_shared<NLEChromaChannel>();
    auto nSegChroma = std::make_shared<NLESegmentChromaChannel>();
    nSegChroma->setEffectSDKChroma(NLEFactory::createNLEResourceNode(NLEResType::CHROMA,
                                                                     tMat->get_path())); //  todo 蒙版res id固定 6825780387113865741
    nSegChroma->setColor(ConvertUtils::getColorArgb(tMat->get_color(), ConvertUtils::WHITE()));
    nSegChroma->setIntensity((float) tMat->get_intensity_value());
    nSegChroma->setShadow((float) tMat->get_shadow_value());
    nChroma->setLayer(INDEX_CHROMA_START);
    nChroma->setSegment(nSegChroma);
    nSlot->addChromaChannel(nChroma);
    return CONVERT_RESULT_SUCCESS;
}

// 蒙版
static int32_t tmVideoMaskToNLE(const std::shared_ptr<TemplateModel> &tModel,
                                const std::shared_ptr<Segment> &tSeg,
                                std::shared_ptr<NLETrackSlot> &nSlot,
                                const std::shared_ptr<MaterialVideo> &tMaterialVideo) {
    const auto tMat = getTemplateModelRefMaterial<MaterialMask>(tModel,
                                                                tSeg->get_extra_material_refs());
    if (isTmMaterialInvalid(tMat) || tMat->get_path().empty()) {
        return CONVERT_RESULT_SUCCESS;
    }

    const auto tConfig = tMat->get_config();
    auto nMask = std::make_shared<NLEMask>();
    auto nSegMask = std::make_shared<NLESegmentMask>();

    // todo 效果不对暂时关掉，应该是视频真实宽高获取错误，这块逻辑看来还是要Android/iOS分开写
    if (tMat->get_resource_type() == "geometric_shape") {
//        ConvertUtils::processMaskConfig(tSeg, tMat->get_config(), tMaterialVideo);
    }

    nSegMask->setAspectRatio((float) tConfig->get_aspect_ratio());
    nSegMask->setCenterX((float) tConfig->get_center_x());
    nSegMask->setCenterY((float) tConfig->get_center_y());
    nSegMask->setWidth((float) tConfig->get_width()); // todo re calculate width height
    nSegMask->setHeight((float) tConfig->get_height());
    nSegMask->setFeather((float) tConfig->get_feather());
    nSegMask->setRoundCorner((float) tConfig->get_round_corner());
    nSegMask->setRotation((float) tConfig->get_rotation());//透传Effect 不需要转换
    nSegMask->setInvert(tConfig->get_invert());
    nSegMask->setMaskType(tMat->get_resource_type());
    auto nRes = std::make_shared<NLEResourceNode>();
    nRes->setResourceFile(tMat->get_path());
    nRes->setResourceId(tMat->get_resource_id()); // todo not have effect id???
    nSegMask->setEffectSDKMask(nRes);
    nMask->setLayer(INDEX_VIDEO_MASK_START);
    nMask->setSegment(nSegMask);
    nSlot->addMask(nMask);
    return CONVERT_RESULT_SUCCESS;
}

// 视频动画
static int32_t tmVideoAnimToNLE(const std::shared_ptr<TemplateModel> &tModel,
                                const std::shared_ptr<Segment> &tSeg,
                                const std::shared_ptr<MaterialEffect> &tMat,
                                std::shared_ptr<NLETrackSlot> &nSlot) {
    auto animDuration = (int64_t) CutsameConvertUtils::cutsameToUs(tMat->get_value());
    auto nVideoAnim = std::make_shared<NLEVideoAnimation>();
    if (tMat->get_category_name() == TM_ANIM_OUT) {
        nVideoAnim->setStartTime(nSlot->getDuration() - animDuration);
    } else {
        nVideoAnim->setStartTime(0);
    }
    nVideoAnim->setDuration(animDuration); // todo maybe == 0  need LV draft upgrade
    auto nVideoAnimSeg = std::make_shared<NLESegmentVideoAnimation>();
    nVideoAnimSeg->setEffectSDKVideoAnimation(
            NLEFactory::createNLEResourceNode(NLEResType::ANIMATION_VIDEO, tMat->get_path(),
                                              tMat->get_effect_id()));
    nVideoAnimSeg->setAnimationDuration(animDuration);
    nVideoAnim->setSegment(nVideoAnimSeg);
    nSlot->addVideoAnim(nVideoAnim);
    return CONVERT_RESULT_SUCCESS;
}

// 视频混合模式
static int32_t tmVideoMixModeToNLE(const std::shared_ptr<TemplateModel> &tModel,
                                   const std::shared_ptr<Segment> &tSeg,
                                   const std::shared_ptr<MaterialEffect> &tMat,
                                   std::shared_ptr<NLETrackSlot> &nSlot,
                                   std::shared_ptr<NLESegmentVideo> &nSegVideo) {
    nSegVideo->setBlendFile(
            NLEFactory::createNLEResourceNode(NLEResType::MIX_MODE, tMat->get_path(),
                                              tMat->get_resource_id()));
    return CONVERT_RESULT_SUCCESS;
}

// 视频滤镜
static int32_t tmVideoFilterToNLE(const std::shared_ptr<TemplateModel> &tModel,
                                  const std::shared_ptr<Segment> &tSeg,
                                  const std::shared_ptr<MaterialEffect> &tMat,
                                  std::shared_ptr<NLETrackSlot> &nSlot) {
    auto nFilter = std::make_shared<NLEFilter>();
    auto nSegFilter = std::make_shared<NLESegmentFilter>();
    nSegFilter->setEffectSDKFilter(
            NLEFactory::createNLEResourceNode(NLEResType::FILTER, tMat->get_path(),
                                              tMat->get_resource_id()));
    nSegFilter->setIntensity((float) tMat->get_value());
    nSegFilter->setFilterName(tMat->get_type());
    if (tMat->get_type() == TM_MATERIAL_TYPE_FILTER) { // 滤镜
        nFilter->setLayer(INDEX_FILTER_START);
    } else if (tMat->get_type() == TM_MATERIAL_TYPE_BEAUTY) { // 美颜
        nFilter->setLayer(INDEX_BEAUTY_START);
    } else if (tMat->get_type() == TM_MATERIAL_TYPE_RESHAPE) { // 形变 例如：瘦脸
        nFilter->setLayer(INDEX_RESHAPE_START);
    } else if (tMat->get_type() == TM_MATERIAL_TYPE_BRIGHTNESS ||
            tMat->get_type() == TM_MATERIAL_TYPE_CONTRAST ||
            tMat->get_type() == TM_MATERIAL_TYPE_SATURATION ||
            tMat->get_type() == TM_MATERIAL_TYPE_SHARPENING ||
            tMat->get_type() == TM_MATERIAL_TYPE_HIGHLIGHT ||
            tMat->get_type() == TM_MATERIAL_TYPE_SHADOW ||
            tMat->get_type() == TM_MATERIAL_TYPE_COLOR_TEMPERATURE ||
            tMat->get_type() == TM_MATERIAL_TYPE_HUE ||
            tMat->get_type() == TM_MATERIAL_TYPE_FADE ||
            tMat->get_type() == TM_MATERIAL_TYPE_VIGNETTING ||
            tMat->get_type() == TM_MATERIAL_TYPE_PARTICLE ||
            tMat->get_type() == TM_MATERIAL_TYPE_LIGHT_SENSATION) {
        nFilter->setLayer(getAdjustIndex(tMat->get_type()));
    }

    nFilter->setSegment(nSegFilter);
    nSlot->addFilter(nFilter);
    return CONVERT_RESULT_SUCCESS;
}

// 副轨单段素材特效
static int32_t tmSubVideoEffectToNLE(const std::shared_ptr<TemplateModel> &tModel,
                                     const std::shared_ptr<Segment> &tSeg,
                                     const std::shared_ptr<MaterialEffect> &tMat,
                                     std::shared_ptr<NLETrackSlot> &nSlot) {
    auto tEffectSeg = getEffectSegmentByMaterial(tModel, tMat->get_id());

    auto nVideoEffect = std::make_shared<NLEVideoEffect>();
    auto nSegEffect = std::make_shared<NLESegmentEffect>();
    nSegEffect->setEffectSDKEffect(
            NLEFactory::createNLEResourceNode(NLEResType::EFFECT, tMat->get_path(),
                                              tMat->get_resource_id()));
    for (auto adjustParam : tMat->get_adjust_params()) {
        auto info = std::make_shared<NLEStringFloatPair>();
        info->setFirst(adjustParam->get_name());
        info->setSecond(adjustParam->get_value());
        nSegEffect->addAdjustParams(info);
    }

    // 这个只需要保证唯一就可以了，做Key用，所以取id
    nSegEffect->setEffectName(tMat->get_id());
    nSegEffect->setApplyTargetType(tMat->get_apply_target_type());
    auto targetStart = tEffectSeg->get_target_timerange()->get_start();
    auto targetEnd = targetStart + tEffectSeg->get_target_timerange()->get_duration();

    nVideoEffect->setStartTime(CutsameConvertUtils::cutsameToUs(targetStart));
    nVideoEffect->setEndTime(CutsameConvertUtils::cutsameToUs(targetEnd));

    nVideoEffect->setLayer(tEffectSeg->get_render_index());
    nVideoEffect->setSegment(nSegEffect);

    nSlot->addVideoEffect(nVideoEffect);
    return CONVERT_RESULT_SUCCESS;
}

//视频效果，包括：视频动画、滤镜、美颜、调节
static int32_t tmVideoEffectToNLE(const std::shared_ptr<TemplateModel> &tModel,
                                  const std::shared_ptr<Segment> &tSeg,
                                  std::shared_ptr<NLETrackSlot> &nSlot,
                                  std::shared_ptr<NLESegmentVideo> &nSegVideo) {

    for (const auto &refId: tSeg->get_extra_material_refs()) {
        const auto &tMat = getTemplateModelMaterial<MaterialEffect>(tModel, refId);
        if (isTmMaterialInvalid(tMat)) {
            continue;
        }

        if (tMat->get_type() == TM_MATERIAL_TYPE_VIDEO_ANIM) {
            tmVideoAnimToNLE(tModel, tSeg, tMat, nSlot);
        } else if (tMat->get_type() == TM_MATERIAL_TYPE_MIX_MODE) {
            tmVideoMixModeToNLE(tModel, tSeg, tMat, nSlot, nSegVideo);
        } else if (tMat->get_type() == TM_MATERIAL_TYPE_VIDEO_EFFECT ||
                   tMat->get_type() == TM_MATERIAL_TYPE_FACE_EFFECT) {
            // 这里只添加副轨的effect，主轨的effect见tmEffectTrackToNLETrack函数
            if (tMat->get_apply_target_type() == APPLY_TARGET_SUB) {
                tmSubVideoEffectToNLE(tModel, tSeg, tMat, nSlot);
            }
        } else { // other is filter
            tmVideoFilterToNLE(tModel, tSeg, tMat, nSlot);
        }
    }

    return CONVERT_RESULT_SUCCESS;
}

// 视频、图片、贴纸、文本的裁剪、位移
static int32_t tmClipToNLE(const std::shared_ptr<Segment> &tSeg,
                           std::shared_ptr<NLETrackSlot> &nSlot) {
    const auto &tClip = tSeg->get_clip();
//    nSeg->setAlpha(tClip->get_alpha()); // todo NLESegmentVideo的alpha呢？
//    nSlot->setScale(
//            (float) tMaterialVideo->get_crop_scale()); // todo 还有个TM->track->segment->clip->scale
    nSlot->setScale((float) tClip->get_scale()->get_x()); // todo scale Y?
    nSlot->setMirror_X(tClip->get_flip()->get_horizontal());
    nSlot->setMirror_Y(tClip->get_flip()->get_vertical());
    nSlot->setTransformX((float) tClip->get_transform()->get_x());
    nSlot->setTransformY((float) tClip->get_transform()->get_y());
    nSlot->setTransformZ(tSeg->get_render_index());
    return CONVERT_RESULT_SUCCESS;
}

// 转场
static int32_t tmVideoTransitionToNLE(const std::shared_ptr<TemplateModel> &tModel,
                                      const std::shared_ptr<Segment> &tSeg,
                                      std::shared_ptr<NLETrackSlot> &nSlot) {
    const auto tTransition = getTemplateModelRefMaterial<MaterialTransition>(tModel,
                                                                             tSeg->get_extra_material_refs());
    if (isTmMaterialInvalid(tTransition) || tTransition->get_path().empty()) {
        return CONVERT_RESULT_SUCCESS;
    }

    auto nTransition = std::make_shared<NLESegmentTransition>();
    nTransition->setTransitionDuration(
            CutsameConvertUtils::cutsameToUs(tTransition->get_duration()));
    auto nRes = std::make_shared<NLEResourceAV>();
    nRes->setResourceFile(tTransition->get_path());
    nTransition->setOverlap(tTransition->get_is_overlap());
    nTransition->setEffectSDKTransition(nRes);
    nSlot->setEndTransition(nTransition);
    return CONVERT_RESULT_SUCCESS;
}

// 音效 音量、淡入淡出、变声
static int32_t tmAudioEffectToNLE(const std::shared_ptr<TemplateModel> &tModel,
                                  const std::shared_ptr<Segment> &tSeg,
                                  std::shared_ptr<NLESegmentAudio> &nSeg) {
    nSeg->setKeepTone(!tSeg->get_is_tone_modify()); // 变调
    nSeg->setVolume((float) tSeg->get_volume()); // 音量

    const auto tMatFade = getTemplateModelRefMaterial<MaterialAudioFade>(tModel,
                                                                         tSeg->get_extra_material_refs());
    if (!isTmMaterialInvalid(tMatFade)) {
        nSeg->setFadeInLength(
                CutsameConvertUtils::cutsameToUs(tMatFade->get_fade_in_duration())); // 淡入
        nSeg->setFadeOutLength(
                CutsameConvertUtils::cutsameToUs(tMatFade->get_fade_out_duration())); // 淡出
    }

    const auto tMatEffect = getTemplateModelRefMaterial<MaterialAudioEffect>(tModel,
                                                                             tSeg->get_extra_material_refs());
    if (!isTmMaterialInvalid(tMatEffect)) {
        auto nChanger = NLEAudioChanger::NONE;
        if (tMatEffect->get_name() == TM_AUDIO_CHANGER_NONE) {
            nChanger = NLEAudioChanger::NONE;
        } else if (tMatEffect->get_name() == TM_AUDIO_CHANGER_BOY) {
            nChanger = NLEAudioChanger::BOY;
        } else if (tMatEffect->get_name() == TM_AUDIO_CHANGER_GIRL) {
            nChanger = NLEAudioChanger::GIRL;
        } else if (tMatEffect->get_name() == TM_AUDIO_CHANGER_LOLI) {
            nChanger = NLEAudioChanger::LOLI;
        } else if (tMatEffect->get_name() == TM_AUDIO_CHANGER_UNCLE) {
            nChanger = NLEAudioChanger::UNCLE;
        } else if (tMatEffect->get_name() == TM_AUDIO_CHANGER_MONSTER) {
            nChanger = NLEAudioChanger::MONSTER;
        }
        nSeg->setChanger(nChanger);
    }
    return CONVERT_RESULT_SUCCESS;
}

// 音频
static int32_t tmAudioToNLE(const std::shared_ptr<TemplateModel> &tModel,
                            const std::shared_ptr<Segment> &tSeg,
                            std::shared_ptr<NLETrack> &nTrack,
                            std::shared_ptr<NLETrackSlot> &nSlot,
                            std::shared_ptr<NLESegmentAudio> &nSeg) {
    const auto tSourceTimeRange = tSeg->get_source_timerange();
    nSeg->setTimeClipStart(CutsameConvertUtils::cutsameToUs(tSourceTimeRange->get_start()));
    nSeg->setTimeClipEnd(
            CutsameConvertUtils::cutsameToUs(
                    tSourceTimeRange->get_start() + tSourceTimeRange->get_duration()));

    // res
    const auto tMatAudio = getTemplateModelMaterial<MaterialAudio>(tModel, tSeg->get_material_id());
    auto tResAV = std::make_shared<NLEResourceAV>();
    tResAV->setResourceFile(tMatAudio->get_path());
    tResAV->setResourceType(NLEResType::AUDIO);
    tResAV->setDuration(CutsameConvertUtils::cutsameToUs(tMatAudio->get_duration()));
    nSeg->setAVFile(tResAV);

    nSeg->setVolume((float) tSeg->get_volume());

    tmAudioEffectToNLE(tModel, tSeg, nSeg);
    tmSpeedToNLE(tModel, tSeg, nSeg);
    tmKeyFrameAudioToNLE(tModel, tSeg, nTrack, nSlot);
    return CONVERT_RESULT_SUCCESS;
}

// 视频
static int32_t tmVideoToNLE(const std::shared_ptr<TemplateModel> &tModel,
                            const std::shared_ptr<Segment> &tSeg,
                            std::shared_ptr<NLETrackSlot> &nSlot,
                            std::shared_ptr<NLESegmentVideo> &nSegVideo,
                            std::shared_ptr<NLETrack> &nTrack,
                            bool isMainTrack) {
    const auto tSourceTimeRange = tSeg->get_source_timerange();
    nSegVideo->setTimeClipStart(CutsameConvertUtils::cutsameToUs(tSourceTimeRange->get_start()));
    nSegVideo->setTimeClipEnd(
            CutsameConvertUtils::cutsameToUs(
                    tSourceTimeRange->get_start() + tSourceTimeRange->get_duration()));
    nSegVideo->setKeepTone(tSeg->get_is_tone_modify());

    const auto tMaterialVideo = getTemplateModelMaterial<MaterialVideo>(tModel,
                                                                        tSeg->get_material_id());

    auto nResAV = std::make_shared<NLEResourceAV>();
    if (tMaterialVideo->get_type() == TM_MATERIAL_TYPE_IMAGE) {
        nResAV->setResourceType(NLEResType::IMAGE);
    } else {
        nResAV->setResourceType(NLEResType::VIDEO);
    }

    nResAV->setResourceFile(CutsameConvertUtils::getPlayVideoPath(tSeg, tMaterialVideo));
    nResAV->setWidth(tMaterialVideo->get_width());
    nResAV->setHeight(tMaterialVideo->get_height());
    nResAV->setDuration(CutsameConvertUtils::cutsameToUs(tMaterialVideo->get_duration()));
    nSegVideo->setAVFile(nResAV);


    // canvas
    const auto tMaterialCanvas = getTemplateModelRefMaterial<MaterialCanvas>(tModel,
                                                                             tSeg->get_extra_material_refs());
    auto nCanvas = std::make_shared<NLEStyCanvas>();
    const auto tCanvasType = tMaterialCanvas->get_type();
    auto nCanvasType = NLECanvasType::COLOR;
    if (tCanvasType == TM_CANVAS_TYPE_COLOR) {
        nCanvasType = NLECanvasType::COLOR;
    } else if (tCanvasType == TM_CANVAS_TYPE_IMAGE) {
        nCanvasType = NLECanvasType::IMAGE;
    } else if (tCanvasType == TM_CANVAS_TYPE_BLUR) {
        nCanvasType = NLECanvasType::VIDEO_FRAME;
    } else {
        assert("canvas type not found");
    }
    nCanvas->setType(nCanvasType);
    // TODO: iOS 的剪同款在使用这个值时，会乘以16来赋值给VE，不知道Android是否一样
    // todo Android VE模糊共14档  是乘以14的 先按iOS乘16处理
    nCanvas->setBlurRadius(tMaterialCanvas->get_blur() * 16.f);
    const auto tCanvasColor = tMaterialCanvas->get_color();
    nCanvas->setColor(ConvertUtils::getColorArgb(tCanvasColor, ConvertUtils::BLACK()));
    nCanvas->setImage(
            NLEFactory::createNLEResourceNode(NLEResType::IMAGE, tMaterialCanvas->get_image()));
    nSegVideo->setCanvasStyle(nCanvas);
    // canvas

    // crop
    const auto &tCrop = tMaterialVideo->get_crop();
    auto nCrop = std::make_shared<NLEStyCrop>();

    nCrop->setXLeft(tCrop->get_upper_left_x());
    nCrop->setYUpper(tCrop->get_upper_left_y());

    nCrop->setXRightUpper(tCrop->get_upper_right_x());
    nCrop->setYRightUpper(tCrop->get_upper_right_y());

    nCrop->setXLeftLower(tCrop->get_lower_left_x());
    nCrop->setYLeftLower(tCrop->get_lower_left_y());

    nCrop->setXRight(tCrop->get_lower_right_x());
    nCrop->setYLower(tCrop->get_lower_right_y());

    nSegVideo->setCrop(nCrop);
    // crop

    tmClipToNLE(tSeg, nSlot);
    // 视频的scale = 素材scale * clip的scale
    nSlot->setScale(nSlot->getScale() * tMaterialVideo->get_crop_scale());
    nSlot->setRotation(
            ConvertUtils::getRotation(tSeg->get_clip()->get_rotation())); //转换NLE标准，正值为逆时针

    nSegVideo->setAlpha(tSeg->get_clip()->get_alpha());
    if (isMainTrack) {
        tmVideoTransitionToNLE(tModel, tSeg, nSlot); // just main track has transition
    }
    tmVideoEffectToNLE(tModel, tSeg, nSlot, nSegVideo);
    tmVideoMaskToNLE(tModel, tSeg, nSlot, tMaterialVideo);
    tmVideoChromaToNLE(tModel, tSeg, nSlot);

    auto nSegAudio = std::static_pointer_cast<NLESegmentAudio>(nSegVideo);
    tmAudioEffectToNLE(tModel, tSeg, nSegAudio);
    tmSpeedToNLE(tModel, tSeg, nSegAudio);
    tmVideoKeyFrameToNLE(tModel, tSeg, nTrack, nSlot, tMaterialVideo);

    const auto tMat = std::static_pointer_cast<Material>(tMaterialVideo);
    auto nNode = std::static_pointer_cast<NLENode>(nSegVideo);
    putCutSameInfo(tModel, tMat, nNode);
    return CONVERT_RESULT_SUCCESS;
}

// 贴纸动画
static int32_t tmStickerAnimToNLE(const std::shared_ptr<TemplateModel> &tModel,
                                  const std::shared_ptr<Segment> &tSeg,
                                  std::shared_ptr<NLESegmentSticker> &nSeg) {
    const auto tAnim = getTemplateModelRefMaterial<Animations>(tModel,
                                                               tSeg->get_extra_material_refs());
    if (isTmMaterialInvalid(tAnim)) {
        return CONVERT_RESULT_SUCCESS;
    }
    const auto tAnims = tAnim->get_animations();
    auto nAnim = std::make_shared<NLEStyStickerAnim>();
    for (const auto &anim : tAnims) {
        if (anim->get_type() == TM_ANIM_LOOP) {
            nAnim->setLoop(true);
            nAnim->setInAnim(NLEFactory::createNLEResourceNode(NLEResType::ANIMATION_STICKER,
                                                               anim->get_path()));
            nAnim->setInDuration(CutsameConvertUtils::cutsameToUs(anim->get_duration()));
        } else if (anim->get_type() == TM_ANIM_IN) {
            nAnim->setInAnim(NLEFactory::createNLEResourceNode(NLEResType::ANIMATION_STICKER,
                                                               anim->get_path()));
            nAnim->setInDuration(CutsameConvertUtils::cutsameToUs(anim->get_duration()));
        } else if (anim->get_type() == TM_ANIM_OUT) {
            nAnim->setOutAnim(NLEFactory::createNLEResourceNode(NLEResType::ANIMATION_STICKER,
                                                                anim->get_path()));
            nAnim->setOutDuration(CutsameConvertUtils::cutsameToUs(anim->get_duration()));
        }
    }
    nSeg->setAnimation(nAnim);
    return CONVERT_RESULT_SUCCESS;
}

// 信息化贴纸
static int32_t tmInfoStickerToNLE(const std::shared_ptr<TemplateModel> &tModel,
                                  const std::shared_ptr<Segment> &tSeg,
                                  const std::shared_ptr<MaterialSticker> &tMat,
                                  std::shared_ptr<NLETrack> &nTrack,
                                  std::shared_ptr<NLETrackSlot> &nSlot,
                                  std::shared_ptr<NLESegmentInfoSticker> &nSeg) {
    tmClipToNLE(tSeg, nSlot);
    nSlot->setRotation(
            ConvertUtils::getRotation(tSeg->get_clip()->get_rotation())); //转换NLE标准，正值为逆时针

    auto nSegSticker = std::static_pointer_cast<NLESegmentSticker>(nSeg);
    tmStickerAnimToNLE(tModel, tSeg, nSegSticker);

    auto nResSticker = std::make_shared<NLEResourceNode>();
    nResSticker->setResourceFile(tMat->get_path());
    nResSticker->setResourceId(tMat->get_resource_id()); // todo sticker not have effect id???
//    infoStringList.push_back(tMaterial->get_unicode()); // todo how to handle unicode
    nSeg->setEffectSDKFile(nResSticker); // todo 什么鬼名字

    tmKeyFrameStickerToNLE(tModel, tSeg, nTrack, nSlot);
    return CONVERT_RESULT_SUCCESS;
}

// 文本
static int32_t tmTextToNLE(const std::shared_ptr<TemplateModel> &tModel,
                           const std::shared_ptr<Segment> &tSeg,
                           const std::shared_ptr<MaterialText> &tMatText,
                           std::shared_ptr<NLETrack> &nTrack,
                           std::shared_ptr<NLETrackSlot> &nSlot,
                           std::shared_ptr<NLESegmentTextSticker> &nSegText) {
    tmClipToNLE(tSeg, nSlot);
    nSlot->setRotation(
            ConvertUtils::getRotation(tSeg->get_clip()->get_rotation())); //转换NLE标准，正值为逆时针

    auto nSegSticker = std::static_pointer_cast<NLESegmentSticker>(nSegText);
    tmStickerAnimToNLE(tModel, tSeg, nSegSticker);

    const auto tMatTextEffect = getTemplateModelMaterialEffect(
            tModel, tSeg->get_extra_material_refs(), TM_EFFECT_TYPE_TEXT_EFFECT);
    const auto tMatTextShape = getTemplateModelMaterialEffect(
            tModel, tSeg->get_extra_material_refs(), TM_EFFECT_TYPE_TEXT_SHAPE);

    nSegText->setContent(tMatText->get_content());

    auto nResTextSticker = std::make_shared<NLEResourceNode>();
    auto nStyText = std::make_shared<NLEStyText>();

    uint32_t textColor = ConvertUtils::getColorArgb(tMatText->get_text_color(),
                                                    ConvertUtils::WHITE());
    uint32_t textAlpha = (int) (tMatText->get_text_alpha() * 255);
    if (!tMatTextEffect->get_path().empty() || textAlpha > 255) {
        textAlpha = 255;
    }
    nStyText->setTextColor(textColor & 0x00FFFFFF | (textAlpha << 24));

    nStyText->setFontSize(tMatText->get_font_size());
    if (ConvertUtils::isValidColor(tMatText->get_background_color())) {
        uint32_t bgColor = ConvertUtils::getColorArgb(tMatText->get_background_color(),
                                                      ConvertUtils::TRANSPARENT());
        uint32_t bgColorAlpha = (int) (tMatText->get_background_alpha() * 255);
        if (bgColorAlpha > 255) {
            bgColorAlpha = 255;
        }
        nStyText->setBackgroundColor(bgColor & 0x00FFFFFF | (bgColorAlpha << 24));
        nStyText->setBackground(bgColorAlpha != 0);
    } else {
        nStyText->setBackground(false);
    }
    nStyText->setTypeSettingKind(tMatText->get_typesetting());
    nStyText->setAlignType(tMatText->get_alignment());

    nStyText->setShadow(tMatText->get_has_shadow());
    uint32_t shadowColor = ConvertUtils::getColorArgb(tMatText->get_shadow_color(),
                                                      ConvertUtils::TRANSPARENT());
    if (ConvertUtils::isValidColor(tMatText->get_shadow_color())) {
        uint32_t shadowAlpha = (int) (tMatText->get_shadow_alpha() * textAlpha) << 24;
        nStyText->setShadowColor(shadowColor & 0x00FFFFFF | shadowAlpha);
    }
    nStyText->setShadowSmoothing(tMatText->get_shadow_smoothing() / 18.0f); // 相对于 textSize=18 的比例

    Point *point = tMatText->get_shadow_point().get();
    double shadowOffsetX = point == nullptr ? 0 : point->get_x();
    double shadowOffsetY = point == nullptr ? 0 : point->get_y();
    nStyText->setShadowOffsetX(shadowOffsetX / 18.0f); // 相对于 textSize=18 的比例
    nStyText->setShadowOffsetY(shadowOffsetY / 18.0f); // 相对于 textSize=18 的比例

//    nStyText->setBold();   // todo cutsame无此字段
    nStyText->setBoldWidth((float) tMatText->get_bold_width());

    nStyText->setItalicDegree(tMatText->get_italic_degree());

    nStyText->setUnderline(tMatText->get_underline());
    nStyText->setUnderlineWidth((float) tMatText->get_underline_width());
    nStyText->setUnderlineOffset((float) tMatText->get_underline_offset());

    nStyText->setLineGap((float) tMatText->get_line_spacing());
    nStyText->setCharSpacing((float) tMatText->get_letter_spacing());

    bool outline = false;
    uint32_t outlineColor = ConvertUtils::getColorArgb(tMatText->get_border_color(),
                                                       ConvertUtils::TRANSPARENT());

    uint32_t borderAlpha = ConvertUtils::getColorAlpha(tMatText->get_border_color());
    if (ConvertUtils::isValidColor(tMatText->get_border_color())) {
        outline = textAlpha != 0 && borderAlpha != 0;

        // outline alpha 与 text 同步
        nStyText->setOutline(outline);
        // 剪同款是textAlpha * borderAlpha来作为outline color 的alpha值
        uint32_t mixAlpha = (uint32_t) ((textAlpha / 255.0) * (borderAlpha / 255.0) * 255.0);
        if (mixAlpha > 255) {
            mixAlpha = 255;
        }
        nStyText->setOutlineColor(outlineColor & 0x00FFFFFF | (mixAlpha << 24));
    }

    float outlineWidth = (float) tMatText->get_border_width();
    if (!outline) outlineWidth = 0.0f;
    nStyText->setOutlineWidth(outlineWidth);

    float innerPadding = 0.12f;
    if (tMatTextEffect->get_path().empty()) { innerPadding += outlineWidth; } else { innerPadding += 0.15f; }
    nStyText->setInnerPadding(innerPadding);

    // todo 这里可能有坑
//    float lineMaxWidth = 0.82f;
//    if (tMatText->get_type() == "text") lineMaxWidth = -1.0f;
    float lineMaxWidth = -1.0f;
    nStyText->setLineMaxWidth(lineMaxWidth);
    nStyText->setFont(NLEFactory::createNLEResourceNode(NLEResType::FONT,
                                                        getFontPathInDir(tMatText->get_font_path(),
                                                                         tModel->get_workspace()),
                                                        tMatText->get_font_resource_id()));

    nStyText->setFallbackFont(NLEFactory::createNLEResourceNode(NLEResType::FONT,
                                                                getFontPathInDir(
                                                                        tMatText->get_fallback_font_path(),
                                                                        tModel->get_workspace())));

    // todo fallbackFontList
//    if (!fallbackFontPathStr.empty()) {
//        try {
//            nlohmann::json fallbackFontPathJson = nlohmann::json::parse(fallbackFontPathStr);
//            if (fallbackFontPathJson.is_array()) {
//                for (auto &fontPath : fallbackFontPathJson.value().items()) {
//                    nStyText->getFallbackFontLists().push_back(NLEFactory::createNLEResourceNode(
//                            NLEResType::FONT,
//                            fontPath))
//                }
//            } else {
//                nStyText->setFallbackFont(NLEFactory::createNLEResourceNode(
//                        NLEResType::FONT,
//                        fallbackFontPathStr));
//            }
//        } catch (...) {
//        }
//    }

    nStyText->setShapeFlipX(tMatText->get_shape_clip_x());
    nStyText->setShapeFlipY(tMatText->get_shape_clip_y());

    if (ConvertUtils::isValidColor(tMatText->get_ktv_color())) {
        uint32_t ktvColor = ConvertUtils::getColorArgb(tMatText->get_ktv_color(),
                                                       ConvertUtils::TRANSPARENT()); // RGBA
        nStyText->setKTVColor(ktvColor);
        double ktvColorHsv[3];
        RGBConvertUtils::argbToHsv(ktvColor, ktvColorHsv);

        if (ConvertUtils::isValidColor(tMatText->get_shadow_color())) {
            double shadowColorHsv[3];
            RGBConvertUtils::argbToHsv(shadowColor, shadowColorHsv);
            shadowColorHsv[0] = (shadowColorHsv[0] + ktvColorHsv[0]) / 2.0;
            double ktvShadowColor[4] = {0, 0, 0, tMatText->get_shadow_alpha()};

            RGBConvertUtils::hsvToDoubleRgb(
                    shadowColorHsv[0],
                    shadowColorHsv[1],
                    shadowColorHsv[2],
                    ktvShadowColor);

            const std::vector<float> ktvShadowColorVector = std::vector<float>(ktvShadowColor,
                                                                               ktvShadowColor + 4);
            nStyText->setKTVShadowColorVector(ktvShadowColorVector);
        }

        if (ConvertUtils::isValidColor(tMatText->get_border_color())) {
            double outlineColorHsv[3];
            RGBConvertUtils::argbToHsv(outlineColor, outlineColorHsv);
            outlineColorHsv[0] = (outlineColorHsv[0] + ktvColorHsv[0]) / 2.0;

            double ktvOutlineColor[4] = {0, 0, 0, 1.0};
            RGBConvertUtils::hsvToDoubleRgb(
                    outlineColorHsv[0],
                    outlineColorHsv[1],
                    outlineColorHsv[2],
                    ktvOutlineColor);

            const std::vector<float> ktvOutlineColorVector = std::vector<float>(ktvOutlineColor,
                                                                                ktvOutlineColor +
                                                                                4);
            nStyText->setKTVOutlineColorVector(ktvOutlineColorVector);
        }
    }

    nStyText->setFlower(NLEFactory::createNLEResourceNode(NLEResType::FLOWER,
                                                          tMatTextEffect->get_path(),
                                                          tMatTextEffect->get_effect_id()));
    nStyText->setShape(NLEFactory::createNLEResourceNode(NLEResType::TEXT_SHAPE,
                                                         tMatTextShape->get_path(),
                                                         tMatTextShape->get_effect_id()));
    nStyText->setUseFlowerDefaultColor(tMatText->get_use_effect_default_color());

    // 是不是开启 一行自动截断模式，到达自动换行宽度后会自动截断文字并填充尾字符串
//    nStyText->setOneLineTruncated();    // todo cutsame无此字段
    // 自动截断时填充的尾字符串
//    nStyText->setTruncatedPostfix();    // todo cutsame无此字段

    nSegText->setStyle(nStyText);
    nSegText->setContent(tMatText->get_content());
    tmKeyFrameTextToNLE(tModel, tSeg, nTrack, nSlot);

    const auto tMat = std::static_pointer_cast<Material>(tMatText);
    auto nNode = std::static_pointer_cast<NLENode>(nSegText);
    putCutSameInfo(tModel, tMat, nNode);
    return CONVERT_RESULT_SUCCESS;
}

static std::string getFontPath(const std::string &fontDir) {
    if (fontDir.empty()) {
        return fontDir;
    }

    if (fontDir.find(".otf") != std::string::npos || fontDir.find(".ttf") != std::string::npos) {
        return fontDir;
    }

    DIR *dir = opendir(fontDir.c_str());
    if (dir == nullptr) {
        return "";
    }
    struct dirent *fileName;
    while ((fileName = readdir(dir)) != nullptr) {
        std::string tmpStr{fileName->d_name};
        std::string nameStr = std::string(fileName->d_name);
        std::transform(nameStr.begin(), nameStr.end(), nameStr.begin(),
                       [](unsigned char c) { return std::tolower(c); });
        if (nameStr.find(".otf") != std::string::npos ||
            nameStr.find(".ttf") != std::string::npos) {
            closedir(dir);
            return fontDir + "/" + tmpStr;
        }
    }

    closedir(dir);
    return "";
}

// 文字模板
static int32_t tmTextTemplateToNLE(const std::shared_ptr<TemplateModel> &tModel,
                                   const std::shared_ptr<Segment> &tSeg,
                                   const std::shared_ptr<MaterialTextTemplate> &tMatTemp,
                                   std::shared_ptr<NLETrackSlot> &nSlot,
                                   std::shared_ptr<NLESegmentTextTemplate> &nSegTemp) {
    tmClipToNLE(tSeg, nSlot);
    nSlot->setRotation((float) tSeg->get_clip()->get_rotation());//透传Effect 不需要转换
    nSegTemp->setEffectSDKFile(
            NLEFactory::createNLEResourceNode(NLEResType::TEXT_TEMPLATE, tMatTemp->get_path(),
                                              tMatTemp->get_effect_id()));
    for (const auto &tRes: tMatTemp->get_resources()) {
        if (tRes->get_panel() == "fonts") {
            nSegTemp->addFont(
                    NLEFactory::createNLEResourceNode(NLEResType::FONT,
                                                      getFontPath(tRes->get_path()),
                                                      tRes->get_resource_id()));
        } else {
            nSegTemp->addFont(
                    NLEFactory::createNLEResourceNode(NLEResType::FONT,
                                                      tRes->get_path(),
                                                      tRes->get_resource_id()));
        }
    }
    for (const auto &refId: tSeg->get_extra_material_refs()) {
        const auto &tMatText = getTemplateModelMaterial<MaterialText>(tModel, refId);
        if (isTmMaterialInvalid(tMatText)) {
            continue;
        }
        auto textClip = std::make_shared<NLETextTemplateClip>();
        textClip->setContent(tMatText->get_content());

        const auto tMat = std::static_pointer_cast<Material>(tMatText);
        auto nNode = std::static_pointer_cast<NLENode>(textClip);
        putCutSameInfo(tModel, tMat, nNode);

        nSegTemp->addTextClip(textClip);
    }
    return CONVERT_RESULT_SUCCESS;
}

// 图片贴纸 todo 剪同款image sticker也是用info sticker实现的 keyframe
static int32_t tmImageToNLE(const std::shared_ptr<TemplateModel> &tModel,
                            const std::shared_ptr<Segment> &tSeg,
                            const std::shared_ptr<MaterialImage> &tMat,
                            std::shared_ptr<NLETrackSlot> &nSlot,
                            std::shared_ptr<NLESegmentImageSticker> &nSeg) {
    tmClipToNLE(tSeg, nSlot);
    nSlot->setRotation(
            ConvertUtils::getRotation(tSeg->get_clip()->get_rotation())); //转换NLE标准，正值为逆时针
    // todo zouli 验证图片贴纸比例
    nSlot->setScale((float) tSeg->get_clip()->get_scale()->get_x() * tMat->get_initial_scale());

    auto nSegSticker = std::static_pointer_cast<NLESegmentSticker>(nSeg);
    tmStickerAnimToNLE(tModel, tSeg, nSegSticker);

    auto nRes = NLEFactory::createNLEResourceNode(NLEResType::IMAGE, tMat->get_path());
    nRes->setWidth(tMat->get_width());
    nRes->setHeight(tMat->get_height());
    nSeg->setImageFile(nRes);
    return CONVERT_RESULT_SUCCESS;
}

// 滤镜 全局
static int32_t tmFilterToNLE(const std::shared_ptr<TemplateModel> &tModel,
                             const std::shared_ptr<Segment> &tSeg,
                             const std::shared_ptr<MaterialEffect> &tMat,
                             std::shared_ptr<NLETrack> &nTrack,
                             std::shared_ptr<NLETrackSlot> &nSlot,
                             std::shared_ptr<NLESegmentFilter> &nSeg) {
    auto tRes = NLEFactory::createNLEResourceNode(NLEResType::FILTER, tMat->get_path(),
                                                  tMat->get_effect_id());
    tRes->setResourceName(tMat->get_name());
    nSeg->setEffectSDKFilter(tRes);
    nSeg->setIntensity((float) tMat->get_value());
    nSeg->setFilterName(tMat->get_type());
    tmFilterKeyFrameToNLE(tModel, tSeg, tMat, nTrack, nSlot);
    return CONVERT_RESULT_SUCCESS;
}

// 调节 全局 todo 比较特殊，会转换成N个轨道
static int32_t tmAdjustToNLE(const std::shared_ptr<TemplateModel> &tModel,
                             const std::shared_ptr<Segment> &tSeg,
                             const std::shared_ptr<MaterialPlaceholder> &tMat,
                             const std::shared_ptr<NLEModel> &nModel) {
    for (const auto &refId: tSeg->get_extra_material_refs()) { // todo 调节会有N个轨道
        const auto &tRefMaterial = getTemplateModelMaterial<MaterialEffect>(tModel, refId);
        auto tMatEffect = std::dynamic_pointer_cast<MaterialEffect>(tRefMaterial);
        if (tMatEffect == nullptr || isTmMaterialInvalid(tRefMaterial)) {
            continue;
        }

        auto nAdjustTrack = std::make_shared<NLETrack>();
        auto nNode = std::static_pointer_cast<NLENode>(nAdjustTrack);
        tagNLENodeCutSme(nNode);
        auto nSlot = std::make_shared<NLETrackSlot>();
        const auto &tTargetTimeRange = tSeg->get_target_timerange();
        nSlot->setStartTime(CutsameConvertUtils::cutsameToUs(tTargetTimeRange->get_start()));
        nSlot->setEndTime(CutsameConvertUtils::cutsameToUs(
                tTargetTimeRange->get_start() + tTargetTimeRange->get_duration()));
        auto tRes = NLEFactory::createNLEResourceNode(NLEResType::FILTER, tMatEffect->get_path(),
                                                      tMatEffect->get_effect_id());
        tRes->setResourceName(tMat->get_name());
        auto nSeg = std::make_shared<NLESegmentFilter>();
        nSeg->setFilterName(tMatEffect->get_type());
        nSeg->setEffectSDKFilter(tRes);
        nSeg->setIntensity((float) tMatEffect->get_value());
        nSlot->setMainSegment(nSeg);
        tmKeyFrameAdjustToNLE(tModel, tSeg, nAdjustTrack, nSlot, nSeg);
        nAdjustTrack->addSlot(nSlot);
        nModel->addTrack(nAdjustTrack);
    }
    return CONVERT_RESULT_SUCCESS;
}

// effect轨道太恶心了，单独处理一下，这里是主视频轨的effect，副轨见tmSubVideoEffectToNLE
static int32_t tmMainVideoEffectToNLE(const std::shared_ptr<TemplateModel> &tModel,
                                      const std::shared_ptr<Track> &tTrack,
                                      const std::shared_ptr<NLEModel> &nModel,
                                      std::shared_ptr<NLETrack> &nTrack) {
    if (tTrack->get_type() != TM_TRACK_TYPE_EFFECT) {
        return CONVERT_RESULT_SUCCESS;
    }

    for (const auto &tSegEffect: tTrack->get_segments()) {
        auto tMat = getTemplateModelMaterial<MaterialEffect>(tModel, tSegEffect->get_material_id());

        auto nSegEffect = std::make_shared<NLESegmentEffect>();
        nSegEffect->setEffectSDKEffect(
                NLEFactory::createNLEResourceNode(NLEResType::EFFECT, tMat->get_path(),
                                                  tMat->get_resource_id()));
        // 这个只需要保证唯一就可以了，做Key用，所以取id
        nSegEffect->setEffectName(tMat->get_id());
        for (auto adjustParam : tMat->get_adjust_params()) {
            auto info = std::make_shared<NLEStringFloatPair>();
            info->setFirst(adjustParam->get_name());
            info->setSecond(adjustParam->get_value());
            nSegEffect->addAdjustParams(info);
        }

        nSegEffect->setApplyTargetType(tMat->get_apply_target_type());
        auto targetStart = tSegEffect->get_target_timerange()->get_start();
        auto targetEnd = targetStart + tSegEffect->get_target_timerange()->get_duration();

        if (tMat->get_apply_target_type() == APPLY_TARGET_MAIN) { // 主轨特效
            auto nVideoEffect = std::make_shared<NLEVideoEffect>();
            nVideoEffect->setStartTime(CutsameConvertUtils::cutsameToUs(targetStart));
            nVideoEffect->setEndTime(CutsameConvertUtils::cutsameToUs(targetEnd));
            nVideoEffect->setLayer(tSegEffect->get_render_index());
            nVideoEffect->setSegment(nSegEffect);

            // 主轨特效挂在video的slot下面
            for (auto nSlot: nTrack->getSlots()) {
                if (nSlot->getStartTime() > nVideoEffect->getEndTime() ||
                    nSlot->getEndTime() < nVideoEffect->getStartTime()) {
                    continue;
                }
                nSlot->addVideoEffect(nVideoEffect);
            }
        } else if (tMat->get_apply_target_type() == APPLY_TARGET_ALL) { // 全局特效
            // 全局特效挂在单独slot下
            auto nEffectTrack = std::make_shared<NLETrack>();
            auto nNode = std::static_pointer_cast<NLENode>(nEffectTrack);
            tagNLENodeCutSme(nNode);
            auto nSlot = std::make_shared<NLETrackSlot>();
            nSlot->setStartTime(CutsameConvertUtils::cutsameToUs(targetStart));
            nSlot->setEndTime(CutsameConvertUtils::cutsameToUs(targetEnd));
            nSlot->setLayer(tSegEffect->get_render_index());
            nSlot->setMainSegment(nSegEffect);
            nEffectTrack->addSlot(nSlot);
            nModel->addTrack(nEffectTrack);
        }
    }

    return CONVERT_RESULT_SUCCESS;
}

static int32_t tmTrackToNLETrack(const std::shared_ptr<TemplateModel> &tModel,
                                 const std::shared_ptr<Track> &tTrack,
                                 const std::shared_ptr<NLEModel> &nModel,
                                 std::shared_ptr<NLETrack> &nTrack) {
    const auto &tSegs = tTrack->get_segments();
    for (const auto &tSeg : tSegs) {

        auto nSlot = std::make_shared<NLETrackSlot>();
        const auto &tTargetTimeRange = tSeg->get_target_timerange();
        nSlot->setStartTime(CutsameConvertUtils::cutsameToUs(tTargetTimeRange->get_start()));
        nSlot->setEndTime(CutsameConvertUtils::cutsameToUs(
                tTargetTimeRange->get_start() + tTargetTimeRange->get_duration()));
        nSlot->setLayer(tSeg->get_render_index());
        // segment
        int32_t result = CONVERT_RESULT_SUCCESS;
        std::shared_ptr<NLESegment> nSeg = nullptr;
        const auto &trackType = tTrack->get_type();
        if (trackType == TM_TRACK_TYPE_VIDEO) {
            if (tTrack->get_flag() == TM_TRACK_FLAG_MAIN_TRACK) {
                nTrack->setMainTrack(true);
            }
            auto nSegVideo = std::make_shared<NLESegmentVideo>();
            nSeg = nSegVideo;
            result = tmVideoToNLE(tModel, tSeg, nSlot, nSegVideo, nTrack,
                                  nTrack->hasMainTrack());

            // 存储原始路径
            if (nSegVideo->getExtra(EXTRA_KEY_CUTSAME_IS_MUTABLE) == TRUE) {
                const auto tMaterialVideo = getTemplateModelMaterial<MaterialVideo>(tModel,
                                                                                    tSeg->get_material_id());
                if (tMaterialVideo->get_path().size() > 0) {
                    nSlot->setExtra(EXTRA_KEY_ORIGIN_VIDEO_PATH, tMaterialVideo->get_path());
                }
            }
        } else if (trackType == TM_TRACK_TYPE_AUDIO) {
            auto nSegAudio = std::make_shared<NLESegmentAudio>();
            result = tmAudioToNLE(tModel, tSeg, nTrack, nSlot, nSegAudio);
            nSeg = nSegAudio;
        } else if (trackType == TM_TRACK_TYPE_STICKER) { // sticker text image
            const auto tMat = getTemplateModelMaterial<MaterialSticker>(tModel,
                                                                        tSeg->get_material_id());
            if (isTmMaterialInvalid(tMat)) {
                const auto tMatText = getTemplateModelMaterial<MaterialText>(tModel,
                                                                             tSeg->get_material_id());
                if (isTmMaterialInvalid(tMatText)) {
                    const auto tMatImage = getTemplateModelMaterial<MaterialImage>(tModel,
                                                                                   tSeg->get_material_id());
                    if (isTmMaterialInvalid(tMatImage)) {
                        const auto tMatTextTemplate = getTemplateModelMaterial<MaterialTextTemplate>(
                                tModel,
                                tSeg->get_material_id());
                        if (isTmMaterialInvalid(tMatTextTemplate)) {
                            throw "invalid type sticker";
                        } else {
                            auto nSegTextTemplate = std::make_shared<NLESegmentTextTemplate>();
                            nSeg = nSegTextTemplate;
                            result = tmTextTemplateToNLE(tModel, tSeg, tMatTextTemplate, nSlot,
                                                         nSegTextTemplate);
                        }
                    } else {
                        auto nSegImage = std::make_shared<NLESegmentImageSticker>();
                        nSeg = nSegImage;
                        result = tmImageToNLE(tModel, tSeg, tMatImage, nSlot, nSegImage);
                    }
                } else {
                    auto nSegText = std::make_shared<NLESegmentTextSticker>();
                    nSeg = nSegText;
                    result = tmTextToNLE(tModel, tSeg, tMatText, nTrack, nSlot, nSegText);
                }
            } else {
                auto nSegSticker = std::make_shared<NLESegmentInfoSticker>();
                nSeg = nSegSticker;
                result = tmInfoStickerToNLE(tModel, tSeg, tMat, nTrack, nSlot, nSegSticker);
            }
        } else if (trackType == TM_TRACK_TYPE_FILTER) { // global adjust/filter
            const auto tMatEffect = getTemplateModelMaterial<MaterialEffect>(tModel,
                                                                             tSeg->get_material_id()); // 滤镜
            if (isTmMaterialInvalid(tMatEffect)) {
                const auto tMatPlace = getTemplateModelMaterial<MaterialPlaceholder>(tModel,
                                                                                     tSeg->get_material_id()); // 调节
                if (isTmMaterialInvalid(tMatPlace)) {
                    throw "invalid type filter";
                } else {
                    result = tmAdjustToNLE(tModel, tSeg, tMatPlace, nModel);
                }
            } else {
                auto nSegFilter = std::make_shared<NLESegmentFilter>();
                result = tmFilterToNLE(tModel, tSeg, tMatEffect, nTrack, nSlot, nSegFilter);
                nSeg = nSegFilter;
            }
        } else {
            LOGGER->w("TMNLEC: unknown track");
        }

        if (nSeg != nullptr) {
            nSlot->setMainSegment(nSeg);
        }
        // segment

        if (!isCovertSuccess(result)) {
            convertFailClearSlot(nTrack);
            return result;
        }
        if (nSlot->getMainSegment() != nullptr) {
            nTrack->addSlot(nSlot);
        }
    }
    return CONVERT_RESULT_SUCCESS;
}

#endif //TEMPLATECONSUMERAPP_CUTSAMECONSUMERCONVERT_H
