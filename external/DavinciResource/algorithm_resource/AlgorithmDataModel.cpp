//
// Created by wangchengyi.1 on 2021/5/8.
//

#include "AlgorithmDataModel.h"
#include <nlohmann/json.hpp>

void davinci::algorithm::from_json(const nlohmann::json &j, davinci::algorithm::AlgorithmUrlModel &urlModel) {
    if (j.find("url_list") != j.end()) {
        urlModel.url_list = j.at("url_list").get<std::vector<std::string>>();
    }
    if (j.find("zip_url_list") != j.end()) {
        urlModel.zip_url_list = j.at("zip_url_list").get<std::vector<std::string>>();
    }
    if (j.find("uri") != j.end()) {
        j.at("uri").get_to(urlModel.uri);
    }
}

void davinci::algorithm::from_json(const nlohmann::json &j, davinci::algorithm::ModelInfo &modelInfo) {
    if (j.find("name") != j.end()) {
        j.at("name").get_to(modelInfo.name);
    }
    if (j.find("type") != j.end()) {
        j.at("type").get_to(modelInfo.type);
    }
    if (j.find("version") != j.end()) {
        j.at("version").get_to(modelInfo.version);
    }
    if (j.find("file_url") != j.end()) {
        modelInfo.file_url = j.at("file_url").get<AlgorithmUrlModel>();
    }
    if (j.find("status") != j.end()) {
        j.at("status").get_to(modelInfo.status);
    }
}

void davinci::algorithm::from_json(const nlohmann::json &j, davinci::algorithm::ModelInfoMap &modelInfoMap) {
    if (j.find("arithmetics") != j.end()) {
        modelInfoMap.arithmetics = j.at("arithmetics").get<std::unordered_map<std::string, std::vector<ModelInfo>>>();
    }
}

void davinci::algorithm::from_json(const nlohmann::json &j, davinci::algorithm::ModelInfoResponse &modelsInfoResponse) {
    if (j.find("data") != j.end()) {
        modelsInfoResponse.data = j.at("data").get<ModelInfoMap>();
    }
    if (j.find("status_code") != j.end()) {
        j.at("status_code").get_to(modelsInfoResponse.status_code);
    }
    if (j.find("message") != j.end()) {
        j.at("message").get_to(modelsInfoResponse.message);
    }
}
