//
// Created by shen chen on 2021/3/12.
//

#include "include/ANetSpeedPredictIES.h"
#include <algorithm>
#include <math.h>

NETWORKPREDICT_NAMESPACE_BEGIN

int ANetSpeedPredictIES::DEFAULT_QUEUE_CAPACITY = 10;
int ANetSpeedPredictIES::DEAFULT_SPEED_RECORD_VALID_THRESHOLD = 1;
double ANetSpeedPredictIES::INVALID_SPEED = -1.0;
double ANetSpeedPredictIES::VALID_SPEED_MIN = 0.001;

bool compSpeedRecordOld(std::shared_ptr<SpeedRecordOld> a,std::shared_ptr<SpeedRecordOld> b) {
    return (a->speedInbPS < b->speedInbPS);
}

ANetSpeedPredictIES::ANetSpeedPredictIES():mSpeed(0),mDefaultInitalSpeed(INVALID_SPEED),mAverageSpeed(INVALID_SPEED),maxCapacity(DEFAULT_QUEUE_CAPACITY) {
    LOGD("use ANetSpeedPredictIES algorithm");
}

ANetSpeedPredictIES::~ANetSpeedPredictIES() {

}

void ANetSpeedPredictIES::setConfigSpeedInfo(std::map<std::string, std::string> feature) {
    std::lock_guard<std::mutex> mlx(mtx);
    if (feature.count("queueCapacity") > 0) {
        std::string value = feature["queueCapacity"];
        int newSize = atoi(value.c_str());
        DEFAULT_QUEUE_CAPACITY = newSize;
        maxCapacity = newSize;
        LOGD("shenchenspeed newSize:%d",maxCapacity);
        if (speedRecordQueue.size() > maxCapacity) {
           std::deque<std::shared_ptr<SpeedRecordOld>> newqueue;
            for (int i = 0; i < maxCapacity; ++i) {
               newqueue.push_back(speedRecordQueue.front());
               speedRecordQueue.pop_front();
            }
            while (!speedRecordQueue.empty()) {
                speedRecordQueue.pop_front();
            }
            speedRecordQueue = newqueue;
        }
    }
}

void ANetSpeedPredictIES::setSpeedQueueSize(int size) {
    std::lock_guard<std::mutex> mlx(mtx);
    if (size >= 1)  {
        if (size >= maxCapacity) {
           maxCapacity = size;
        } else if (size < maxCapacity) {
            maxCapacity = size;
            if (speedRecordQueue.size() > size) {
                std::deque<std::shared_ptr<SpeedRecordOld>> newqueue;
                for (int i = 0; i < maxCapacity; ++i) {
                    newqueue.push_back(speedRecordQueue.front());
                    speedRecordQueue.pop_front();
                }
                while (!speedRecordQueue.empty()) {
                    speedRecordQueue.pop_front();
                }
                speedRecordQueue = newqueue;
            }
        }
    }
}

void ANetSpeedPredictIES::prepare() {
}

void ANetSpeedPredictIES::start() {
}
void ANetSpeedPredictIES::stop() {
}

void ANetSpeedPredictIES::updateOldWithStreamId(std::shared_ptr<SpeedRecordOld> speedRecord, std::map<std::string, int> mediaInfo) {
    std::lock_guard<std::mutex> mlx(mtx);
    if (speedRecord->time != 0) {
        if (speedRecordQueue.size() < maxCapacity) {
            speedRecordQueue.push_back(speedRecord);
        } else {
            speedRecordQueue.pop_front();
            speedRecordQueue.push_back(speedRecord);
        }
    }
}

void ANetSpeedPredictIES::updateSpeed(double speed, long size, long costTime, long timestamp) {
    std::lock_guard<std::mutex> mlx(mtx);
    std::shared_ptr<SpeedRecordOld> speedRecord;
    if (mRecycledSpeedRecord != nullptr) {
       speedRecord = mRecycledSpeedRecord;
       mRecycledSpeedRecord = nullptr;
    } else {
        speedRecord = std::make_shared<SpeedRecordOld>();
    }
    speedRecord->speedInbPS = speed;
    speedRecord->time = costTime;
    speedRecord->bytes = size;
    speedRecord->timestamp = timestamp;
    if (speedRecordQueue.size() < maxCapacity) {
        speedRecordQueue.push_back(speedRecord);
    } else {
        mRecycledSpeedRecord = speedRecordQueue.front();
        speedRecordQueue.pop_front();
        speedRecordQueue.push_back(speedRecord);
    }
    mAverageSpeed = INVALID_SPEED;
}

void ANetSpeedPredictIES::close() {

}

double ANetSpeedPredictIES::getSpeed() {
    double result = mAverageSpeed;
    if (mAverageSpeed == INVALID_SPEED) {
        std::lock_guard<std::mutex> mlx(mtx);
        if (mAverageSpeed == INVALID_SPEED) {
            result = calculate();
            mAverageSpeed = result;
        } else {
            result = mAverageSpeed;
        }
    }
    if (result <= VALID_SPEED_MIN && mDefaultInitalSpeed > VALID_SPEED_MIN) {
        result = mDefaultInitalSpeed;
    }
    return result;
}

float ANetSpeedPredictIES::getPredictSpeed(int media_type) {
    return getSpeed();
}

float ANetSpeedPredictIES::calculate() {
    float speed = -1;
    if (speedRecordQueue.size() < DEAFULT_SPEED_RECORD_VALID_THRESHOLD) {
        return speed;
    }

    std::vector<std::shared_ptr<SpeedRecordOld>> buffer;
    for (int i = 0; i < speedRecordQueue.size(); ++i) {
       buffer.push_back(speedRecordQueue[i]);
    }

   //buffer排序
    std::sort(buffer.begin(),buffer.end(),compSpeedRecordOld);

    int start = 0, end = speedRecordQueue.size();

    // weighted median
    double targetWeight = 0;
    for (int i = start; i < end; i++) {
        targetWeight += buffer[i]->bytes;
    }
    targetWeight /= 2.0;

    float result = -1;
    for (int i = start; i < end; i++) {
        targetWeight -= buffer[i]->bytes;
        if (targetWeight <= 0) {
            float speedresult = buffer[i]->speedInbPS;
            result = speedresult;
            break;
        }
    }
    if (result < 0) {
        return -1.0;
    }
    speed = result;
    return result;
}

std::map<std::string, std::string> ANetSpeedPredictIES::getDownloadSpeed(int media_type) {
    return std::map<std::string, std::string>();
}

int ANetSpeedPredictIES::getAverageSpeedForIes() {//这里的单位是B/ms或者KB/s{
    int intAverageSpeed;
    double doubleAverageSpeed = getSpeed();
    if (fabs(doubleAverageSpeed - INVALID_SPEED) <= 1e-6) {
        intAverageSpeed = -1;
    } else {
        intAverageSpeed = (int) (doubleAverageSpeed / 8.0 /1000.0);
    }
    return intAverageSpeed;
}

NETWORKPREDICT_NAMESPACE_END
