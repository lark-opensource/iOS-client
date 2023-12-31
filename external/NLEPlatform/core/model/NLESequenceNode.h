//
// Created by bytedance on 2020/5/28.
//

#ifndef NLEPLATFORM_SEQUENCE_NODE_H
#define NLEPLATFORM_SEQUENCE_NODE_H

#include <string>
#include <sstream>
#include <map>
#include <memory>
#include <vector>

#include "nle_export.h"
#include "NLENode.h"
#include "NLEStyle.h"
#include "NLEResourceNode.h"
#include "NLEResType.h"
#include "NLETrackType.h"
#include "NLENodeDecoder.h"
#include "NLEAnimationType.h"


namespace cut::model {
struct NLESize {
    float width;
    float height;

    NLESize (float w, float h): width(w), height(h) { }

    std::string debug() const {
        return "NLESize { width: " + std::to_string(this->width) + ", height: " + std::to_string(this->height) + " }";
    }

    bool valid() {
        return (this->width > 0) && (this->height > 0);
    }
};

class NLETrackSlot;
    /**
     * NLETrackSlot 是全局时空坐标：基于全局的时间轴坐标, 基于全局的画布坐标，平移缩放旋转镜像等等；
     * NLESegment 是模型自身坐标：基于模型自身的裁剪等等；
     */
    class NLE_EXPORT_CLASS NLESegment : public NLENode {
    KEY_FUNCTION_DEC_OVERRIDE(NLESegment)

    public:

        /**
         * 有一些Segment有duration（比如：视频，音频，转场）
         * 有一些Segment没有duration（比如：滤镜，图片贴纸）
         */
        virtual NLETime getDuration() const {
            auto resource = getResource();
            if (resource) {
                return resource->getDuration();
            }
            return NLETimeMax;
        }

        /**
         * 有一些Segment有Resource（比如：视频，特效）
         * 有一些Segment没有Resource（比如：文本贴纸，Emoji贴纸）
         */
        virtual std::shared_ptr<NLEResourceNode> getResource() const { return nullptr; }

        virtual NLEResType getType() const {
            auto resource = getResource();
            if (resource) {
                return resource->getResourceType();
            }
            return NLEResType::NONE;
        }
    };

    /**
     * MV模板分辨率枚举类 默认不关心这个参数
     */
    enum class NLESegmentMVResolution : int32_t {
        RES_720P = 0,
        RES_1080P = 1
    };

    enum class NLESegmentMVResultInType : int32_t {
        TYPE_IMAGE = 0,
        TYPE_VIDEO = 1,
        TYPE_JSON = 2
    };

    /**
     * MV背景分割走服务端Effect接口 {@link #initMV(String, String[], String[])}之后调用
     * VEEditor.java # setExternalAlgorithmResult(String photoPath, String algorithmType, String result, VEMVAlgorithmConfig.MV_REESULT_IN_TYPE type)
     */
    class NLE_EXPORT_CLASS NLEMVExternalAlgorithmResult : public NLENode {
    NLENODE_RTTI(NLEMVExternalAlgorithmResult);
    NLE_PROPERTY_OBJECT(NLEMVExternalAlgorithmResult, Photo, NLEResourceNode, NLEFeature::MV) ///<原图

    NLE_PROPERTY_DEC(NLEMVExternalAlgorithmResult, AlgorithmName, std::string, std::string(), NLEFeature::MV) ///<hair,background……

    NLE_PROPERTY_OBJECT(NLEMVExternalAlgorithmResult, Mask, NLEResourceNode, NLEFeature::MV) ///<mask文件的存储地址

    NLE_PROPERTY_DEC(NLEMVExternalAlgorithmResult, ResultInType, int32_t, 0, NLEFeature::MV) ///<资源类型
    };

    /**
     * MV模式参数内容集合
     */
    class NLE_EXPORT_CLASS NLESegmentMV : public NLESegment {
    NLENODE_RTTI(NLESegmentMV);
    KEY_FUNCTION_DEC_OVERRIDE(NLESegmentMV)

    public:
        static const std::string TYPE_IMAGE;
        static const std::string TYPE_VIDEO;
        static const std::string TYPE_AUDIO;
        static const std::string TYPE_TEXT;
        static const std::string TYPE_GIF;
        static const std::string TYPE_BGIMG;
        static const std::string TYPE_RGBA;

    NLE_PROPERTY_OBJECT(NLESegmentMV, SourceFile, NLEResourceNode, NLEFeature::MV) ///<用户资源

    NLE_PROPERTY_DEC(NLESegmentMV, SourceFileType, std::string, std::string(), NLEFeature::MV) ///<用户资源对应的类型, TYPE_IMAGE / TYPE_VIDEO / TYPE_RGBA

    NLE_PROPERTY_DEC(NLESegmentMV, Volume, float, 1.0f, NLEFeature::MV) ///<原音量=1.0f, 静音=0.0f

    NLE_PROPERTY_DEC(NLESegmentMV, TimeClipStart, NLETime, 0, NLEFeature::MV) ///<起始时间

    NLE_PROPERTY_DEC(NLESegmentMV, TimeClipEnd, NLETime, 0, NLEFeature::MV) ///<结束时间

    NLE_PROPERTY_DEC(NLESegmentMV, Width, uint32_t, 0, NLEFeature::MV) ///<MV素材分辨率 [rgba模式用]

    NLE_PROPERTY_DEC(NLESegmentMV, Height, uint32_t, 0, NLEFeature::MV) ///<MV素材分辨率 [rgba模式用]

    NLE_PROPERTY_OBJECT(NLESegmentMV, Crop, NLEStyCrop, NLEFeature::MV) /**< @deprecated 空间裁剪 (0,1)坐标系，右下为正，已废弃，请使用Clip*/
    NLE_PROPERTY_OBJECT(NLESegmentMV, Clip, NLEStyClip, NLEFeature::CLIP) /**< 空间裁剪 (-1,1)坐标系，右上为正*/

    public:
        std::shared_ptr<NLEResourceNode> getResource() const override {
            return getSourceFile();
        }
    };

    /**
     * 对应 EffectSDK 视频动画
     */
    class NLE_EXPORT_CLASS NLESegmentVideoAnimation : public NLESegment {
    NLENODE_RTTI(NLESegmentVideoAnimation);
    KEY_FUNCTION_DEC_OVERRIDE(NLESegmentVideoAnimation)

    NLE_PROPERTY_OBJECT(NLESegmentVideoAnimation, EffectSDKVideoAnimation, NLEResourceNode, NLEFeature::E)

    NLE_PROPERTY_DEC(NLESegmentVideoAnimation, AnimationDuration, NLETime, 0, NLEFeature::E)

    public:
        NLETime getDuration() const override {
            return getAnimationDuration();
        }

        std::shared_ptr<NLEResourceNode> getResource() const override {
            return getEffectSDKVideoAnimation();
        }
    };



    /**
     * 卡点场景。
     * 图片[视频]Scale动画。由于这个动画不需要设置时间，因此没有挂在NLETrackSlot[NLETimeSpaceNode]上，而是作为NLESegmentVideo的成员属性。
     */
    class NLE_EXPORT_CLASS NLESegmentImageVideoAnimation : public NLESegmentVideoAnimation {
    NLENODE_RTTI(NLESegmentImageVideoAnimation);
    KEY_FUNCTION_DEC_OVERRIDE(NLESegmentImageVideoAnimation);

    NLE_PROPERTY_DEC(NLESegmentImageVideoAnimation, BeginScale, float, 1.0f, NLEFeature::E) ///<卡点场景。图片[视频]Scale动画，开始时间的scale大小。如果BeginScale < EndScale，效果上是Zoom In；如果BeginScale > EndScale， 效果上是Zoom Out。

    NLE_PROPERTY_DEC(NLESegmentImageVideoAnimation, EndScale, float, 1.0f, NLEFeature::E) ///<卡点场景。图片[视频]Scale动画，结束时间的scale大小。如果BeginScale < EndScale，效果上是Zoom In；如果BeginScale > EndScale， 效果上是Zoom Out。
    };

    /**
     * 蒙板（类似于PhotoShop中的蒙板）
     */
    class NLE_EXPORT_CLASS NLESegmentMask : public NLESegment {
    NLENODE_RTTI(NLESegmentMask);
    KEY_FUNCTION_DEC_OVERRIDE(NLESegmentMask)

    NLE_PROPERTY_DEC(NLESegmentMask, AspectRatio, float, 1.0f, NLEFeature::E)

    NLE_PROPERTY_DEC(NLESegmentMask, CenterX, float, 0.0f, NLEFeature::E)

    NLE_PROPERTY_DEC(NLESegmentMask, CenterY, float, 0.0f, NLEFeature::E)

    NLE_PROPERTY_DEC(NLESegmentMask, Feather, float, 0.0f, NLEFeature::E)

    NLE_PROPERTY_DEC(NLESegmentMask, Width, float, 0.0f, NLEFeature::E)

    NLE_PROPERTY_DEC(NLESegmentMask, Height, float, 0.0f, NLEFeature::E)

    NLE_PROPERTY_DEC(NLESegmentMask, Rotation, float, 0.0f, NLEFeature::E)

    NLE_PROPERTY_DEC(NLESegmentMask, RoundCorner, float, 0.0f, NLEFeature::E)

    NLE_PROPERTY_DEC(NLESegmentMask, Invert, bool, false, NLEFeature::E)

    NLE_PROPERTY_DEC(NLESegmentMask, MaskType, std::string, std::string(), NLEFeature::E)

    NLE_PROPERTY_OBJECT(NLESegmentMask, EffectSDKMask, NLEResourceNode, NLEFeature::E)

    public:
        std::shared_ptr<NLEResourceNode> getResource() const override {
            return getEffectSDKMask();
        }

