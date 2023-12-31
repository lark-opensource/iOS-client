//
// Created by xuzhimin on 2020-03-20.
//

#ifndef ABR_ABRANETSPEEDPREDICTOR_H
#define ABR_ABRANETSPEEDPREDICTOR_H
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

class abrANetSpeedPredictor: public abrBaseSpeedPredictor{
public:
    abrANetSpeedPredictor();
    ~abrANetSpeedPredictor();

    float predictBandwidth(int media_type) override;
private:
    float mBandwidthSafeParameter;
};

NETWORKPREDICT_NAMESPACE_END
#endif //ABR_ABRANETSPEEDPREDICTOR_H
