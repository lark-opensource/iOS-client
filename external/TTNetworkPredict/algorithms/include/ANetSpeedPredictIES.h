//
// Created by shen chen on 2021/3/12.
//

#ifndef VIDEOENGINE_ANETSPEEDPREDICTIES_H
#define VIDEOENGINE_ANETSPEEDPREDICTIES_H

#include "INetworkSpeedPredictor.h"
#include <queue>
#include <mutex>
#include <queue>
#include <mutex>
#include "network_speed_predict_timer.h"
#include <functional>

NETWORKPREDICT_NAMESPACE_BEGIN

typedef std::function<void(void)> Functional;

class ANetSpeedPredictIES:public INetworkSpeedPredictor {
private:
    //std::queue<std::shared_ptr<SpeedRecordOld>> speedRecordQueue;//后续把测速信息队列公用
    std::deque<std::shared_ptr<SpeedRecordOld>> speedRecordQueue;//后续把测速信息队列公用
    std::mutex mtx;
    float mSpeed;
    std::shared_ptr<SpeedRecordOld> mRecycledSpeedRecord;
    float mDefaultInitalSpeed;
    float mAverageSpeed;
    static int DEFAULT_QUEUE_CAPACITY;
    int maxCapacity;//speed队列最大容量
    static int DEAFULT_SPEED_RECORD_VALID_THRESHOLD;
    static double INVALID_SPEED;
    static double VALID_SPEED_MIN;
public:
    ANetSpeedPredictIES();
    ~ANetSpeedPredictIES();
    void prepare() override;
    void setConfigSpeedInfo(std::map<std::string, std::string> feature) override;
    void setSpeedQueueSize(int size) override;
    void start() override;
    void stop();
    void close() override;

    void updateOldWithStreamId(std::shared_ptr<SpeedRecordOld> speedRecord, std::map<std::string, int> mediaInfo) override;
    void updateSpeed(double speed, long size, long costTime, long timestamp) override;
    float getPredictSpeed(int media_type=0) override;
    std::map<std::string, std::string> getDownloadSpeed(int media_type=0) override;
    int getAverageSpeedForIes() override;

private:
    float calculate();
    double getSpeed();
};

NETWORKPREDICT_NAMESPACE_END

#endif //VIDEOENGINE_ANETSPEEDPREDICTIES_H
