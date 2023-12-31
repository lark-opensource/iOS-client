//
// Created by bytedance on 2021/4/21.
//

#include "LokiResourceConfig.h"

std::unordered_map<std::string, std::string> davinci::loki::LokiResourceConfig::getRequestParams() const {
    std::unordered_map<std::string, std::string> requestParams;
    if (!appID.empty()) {
        requestParams["aid"] = appID;
    }
    if (!accessKey.empty()) {
        requestParams["access_key"] = accessKey;
    }
    if (!channel.empty()) {
        requestParams["channel"] = channel;
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
    return requestParams;
}
