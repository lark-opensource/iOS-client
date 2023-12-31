//
// Created by shen chen on 2021/2/25.
//

#ifndef NETWORKPREDICT_TFENGINESPEEDPREDICTOR_H
#define NETWORKPREDICT_TFENGINESPEEDPREDICTOR_H

#include "INetworkSpeedPredictor.h"
#include "inetwork_speed_predict_mlcomponent_wrapper.h"
#include <queue>
#include <mutex>
#include "network_speed_predict_timer.h"
#include <functional>

NETWORKPREDICT_NAMESPACE_BEGIN

typedef std::function<void(void)> Functional;

class TFEngineSpeedPredict:public INetworkSpeedPredictor {
private:
    std::map<std::string, std::string> featureList;
    std::shared_ptr<INetworkSpeedPredictMlcomponentWrapper> componentWrapper;
    std::queue<std::shared_ptr<SpeedRecordOld>> speedRecordQueue;
    std::mutex mtx;
    float mSpeed;
    std::mutex speedMtx;
    std::shared_ptr<Timer<Functional>> mTimer;
    static int DEFAULT_QUEUE_CAPACITY;
public:
    TFEngineSpeedPredict();
    ~TFEngineSpeedPredict();
    void setModelComponent(std::shared_ptr<INetworkSpeedPredictMlcomponentWrapper> component) override;
    void setConfigSpeedInfo(std::map<std::string, std::string> feature) override;
    void prepare() override;
    void start() override;
    void stop();
    void close() override;

    void updateOldWithStreamId(std::shared_ptr<SpeedRecordOld> speedRecord, std::map<std::string, int> mediaInfo) override;
    void updateSpeed(double speed, long size, long costTime, long timestamp) override;
    float getPredictSpeed(int media_type=0) override;
    std::map<std::string, std::string> getDownloadSpeed(int media_type=0) override;
private:
    float calculate();
};
NETWORKPREDICT_NAMESPACE_END

#endif //NETWORKPREDICT_TFENGINESPEEDPREDICTOR_H
