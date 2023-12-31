//
// Created by bytedance on 2021/6/4.
//
#ifndef ABR_ABRBASESPEEDPREDICTOR_H
#define ABR_ABRBASESPEEDPREDICTOR_H

#include "INetworkSpeedPredictor.h"
#include "NetworkSpeedRecord.h"
#include "NetworkSpeedResult.h"
#include "network_speed_predictor_key.h"
#include "network_speed_pedictor_base.h"
#include "algorithmCommon.h"
#include <deque>
#if defined(__APPLE__)
#include <sys/types.h>
#endif
NETWORKPREDICT_NAMESPACE_BEGIN


class abrBaseSpeedPredictor: public INetworkSpeedPredictor {
public:
    abrBaseSpeedPredictor();
    ~abrBaseSpeedPredictor();

protected:
    float getPredictSpeed(int media_type) override;
    std::map<std::string, std::string> getDownloadSpeed(int media_type) override;
    NetworkSpeedResultVec getMultidimensionalDownloadSpeeds() override;
    NetworkSpeedResultVec getMultidimensionalPredictSpeeds() override;
    float getLastPredictConfidence() override;
    float getAverageDownloadSpeed(int media_type, int speed_type, bool trigger) override ;

    void updateOldWithStreamId(std::shared_ptr<SpeedRecordOld> speedRecord, std::map<std::string, int> mediaInfo) override;
    void update(std::vector<std::shared_ptr<SpeedRecord>> speedRecords, std::map<std::string, int> mediaInfo) override;
    void updateMultidimensionalPredictSpeed();

    float confBasedBandwidthPredict(SpeedInfo& speedInfo);

protected:
    float mLastVideoDownloadSpeed;  // Including speed < MINIMUM_SPEED and speed > MAXIMUM_SPEED
    float mLastAudioDownloadSpeed;
    uint64_t mLastVideoDownloadSize;
    uint64_t mLastAudioDownloadSize;
    int64_t mLastVideoDownloadTime;
    int64_t mLastAudioDownloadTime;
    int64_t mLastVideoLastDataRecv;
    int64_t mLastAudioLastDataRecv;
    int64_t mLastVideoRTT;
    int64_t mLastAudioRTT;
    std::string mVideoCurrentStreamId;
    std::string mAudioCurrentStreamId;
    std::string mVideoMDLLoaderType; // HTTP or PCDN loader
    std::string mAudioMDLLoaderType;

    float mPredictedVideoBandwidth;
    float mPredictedAudioBandwidth;
    float mPredictConfidence;
    std::vector<float> mRecentVideoBandwidth;
    std::vector<float> mRecentAudioBandwidth;

    NetworkSpeedResultVec mMultidimensionalDownloadSpeed;  // With aggregation when timestamp overlap
    NetworkSpeedResultVec mMultidimensionalPredictSpeed;

    int mVideoCallCount;
    int mAudioCallCount;
    float mVideoAvgSpeed;
    float mAudioAvgSpeed;
    float mVideoAvgWindowSpeed;
    float mAudioAvgWindowSpeed;
    int mStartupWindowSize;
    std::vector<float> mVideoStartupSpeed;
    std::vector<float> mAudioStartupSpeed;

    // Exponential moving average
    float mEMAWeight;
    float mEMAVideoSpeed;
    float mEMAAudioSpeed;
    float mEMAVideoStartupEndSpeed;
    float mEMAAudioStartupEndSpeed;
    float mEMAVideoStartupSpeed;
    float mEMAAudioStartupSpeed;

    int mBandwidthSlidingWindowSize;
    DowloadInfoMap mExistedMultidimensionalInfo;

    int64_t mCostTimeFilterValue;  // ms
    bool mOpenNetworkSpeedOptimize;
    std::vector<int64_t> mRecentVideoTimestamp;
    std::vector<int64_t> mRecentAudioTimestamp;

    std::deque<float> mRecentAccuracy;
    std::deque<int64_t> mRecentConfTimestamp;
    std::deque<float> mRecentConfSpeed;
    float mConfBasedPredSpeed;

    int mConfBasedPredict;
    pthread_rwlock_t mLock;
};

NETWORKPREDICT_NAMESPACE_END
#endif //ABR_ABRBASESPEEDPREDICTOR_H
