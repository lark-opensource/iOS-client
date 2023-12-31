//
// Created by shen chen on 2020/9/14.
//

#ifndef VIDEOENGINE_NETWORKSPEEDRESULT_H
#define VIDEOENGINE_NETWORKSPEEDRESULT_H

#if defined(__ANDROID__)
#include <jni.h>
#endif
#include <stdint.h>
#include <string>
#include <vector>
#include <memory>

class NetworkSpeedResultItem {
public:
    NetworkSpeedResultItem(std::string loadType,std::string host, float bandwidth,int trackType);
    ~NetworkSpeedResultItem() {}
    std::string loadType;
    std::string host;
    float bandwidth;
    int trackType;
};

class NetworkSpeedResult {
public:
    NetworkSpeedResult() {}
    ~NetworkSpeedResult() {}
    std::string fileId;
    std::vector<std::shared_ptr<NetworkSpeedResultItem>> speedResultItems;
};

#endif //VIDEOENGINE_NETWORKSPEEDRESULT_H
