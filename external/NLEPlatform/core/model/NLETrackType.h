//
// Created by bytedance on 2020/6/8.
//

#ifndef NLEPLATFORM_NLETRACKTYPE_H
#define NLEPLATFORM_NLETRACKTYPE_H

#include "nle_export.h"

namespace cut::model {

    enum NLE_EXPORT_CLASS class NLETrackType {
        NONE = 0,       ///< 空/未知/占位
        AUDIO = 1,      ///< 音频
        VIDEO = 2,      ///< 视频
        STICKER = 3,    ///< 贴纸
        EFFECT = 4,     ///< 特效
        FILTER = 5,     ///< 全局滤镜
        IMAGE = 6, ///< 图片编辑
        MV = 7         ///< MV轨
    };

    constexpr const char *NLETrackTypeToString(const NLETrackType &type) {
        switch (type) {
            default:
            case NLETrackType::NONE:
                return "NONE";
            case NLETrackType::AUDIO:
                return "AUDIO";
            case NLETrackType::VIDEO:
                return "VIDEO";
            case NLETrackType::STICKER:
                return "STICKER";
            case NLETrackType::EFFECT:
                return "EFFECT";
            case NLETrackType::FILTER:
                return "FILTER";
            case NLETrackType::MV:
                return "MV";
        }
    }
}

#endif //NLEPLATFORM_NLETRACKTYPE_H
