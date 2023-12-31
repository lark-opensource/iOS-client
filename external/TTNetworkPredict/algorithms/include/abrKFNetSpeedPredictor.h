//
// Created by xuzhimin on 2020-05-29.
//

#ifndef ABR_ABRKFNETSPEEDPREDICTOR_H
#define ABR_ABRKFNETSPEEDPREDICTOR_H
#include "INetworkSpeedPredictor.h"
#include "abrBaseSpeedPredictor.h"
#include "NetworkSpeedRecord.h"
#include "NetworkSpeedResult.h"
#include "network_speed_predictor_key.h"
#include "network_speed_pedictor_base.h"
#include "algorithmCommon.h"
#include <vector>
#include <inttypes.h>
#include <math.h>
#include <map>

NETWORKPREDICT_NAMESPACE_BEGIN

class abrKFNetSpeedPredictor: public abrBaseSpeedPredictor{
public:
    abrKFNetSpeedPredictor();
    ~abrKFNetSpeedPredictor();

    void updateOldWithStreamId(std::shared_ptr<SpeedRecordOld>, std::map<std::string, int> mediaInfo) override;
    void update(std::vector<std::shared_ptr<SpeedRecord>> speedRecords, std::map<std::string, int> mediaInfo) override;
    float predictBandwidth(int media_type) override;
private:
    float videoX, audioX;  // State estimate
    float videoP, audioP;  // Estimate covaConfigureriance
    float videoF, audioF;  // State transition model
    float videoQ, audioQ;  // Process noise covariance
    float videoH, audioH;  // Observation model
    float videoR, audioR;  // Observation noise covariance
    float videoZ, audioZ;  // Measurement of the state X


    float videoPositiveGrow, audioPositiveGrow; // Change point detection positive Part
    float videoNegativeGrow, audioNegativeGrow; // Change point detection negative Part
    float videoPositiveThreshold, audioPositiveThreshold; // Positive threshold
    float videoNegativeThreshold, audioNegativeThreshold; // Negative threshold
    float videoV, audioV; // Changepoint detection tolerance
    float videoStableQ, audioStableQ; // Q value when there is not change point
    float videoDynamicUpQ, audioDynamicUpQ; // Q value when detect up change point
    float videoDynamicDownQ, audioDynamicDownQ; // Q value when detect down change point

    float videoStableCount, audioStableCount; // successive points without chang points
    float videoStableMeasurementDiscount, audioStableMeasurementDiscount;
    float videoDynamicMeasurementDiscount, audioDynamicMeasurementDiscount;
    float videoMeasurementDiscount, audioMeasurementDiscount;
    float videoStableThreshold, audioStableThreshold;
};

NETWORKPREDICT_NAMESPACE_END
#endif //ABR_ABRKFNETSPEEDPREDICTOR_H
