//
// Created by wangchengyi.1 on 2021/5/27.
//
#include "LokiResourceUtils.h"

using davinci::loki::LokiResourceUtils;

std::shared_ptr<davinci::loki::Effect> davinci::loki::LokiResourceUtils::getEffectInfoFromExtraParams(
        const std::unordered_map<std::string, std::string> &extraParams) {
    if (extraParams.find("url_list") == extraParams.end()) {
        return nullptr;
    }
    auto effectInfo = std::make_shared<davinci::loki::Effect>();
    if (extraParams.find("url_list") != extraParams.end()) {
        nlohmann::json j = nlohmann::json::parse(extraParams.find("url_list")->second);
        effectInfo->file_url = j.get<std::vector<std::string>>();
    }
    if (extraParams.find("requirements") != extraParams.end()) {
        nlohmann::json j = nlohmann::json::parse(extraParams.find("requirements")->second);
        effectInfo->file_url = j.get<std::vector<std::string>>();
    }
    if (extraParams.find("effect_id") != extraParams.end()) {
        effectInfo->effect_id = extraParams.find("effect_id")->second;
    }
    if (extraParams.find("resource_id") != extraParams.end()) {
        effectInfo->resource_id = extraParams.find("resource_id")->second;
    }
    if (extraParams.find("md5") != extraParams.end()) {
        effectInfo->md5 = extraParams.find("md5")->second;
    }
    if (extraParams.find("name") != extraParams.end()) {
        effectInfo->name = extraParams.find("name")->second;
    }
    if (extraParams.find("model_names") != extraParams.end()) {
        effectInfo->model_names = extraParams.find("model_names")->second;
    }
    return effectInfo;
}
