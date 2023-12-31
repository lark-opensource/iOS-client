//
// Created by guikunzhi on 2020-03-11.
//

#ifndef INETWORKSPEEDMANAGER_H
#define INETWORKSPEEDMANAGER_H

#include "NetworkSpeedRecord.h"
#include "NetworkSpeedResult.h"
#include <memory>
#include <map>
#include "network_speed_pedictor_base.h"
#include "inetwork_speed_predict_mlcomponent_wrapper.h"

NETWORKPREDICT_NAMESPACE_BEGIN

class INetworkSpeedPredictor {
public:
    virtual ~INetworkSpeedPredictor() {}
    virtual float getPredictSpeed(int media_type=0) = 0;
    virtual float getLastPredictConfidence(){ return -1;};
    virtual std::map<std::string, std::string> getDownloadSpeed(int media_type=0) = 0;
    virtual float predictBandwidth(int media_type){ return  -1;};
    virtual void update(std::vector<std::shared_ptr<SpeedRecord>> speedRecords, std::map<std::string, int> mediaInfo){};
    virtual void updateOldWithStreamId(std::shared_ptr<SpeedRecordOld> speedRecord, std::map<std::string, int> mediaInfo) = 0;
    virtual void updateSpeed(double speed, long size, long costTime, long timestamp) {};
    virtual std::vector<std::shared_ptr<NetworkSpeedResult>> getMultidimensionalDownloadSpeeds(){return std::vector<std::shared_ptr<NetworkSpeedResult>>();};
    virtual std::vector<std::shared_ptr<NetworkSpeedResult>> getMultidimensionalPredictSpeeds(){ return std::vector<std::shared_ptr<NetworkSpeedResult>>();};
    virtual float getAverageDownloadSpeed(int media_type, int speed_type, bool trigger){ return -1;};
    virtual int getAverageSpeedForIes() { return -1;}; //ies测速下沉保留其原有的接口
    virtual void setModelComponent(std::shared_ptr<INetworkSpeedPredictMlcomponentWrapper> component){};
    virtual void setConfigSpeedInfo(std::map<std::string, std::string> feature){};
    virtual void setSpeedQueueSize(int size){};
    virtual void prepare(){};
    virtual void start(){};
    virtual void close(){};

};

NETWORKPREDICT_NAMESPACE_END

#endif //ABR_INETSPEEDMANAGER_H
