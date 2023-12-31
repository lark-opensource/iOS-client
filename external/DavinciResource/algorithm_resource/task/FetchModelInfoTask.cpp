//
// Created by wangchengyi.1 on 2021/5/10.
//

#include "FetchModelInfoTask.h"
#include "DAVPublicUtil.h"
#include "../ModelsInfoCache.h"
#include "../AlgorithmResourceUtils.h"

using davinci::algorithm::FetchModelInfoTask;

davinci::algorithm::FetchModelInfoTask::FetchModelInfoTask(const davinci::algorithm::AlgorithmResourceConfig &config,
                                                           const std::vector<std::string> &modelNames,
                                                           const std::unordered_map<std::string, std::string> &extraParams) {
    std::unordered_map<std::string, std::string> requestParams = config.getRequestParams();
    for (auto &modelName:modelNames) {
        auto normalizedName = AlgorithmResourceUtils::getNormalizedNameOfModel(modelName);
        if (ModelsInfoCache::getInstance().getModelInfo(normalizedName) != nullptr) {
            continue;
        }
        modelList += normalizedName;
        modelList += ",";
    }
    if (!modelList.empty()) {
        modelList = modelList.substr(0, modelList.size() - 1);
    }
    requestParams["required_model_list"] = modelList;
    if (!extraParams.empty()) {
        requestParams.insert(extraParams.begin(), extraParams.end());
    }
    std::string path = "/model/api/arithmetics";
    this->url = config.host + path + davinci::resource::DAVPublicUtil::map_to_query_params(requestParams);
}

void davinci::algorithm::FetchModelInfoTask::processResponse(
        std::shared_ptr<davinci::algorithm::ModelInfoResponse> response) {
    for (auto &entry: response->data.arithmetics) {
        for (auto &modelInfo: entry.second) {
            auto info = std::make_shared<davinci::algorithm::ModelInfo>(modelInfo);
            ModelsInfoCache::getInstance().saveModelInfo(modelInfo.name, info);
        }
    }
}

void davinci::algorithm::FetchModelInfoTask::run() {
    if (modelList.empty()) {
        notifyBehindTasksSuccess();
        return;
    }
    BaseUrlFetcherTask::run();
}
