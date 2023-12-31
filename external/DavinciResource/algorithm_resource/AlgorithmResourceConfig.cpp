//
// Created by wangchengyi.1 on 2021/5/27.
//
#include "AlgorithmResourceConfig.h"

using davinci::algorithm::AlgorithmResourceConfig;

std::unordered_map<std::string, std::string> davinci::algorithm::AlgorithmResourceConfig::getRequestParams() const {
    std::unordered_map<std::string, std::string> requestParams;
    if (!appID.empty()) {
        requestParams["aid"] = appID;
    }
    if (!accessKey.empty()) {
        requestParams["access_key"] = accessKey;
    }
    if (!sdkVersion.empty()) {
        requestParams["sdk_version"] = sdkVersion;
    }
    if (!appVersion.empty()) {
        requestParams["app_version"] = appVersion;
    }
    if (!deviceType.empty()) {
        requestParams["device_type"] = deviceType;
    }
    if (!deviceId.empty()) {
        requestParams["device_id"] = deviceId;
    }
    if (!platform.empty()) {
        requestParams["device_platform"] = platform;
    }
    if (!busiId.empty()) {
      requestParams["busi_id"] = busiId;
    }
    if (!status.empty()) {
      requestParams["status"] = status;
    }

    return requestParams;
}