        std::string toEffectJson(const std::shared_ptr<NLETrackSlot>& slot) const;
    };

    /**
     * 色度抠图（类似于PhotoShop中的通道）
     */
    class NLE_EXPORT_CLASS NLESegmentChromaChannel : public NLESegment {
    NLENODE_RTTI(NLESegmentChromaChannel);
    KEY_FUNCTION_DEC_OVERRIDE(NLESegmentChromaChannel)

    NLE_PROPERTY_DEC(NLESegmentChromaChannel, Color, uint32_t , 0, NLEFeature::E)

    NLE_PROPERTY_DEC(NLESegmentChromaChannel, Intensity, float, 0.0f, NLEFeature::E)

    NLE_PROPERTY_DEC(NLESegmentChromaChannel, Shadow, float, 0.0f, NLEFeature::E)

    NLE_PROPERTY_OBJECT(NLESegmentChromaChannel, EffectSDKChroma, NLEResourceNode, NLEFeature::E)

    public:
        std::shared_ptr<NLEResourceNode> getResource() const override {
            return getEffectSDKChroma();
        }
    };

    /**
     * 单点滤镜 / 全局滤镜 / 调节 / 亮度值，对比度，饱和度，锐化，高光，色温
     */
    class NLE_EXPORT_CLASS NLESegmentFilter : public NLESegment {
    NLENODE_RTTI(NLESegmentFilter);
    KEY_FUNCTION_DEC_OVERRIDE(NLESegmentFilter)

    NLE_PROPERTY_DEC(NLESegmentFilter, Intensity, float, 1.0f, NLEFeature::E) /**< 滤镜强度，亮度值，对比度，饱和度，锐化，高光，色温 */

    NLE_PROPERTY_DEC(NLESegmentFilter, RightIntensity, float, 1.0f, NLEFeature::COLOR_FILTER) /**< 右滤镜强度，滤镜分屏时使用 */

    NLE_PROPERTY_DEC(NLESegmentFilter, FilterName, std::string, std::string(), NLEFeature::E)  /**< NLEFilterName */

    NLE_PROPERTY_DEC(NLESegmentFilter, UseFilterV3, bool, false, NLEFeature::COLOR_FILTER)  /**< Use effect v3 engine. */

    NLE_PROPERTY_DEC(NLESegmentFilter, FilterPosition, float, 0.0f, NLEFeature::COLOR_FILTER)  /**< 滤镜分屏百分比. */

    NLE_PROPERTY_OBJECT(NLESegmentFilter, EffectSDKFilter, NLEResourceNode, NLEFeature::E)

    NLE_PROPERTY_OBJECT(NLESegmentFilter, RightFilter, NLEResourceNode, NLEFeature::COLOR_FILTER) /**< 右滤镜，滤镜分屏的时候使用，EffectSDKFilter存的是左滤镜 */

    public:
        std::shared_ptr<NLEResourceNode> getResource() const override {
            return getEffectSDKFilter();
        }
    };

    /**
     * Composer 滤镜、美颜
     */
    class NLE_EXPORT_CLASS NLESegmentComposerFilter: public NLESegmentFilter {
        NLENODE_RTTI(NLESegmentComposerFilter);
        KEY_FUNCTION_DEC_OVERRIDE(NLESegmentComposerFilter)

        NLE_PROPERTY_DEC(NLESegmentComposerFilter, NodePaths, std::vector<std::string>, std::vector<std::string>(), NLEFeature::E)

        NLE_PROPERTY_OBJECT_LIST(NLESegmentComposerFilter, EffectNodeKeyValuePair, NLEStringFloatPair, NLEFeature::E) /**< pair示例: key = "intensity", value = 0.6f */

        NLE_PROPERTY_DEC(NLESegmentComposerFilter, EffectTags, std::vector<std::string>, std::vector<std::string>(), NLEFeature::E) /**< 通常将服务端下发的extra字段设给EffectTags，EffectTags数组长度通常为1*/
    };

    /**
     * HDR
     */
    class NLE_EXPORT_CLASS NLESegmentHDRFilter: public NLESegmentFilter {
    NLENODE_RTTI(NLESegmentHDRFilter);
    KEY_FUNCTION_DEC_OVERRIDE(NLESegmentHDRFilter)

    NLE_PROPERTY_DEC(NLESegmentHDRFilter, FilePath, std::string, std::string(), NLEFeature::E) /**< 新算法模型, 需要的文件路径 */

    NLE_PROPERTY_DEC(NLESegmentHDRFilter, FrameType, int32_t, -1, NLEFeature::E) /**< 抽帧类型 */

    NLE_PROPERTY_DEC(NLESegmentHDRFilter, Denoise, bool, false, NLEFeature::E) /**< 是否降噪 */

    NLE_PROPERTY_DEC(NLESegmentHDRFilter, AsfMode, int32_t, 0, NLEFeature::ONE_KEY_HDR) /**< OneKeyHDR场景下使用。 0：代表开启锐化，1：代表在20004夜景时关闭锐化，2：代表在非20004的情况下关闭锐化，3：代表关闭锐化*/

    NLE_PROPERTY_DEC(NLESegmentHDRFilter, HdrMode, int32_t, 0, NLEFeature::ONE_KEY_HDR) /**< OneKeyHDR场景下使用。 0：代表所有场景开启HDR，1：代表在20001时关闭HDR，2：代表在20001或20003关闭HDR，3：代表在20004关闭HDR，4：所有case情况关闭HDR */
    };


    /**
     * 音频滤镜: Loudness Balance
     */
    class NLE_EXPORT_CLASS NLESegmentAudioLoudnessBalanceFilter: public NLESegmentFilter {
    NLENODE_RTTI(NLESegmentAudioLoudnessBalanceFilter);
    KEY_FUNCTION_DEC_OVERRIDE(NLESegmentAudioLoudnessBalanceFilter)

    NLE_PROPERTY_DEC(NLESegmentAudioLoudnessBalanceFilter, AvgLoudness, double, 0.0, NLEFeature::E) ///< avg loudness

    NLE_PROPERTY_DEC(NLESegmentAudioLoudnessBalanceFilter, PeakLoudness, double, 0.0, NLEFeature::E) ///< peak loudness

    NLE_PROPERTY_DEC(NLESegmentAudioLoudnessBalanceFilter, TargetLoudness, double, 0.0, NLEFeature::E) ///< target loudness, need set by user
    };


    /**
     * 音频滤镜: Volume Filter
     * NLESegment::Volume这个字段控制VideoSlot或AudioSlot(一般情况单个AudioSlot构成一条AudioTrack)的整体音量。
     * VolumeFilter挂在Track上，精确控制Track上任意出入点的音量。
     */
    class NLE_EXPORT_CLASS NLESegmentAudioVolumeFilter: public NLESegmentFilter {
    NLENODE_RTTI(NLESegmentAudioVolumeFilter);
    KEY_FUNCTION_DEC_OVERRIDE(NLESegmentAudioVolumeFilter)

    NLE_PROPERTY_DEC(NLESegmentAudioVolumeFilter, Volume, float, 1.0f, NLEFeature::E) /**< 原音量=1.0f, 静音=0.0f */
    };

    /**
     * 音频片段
     */
    class NLE_EXPORT_CLASS NLESegmentAudio : public NLESegment {
    NLENODE_RTTI(NLESegmentAudio);
    KEY_FUNCTION_DEC_OVERRIDE(NLESegmentAudio)

    NLE_PROPERTY_DEC(NLESegmentAudio, FadeInLength, NLETime, 0, NLEFeature::E) /**< 淡入 */

    NLE_PROPERTY_DEC(NLESegmentAudio, FadeOutLength, NLETime, 0, NLEFeature::E) /**< 淡出 */

    NLE_PROPERTY_DEC(NLESegmentAudio, Volume, float, 1.0f, NLEFeature::E) /**< 原音量=1.0f, 静音=0.0f */

    NLE_PROPERTY_DEC(NLESegmentAudio, TimeClipStart, NLETime, -1, NLEFeature::E) /**< Resource时间坐标-起始点, 单位微秒 1s=1000000us */

    NLE_PROPERTY_DEC(NLESegmentAudio, TimeClipEnd, NLETime, -1, NLEFeature::E) /**< Resource时间坐标-终止点, 单位微秒 1s=1000000us */

        /**
         *
         * "常规变速"的参数值，正值表示正播，负值表示倒播，绝对值表示速率倍数；
         * 比如：Speed=2.0f表示两倍速播放；Speed=-3.0f表示三倍速倒放；
         * 有相应的简便函数：setAbsSpeed, getAbsSpeed, setRewind, getRewind；
         *
         * 此参数与曲线变速无关；此参数与曲线变速参数同时"叠加"作用；
         *
         */
    NLE_PROPERTY_DEC(NLESegmentAudio, Speed, float, 1.0f, NLEFeature::E)

        /**
         * 曲线变速 point；基于播放时间坐标；VE Seq PointX；
         *
         * SegCurveSpeedPoint / CurveSpeedPoint 两个字段二选一；
         * 优先使用 CurveSpeedPoint 当它不为空时；
         *
         * 详情：https://bytedance.feishu.cn/docs/doccnjeUq16kaAuk08YoQumO0Pf
         */
    NLE_PROPERTY_OBJECT_LIST(NLESegmentAudio, CurveSpeedPoint, NLEPoint, NLEFeature::E)

        /**
         * 曲线变速 point；基于素材时间坐标；VE Trim PointX（Segment PointX）；
         *
         * SegCurveSpeedPoint / CurveSpeedPoint 两个字段二选一；
         * 优先使用 CurveSpeedPoint 当它不为空时；
         *
         * 详情：https://bytedance.feishu.cn/docs/doccnjeUq16kaAuk08YoQumO0Pf
         */
    NLE_PROPERTY_OBJECT_LIST(NLESegmentAudio, SegCurveSpeedPoint, NLEPoint, NLEFeature::SEGMENT_CURVE_SPEED)

