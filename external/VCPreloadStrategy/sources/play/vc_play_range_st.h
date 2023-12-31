//
// Created by 黄清 on 2021/12/24.
//

#ifndef PRELOAD_VC_PLAY_RANGE_ST_H
#define PRELOAD_VC_PLAY_RANGE_ST_H
#pragma once

#include <algorithm>
#include <limits>
#include <unordered_map>

#include "vc_play_range_interface.h"
#include "vc_utils.h"

#define ALGO_PARAM_DEFAULT_KEY "default"

VC_NAMESPACE_BEGIN

struct DynamicPreloadParams {
    /// 判断当前播放是否处于起始播放阶段的阈值
    int mInitPlayThresholdInMS;
    /// 0: 使用下沉测速； 1: 使用MDL任务测速
    int mNetworkSpeedOption;
    int mMaxPreloadSize;

    struct ParameterOptions {
        bool bandwidthEnable{false};
        bool stallEnable{false};
        bool smartPreloadEnable{false};
        bool sceneRecordEnable{false};
    } mParameterOptions;

    struct BandwidthParameters {
        int lowSpeedThreshold{1000};  // kbps
        int highSpeedThreshold{3000}; // kbps
        int slidingWindowSize{20};
        float safeFactor{0.1};
        float stallFactor{1.};
    } mBandwidthParams;

    struct EstPlayTimeParameters {
        int estPlayTimeInitPlayDefaultInMS{8000};
        int estPlayTimeInitPlayQuickInMS{5000};
        int estPlayTimeInitPlaySlowInMS{10000};
        int estPlayTimeContinuePlayDefaultInMS{20000};
        int estPlayTimeContinuePlayQuickInMS{12000};
        int estPlayTimeContinuePlaySlowInMS{30000};
        int estPlayTimePreloadDefaultInMS{20000};
        int estPlayTimePreloadQuickInMS{12000};
        int estPlayTimePreloadSlowInMS{30000};
    } mEstPlayTimeParams;

    struct ThresholdParameters {
        int minDangerThresholdInS{6};
        int maxDangerThresholdInS{15};
        int maxSecureThresholdInS{25};
        int minThresholdDiffInS{5};
        int preloadSizeDefaultKB{800};
        float preloadSizeRatio{1.0};
    } mThresholdParams;

    mutable std::mutex mMutex;
    void parseConfigJson(VCStrCRef json);
};

class VCPlayRangeSimpleST : public IVCPlayRange {
private:
    class AlgorithmParam : public IVCPrintable {
    public:
        AlgorithmParam() = default;
        ~AlgorithmParam() override = default;

    public:
        bool parseJson(const VCJson &root);
        bool parseJson(const std::string &jsonStr);

    public:
        std::string toString(void) const override;

    public:
        struct Param : public IVCPrintable {
            int mFixedSize{-1};
            int mAudioFixedSize{-1};
            int mFixedDuration{10};
            int mLimitDuration{20};
            int mRangeMinSize{1024 * 1024};
            int mRangeMaxSize{8 * 1024 * 1024};
            int mAudioRangeMinSize{400 * 1024};
            int mMaskRangeMinSize{200 * 1024};
            int mFirstRangeSize{0};
            int mAudioFirstRangeSize{0};
            int mIgnorePlayerRange{0};
            int mNearEndMinSize{0};
            int mMaskRangeEnable{0};

            /// 动态 range
            bool mEnableDynamicRangeControl{false};
            /// 动态 range 参数
            int mRangeMinDuration, mRangeMaxDuration;
            /// 是否启用预加载的动态水位
            bool mEnableDynamicPreloadThreshold{false};
            /// 是否启用 MDL 扩展 buffer
            bool mEnableNonBlockRange{false};

            /// 自适应 range
            bool mEnableAdaptiveRangeControl{false};
            /// 目标缓存长度（秒）
            int mTargetBufferLength{25};
            /// 候选 range 起点
            int mRangeBegin{2};
            /// 候选 range 终点（包含）
            int mRangeEnd{16};
            /// 候选 range 间隔
            int mRangeStep{2};
            /// 判断带宽是否充足的超参
            float mAlpha{-1.0f}, mBeta{-1.0f};
            /// 是否开启动态目标水位
            bool mEnableDynamicTargetBuffer{false};
            /// 是否开启网速range拆分
            bool mEnableBandwidthRangeControl{false};
            /// 安全网速值(KBps)
            int mSafeBandwidth{0};
            /// 网速码率比值——range时长
            std::vector<std::pair<float, int>> mBandwidthRatioRange;

