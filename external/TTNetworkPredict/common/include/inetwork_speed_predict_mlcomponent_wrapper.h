//
// Created by shen chen on 2021/2/25.
//

#ifndef NETWORKPREDICT_INETWORK_SPEED_PREDICT_MLCOMPONENT_WRAPPER_H
#define NETWORKPREDICT_INETWORK_SPEED_PREDICT_MLCOMPONENT_WRAPPER_H

#include "network_speed_pedictor_base.h"
#include <map>
#include <vector>

NETWORKPREDICT_NAMESPACE_BEGIN

class INetworkSpeedPredictMlcomponentWrapper {
public:
    virtual ~INetworkSpeedPredictMlcomponentWrapper(){};
    virtual bool prepareAlreadFinish() = 0;
    virtual std::vector<float> calculate(std::map<std::string, std::string> input) = 0;
    virtual bool enable() = 0;
    virtual void release() = 0;
};

NETWORKPREDICT_NAMESPACE_END

#endif //NETWORKPREDICT_INETWORK_SPEED_PREDICT_MLCOMPONENT_WRAPPER_H