        /** 重复次数 */
        static const int32_t REPEAT_NORMAL;      //正常
        static const int32_t REPEAT_INFINITE;   //循环

    NLE_PROPERTY_DEC(NLESegmentAudio, RepeatCount, int32_t, REPEAT_NORMAL, NLEFeature::E)

    NLE_PROPERTY_DEC(NLESegmentAudio, KeepTone, bool, true, NLEFeature::E) /**< 设置变速后音频是否维持原唱，true-维持，false-变速(默认), VEEditor.java setClipReservePitch */

    NLE_PROPERTY_DEC(NLESegmentAudio, Changer, NLEAudioChanger, NLEAudioChanger::NONE, NLEFeature::E) /**< 变调 （男生、女生、萝莉、大叔...）*/

    NLE_PROPERTY_OBJECT(NLESegmentAudio, AVFile, NLEResourceAV, NLEFeature::E) /**< 音频文件 */

    NLE_PROPERTY_OBJECT(NLESegmentAudio, ReversedAVFile, NLEResourceAV, NLEFeature::E) /**< 倒放音频文件 */


    public:

        /**
         * @param absSpeed 播放速率 变速参数；absSpeed = 2 表示2倍速快播；不可以设置为 0；
         */
        virtual void setAbsSpeed(float absSpeed) {
            auto isRewind = getRewind();
            setSpeed(absSpeed);
            setRewind(isRewind);
        }

        /**
         * 播放速率 变速参数；absSpeed = 2 表示2倍速快播；
         */
        virtual inline float getAbsSpeed() const {
            return abs(getSpeed());
        }

        /**
         * 倒播
         */
        virtual void setRewind(bool rewind) {
            if (getRewind() == rewind) {
                return;
            }
            if (rewind) {
                setSpeed(-getAbsSpeed());     // 倒播为负
            } else {
                setSpeed(getAbsSpeed());      // 顺播为正
            }
        }

        /**
         * 倒播
         */
        virtual inline bool getRewind() const {
            return getSpeed() < 0;
        }

        /**
         * 获取曲线变速的平均速度
         */
        double getCurveAveSpeed() const;

        /**
         * 假如存在 CurveSpeedPoint，则直接返回；
         * 否则通过 SegCurveSpeedPoint 转换得来；
         *
         * @return 锚点 按照X轴正序排列
         */
        std::vector<std::shared_ptr<NLEPoint>> getSeqCurveSpeedPoints() const;

        /**
         * 设置曲线变速锚点
         * 会先清空原来的锚点信息
         * @param points
         */
        void setSegCurveSpeedPoints(std::vector<std::shared_ptr<NLEPoint>> points);

        /**
         * 设置曲线变速锚点
         * 会先清空原来的锚点信息
         * @param points
         */
        void setCurveSpeedPoints(std::vector<std::shared_ptr<NLEPoint>> points);


        std::shared_ptr<NLEResourceNode> getResource() const override {
            return getAVFile();
        }

        /**
         * 忽略曲线变速的情况，计算时长
         * @return
         */
        NLETime getDurationWithoutCurveSpeed() const {
            if (hasTimeClipStart() && hasTimeClipEnd()) {
                return (getTimeClipEnd() - getTimeClipStart()) * getRepeatCount() / getAbsSpeed();
            } else if (auto file = getResource()) {
                auto resourceDuration = file->getDuration();
                if (hasTimeClipStart()) {
                    return (resourceDuration - getTimeClipStart()) * getRepeatCount() / getAbsSpeed();
                } else if (hasTimeClipEnd()) {
                    return (getTimeClipEnd() - 0) * getRepeatCount() / getAbsSpeed();
                } else {
                    return resourceDuration * getRepeatCount() / getAbsSpeed();
                }
            } else {
                return NLESegment::getDuration();
            }
        }

        /**
         * 获取音视频未设置变速元素时长
         * @return
         */
        virtual  inline NLETime getRawDuration() const {
            if (hasTimeClipStart() && hasTimeClipEnd()) {
                return (getTimeClipEnd() - getTimeClipStart()) * getRepeatCount() ;
            } else if (auto file = getResource()) {
                auto resourceDuration = file->getDuration();
                if (hasTimeClipStart()) {
                    return (resourceDuration - getTimeClipStart()) * getRepeatCount() ;
                } else if (hasTimeClipEnd()) {
                    return (getTimeClipEnd() - 0)  * getRepeatCount();
                } else {
                    return resourceDuration * getRepeatCount() ;
                }
            } else {
                return NLESegment::getDuration() * getRepeatCount();
            }
        }

        std::shared_ptr<NLEResourceNode> getPlayResource() const {
            if (getRewind()) {
                return getReversedAVFile();
            } else {
                return getAVFile();
            }
        }

        NLETime getDuration() const override {
            if (hasTimeClipStart() && hasTimeClipEnd()) {
                return (getTimeClipEnd() - getTimeClipStart()) * getRepeatCount() / getAbsSpeed() / getCurveAveSpeed();
            } else if (auto file = getResource()) {
                auto resourceDuration = file->getDuration();
                if (hasTimeClipStart()) {
                    return (resourceDuration - getTimeClipStart()) * getRepeatCount() / getAbsSpeed() / getCurveAveSpeed();
                } else if (hasTimeClipEnd()) {
                    return (getTimeClipEnd() - 0) * getRepeatCount() / getAbsSpeed() / getCurveAveSpeed();
                } else {
                    return resourceDuration * getRepeatCount() / getAbsSpeed() / getCurveAveSpeed();
                }
            } else {
                return NLESegment::getDuration();
            }
        }

        std::string changerToEffectJson() const;
    };

    /**
     * 图片片段，一般用于图片编辑
     */
    class NLE_EXPORT_CLASS NLESegmentImage: public NLESegment {
    NLENODE_RTTI(NLESegmentImage);
    KEY_FUNCTION_DEC_OVERRIDE(NLESegmentImage)

    NLE_PROPERTY_DEC(NLESegmentImage, Alpha, float, 1.0f, NLEFeature::E) /**< 透明度 **/

    NLE_PROPERTY_OBJECT(NLESegmentImage, ImageFile, NLEResourceNode, NLEFeature::E) /**< 图片文件 */

    NLE_PROPERTY_OBJECT(NLESegmentImage, CanvasStyle, NLEStyCanvas, NLEFeature::E) /**< 图片画布参数 */

    NLE_PROPERTY_OBJECT(NLESegmentImage, Crop, NLEStyCrop, NLEFeature::E) /**< @deprecated 空间裁剪 (0,1)坐标系，右下为正，已废弃，请使用Clip*/
    NLE_PROPERTY_OBJECT(NLESegmentImage, Clip, NLEStyClip, NLEFeature::CLIP) /**< 空间裁剪 (-1,1)坐标系，右上为正*/

public:
        std::shared_ptr<NLEResourceNode> getResource() const override {
            return getImageFile();
        }
    };
    /**
     * 视频片段
     */
    class NLE_EXPORT_CLASS NLESegmentVideo : public NLESegmentAudio {
    NLENODE_RTTI(NLESegmentVideo);
    KEY_FUNCTION_DEC_OVERRIDE(NLESegmentVideo)

    NLE_PROPERTY_DEC(NLESegmentVideo, EnableAudio, bool, true, NLEFeature::E)

    NLE_PROPERTY_DEC(NLESegmentVideo, Alpha, float, 1.0f, NLEFeature::E)

    NLE_PROPERTY_OBJECT(NLESegmentVideo, Crop, NLEStyCrop, NLEFeature::E) /**< @deprecated 空间裁剪 (0,1)坐标系，右下为正，已废弃，请使用Clip*/
    NLE_PROPERTY_OBJECT(NLESegmentVideo, Clip, NLEStyClip, NLEFeature::CLIP) /**< 空间裁剪 (-1,1)坐标系，右上为正*/

    NLE_PROPERTY_OBJECT(NLESegmentVideo, CanvasStyle, NLEStyCanvas, NLEFeature::E) ///<设置此视频片段的画布参数

    NLE_PROPERTY_OBJECT(NLESegmentVideo, BlendFile, NLEResourceNode, NLEFeature::E) ///<混合模式资源
    };

    // 贴纸
    class NLE_EXPORT_CLASS NLESegmentSticker : public NLESegment {
    NLENODE_RTTI(NLESegmentSticker);
    KEY_FUNCTION_DEC_OVERRIDE(NLESegmentSticker)

    NLE_PROPERTY_DEC(NLESegmentSticker, EffectInfo, std::string, std::string(), NLEFeature::E) /**< 文本内容, 气温，位置，天气 ... json array string : [xxx, xxx, xxx, xxx] */

    NLE_PROPERTY_DEC(NLESegmentSticker, Alpha, float, 1.0f, NLEFeature::E)

    NLE_PROPERTY_OBJECT(NLESegmentSticker, Animation, NLEStyStickerAnim, NLEFeature::E)

    public:
        void setInfoStringList(const std::vector<std::string>& infoStringList);
        std::vector<std::string> getInfoStringList() const;
    };

    /**
     * 图片贴纸
     */
    class NLE_EXPORT_CLASS NLESegmentImageSticker : public NLESegmentSticker {
    NLENODE_RTTI(NLESegmentImageSticker);
    KEY_FUNCTION_DEC_OVERRIDE(NLESegmentImageSticker)

    NLE_PROPERTY_OBJECT(NLESegmentImageSticker, ImageFile, NLEResourceNode, NLEFeature::E)

