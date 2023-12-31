//
// Created by bytedance on 2021/10/11.
//

#ifndef NETWORKPREDICT_ABRACNETSPEEDPREDICTOR_H
#define NETWORKPREDICT_ABRACNETSPEEDPREDICTOR_H

#include "INetworkSpeedPredictor.h"
#include "abrBaseSpeedPredictor.h"
#include "NetworkSpeedRecord.h"
#include "NetworkSpeedResult.h"
#include "network_speed_predictor_key.h"
#include "network_speed_pedictor_base.h"
#include "algorithmCommon.h"
#include <vector>
#include <numeric>
#include <cmath>
#include <ctime>
#include <inttypes.h>
#include <map>

NETWORKPREDICT_NAMESPACE_BEGIN

class abrACNetSpeedPredictor: public abrBaseSpeedPredictor{
public:
    abrACNetSpeedPredictor();
    ~abrACNetSpeedPredictor();

    float predictBandwidth(int media_type) override;
private:
    float mBandwidthSafeParameter;
};

NETWORKPREDICT_NAMESPACE_END
#endif //NETWORKPREDICT_ABRACNETSPEEDPREDICTOR_H
