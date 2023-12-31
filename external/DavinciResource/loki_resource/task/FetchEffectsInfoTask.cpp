//
// Created by bytedance on 2021/4/16.
//

#include "FetchEffectsInfoTask.h"
#include "DAVFile.h"
#include <sys/stat.h>

davinci::loki::FetchEffectsInfoTask::FetchEffectsInfoTask(const davinci::loki::LokiResourceConfig &config,
                                                          const std::shared_ptr<davinci::resource::DAVResource> &davinciResource,
                                                          const std::unordered_map<std::string, std::string> &extraParams) {
    this->url = buildRequestUrl(config, davinciResource);
    this->extraParams = extraParams;
    this->cacheDir = config.effectCacheDir;
}

void davinci::loki::FetchEffectsInfoTask::run() {
    auto effectInfo = davinci::loki::LokiResourceUtils::getEffectInfoFromExtraParams(extraParams);
    if (effectInfo != nullptr && !effectInfo->file_url.empty()) {
        bundle->putModel(davinci::loki::LokiConstanceDefine::PARAM_EFFECT_INFO, effectInfo);
        notifyBehindTasksSuccess();
    } else {
        BaseUrlFetcherTask::run();
    }
}

std::string
davinci::loki::FetchEffectsInfoTask::buildRequestUrl(const davinci::loki::LokiResourceConfig &config,
                                                     const std::shared_ptr<davinci::resource::DAVResource> &davinciResource) {
    using namespace davinci::loki;
    auto parser = std::make_shared<davinci::resource::DAVResourceIdParser>(
            davinciResource->getResourceId());
    auto resourceParam = parser->queryParams;
    std::unordered_map<std::string, std::string> requestParams;
    std::string path;
    if (resourceParam.find(LokiResourceProtocol::PARAM_EFFECT_ID()) != resourceParam.end()) {
        std::string effectId = resourceParam.at(LokiResourceProtocol::PARAM_EFFECT_ID());
        requestParams["effect_ids"] = "[\"" + effectId + "\"]";
        path = "/effect/api/v3/effect/list";
    }
    if (resourceParam.find(LokiResourceProtocol::PARAM_RESOURCE_ID()) != resourceParam.end() &&
        resourceParam.find(LokiResourceProtocol::PARAM_PANEL()) != resourceParam.end()) {
        std::string resourceId = resourceParam.at(LokiResourceProtocol::PARAM_RESOURCE_ID());
        std::string panel = resourceParam.at(LokiResourceProtocol::PARAM_PANEL());
        requestParams["resource_ids"] = "[\"" + resourceId + "\"]";
        requestParams[LokiResourceProtocol::PARAM_PANEL()] = panel;
        path = "/effect/api/v3/effect/listByResourceId";
    }
    std::unordered_map<std::string, std::string> commonParams = config.getRequestParams();

    requestParams.insert(extraParams.begin(), extraParams.end());

    requestParams.insert(commonParams.begin(), commonParams.end());
    return config.host + path + davinci::resource::DAVPublicUtil::map_to_query_params(requestParams);
}

void davinci::loki::FetchEffectsInfoTask::processResponse(std::shared_ptr<davinci::loki::EffectListResponse> response) {
    if (!(*response).data.empty()) {
        auto effectInfo = response->data.at(0);
        bundle->putModel(davinci::loki::LokiConstanceDefine::PARAM_EFFECT_INFO, std::make_shared<Effect>(effectInfo));
        auto effectCacheDir = this->cacheDir + "/" + effectInfo.effect_id;
        bundle->putString(davinci::loki::LokiConstanceDefine::PARAM_EFFECT_CACHE_DIR, effectCacheDir);
        if (!davinci::file::DAVFile::isDirExist(effectCacheDir)) {
            davinci::file::DAVFile::mkdir(effectCacheDir, S_IRWXU | S_IRWXG | S_IROTH);
        }
        auto effectJsonFile = effectCacheDir + "/" + LokiConstanceDefine::CACHE_JSON_FILE_NAME;
        auto effectJson = nlohmann::json(effectInfo);
        auto effectJsonString = effectJson.dump(4);
        davinci::file::DAVFile::write(effectJsonFile, effectJsonString.c_str(), effectJsonString.size());
    }
}
