//
// Created by shen chen on 2021/2/25.
//

#include "include/TFEngineSpeedPredictor.h"
#include <string>
#include <cmath>
#include <cinttypes>
#include "network_speed_predict_timer.h"

NETWORKPREDICT_NAMESPACE_BEGIN

int TFEngineSpeedPredict::DEFAULT_QUEUE_CAPACITY = 10;

TFEngineSpeedPredict::TFEngineSpeedPredict():mSpeed(0) {
    LOGD("use TFEngineSpeedPredict algorithm");
}

TFEngineSpeedPredict::~TFEngineSpeedPredict() {
    LOGE("destory","destory TFEngineSpeedPredict");
}

void TFEngineSpeedPredict::setModelComponent(std::shared_ptr<INetworkSpeedPredictMlcomponentWrapper> component) {
    componentWrapper = component;
}

void TFEngineSpeedPredict::setConfigSpeedInfo(std::map<std::string, std::string> feature) {
    featureList = feature;
}

void TFEngineSpeedPredict::prepare() {
    if (componentWrapper == nullptr) return;
    componentWrapper->prepareAlreadFinish();
}

void TFEngineSpeedPredict::start() {
    if (componentWrapper == nullptr) return;
    if(mTimer != nullptr) return;
    mTimer = std::make_shared<Timer<Functional>>([this]{
       calculate();
    }, std::chrono::milliseconds{500});
    mTimer->start();
}
void TFEngineSpeedPredict::stop() {
    mTimer = nullptr;
}

void TFEngineSpeedPredict::updateOldWithStreamId(std::shared_ptr<SpeedRecordOld> speedRecord, std::map<std::string, int> mediaInfo) {
    std::lock_guard<std::mutex> mlx(mtx);
    if (speedRecord->time != 0) {
        if (speedRecordQueue.size() < DEFAULT_QUEUE_CAPACITY) {
            speedRecordQueue.push(speedRecord);
        } else {
            speedRecordQueue.pop();
            speedRecordQueue.push(speedRecord);
        }
    }
}

void TFEngineSpeedPredict::updateSpeed(double speed, long size, long costTime, long timestamp) {
    std::lock_guard<std::mutex> mlx(mtx);
    std::shared_ptr<SpeedRecordOld> speedRecord = std::make_shared<SpeedRecordOld>();
    speedRecord->speedInbPS = speed;
    speedRecord->time = costTime;
    speedRecord->bytes = size;
    speedRecord->timestamp = timestamp;
    if (speedRecordQueue.size() < DEFAULT_QUEUE_CAPACITY) {
        speedRecordQueue.push(speedRecord);
    } else {
        speedRecordQueue.pop();
        speedRecordQueue.push(speedRecord);
    }
}

void TFEngineSpeedPredict::close() {
    if (componentWrapper == nullptr) return;
    componentWrapper->release();
    componentWrapper = nullptr;
}

float TFEngineSpeedPredict::getPredictSpeed(int media_type) {
    std::lock_guard<std::mutex> mlx(speedMtx);
    return mSpeed;
}

std::map<std::string, std::string> TFEngineSpeedPredict::getDownloadSpeed(int media_type) {
    return std::map<std::string,std::string>();
}

float TFEngineSpeedPredict::calculate() {
    std::lock_guard<std::mutex> mlx(mtx);
    float speed = -1;
    if (componentWrapper == nullptr || !componentWrapper->enable() || !componentWrapper->prepareAlreadFinish()) {
        if (componentWrapper == nullptr) {
            LOGE("componentWrapper is null");
        } else {
            LOGE("component is not prepareFinish");
        }
        return speed;
    }

    std::map<std::string, std::string> input(featureList);
    std::vector<std::shared_ptr<SpeedRecordOld>> buffer;
    while (!speedRecordQueue.empty()) {
       buffer.push_back(speedRecordQueue.front());
       speedRecordQueue.pop();
    }
    for (int i = 0; i < buffer.size(); ++i) {
       speedRecordQueue.push(buffer[i]);
    }
    int length = std::min(speedRecordQueue.size(), buffer.size());
    int preIndexName = 0;
    for (int index = length - 1; index >= 0; index--) {
        std::shared_ptr<SpeedRecordOld> temp = buffer[index];
        if (temp == nullptr) continue;
        std::shared_ptr<SpeedRecordOld> lastRecord = buffer[length - 1];
        preIndexName = length - index;
        std::string fstr("f");
        char preIndexNameStr[25];
        sprintf(preIndexNameStr, " %d" , preIndexName);
        fstr.append(std::string(preIndexNameStr));

        char bytesStr[25];
        sprintf(bytesStr, " %" PRId64 "" , temp->bytes);
        input[fstr] =  std::string(bytesStr);

        float speedTemp = (double)temp->bytes / (double)temp->time;
        std::string sstr("s");
        sstr.append(std::string(preIndexNameStr));
        char speedTempStr[25];
        sprintf(speedTempStr, " %f" , speedTemp);
        input[sstr] =  std::string(speedTempStr);

        std::string istr("i");
        istr.append(std::string(preIndexNameStr));
        char timestampStr[25];
        sprintf(timestampStr, " %" PRId64 "" , (lastRecord->timestamp - temp->timestamp));
        input[istr] =  std::string(timestampStr);
    }
    std::lock_guard<std::mutex> speedmlx(speedMtx);
    std::vector<float> vec = componentWrapper->calculate(input);
    if(vec.size() > 0) {
        mSpeed = vec[0];
    }
    return mSpeed;
}


NETWORKPREDICT_NAMESPACE_END