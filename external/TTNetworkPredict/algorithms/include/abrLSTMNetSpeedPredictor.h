//
// Created by xuzhimin on 2020-03-20.
//

#ifndef ABR_ABRLSTMNETSPEEDPREDICTOR_H
#define ABR_ABRLSTMNETSPEEDPREDICTOR_H
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

class abrLSTMNetSpeedPredictor: public abrBaseSpeedPredictor{
public:
    abrLSTMNetSpeedPredictor();
    ~abrLSTMNetSpeedPredictor();

    float predictBandwidth(int media_type) override;
};

NETWORKPREDICT_NAMESPACE_END
#endif //ABR_ABRLSTMNETSPEEDPREDICTOR_H