    NLE_PROPERTY_OBJECT(NLESegmentImageSticker, Crop, NLEStyCrop, NLEFeature::E) /**< @deprecated 空间裁剪 (0,1)坐标系，右下为正，已废弃，请使用Clip*/
    NLE_PROPERTY_OBJECT(NLESegmentImageSticker, Clip, NLEStyClip, NLEFeature::CLIP) /**< 空间裁剪 (-1,1)坐标系，右上为正*/

public:
        std::shared_ptr<NLEResourceNode> getResource() const override {
            return getImageFile();
        }

        virtual NLEResType getType() const override {
            return NLEResType::IMAGE_STICKER;
        }
    };

    /**
     * 转场
     */
    class NLE_EXPORT_CLASS NLESegmentTransition : public NLESegment {
    NLENODE_RTTI(NLESegmentTransition);
    KEY_FUNCTION_DEC_OVERRIDE(NLESegmentTransition)

    NLE_PROPERTY_DEC(NLESegmentTransition, Overlap, bool, true, NLEFeature::E) /**< 转场是否交叠，交叠的话此片段之后的片段的起始时间全部前移；不交叠的话，不影响时间轴 */

    NLE_PROPERTY_DEC(NLESegmentTransition, TransitionDuration, NLETime, 0, NLEFeature::E) /**< 转场总时长，单位 us 微秒 */

    NLE_PROPERTY_OBJECT(NLESegmentTransition, EffectSDKTransition, NLEResourceNode, NLEFeature::E) /**< Loki Transition File */

    NLE_PROPERTY_DEC(NLESegmentVideoAnimation, MediaTransType, NLEMediaTransType, NLEMediaTransType::NONE, NLEFeature::E) ///<画布图片的过场动画类型

    public:
        std::shared_ptr<NLEResourceNode> getResource() const override {
            return getEffectSDKTransition();
        }

        NLETime getDuration() const override {
            return getTransitionDuration();
        }
    };

    /**
     * Emoji 贴纸
     */
    class NLE_EXPORT_CLASS NLESegmentEmojiSticker : public NLESegmentSticker {
    NLENODE_RTTI(NLESegmentEmojiSticker);
    KEY_FUNCTION_DEC_OVERRIDE(NLESegmentEmojiSticker)

    NLE_PROPERTY_DEC(NLESegmentEmojiSticker, utf8Code, std::string, std::string(), NLEFeature::E)
    public:
        virtual NLEResType getType() const override {
            return NLEResType::EMOJI_STICKER;
        }
    };

    /**
     * 信息化贴纸
     */
    class NLE_EXPORT_CLASS NLESegmentInfoSticker : public NLESegmentSticker {
    NLENODE_RTTI(NLESegmentInfoSticker);
    KEY_FUNCTION_DEC_OVERRIDE(NLESegmentInfoSticker)

    NLE_PROPERTY_OBJECT(NLESegmentInfoSticker, EffectSDKFile, NLEResourceNode, NLEFeature::E) /**< 信息化贴纸，会带上一个EffectSDK资源 */

    NLE_PROPERTY_DEC(NLESegmentInfoSticker, AddWithBuffer, bool, false, NLEFeature::E) /**< 该信息话贴纸是否以buffer形式添加*/

    public:
        std::shared_ptr<NLEResourceNode> getResource() const override {
            return getEffectSDKFile();
        }
    };

    /**
     * 普通文本贴纸
     */
    class NLE_EXPORT_CLASS NLESegmentTextSticker : public NLESegmentSticker {
    NLENODE_RTTI(NLESegmentTextSticker);
    KEY_FUNCTION_DEC_OVERRIDE(NLESegmentTextSticker)

    NLE_PROPERTY_DEC(NLESegmentTextSticker, Content, std::string, std::string(), NLEFeature::E) /**< 文本内容 */

    NLE_PROPERTY_OBJECT(NLESegmentTextSticker, Style, NLEStyText, NLEFeature::E) /**< 文本样式 */

    public:
        NLESegmentTextSticker() = default;
        NLESegmentTextSticker(const std::string &effectSDKJsonString);
        
        void setEffectSDKJsonString(const std::string &effectSDKJsonString);
        std::string toEffectJson() const;

        virtual NLEResType getType() const override {
            return NLEResType::TEXT_STICKER;
        }
    };

    /**
     * SRT 歌词贴纸 / 字幕贴纸
     */
    class NLE_EXPORT_CLASS NLESegmentSubtitleSticker : public NLESegmentSticker {
    NLENODE_RTTI(NLESegmentSubtitleSticker);
    KEY_FUNCTION_DEC_OVERRIDE(NLESegmentSubtitleSticker)

    NLE_PROPERTY_OBJECT(NLESegmentSubtitleSticker, SRTFile, NLEResourceNode, NLEFeature::E) /**< srt 文件 */

    NLE_PROPERTY_OBJECT(NLESegmentSubtitleSticker, EffectSDKFile, NLEResourceNode, NLEFeature::E) /**< 抖音歌词贴纸的样式文件，来自Loki资源包，不知道是啥 */

    NLE_PROPERTY_OBJECT(NLESegmentSubtitleSticker, Style, NLEStyText, NLEFeature::E) /**< 文字样式 */

    NLE_PROPERTY_DEC(NLESegmentSubtitleSticker, TimeClipStart, NLETime, -1, NLEFeature::E) /**< Resource时间坐标-起始点, 单位微秒 1s=1000000us */

    NLE_PROPERTY_DEC(NLESegmentSubtitleSticker, TimeClipEnd, NLETime, -1, NLEFeature::E) /**< Resource时间坐标-终止点, 单位微秒 1s=1000000us */

    NLE_PROPERTY_DEC(NLESegmentSubtitleSticker, ConnectedAudioSlotUUID, std::string , std::string(), NLEFeature::E) /**< 与 歌词贴纸/字幕贴纸 相关联的AudioSlotUUID*/
    public:

        std::shared_ptr<NLEResourceNode> getResource() const override {
            if(getSRTFile() != nullptr)
                return getSRTFile();
            else
                return getEffectSDKFile();
        }
    };

    class NLE_EXPORT_CLASS NLESegmentTextTemplate : public NLESegment {
    NLENODE_RTTI(NLESegmentTextTemplate);
    KEY_FUNCTION_DEC_OVERRIDE(NLESegmentTextTemplate)

    NLE_PROPERTY_OBJECT_LIST(NLESegmentTextTemplate, Font, NLEResourceNode, NLEFeature::E) ///< 文字模板用到的字体文件  可能有几个

    NLE_PROPERTY_OBJECT_LIST(NLESegmentTextTemplate, TextClip, NLETextTemplateClip, NLEFeature::E) ///< 文字模板的文字片段  可能有几段文本

    NLE_PROPERTY_OBJECT(NLESegmentTextTemplate, EffectSDKFile, NLEResourceNode, NLEFeature::E) ///< 文字模板的资源

    public:
        nlohmann::json getEffectJson();

        virtual NLEResType getType() const override {
            return NLEResType::TEXT_TEMPLATE;
        }
    };

    /**
     * 用于预览的segment，可塞任何可预览资源
     */
    class NLE_EXPORT_CLASS NLESegmentPlay : public NLESegment {
    NLENODE_RTTI(NLESegmentPlay);
    KEY_FUNCTION_DEC_OVERRIDE(NLESegmentPlay)

    NLE_PROPERTY_DEC(NLESegmentPlay, Cover, std::string, std::string(), NLEFeature::E) ///<播放时的监视器封面。注意：播放音频等素材时必须设置，不然放不出来。因为需要用这个封面做一段视频，VE视频轨不能为空。

    NLE_PROPERTY_DEC(NLESegmentPlay, CoverScale, float, 0.5f, NLEFeature::E)

    NLE_PROPERTY_OBJECT(NLESegmentPlay, AVFile, NLEResourceNode, NLEFeature::E)

    };

    /**
     * EffectSDK 特效片段
     */
    class NLE_EXPORT_CLASS NLESegmentEffect : public NLESegment {
    NLENODE_RTTI(NLESegmentEffect);
    KEY_FUNCTION_DEC_OVERRIDE(NLESegmentEffect)

    NLE_PROPERTY_DEC(NLESegmentEffect, EffectName, std::string, std::string(), NLEFeature::E)

    NLE_PROPERTY_DEC(NLESegmentEffect, EffectTag, std::string, std::string(), NLEFeature::E)

    NLE_PROPERTY_DEC(NLESegmentEffect, ApplyTargetType, std::int32_t , 0, NLEFeature::E)

    NLE_PROPERTY_OBJECT(NLESegmentEffect, EffectSDKEffect, NLEResourceNode, NLEFeature::E)
    NLE_PROPERTY_OBJECT_LIST(NLESegmentEffect, AdjustParams, NLEStringFloatPair, NLEFeature::EFFECT_ADJUST_PARAMS)

    public:
        std::shared_ptr<NLEResourceNode> getResource() const override {
            return getEffectSDKEffect();
        }
    };

    enum class NLEBrickEffectType : int {
        BrickAnimator, // 动作
        BrickBackground, // 背景
        BrickBlendShape, // 口型
        BrickMainBody, // 虚拟人主体
        BrickMainLight // 光源
    };

    class NLE_EXPORT_CLASS NLESegmentBrickEffect : public NLESegment {
    NLENODE_RTTI(NLESegmentBrickEffect);
    KEY_FUNCTION_DEC_OVERRIDE(NLESegmentBrickEffect)
    // filter参数
    NLE_PROPERTY_DEC(NLESegmentBrickEffect, EffectJsonParam, std::string, std::string(), NLEFeature::BRICK_EFFECT)
    // brick_effect类型
    NLE_PROPERTY_DEC(NLESegmentBrickEffect, BrickType, NLEBrickEffectType, NLEBrickEffectType::BrickAnimator, NLEFeature::BRICK_EFFECT)

