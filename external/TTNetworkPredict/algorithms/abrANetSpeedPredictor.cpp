//
// Created by xuzhimin on 2020-03-20.
//

#include "abrANetSpeedPredictor.h"

NETWORKPREDICT_NAMESPACE_BEGIN

abrANetSpeedPredictor::abrANetSpeedPredictor()
:mBandwidthSafeParameter(0.90)
{
}

abrANetSpeedPredictor::~abrANetSpeedPredictor() {
}

float abrANetSpeedPredictor::predictBandwidth(int media_type) {
    float predicted_bandwidth = 0.0;
    if (media_type == VIDEO_TYPE) {
        predicted_bandwidth = (mRecentVideoBandwidth.size() > 0 ? std::accumulate(mRecentVideoBandwidth.begin(), mRecentVideoBandwidth.end(),0) / (mRecentVideoBandwidth.size()) : 0) * mBandwidthSafeParameter;
    } else if (media_type == AUDIO_TYPE) {
        predicted_bandwidth = (mRecentAudioBandwidth.size() > 0 ? std::accumulate(mRecentAudioBandwidth.begin(), mRecentAudioBandwidth.end(),0) / (mRecentAudioBandwidth.size()) : 0) * mBandwidthSafeParameter;
    } else {
      //pass
    }
    LOGD("[SelectorLog] [ANet] predicted_bandwidth=%f", predicted_bandwidth);
    return predicted_bandwidth;
}

NETWORKPREDICT_NAMESPACE_END