            std::string toString() const override;

            void parse(const VCJson &root);

            bool shouldEnableNonBlockRange() const {
                return mEnableAdaptiveRangeControl ||
                       (mEnableDynamicRangeControl && mEnableNonBlockRange);
            }
        } mDefault, mDash;

        int mConcurrentEnable{1};
        int mAllowedSegmentDownload{0};
        int mDashEnable{0};

        /// buffer 埋点间隔（毫秒）
        int mBufferEventIntervalMs{500};
        /// range 大小埋点分桶
        static std::vector<int> &getRangeBuckets();
        /// buffer 大小埋点分桶
        static std::vector<int> &getBufferBuckets();
    };

public:
    VCPlayRangeSimpleST();
    ~VCPlayRangeSimpleST() override = default;

public:
    std::shared_ptr<VCStrategyResult>
    probeAction(const std::shared_ptr<VCMessage> &msg) override;
    bool taskConcurrent() override;
    void rangeSize(VCRangeParam &param) override;

public:
    void configAlgorithmParam(VCKey key, const VCJson &json);

private:
    void setSelectedAlgoParam(VCStrCRef paramName);

    AlgorithmParam getCurrParam() const;

    void trigBufferLog(int interval, int times);

    int64_t getCurrentBufferedDurationMs() const;

    int adaptiveRangeDuration(const std::string &mediaId,
                              const AlgorithmParam::Param &param,
                              int bitrate) const;

    int dynamicRangeDuration(const AlgorithmParam::Param &param,
                             const VCMediaInfo::Ptr &mediaInfo,
                             int mediaBitrate) const;

    int64_t bandwidthRangeSize(const AlgorithmParam::Param &param,
                               const std::string &mediaId,
                               int bitrate,
                               bool isAudio) const;

    bool isRangeAvailable(const VCMediaInfo::Ptr &mediaInfo,
                          const AlgorithmParam &algoParam) const;

    void logRangeDuration(VCStrCRef mediaId, int duration);

    void logRangeMinSize(VCStrCRef mediaId);

    void reportLog(VCStrCRef mediaId);

    /// 对当前视频未来观播时长的预测
    int getEstPlayTimeMs(const DynamicPreloadParams &param) const;
    /// 获取卡顿
    int getStallCount(const DynamicPreloadParams &param) const;
    /// 获取测速
    int64_t getBandwidthBitPerSec(const DynamicPreloadParams &param) const;
    /// 获取（危险水位，安全水位）
    std::pair<int, int> getThresholdMs(const DynamicPreloadParams &param,
                                       const VCMediaInfo::Ptr &mediaInfo,
                                       int estPlaytimeMs,
                                       int64_t safeBandwidthBitPerSec) const;

    void updatePreloadConfig(VCStrCRef sceneId, VCStrCRef jsonStr);

private:
    std::string mConfigString;
    std::string mCurrParamKey{ALGO_PARAM_DEFAULT_KEY};
    mutable std::mutex mCurrParamKeyMutex;
    std::unordered_map<std::string, AlgorithmParam> mParamMap{
            {ALGO_PARAM_DEFAULT_KEY, AlgorithmParam()}};

    struct MapItem {
        /// （动态）目标水位，从 PlayLoad 模块接收消息
        int targetBufferLength{0};

        /// buffer 长度埋点统计：超过 target buffer 的次数
        int exceedTargetCount{0};
        /// 走到兜底rangeMinSize的次数
        int rangeMinSizeCount{0};
        /// range 长度埋点
        BucketLog<int> rangeDurations{AlgorithmParam::getRangeBuckets()};
        /// buffer 长度埋点
        BucketLog<int> bufferDurations{AlgorithmParam::getBufferBuckets()};
    };

    std::map<std::string, MapItem> mMediaIdMap;
    mutable std::mutex mMediaIdMapMutex;

    std::string mPreloadLabel;
    mutable std::mutex mPreloadLabelMutex;
    DynamicPreloadParams mDynamicThresholdParam;

private:
    VC_DISALLOW_COPY_ASSIGN_AND_MOVE(VCPlayRangeSimpleST);
};

VC_NAMESPACE_END

#endif // PRELOAD_VC_PLAY_RANGE_ST_H
