//
// Created by xuzhimin on 2020-03-18.
//

#ifndef ABR_ABRHECNETSPEEDPREDICTOR_H
#define ABR_ABRHECNETSPEEDPREDICTOR_H

#include "INetworkSpeedPredictor.h"
#include "abrBaseSpeedPredictor.h"
#include "NetworkSpeedRecord.h"
#include "NetworkSpeedResult.h"
#include "network_speed_predictor_key.h"
#include "network_speed_pedictor_base.h"
#include "algorithmCommon.h"
#include <vector>
#include <cmath>
#include <inttypes.h>
#include <map>

NETWORKPREDICT_NAMESPACE_BEGIN

class abrHECNetSpeedPredictor: public abrBaseSpeedPredictor{
public:
    abrHECNetSpeedPredictor();
    ~abrHECNetSpeedPredictor();

    float predictBandwidth(int media_type) override;
private:
    int mPredictedErrorBandwidthSize;
    float mLastVideoPredictedBandwidth;
    float mLastAudioPredictedBandwidth;
    std::vector<float> mRecentVideoBandwidthError;
    std::vector<float> mRecentAudioBandwidthError;
};

NETWORKPREDICT_NAMESPACE_END
#endif //ABR_ABRHECNETSPEEDPREDICTOR_H