    NLE_PROPERTY_OBJECT(NLESegmentBrickEffect, EffectSDKEffect, NLEResourceNode, NLEFeature::BRICK_EFFECT)
    // 口型数据源
    NLE_PROPERTY_OBJECT(NLESegmentBrickEffect, ShapeDataRes, NLEResourceNode, NLEFeature::BRICK_EFFECT)

    public:
        std::shared_ptr<NLEResourceNode> getResource() const override {
            return getEffectSDKEffect();
        }
    };

    /**
     * 全局时间特效，可作用与多端视频；记录在 NLETrackSlot segment 字段；
     * 倒放，重复，变速;
     * 目前只在抖音上有，由VESDK实现；
     */
    class NLE_EXPORT_CLASS NLESegmentTimeEffect : public NLESegment {
    NLENODE_RTTI(NLESegmentTimeEffect);
    KEY_FUNCTION_DEC_OVERRIDE(NLESegmentTimeEffect)

        static const int32_t TIME_REPEAT_COUNT = 3; ///< 重复时间特效的重复次数，固定3，暂不考虑拓展
        constexpr static const double TIME_SLOW_SPEED = 0.5; ///< 慢播时间特效的速度，固定0.5f，暂不考虑拓展

        static const int32_t TIME_NORMAL = 0;   ///< 正常
        static const int32_t TIME_REWIND = 1;   ///< 倒播
        static const int32_t TIME_REPEAT = 2;   ///< 重复，业务不指定次数
        static const int32_t TIME_SLOW = 3;     ///< 慢播，业务不指定速度

    NLE_PROPERTY_DEC(NLESegmentTimeEffect, TimeEffectType, uint32_t, TIME_NORMAL, NLEFeature::E)

    public:

        virtual NLEResType getType() const override {
            return NLEResType::TIME_EFFECT;
        }
    };

    /**
     * 电音效果。
     * 没有普通特效拥有的资源包，由VESDK实现。
     * 不继承NLESegmentEffect。
     */
    class NLE_EXPORT_CLASS NLESegmentCherEffect : public NLESegment {
    NLENODE_RTTI(NLESegmentCherEffect);
    KEY_FUNCTION_DEC_OVERRIDE(NLESegmentCherEffect);

    NLE_PROPERTY_DEC(NLESegmentCherEffect, CherMatrix, std::vector<std::string>, std::vector<std::string>(), NLEFeature::E)

    NLE_PROPERTY_DEC(NLESegmentCherEffect, CherDuration, std::vector<double>, std::vector<double>(), NLEFeature::E)

    public:
        virtual NLEResType getType() const override {
            return NLEResType::CHER_EFFECT;
        }
    };

    class NLE_EXPORT_CLASS NLEMatrix {
    public:
        float relativeWidth = 1.0f;
        float relativeHeight = 1.0f;
        float transformX = 0.0f;
        float transformY = 0.0f;
        int32_t transformZ = 0;
        float rotation = 0.0f;

        NLETime startTime = 0;

        std::string toString() const {
            std::stringstream ss;
            ss << "relativeWidth=";
            ss << relativeWidth;
            ss << ", relativeHeight=";
            ss << relativeHeight;
            ss << ", transformX=";
            ss << transformX;
            ss << ", transformY=";
            ss << transformY;
            ss << ", transformZ=";
            ss << transformZ;
            ss << ", rotation=";
            ss << rotation;
            return ss.str();
        }
    };

    class NLE_EXPORT_CLASS NLETimeSpaceNode : public NLENode {
    NLENODE_RTTI(NLETimeSpaceNode);
    KEY_FUNCTION_DEC_OVERRIDE(NLETimeSpaceNode)

    // 对齐父节点
    static const int32_t MATCH_PARENT = -2;
    // 对齐自身的最小/最大值
    static const int32_t WRAP_CONTENT = -1;

        /********************* 父容器时间维度 *********************/
    NLE_PROPERTY_DEC(NLETimeSpaceNode, StartTime, NLETime, 0, NLEFeature::E) /**< 起始时间 */

    NLE_PROPERTY_DEC(NLETimeSpaceNode, EndTime, NLETime, 0, NLEFeature::E) /**< 终止时间，假如未设置或者为-1，表示 WRAP_CONTENT，根据 segment 计算出时长 */

    NLE_PROPERTY_DEC(NLETimeSpaceNode, Speed, float, 1.0f, NLEFeature::TIME_SPACE_SPEED) /**< 变速 */

        /********************* 画布空间维度 *********************/
        // 坐标原点：屏幕中心
        // X轴正方向：用户视角：屏幕left -> 屏幕right
        // Y轴正方向：用户视角：屏幕bottom -> 屏幕top
        // Z轴正方向：用户视角：屏幕inside -> 屏幕outside

    NLE_PROPERTY_DEC(NLETimeSpaceNode, RelativeWidth, float, 1.0f, NLEFeature::E) /**< 宽，（相对于parent），默认等于 parent 尺寸 */

    NLE_PROPERTY_DEC(NLETimeSpaceNode, RelativeHeight, float, 1.0f, NLEFeature::E) /**< 高，（相对于parent，比如parent高度1000，当前节点高度200，那么 RelativeHeight = 0.2f），默认等于 parent 尺寸 */

    NLE_PROPERTY_DEC(NLETimeSpaceNode, TransformX, float, 0, NLEFeature::E) /**< 位移 -1.0f~1.0f */

    NLE_PROPERTY_DEC(NLETimeSpaceNode, TransformY, float, 0, NLEFeature::E)  /**< 位移 -1.0f~1.0f */

    NLE_PROPERTY_DEC(NLETimeSpaceNode, TransformZ, int32_t, 0, NLEFeature::E) ///<位移（Z轴） 0~1000; 渲染层级，数值越大显示在越上面；取值范围：0~1000；@see getRawTransformZ()

    NLE_PROPERTY_DEC(NLETimeSpaceNode, Rotation, float, 0, NLEFeature::E) /**< 基于Z轴正方向逆时针旋转，取值范围 0~359; （正值：逆时针旋转 负值：顺时针旋转）*/

    NLE_PROPERTY_DEC(NLETimeSpaceNode, Scale, float, 1.0f, NLEFeature::E) ///< RelativeWidth / RelativeHeight 指定当前节点的空间；Scale 是基于 RelativeWidth / RelativeHeight 声明的空间之后做的变换；

    NLE_PROPERTY_DEC(NLETimeSpaceNode, Mirror_X, bool, false, NLEFeature::E)

    NLE_PROPERTY_DEC(NLETimeSpaceNode, Mirror_Y, bool, false, NLEFeature::E)

    /**
     * Processor注册表：https://bytedance.feishu.cn/docs/doccneeMrt2jLrjA6XDLO8g5Ccg#
     */
    NLE_PROPERTY_DEC(NLETimeSpaceNode, Processor, std::vector<std::string>, std::vector<std::string>(), NLEFeature::PROCESSOR)

    protected:
        int32_t measureStartTime = 0;
        int32_t measureEndTime = 0;

        bool getNLEMatrix(NLEMatrix & parentMatrix, const NLETimeSpaceNode * target, NLEMatrix & resultMatrix) const;

        virtual inline std::shared_ptr<NLESegment> virtualGetSegment() const {
            return nullptr;
        }

    public:

        /**
         * 递归获取所有包含 processor 的 对象；不包含当前对象；
         */
        void collectProcessNodes(std::vector<std::shared_ptr<NLETimeSpaceNode>>& processNodes) const;

        virtual void setDuration(NLETime duration) {
            if (hasStartTime() || getStartTime() >= 0) {
                setEndTime(getStartTime() + duration);
            } else {
                LOGGER->wtf("%s setDuration ignore because no start time", getClassName().c_str());
            }
        }

        virtual NLETime getDuration() const {
            // 片段只有一个的时候调用addSlotAtIndex会导致startTime==-1，这里先把getStartTime() >= 0去掉
            if (hasStartTime() && hasEndTime()) {
                return getEndTime() - getStartTime();
            }
            auto segment = virtualGetSegment();
            if (segment) {
                auto segmentDuration = segment->getDuration();
                LOGGER->v("%s getDuration return segment duration %lld", getClassName().c_str(), segmentDuration);
                return segmentDuration;
            }
            return 0;
        }

        virtual void setMeasuredStartTime(NLETime time);
        virtual NLETime getMeasuredStartTime() const;
        virtual void setMeasuredEndTime(NLETime time);
        virtual NLETime getMeasuredEndTime() const;

        virtual inline int32_t getLayer() const {
            return getTransformZ();
        }

        virtual inline void setLayer(int32_t layer) {
            setTransformZ(layer);
        }

        /**
         * @param 播放速率 变速参数；absSpeed = 2 表示2倍速快播；不可以设置为 0；
         */
        virtual inline void setAbsSpeed(float absSpeed) {
            auto isRewind = getRewind();
            setSpeed(absSpeed);
            setRewind(isRewind);
        }

        /**
         * 播放速率 变速参数；absSpeed = 2 表示2倍速快播；
         */
        virtual inline float getAbsSpeed() const {
            return abs(getSpeed());
        }

        /**
         * 倒播
         */
        virtual void setRewind(bool rewind);

