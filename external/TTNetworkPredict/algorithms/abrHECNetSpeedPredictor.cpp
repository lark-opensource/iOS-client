//
// Created by xuzhimin on 2020-03-18.
//

#include "abrHECNetSpeedPredictor.h"
#include <cmath>
#include <algorithm>

NETWORKPREDICT_NAMESPACE_BEGIN

abrHECNetSpeedPredictor::abrHECNetSpeedPredictor()
:mPredictedErrorBandwidthSize(5)
,mLastVideoPredictedBandwidth(-1.0)
,mLastAudioPredictedBandwidth(-1.0)
{
    mRecentVideoBandwidthError.clear();
    mRecentAudioBandwidthError.clear();
}

abrHECNetSpeedPredictor::~abrHECNetSpeedPredictor() {
}

float abrHECNetSpeedPredictor::predictBandwidth(int media_type) {
    float predicted_bandwidth = 0.0;
    float predicted_bandwidth_ha = 0.0;
    float bandwidth_sum = 0.0;
    if (media_type == VIDEO_TYPE) {
        for (int i = 0; i < mRecentVideoBandwidth.size(); i ++) {
            float temp_bandwidth = mRecentVideoBandwidth[i] > 1 ? mRecentVideoBandwidth[i] : 1;
            bandwidth_sum += 1.0/temp_bandwidth;
        }
        predicted_bandwidth_ha = mRecentVideoBandwidth.size() > 0 ? mRecentVideoBandwidth.size() / bandwidth_sum : predicted_bandwidth_ha;

        float predicted_error = 0;
        float max_predicted_error = 0;
        if (mLastVideoPredictedBandwidth < 0.0 || mRecentVideoBandwidth.size() < 1) {
            predicted_bandwidth = predicted_bandwidth_ha;
            mRecentVideoBandwidthError.push_back(predicted_error);// Assume error is zero
        } else {
            float now_bandwidth = mRecentVideoBandwidth[mRecentVideoBandwidth.size()-1];
            predicted_error = fabs(mLastVideoPredictedBandwidth - now_bandwidth) / (now_bandwidth * 1.0f);
            mRecentVideoBandwidthError.push_back(predicted_error);
            if(mRecentVideoBandwidthError.size() > mPredictedErrorBandwidthSize) {
                std::vector<float>::iterator  k = mRecentVideoBandwidthError.begin();
                mRecentVideoBandwidthError.erase(k);
            }
            max_predicted_error = *max_element(mRecentVideoBandwidthError.begin(), mRecentVideoBandwidthError.end());
            predicted_bandwidth = predicted_bandwidth_ha/(1 + max_predicted_error);
        }
        mLastVideoPredictedBandwidth = predicted_bandwidth;
    } else if (media_type == AUDIO_TYPE) {
        for (int i = 0; i < mRecentAudioBandwidth.size(); i ++) {
            float temp_bandwidth = mRecentAudioBandwidth[i] > 1 ? mRecentAudioBandwidth[i] : 1;
            bandwidth_sum += 1.0/temp_bandwidth;
        }
        predicted_bandwidth_ha = mRecentAudioBandwidth.size() > 0 ? mRecentAudioBandwidth.size() / bandwidth_sum : predicted_bandwidth;

        float predicted_error = 0;
        float max_predicted_error = 0;
        if (mLastAudioPredictedBandwidth < 0.0 || mRecentAudioBandwidth.size() < 1) {
            predicted_bandwidth = predicted_bandwidth_ha;
            mRecentAudioBandwidthError.push_back(predicted_error);// Assume error is zero
        } else {
            float now_bandwidth = mRecentAudioBandwidth[mRecentAudioBandwidth.size()-1];
            predicted_error = fabs(mLastAudioPredictedBandwidth - now_bandwidth) / (now_bandwidth * 1.0f);
            mRecentAudioBandwidthError.push_back(predicted_error);
            if(mRecentAudioBandwidthError.size() > mPredictedErrorBandwidthSize) {
                std::vector<float>::iterator  k = mRecentAudioBandwidthError.begin();
                mRecentAudioBandwidthError.erase(k);
            }
            max_predicted_error = *max_element(mRecentAudioBandwidthError.begin(), mRecentAudioBandwidthError.end());
            predicted_bandwidth = predicted_bandwidth_ha/(1 + max_predicted_error);
        }
        mLastAudioPredictedBandwidth = predicted_bandwidth;
    } else {
        //pass
    }
    LOGD("[SelectorLog] [HECNet] predicted_bandwidth=%f", predicted_bandwidth);
    return predicted_bandwidth;
}

NETWORKPREDICT_NAMESPACE_END
