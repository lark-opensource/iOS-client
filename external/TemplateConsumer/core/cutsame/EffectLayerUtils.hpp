#ifndef TEMPLATECONSUMERAPP_EFFECTLAYERUTILS_H
#define TEMPLATECONSUMERAPP_EFFECTLAYERUTILS_H

#include <cstdint>
#include <string>
#include "CutSameConsumerConst.hpp"

namespace TemplateConsumer {
    const static int32_t INDEX_STEP_ADJUST_BRIGHTNESS = 0;
    const static int32_t INDEX_STEP_ADJUST_CONTRAST = 1;
    const static int32_t INDEX_STEP_ADJUST_SATURATION = 2;
    const static int32_t INDEX_STEP_ADJUST_SHARP = 3;
    const static int32_t INDEX_STEP_ADJUST_HIGHLIGHT = 4;
    const static int32_t INDEX_STEP_ADJUST_SHADOW = 5;
    const static int32_t INDEX_STEP_ADJUST_COLOR_TEMPERATURE = 6;
    const static int32_t INDEX_STEP_ADJUST_HUE = 7;
    const static int32_t INDEX_STEP_ADJUST_FADE = 8;
    const static int32_t INDEX_STEP_ADJUST_LIGHT_SENSATION = 9;
    const static int32_t INDEX_STEP_ADJUST_TYPE_VIGNETTING = 10;
    const static int32_t INDEX_STEP_ADJUST_PARTICLE = 11;

    const static int32_t INDEX_RESHAPE_START = 5000;
    const static int32_t INDEX_CHROMA_START = 5500;
    const static int32_t INDEX_ADJUST_START = 6000;
    const static int32_t INDEX_GLOBAL_ADJUST_START = 7000;
    const static int32_t INDEX_BEAUTY_START = 8000;
    const static int32_t INDEX_FILTER_START = 9000;
    const static int32_t INDEX_GLOBAL_FILTER_START = 10000;
    const static int32_t INDEX_VIDEO_EFFECT_START = 11000;
    const static int32_t INDEX_VIDEO_MASK_START = 12000;

    const static int32_t INDEX_GLOBAL_ADJUST_RANGE = 9;

    static int32_t getAdjustIndex(const std::string &type) {
        int32_t index;
        if (type == TM_MATERIAL_TYPE_BRIGHTNESS) {
            index = INDEX_STEP_ADJUST_BRIGHTNESS;
        } else if (type == TM_MATERIAL_TYPE_CONTRAST) {
            index = INDEX_STEP_ADJUST_CONTRAST;
        } else if (type == TM_MATERIAL_TYPE_SATURATION) {
            index = INDEX_STEP_ADJUST_SATURATION;
        } else if (type == TM_MATERIAL_TYPE_SHARPENING) {
            index = INDEX_STEP_ADJUST_SHARP;
        } else if (type == TM_MATERIAL_TYPE_HIGHLIGHT) {
            index = INDEX_STEP_ADJUST_HIGHLIGHT;
        } else if (type == TM_MATERIAL_TYPE_SHADOW) {
            index = INDEX_STEP_ADJUST_SHADOW;
        } else if (type == TM_MATERIAL_TYPE_COLOR_TEMPERATURE) {
            index = INDEX_STEP_ADJUST_COLOR_TEMPERATURE;
        } else if (type == TM_MATERIAL_TYPE_HUE) {
            index = INDEX_STEP_ADJUST_HUE;
        } else if (type == TM_MATERIAL_TYPE_FADE) {
            index = INDEX_STEP_ADJUST_FADE;
        } else if (type == TM_MATERIAL_TYPE_LIGHT_SENSATION) {
            index = INDEX_STEP_ADJUST_LIGHT_SENSATION;
        } else if (type == TM_MATERIAL_TYPE_VIGNETTING) {
            index = INDEX_STEP_ADJUST_TYPE_VIGNETTING;
        } else if (type == TM_MATERIAL_TYPE_PARTICLE) {
            index = INDEX_STEP_ADJUST_PARTICLE;
        } else {
            index = 0;
        }

        return INDEX_ADJUST_START + index;
    }
}

#endif /* TEMPLATECONSUMERAPP_EFFECTLAYERUTILS_H */