        /**
         * 倒播
         */
        virtual bool getRewind() const;
    };

//    class NLE_EXPORT_CLASS NLETimeSpaceNodeGroup : public NLETimeSpaceNode {
//    NLENODE_RTTI(NLETimeSpaceNodeGroup);
//    KEY_FUNCTION_DEC_OVERRIDE(NLETimeSpaceNodeGroup);
//    protected:
//        void addObject(const NLEPropertyBase &key, const std::shared_ptr<NLENode> &object) override {
//            NLETimeSpaceNode::addObject(key, object);
//            if (auto timeSpaceNode = std::dynamic_pointer_cast<NLETimeSpaceNode>(object)) {
//                timeSpaceNode->setParent(this);
//            } else {
//                LOGGER->e("NLETimeSpaceNodeGroup addObject illegal");
//
//                // 多个 segment / 多个非NLETimeSpaceNode 的情况，是正常的不能抛异常
//                // throw std::exception();
//            }
//        }
//
//        bool removeObject(const NLEPropertyBase &key, const std::shared_ptr<NLENode> &object) override {
//            if (auto timeSpaceNode = std::dynamic_pointer_cast<NLETimeSpaceNode>(object)) {
//                timeSpaceNode->setParent(nullptr);
//            }
//            return NLETimeSpaceNode::removeObject(key, object);
//        }
//
//        void clearObject(const NLEPropertyBase &key) override {
//            for (auto object : getChildren(key.name)) {
//                if (auto timeSpaceNode = std::dynamic_pointer_cast<NLETimeSpaceNode>(object.second)) {
//                    timeSpaceNode->setParent(nullptr);
//                }
//            }
//            NLETimeSpaceNode::clearObject(key);
//        }
//    };

    class NLE_EXPORT_CLASS NLEVideoAnimation : public NLETimeSpaceNode {
    NLENODE_RTTI(NLEVideoAnimation);
    KEY_FUNCTION_DEC_OVERRIDE(NLEVideoAnimation);
    NLE_PROPERTY_OBJECT(NLEVideoAnimation, Segment, NLESegmentVideoAnimation, NLEFeature::E)

    protected:
        std::shared_ptr<NLESegment> virtualGetSegment() const override {
            return getSegment();
        }
    };

    /**
     * 单点滤镜 / 全局滤镜 / 调节 / 亮度值，对比度，饱和度，锐化，高光，色温
     */
    class NLE_EXPORT_CLASS NLEFilter : public NLETimeSpaceNode {
    NLENODE_RTTI(NLEFilter);
    KEY_FUNCTION_DEC_OVERRIDE(NLEFilter);
    NLE_PROPERTY_OBJECT(NLEFilter, Segment, NLESegmentFilter, NLEFeature::E)

    protected:
        std::shared_ptr<NLESegment> virtualGetSegment() const override {
            return getSegment();
        }
    };

    /**
     * 视频特效
     */
    class NLE_EXPORT_CLASS NLEVideoEffect : public NLETimeSpaceNode {
    NLENODE_RTTI(NLEVideoEffect);
    KEY_FUNCTION_DEC_OVERRIDE(NLEVideoEffect);
    NLE_PROPERTY_OBJECT(NLEVideoEffect, Segment, NLESegmentEffect, NLEFeature::E)

    protected:
        std::shared_ptr<NLESegment> virtualGetSegment() const override {
            return getSegment();
        }
    };

    /**
     * 时间特效
     */
    class NLE_EXPORT_CLASS NLETimeEffect : public NLETimeSpaceNode {
    NLENODE_RTTI(NLETimeEffect);
    KEY_FUNCTION_DEC_OVERRIDE(NLETimeEffect)

    NLE_PROPERTY_OBJECT(NLETimeEffect, Segment, NLESegmentTimeEffect, NLEFeature::E)

    protected:
        std::shared_ptr<NLESegment> virtualGetSegment() const override {
            return getSegment();
        }
    };

    /**
     * 音频降噪 Noise reduction
     * 只需要设置
     *
     * Android VEEditor.java : int addAudioCleanFilter(int trackIndex, int trackType, int seqIn, int seqOut)
     * iOS: ??
     */
    class NLE_EXPORT_CLASS NLENoiseReduction : public NLETimeSpaceNode {
    NLENODE_RTTI(NLENoiseReduction);
    KEY_FUNCTION_DEC_OVERRIDE(NLENoiseReduction)
    };

    /**
     * 电音
     */
    class NLE_EXPORT_CLASS NLECherEffect : public NLETimeSpaceNode {
    NLENODE_RTTI(NLECherEffect);
    KEY_FUNCTION_DEC_OVERRIDE(NLECherEffect)

    NLE_PROPERTY_OBJECT(NLECherEffect, Segment, NLESegmentCherEffect, NLEFeature::E)

    protected:
        std::shared_ptr<NLESegment> virtualGetSegment() const override {
            return getSegment();
        }
    };

    class NLE_EXPORT_CLASS NLEMask : public NLETimeSpaceNode {
    NLENODE_RTTI(NLEMask);
    KEY_FUNCTION_DEC_OVERRIDE(NLEMask);
    NLE_PROPERTY_OBJECT(NLEMask, Segment, NLESegmentMask, NLEFeature::E)

    protected:
        std::shared_ptr<NLESegment> virtualGetSegment() const override {
            return getSegment();
        }
    };

    class NLE_EXPORT_CLASS NLEChromaChannel : public NLETimeSpaceNode {
    NLENODE_RTTI(NLEChromaChannel);
    KEY_FUNCTION_DEC_OVERRIDE(NLEChromaChannel)

    NLE_PROPERTY_OBJECT(NLEChromaChannel, Segment, NLESegmentChromaChannel, NLEFeature::E)

    protected:
        std::shared_ptr<NLESegment> virtualGetSegment() const override {
            return getSegment();
        }
    };

    // 理论上 NLETrackSlot 可以嵌套 NLETrackSlot
    class NLE_EXPORT_CLASS NLETrackSlot : public NLETimeSpaceNode {
    NLENODE_RTTI(NLETrackSlot);
    KEY_FUNCTION_DEC_OVERRIDE(NLETrackSlot);

        /********************* 资源素材容器 *********************/

    NLE_PROPERTY_OBJECT(NLETrackSlot, MainSegment, NLESegment, NLEFeature::E)
    /**<
     * 主片段（Slot时长会基于主片段的时长进行计算）
     * 音频 NLESegmentAudio
     * 视频 NLESegmentVideo
     * 图片 NLESegmentImage
     * 贴纸 NLESegmentSticker
     * 滤镜 NLESegmentFilter（全局滤镜）
     * 特效 NLESegmentEffect
     * 时间特效 NLESegmentTimeEffect
     */

    NLE_PROPERTY_OBJECT(NLETrackSlot, PinAlgorithmFile, NLEResourceNode, NLEFeature::E) /**< PIN功能就是贴纸跟手跟脸效果，双端PIN功能是VE+Effect支持的，需要传递PIN算法文件 */

    NLE_PROPERTY_OBJECT(NLETrackSlot, EndTransition, NLESegmentTransition, NLEFeature::E) /**< 转场，只能有一个，而且必须放在尾部 */

        /********** 可以设置多个，可以自由调节时间；其实可以完全抽象，但是对上层不友好，所以还是穷举 **********/
    NLE_PROPERTY_OBJECT_LIST(NLETrackSlot, VideoAnim, NLEVideoAnimation, NLEFeature::E) /**< 视频动画 */

    NLE_PROPERTY_OBJECT_LIST(NLETrackSlot, Filter, NLEFilter, NLEFeature::E) /**< 滤镜 */

    NLE_PROPERTY_OBJECT_LIST(NLETrackSlot, Mask, NLEMask, NLEFeature::E) /**< 蒙板 */

    NLE_PROPERTY_OBJECT_LIST(NLETrackSlot, ChromaChannel, NLEChromaChannel, NLEFeature::E) /**< 色度通道/色度抠图 */

    NLE_PROPERTY_OBJECT_LIST(NLETrackSlot, VideoEffect, NLEVideoEffect, NLEFeature::E) /**< 特效 */

    NLE_PROPERTY_OBJECT_LIST(NLETrackSlot, NoiceReduction, NLENoiseReduction, NLEFeature::E); /**< 音频降噪 */

    NLE_PROPERTY_DEC(NLETrackSlot, KeyframesUUIDList, std::vector<std::string>, std::vector<std::string>(), NLEFeature::E) /**< 关键帧列表 该属性已被废弃*/

    NLE_PROPERTY_OBJECT(NLETrackSlot, AudioFilter, NLEFilter, NLEFeature::E) /**< 变声 */
        /** 关键帧节点  TransformX/TransformY/TransformZ使用全局坐标 StartTime使用相对时间*/
    NLE_PROPERTY_OBJECT_LIST(NLETrackSlot, Keyframe, NLETrackSlot, NLEFeature::KEYFRAME)
    public:

        /**************************************************************** 关键帧相关接口****************************************************************/
        // 默认关键帧左右覆盖时间范围各100ms
        static const int32_t KEYFRAME_RANG = 200 * 1000;

        /*
         * 计算变更startTime后整体关键帧偏移量offset，对调整后小于0的关键帧进行移除
         * */
        void setStartTimeAndAdjustKeyframe(NLETime startTime) {
            auto offset = getStartTime() - startTime;
            for(auto keyframe : getKeyframes()){
                keyframe->setStartTime(keyframe->getStartTime() + offset);
                if(keyframe->getStartTime() < 0){
                    removeKeyframe(keyframe);
                }
            }
            setStartTime(startTime);
        }

        /*
         * 计算变更endTime后，大于Duration的关键帧进行移除
         * */
        void setEndTimeAndAdjustKeyframe(NLETime endTime) {
            auto offset = endTime - getStartTime();
            for(auto keyframe : getKeyframes()){
                if(keyframe->getStartTime() > offset){
                    removeKeyframe(keyframe);
                }
            }
            setEndTime(endTime);
        }

        /*
         * 变速后调整后小于0的关键帧进行移除
         * */
        void setSpeedAndAdjustKeyframe(float speed) {
            setAbsSpeedAndAdjustKeyframe(std::abs(speed));
        }

