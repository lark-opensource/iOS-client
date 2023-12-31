//
// Created by wangchengyi.1 on 2021/4/13.
//

#include <string>
#include "LokiResourceHandler.h"
#include "LokiResource.h"
#include "LokiResourceUtils.h"
#include "task/FetchEffectsInfoTask.h"
#include "task/DownloadEffectTask.h"
#include "task/FetchRequiredModelsTask.h"
#include "DAVFile.h"

using namespace davinci::loki;
using namespace davinci::resource;

DAVResourceTaskHandle
davinci::loki::LokiResourceHandler::fetchResource(const std::shared_ptr<DAVResource> &davinciResource,
                                                  const std::unordered_map<std::string, std::string> &extraParams,
                                                  const std::shared_ptr<DAVResourceFetchCallback> &callback) {

    auto builder = davinci::task::TaskGraphBuilder(taskManager->getExecutor(), std::make_shared<davinci::task::Bundle>());

    auto fetchEffectsInfoTask = std::make_shared<FetchEffectsInfoTask>(config, davinciResource, extraParams);

    auto downloadEffectTask = std::make_shared<DownloadEffectTask>(resourceManager, davinciResource);

    auto fetchModelsTask = std::make_shared<FetchRequiredModelsTask>(resourceManager);

    auto task = builder.add(fetchEffectsInfoTask)
            .add(downloadEffectTask).dependOn(fetchEffectsInfoTask)
            .add(fetchModelsTask).dependOn(fetchEffectsInfoTask)
            .onSuccess([callback, davinciResource]() {
                if (callback != nullptr) {
                    callback->onSuccess(davinciResource);
                }
            })
            .onFail([callback](const std::string &error) {
                if (callback != nullptr) {
                    callback->onError(-1);
                }
            })
            .build();
    return taskManager->commit(task);
}

bool LokiResourceHandler::canHandle(const std::shared_ptr<DAVResource> &davinciResource) {
    return LokiResourceProtocol::isLokiResource(davinciResource->getResourceId());
}

std::shared_ptr<DAVResource> LokiResourceHandler::fetchResourceFromCache(const DavinciResourceId &davinciResourceId,
                                                                         const std::unordered_map<std::string, std::string> &extraParams) {
    auto parser = std::make_shared<davinci::resource::DAVResourceIdParser>(davinciResourceId);
    auto resourceParam = parser->queryParams;
    std::unordered_map<std::string, std::string> requestParams;
    std::string path;
    std::string effectId;
    if (resourceParam.find(LokiResourceProtocol::PARAM_EFFECT_ID()) == resourceParam.end()) {
        return nullptr;
    } else {
        effectId = resourceParam.at(LokiResourceProtocol::PARAM_EFFECT_ID());
    }
    auto effectCacheDir = config.effectCacheDir + "/" + effectId;
    if (!davinci::file::DAVFile::isDirExist(effectCacheDir)) {
        return nullptr;
    }
    auto cacheJsonFile = effectCacheDir + "/" + LokiConstanceDefine::CACHE_JSON_FILE_NAME;
    if (!davinci::file::DAVFile::isFileExist(cacheJsonFile)) {
        return nullptr;
    }
    std::string effectJson;
    davinci::file::DAVFile::read(cacheJsonFile, effectJson);
    auto effectInfo = nlohmann::json::parse(effectJson).get<Effect>();
    auto effectMd5Path = effectCacheDir + "/" + effectInfo.md5;
    if (!davinci::file::DAVFile::isDirExist(effectMd5Path)) {
        return nullptr;
    }
    auto lokiResource = std::make_shared<DAVResource>(davinciResourceId);
    lokiResource->setResourceFile(effectMd5Path);
    return lokiResource;
}

LokiResourceHandler::Builder &LokiResourceHandler::Builder::appID(const std::string &appID) {
    config.appID = appID;
    return *this;
}

LokiResourceHandler::Builder &LokiResourceHandler::Builder::accessKey(const std::string &accessKey) {
    config.accessKey = accessKey;
    return *this;
}

LokiResourceHandler::Builder &LokiResourceHandler::Builder::channel(const std::string &channel) {
    config.channel = channel;
    return *this;
}

LokiResourceHandler::Builder &LokiResourceHandler::Builder::sdkVersion(const std::string &sdkVersion) {
    config.sdkVersion = sdkVersion;
    return *this;
}

LokiResourceHandler::Builder &LokiResourceHandler::Builder::appVersion(const std::string &appVersion) {
    config.appVersion = appVersion;
    return *this;
}

LokiResourceHandler::Builder &LokiResourceHandler::Builder::deviceType(const std::string &deviceType) {
    config.deviceType = deviceType;
    return *this;
}

LokiResourceHandler::Builder &LokiResourceHandler::Builder::deviceId(const std::string &deviceId) {
    config.deviceId = deviceId;
    return *this;
}

LokiResourceHandler::Builder &LokiResourceHandler::Builder::effectCacheDir(const std::string &effectCacheDir) {
    config.effectCacheDir = effectCacheDir;
    return *this;
}

LokiResourceHandler::Builder &LokiResourceHandler::Builder::platform(const std::string &platform) {
    config.platform = platform;
    return *this;
}

LokiResourceHandler::Builder &LokiResourceHandler::Builder::host(const std::string &host) {
    config.host = host;
    return *this;
}

std::shared_ptr<LokiResourceHandler> LokiResourceHandler::Builder::build() {
    if (config.accessKey.empty()) {
        LOGGER->e("DavinciResource:: LokiResourceHandler accessKey cannot be null");
        throw std::exception();
    }
    if (config.effectCacheDir.empty()) {
        LOGGER->e("DavinciResource:: LokiResourceHandler cacheDir cannot be null");
        throw std::exception();
    }
    if (!davinci::file::DAVFile::isDirExist(config.effectCacheDir)) {
        LOGGER->e("DavinciResource:: LokiResourceHandler cacheDir: %s not exists!", config.effectCacheDir.c_str());
        throw std::exception();
    }
    return std::shared_ptr<LokiResourceHandler>(new LokiResourceHandler(config));
}
