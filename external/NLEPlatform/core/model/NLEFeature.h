//
// Created by bytedance on 2020/9/10.
//

#ifndef NLEPLATFORM_MODEL_NLEFEATURE_H
#define NLEPLATFORM_MODEL_NLEFEATURE_H

#include "nle_export.h"
#include <string>
#include <unordered_set>
#include <vector>

namespace cut::model {

    using TNLEFeature = std::string;

    class NLE_EXPORT_CLASS TNLEFeatureUnit {
    public:
        TNLEFeatureUnit(const TNLEFeature &feature);
        ~TNLEFeatureUnit() = default;
    };
    #define NLE_FEATURE_DEFINE(F_NAME, F_VALUE) \
        inline static const TNLEFeature F_NAME = F_VALUE; \
        const TNLEFeatureUnit _TNLEFeatureUnit_##F_NAME = TNLEFeatureUnit(F_VALUE);

    class NLE_EXPORT_CLASS NLEFeature {
    public:
        // E project setup, the first VE-Public-API ability. Feature E.
        NLE_FEATURE_DEFINE(E, "E");//0
        NLE_FEATURE_DEFINE(TIME_SPACE_SPEED, "TSS");//1
        NLE_FEATURE_DEFINE(MV, "MV");//2
        NLE_FEATURE_DEFINE(ALGORITHM, "ALGORITHM");//3
        /**
         * NLEStyCrop支持指定4个点
         */
        NLE_FEATURE_DEFINE(CROP_4, "CROP_4");//4
        /**
         * 画布框
         */
        NLE_FEATURE_DEFINE(CANVAS_BORDER, "CB0");//5
        /**
         * 在NLEModel中记录短视频封面数据
         */
        NLE_FEATURE_DEFINE(VIDEO_FRAME_MODEL, "VFM");//6
        /**
         * 支持记录曲线变速Ui锚点数据
         */
        NLE_FEATURE_DEFINE(SEGMENT_CURVE_SPEED, "SCS");//7
        /**
         * 支持虚拟人效果
         */
        NLE_FEATURE_DEFINE(BRICK_EFFECT, "BR_EF");//8

        /**
         * 特效调节参数
         */
        NLE_FEATURE_DEFINE(EFFECT_ADJUST_PARAMS, "EAP");//9
        
        /*
         * One Key HDR新参数
         */
        NLE_FEATURE_DEFINE(ONE_KEY_HDR, "OKH");//10

        /**
         * Processor 字段
         */
        NLE_FEATURE_DEFINE(PROCESSOR, "PRC");//11
        
        // 画布对齐模式
        NLE_FEATURE_DEFINE(ALIGN_MODE, "ALIGN");//12

        /**
         * 空间裁剪，-1到1坐标系，右上为正
         */
        NLE_FEATURE_DEFINE(CLIP, "CLIP");//13

        /// ***** 以下为模板方向定义的feature
        /**
         * 基础模板
         */
        NLE_FEATURE_DEFINE(TBASE, "T_Base");//14

        NLE_FEATURE_DEFINE(COLOR_FILTER, "COF");//15
        
        /*
         * 调整关键帧数据结构  NLETrack -> NLETrackSlot
         */
        NLE_FEATURE_DEFINE(KEYFRAME, "SLOT_KEYFRAME");//16
        
        //注意：新增feature一定要加在最后，不能插入在中间！！！@huangyong.way


        // check support or not
        static bool support(const std::unordered_set<TNLEFeature> &features);

        static std::vector<TNLEFeature> getOrderedFeatures();

        static const std::unordered_set<TNLEFeature> SUPPORT_FEATURES;

        static std::vector<TNLEFeature> ORDERED_FEATURES;
    };
}

#endif //NLEPLATFORM_MODEL_NLEFEATURE_H