        void setAbsSpeedAndAdjustKeyframe(float absSpeed) {
            auto segment = std::dynamic_pointer_cast<NLESegmentVideo>(getMainSegment());
            if (segment == nullptr) {
                return;
            }

            auto orgAbsSpeed = segment->getAbsSpeed();
            auto scale = orgAbsSpeed / absSpeed;
            for(auto keyframe : getKeyframes()){
                keyframe->setStartTime(keyframe->getStartTime() * scale);
            }

            auto isRewind = segment->getRewind();
            segment->setSpeed(absSpeed);
            segment->setRewind(isRewind);
        }

        void setSegCurveSpeedPointAndAdjustKeyframe(std::vector<std::shared_ptr<NLEPoint>> points) {
            auto segment = std::dynamic_pointer_cast<NLESegmentVideo>(getMainSegment());
            if (segment == nullptr) {
                return;
            }

            auto orgAvgSpeed = segment->getCurveAveSpeed();
            segment->setSegCurveSpeedPoints(points);
            auto scale = orgAvgSpeed / segment->getCurveAveSpeed();

            for(auto keyframe : getKeyframes()){
                keyframe->setStartTime(keyframe->getStartTime() * scale);
            }

        }

        void setRewindAndAdjustKeyframe(bool rewind) {
            auto segment = std::dynamic_pointer_cast<NLESegmentVideo>(getMainSegment());
            if (segment == nullptr) {
                return;
            }

            if (segment->getRewind() == rewind) {
                return;
            }
            if (rewind) {
                segment->setSpeed(-segment->getAbsSpeed());     // 倒播为负
            } else {
                segment->setSpeed(segment->getAbsSpeed());      // 顺播为正
            }

            auto keyFrames = getSortKeyframe();
            if (keyFrames.size() > 0) {
                for (auto& keyFrame: keyFrames) {
                    auto time = keyFrame->getStartTime();
                    auto duration = getDuration();
                    keyFrame->setStartTime(duration - time);
                }
            }
        }

        std::vector<std::shared_ptr<NLETrackSlot>> getSortKeyframe() {
            auto keyframes = getKeyframes();
            std::sort(keyframes.begin(),keyframes.end(),[](const auto &obj1, const auto &obj2)
            {
                return obj1->getStartTime() < obj2->getStartTime();
            });
            return keyframes;
        }

        ////从被添加关键帧的Slot拷贝一份适合作为关键帧数据的Keyframe对象
        std::shared_ptr<NLETrackSlot> createKeyframe() {

            std::shared_ptr<NLENode> clone = std::shared_ptr<NLENode>(this->deepClone(true));
            auto keyframe = NLETrackSlot::dynamicCast(clone);

            ///删除不支持关键帧的字段，避免太多冗余数据
            keyframe->clearKeyframe();
            keyframe->clearVideoEffect();
            keyframe->clearVideoAnim();
            keyframe->setAudioFilter(nullptr);
            keyframe->clearChromaChannel();
            keyframe->setEndTransition(nullptr);

            return keyframe;
        }

        /**************************************************************** 关键帧相关接口****************************************************************/

        std::shared_ptr<NLEFilter> getFilterByName(const std::string &filterName) const {
            for (const auto &filter : getFilters()) {
                if (const auto &filterSegment = filter->getSegment()) {
                    if (filterSegment->getFilterName() == filterName) {
                        return filter;
                    }
                }
            }
            return nullptr;
        }

        std::shared_ptr<NLEFilter> removeFilterByName(const std::string &filterName) {
            if (auto filter = getFilterByName(filterName)) {
                removeFilter(filter);
                return filter;
            }
            return nullptr;
        }

    protected:
        std::shared_ptr<NLESegment> virtualGetSegment() const override {
            return getMainSegment();
        }
    };

    /**
     * NLETrack 表示一个空间概念的图层，没有时间概念：
     *  Layer -- 层级，层级越大Z轴坐标越大；
     *
     * NLETrack 是 NLETrackSlot 的集合；
     */
    class NLE_EXPORT_CLASS NLETrack : public NLETimeSpaceNode {
    NLENODE_RTTI(NLETrack);
    KEY_FUNCTION_DEC_OVERRIDE(NLETrack)

    NLE_PROPERTY_DEC(NLETrack, MainTrack, bool, false, NLEFeature::E)

    NLE_PROPERTY_DEC(NLETrack, Volume, float, 1.0, NLEFeature::E) /**<音量，1.0f 表示原声，0.0f 表示无声*/

    NLE_PROPERTY_OBJECT_LIST(NLETrack, Filter, NLEFilter, NLEFeature::E) /**< 滤镜/调节 */

    NLE_PROPERTY_OBJECT_LIST(NLETrack, VideoEffect, NLETrackSlot, NLEFeature::E) /**< 特效 */

    NLE_PROPERTY_OBJECT(NLETrack, TimeEffect, NLETimeEffect, NLEFeature::E) /**< 时间特效 */

    NLE_PROPERTY_OBJECT(NLETrack, CherEffect, NLECherEffect, NLEFeature::E) /**< 电音 */

    NLE_PROPERTY_OBJECT_LIST(NLETrack, Slot, NLETrackSlot, NLEFeature::E) /**< 子节点 */
        
    NLE_PROPERTY_OBJECT_LIST(NLETrack, KeyframeSlot, NLETrackSlot, NLEFeature::E) /**< 子关键帧节点 ,该属性已被废弃，请使用TrackSlot里的Keyframe*/

    private:
        template<typename T>
        static T abs(T value) {
            if (value >= 0) {
                return value;
            } else {
                return -value;
            }
        }

    public:
        /**
         * [画布调节相关]
         * 更新画布比例，同时修改 relativeWidth, relativeHeight 参数以确保原先的子元素布局不变；
         * （调用 setCanvasRatio 不调节 relativeWidth, relativeHeight 参数的话，子元素会错乱）
         */
        void updateRelativeSizeWhileGlobalCanvasChanged(float globalCanvasRatio, float oldGlobalCanvasRatio);

        /**
         * [画布调节相关]
         * Effect的概念，贴纸
         */
        float getEffectScale(float globalCanvasRatio, float surfaceRatio) const;

        /**
         * [画布调节相关]
         * VE的概念，主轨 / 副轨 视频都是基于画布fitCenter模式伸缩
         * 视频都是fitCenter的方式填充画布，画布比例调整之后（setCanvasRatioOnly），需要做缩放
         */
        float getVideoScaleAfterFixCenter(float globalCanvasRatio, float videoRatioAfterCrop) const;

        /**
         * [画布调节相关]
         */
        float getOriginalCanvasRatio(float globalCanvasRatio) const;


        virtual std::shared_ptr<nlohmann::json> toJson() const override;

        std::shared_ptr<NLEFilter> getFilterByName(const std::string &filterName) const {
            for (const auto &filter : getFilters()) {
                if (const auto &filterSegment = filter->getSegment()) {
                    if (filterSegment->getFilterName() == filterName) {
                        return filter;
                    }
                }
            }
            return nullptr;
        }

        std::shared_ptr<NLEFilter> removeFilterByName(const std::string &filterName) {
            if (auto filter = getFilterByName(filterName)) {
                removeFilter(filter);
                return filter;
            }
            return nullptr;
        }

        std::pair<std::vector<std::shared_ptr<NLEPoint>>, std::vector<std::shared_ptr<NLEPoint>>>
        splitSegCurvePointInSlot(NLETime splitTime, const std::shared_ptr<NLETrackSlot> &slot);

        std::pair<std::vector<std::shared_ptr<NLEPoint>>, std::vector<std::shared_ptr<NLEPoint>>>
        splitSeqCurvePointInSlot(NLETime splitTime, const std::shared_ptr<NLETrackSlot> &slot);

        /**
         * 切割。
         * 判断目标slot的(startTime, measuredEndTime)是否包含splitTime，是，则对其进行切割；否，则返回包含nullptr的pair。
         * @param splitTime 切割的时间点
         * @param slot 需要切割的目标slot
         * @return
         */
        std::pair<std::shared_ptr<NLETrackSlot>, std::shared_ptr<NLETrackSlot>>
        splitInSpecificSlot(NLETime splitTime, const std::shared_ptr<NLETrackSlot> &slot);

        /**
         * 切割。
         * 对所有slots进行遍历，找到第一个(startTime, measuredEndTime)包含splitTime的slot，对其进行切割。
         * @param splitTime 切割的时间点
         * @return 一个片段Pair(包含老片段和新生成的片段), 业务层想怎么操作就怎么操作, 比如去除掉老slot的转场。
         */
        std::pair<std::shared_ptr<NLETrackSlot>, std::shared_ptr<NLETrackSlot>>
        splitGetBackSlotPair(NLETime splitTime);

        /**
         * 切割。
         * 对所有slots进行遍历，找到第一个(startTime, measuredEndTime)包含splitTime的slot，对其进行切割。
         * @param splitTime 切割的时间点
         * @return 新生成的片段
         */
        std::shared_ptr<NLETrackSlot> split(NLETime splitTime);

        bool moveSlotToIndex(const std::shared_ptr<NLETrackSlot> &child, int32_t toIndex);

        bool moveSlotToIndex(int32_t fromIndex, int32_t toIndex);

        NLETime getMinStart() const;

        NLETime getMaxEnd() const;
        NLETime getMaxEndExcludeDisabledNode(bool excludeDisabledNode) const;
        NLETime getMeasuredEndTime() const override;

        NLEResType getResourceType() const;

        // 根据第一个Segment确认类型，空轨则为 NONE
        NLETrackType getTrackType() const;

        // setExtraTrackType / getExtraTrackType NLE 没有任何逻辑，当作额外字段考虑
        NLETrackType getExtraTrackType() const;
        void setExtraTrackType(NLETrackType type);

        /** 在轨道头部插入，自动调节各个Slot时间 */
        void addSlotAtStart(const std::shared_ptr<NLETrackSlot> &child);

        /** 在轨道尾部插入，自动调节各个Slot时间 */
        void addSlotAtEnd(const std::shared_ptr<NLETrackSlot> &child);

        /** 指定位置插入片段 */
        void addSlotAtIndex(const std::shared_ptr<NLETrackSlot> &child, int32_t index);

        /**
         * 添加slot到指定索引值处
         * @param child
         * @param index
         * @param insertAtHeader  insertAtHeader为true表示当前节点的开始处，否则就插入到前一个slot结尾处
         */
        void addSlotAtIndex(const std::shared_ptr<NLETrackSlot> &child, int32_t index, bool insertAtHeader);


        void addSlotAfterSlot(const std::shared_ptr<NLETrackSlot> &child,
                              const std::shared_ptr<NLETrackSlot> &anchor);

        std::shared_ptr<NLETrackSlot> getSlotByIndex(int32_t index) const;

        std::shared_ptr<NLETrackSlot> getSlotByTime(int64_t time) const;

        int32_t getSlotIndex(const std::shared_ptr<NLETrackSlot> &slot) const;

        std::vector<std::shared_ptr<NLETrackSlot>> getSortedSlots() const;

        /**
         * 按照时间排序 Slot 确保 index 正确
         * 主轨确保首尾相接，副轨确保不重叠
         */
        void timeSort();

        /**
         * <p>是否关闭音量</p>
         * 若mute,track下所有slot对应的mainSegment全部设置EnableAudio为false，表示静音整个轨道
         * @param enable
         */
        void setAudioEnable(bool enable);


        /**
         * 整个轨道是否为关闭音量
         * <p>有且只有所有的slot下的都是静音</p>
         * @return
         */
        bool isAudioEnable();

        // 对比两个track的时间轴是否变化
        bool isTimelineChange(const std::shared_ptr<const NLETrack> &other) const;
    };

    /**
     * MV track
     */
    class NLE_EXPORT_CLASS NLETrackMV : public NLETrack {
    NLENODE_RTTI(NLETrackMV);
    KEY_FUNCTION_DEC_OVERRIDE(NLETrackMV)

    NLE_PROPERTY_OBJECT(NLETrackMV, MV, NLEResourceNode, NLEFeature::MV) ///< mv资源包

    NLE_PROPERTY_DEC(NLETrackMV, SingleVideo, bool, false, NLEFeature::MV) ///< 是否设置随MV随单个视频时长变化

    NLE_PROPERTY_DEC(NLETrackMV, MVResolution, int32_t, 0, NLEFeature::MV) ///< MV模板分辨率

    NLE_PROPERTY_OBJECT(NLETrackMV, Algorithm, NLEResourceNode, NLEFeature::MV) ///< MV算法文件

    NLE_PROPERTY_DEC(NLETrackMV, AlgorithmConnectedAudioSlotName, std::string, "def",NLEFeature::MV) ///< MV算法文件关联的音轨标识

    NLE_PROPERTY_OBJECT_LIST(NLETrackMV, Mask, NLEMVExternalAlgorithmResult, NLEFeature::MV) ///< 背景分割

    };

    /**
     * Algorithm track
     */
    class NLE_EXPORT_CLASS NLETrackAlgorithm : public NLETrack {
    NLENODE_RTTI(NLETrackAlgorithm);
    KEY_FUNCTION_DEC_OVERRIDE(NLETrackAlgorithm)

    NLE_PROPERTY_DEC(NLETrackAlgorithm, VideoRatio, float, -1.0f, NLEFeature::ALGORITHM) ///<默认 ORIGINAL (理解为：VE支持不传比例，会自动根据宽高比素材比例走)
    };

    /**
     * 针对一个视频帧进行编辑，添加贴纸，添加滤镜，添加文本等等，默认是 disable 状态；
     * 场景：CK封面编辑；
     */
    class NLE_EXPORT_CLASS NLEVideoFrameModel : public NLETimeSpaceNode {
    public:
        /**
        * 默认将 Enable 属性的置为 false
        */
        NLEVideoFrameModel() { setEnable(false);}
    NLENODE_RTTI(NLEVideoFrameModel);
    KEY_FUNCTION_DEC_OVERRIDE(NLEVideoFrameModel);

    /**
     * 封面编辑快照，一张图片；
     */
    NLE_PROPERTY_OBJECT(NLEVideoFrameModel, Snapshot, NLEResourceNode, NLEFeature::VIDEO_FRAME_MODEL)

        /**
         * 被编辑的基底，可以是：纯色 / 渐变色 / 图片 / 视频帧
         */
    NLE_PROPERTY_OBJECT(NLEVideoFrameModel, CoverMaterial, NLEStyCanvas, NLEFeature::VIDEO_FRAME_MODEL)

        /**
         * 当 NLEStyCanvas::Type == NLECanvasType::VIDEO_FRAME 时，此字段才会生效，指定视频帧的时间戳
         */
    NLE_PROPERTY_DEC(NLEVideoFrameModel, VideoFrameTime, cut::model::NLETime, 0 , NLEFeature::VIDEO_FRAME_MODEL)

        /**
         * 画布比例 默认 16:9（桌面端编辑器横屏的情况）；screen width / screen height；宽高比；
         */
    NLE_PROPERTY_DEC(NLEVideoFrameModel, CanvasRatio, float, 16.0f / 9.0f, NLEFeature::VIDEO_FRAME_MODEL)
    NLE_PROPERTY_OBJECT_LIST(NLEVideoFrameModel, Track, NLETrack, NLEFeature::VIDEO_FRAME_MODEL)
    };

    /**
     * 模型
     */
    class NLE_EXPORT_CLASS NLEModel : public NLETimeSpaceNode {
    NLENODE_RTTI(NLEModel);
    KEY_FUNCTION_DEC_OVERRIDE(NLEModel)

    /** 封面 */
    NLE_PROPERTY_OBJECT(NLEModel, Cover, NLEVideoFrameModel, NLEFeature::VIDEO_FRAME_MODEL)

        // thousandFps : 30000 = 每秒30帧
    NLE_PROPERTY_DEC(NLEModel, ThousandFps, uint32_t, 30000, NLEFeature::E)
    // 画布比例 默认 16:9（桌面端编辑器横屏的情况）；screen width / screen height；宽高比；
    NLE_PROPERTY_DEC(NLEModel, CanvasRatio, float, 16.0f / 9.0f, NLEFeature::E)
    NLE_PROPERTY_OBJECT_LIST(NLEModel, Track, NLETrack, NLEFeature::E)
    // 对齐模式("align_canvas", "align_video")
    NLE_PROPERTY_DEC(NLEModel, AlignMode, std::string, "align_canvas", NLEFeature::ALIGN_MODE)

    public:
        /**
         * [画布调节相关]
         * 更新画布比例，同时修改 relativeWidth, relativeHeight 参数以确保原先的子元素布局不变；
         * （调用 setCanvasRatio 不调节 relativeWidth, relativeHeight 参数的话，子元素会错乱）
         */
        void updateRelativeSizeWhileGlobalCanvasChanged(float globalCanvasRatio, float oldGlobalCanvasRatio);

        /**
         * 倒放特定的轨道
         * @param rewind
         * @param trackTypes 无需倒放type的轨道
         */
        void setRewind(bool rewind, std::vector<NLETrackType> exceptTracks);

        /**
         * 获取所有轨道 最小的起始时间点, 起始点为0；
         * 返回 -1 表示当前没有任何轨道；
         * 单位微秒 （1s=1000000us）
         */
        NLETime getMinTargetStart() const;

        /**
         * 获取所有轨道 最大的结束时间点, 起始点为0；
         * @param exceptTracks 这些轨道排除时间计算
         */
        NLETime getMaxTargetEnd(std::vector<NLETrackType> exceptTracks) const;

        /**
         * 获取所有轨道 最大的结束时间点, 起始点为0；
         * 返回 -1 表示当前没有任何轨道；
         * 单位微秒 （1s=1000000us）
         */
        NLETime getMaxTargetEnd() const;

        /// 获取所有轨道 最大的结束时间点，是否排除disable的track和slot
        NLETime getMaxTargetEndExcludeDisabledNode(bool excludeDisable) const;
        NLETime getMeasuredEndTime() const override;
        /**
         * 获取所有轨道 最小的起始时间点, 起始点为0；
         * 永远返回 0
         * 单位微秒 （1s=1000000us）
         */
        NLETime getStartTime() const override;

        /**
         * 获取所有轨道 最大的结束时间点, 起始点为0；
         * 返回 -1 表示当前没有任何轨道；
         * 单位微秒 （1s=1000000us）
         */
        NLETime getDuration() const override;

        int32_t getLayerMax() const;

        /**
        *  获取轨道特效的layer
        * @return
        */
        int32_t getEffectLayerMax() const;

        std::shared_ptr<NLETrack> getTrackBySlot(const std::shared_ptr<NLETrackSlot> &slot) const;


        std::shared_ptr<NLEMatrix> getRawNLEMatrix(const std::shared_ptr<NLETimeSpaceNode> &node) const;

        std::vector<std::shared_ptr<cut::model::NLEResourceNode>> getAllResources() const;

        std::vector<std::shared_ptr<NLETrack>> getSortedTracks() const;
        std::vector<std::shared_ptr<NLETrack>> getSortedTracksWithNoNoneTrack() const;

        std::shared_ptr<NLETrack> getMainTrack(bool withEnable = false) const;

        std::shared_ptr<NLETrack> getFirstTrackWithType(NLETrackType trackType) const;

    private:
        NLETime getMaxTargetEnd(bool excludeDisable, std::vector<NLETrackType> exceptTracks) const;
    };

    class NLE_EXPORT_CLASS NLESizeUtils {

    public:
        // 生成NLESize
        static NLESize NLESizeMake(float width, float height);

    };

}

#endif //NLEPLATFORM_SEQUENCE_NODE_H
