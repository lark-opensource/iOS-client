//
// Created by wangchengyi.1 on 2021/5/7.
//

#include "AlgorithmResourceHandler.h"

#include <utility>
#include <iostream>
#include <sys/stat.h>
#include "AlgorithmResourceProtocol.h"
#include "DAVResourceIdParser.h"
#include "DavinciLogger.h"
#include "AlgorithmResourceParser.h"
#include "task/FetchModelInfoTask.h"
#include "task/DownloadModelTask.h"
#include "AlgorithmConstantsDefine.h"
#include "AlgorithmResourceUtils.h"
#include "ModelsInfoCache.h"
#include "DAVFile.h"

using namespace davinci::resource;
using namespace davinci::algorithm;
using davinci::algorithm::AlgorithmResourceHandler;
namespace davinci {
    namespace algorithm {
        static bool endsWith(const std::string &s, const std::string &sub) {
            return s.rfind(sub) == (s.length() - sub.length());
        }
    }
}

davinci::algorithm::AlgorithmResourceHandler::AlgorithmResourceHandler(
        davinci::algorithm::AlgorithmResourceConfig config) : config(std::move(config)) {

}

std::string
davinci::algorithm::AlgorithmResourceHandler::findModelUri(const std::string &modelName) {
    auto normalizedModelName = AlgorithmResourceUtils::getNormalizedNameOfModel(modelName);
    std::vector<std::string> fileList;
    davinci::file::DAVFile::getFileList(config.cacheDir, fileList);
    for (const auto &fileName: fileList) {
        auto normalizedFileName = AlgorithmResourceUtils::getNormalizedNameOfModel(fileName);
        if (normalizedFileName == normalizedModelName && !endsWith(fileName, "_temp")) {
            return AlgorithmConstantsDefine::MODEL_RESOURCE_URI_PREFIX() + config.cacheDir + "/" +
                   fileName;
        }
    }
    return AlgorithmConstantsDefine::MODEL_NOT_FOUND();
}

davinci::resource::DAVResourceTaskHandle
davinci::algorithm::AlgorithmResourceHandler::fetchResource(
        const std::shared_ptr<davinci::resource::DAVResource> &davinciResource,
        const std::unordered_map<std::string, std::string> &extraParams,
        const std::shared_ptr<davinci::resource::DAVResourceFetchCallback> &callback) {
    LOGGER->d("fetch algorithm in AlgorithmResourceHandler: %s",
              davinciResource->toString().c_str());
    if (!davinci::file::DAVFile::isDirExist(config.cacheDir)) {
        davinci::file::DAVFile::mkdir(config.cacheDir, S_IRWXU);
    }
    AlgorithmResourceParser parser = AlgorithmResourceParser(
            AlgorithmResourceGlobalSettings::getRequirementsPeeker(),
            davinciResource->getResourceId());
    std::vector<std::string> modelNames;
    modelNames.insert(modelNames.end(), parser.modelNames.begin(), parser.modelNames.end());
    if (modelNames.empty()) {
        LOGGER->e("model name is empty! resourceId: %s", davinciResource->getResourceId().c_str());
        if (callback != nullptr) {
            callback->onError(-1);
        }
        return 0;
    }
    auto builder = davinci::task::TaskGraphBuilder(taskManager->getExecutor());

    auto fetchModelInfoTask = std::make_shared<davinci::algorithm::FetchModelInfoTask>(config, modelNames, extraParams);

    builder.add(fetchModelInfoTask);
    for (auto &modelName : modelNames) {
        auto downloadModelInfo = std::make_shared<davinci::algorithm::DownloadModelTask>(config,
                                                                                         modelName,
                                                                                         resourceManager);
        builder.add(downloadModelInfo).dependOn(fetchModelInfoTask);
    }

    builder.onSuccess([callback, davinciResource]() {
        if (callback != nullptr) {
            callback->onSuccess(davinciResource);
        }
    }).onFail([callback](const std::string &error) {
        std::cout << "download models failed!! error:" + error
                  << std::endl;
        if (callback != nullptr) {
            callback->onError(-1);
        }
    });
    taskManager->commit(builder.build());
    return 0;
}

std::shared_ptr<davinci::resource::DAVResource>
davinci::algorithm::AlgorithmResourceHandler::fetchResourceFromCache(
        const DavinciResourceId &davinciResourceId,
        const std::unordered_map<std::string, std::string> &extraParams) {
    LOGGER->d("fetch algorithm from cache in AlgorithmResourceHandler: %s",
              davinciResourceId.c_str());
    if (!davinci::file::DAVFile::isDirExist(config.cacheDir)) {
        davinci::file::DAVFile::mkdir(config.cacheDir, S_IRWXU);
    }
    AlgorithmResourceParser parser = AlgorithmResourceParser(
            AlgorithmResourceGlobalSettings::getRequirementsPeeker(),
            davinciResourceId);
    std::vector<std::string> modelNames;
    modelNames.insert(modelNames.end(), parser.modelNames.begin(), parser.modelNames.end());
    if (modelNames.empty()) {
        LOGGER->e("model name is empty! resourceId: %s", davinciResourceId.c_str());
        return nullptr;
    }
    if (modelNames.size() > 1) {
        LOGGER->e("can not fetch multiple model names from cache! resourceId: %s",
                  davinciResourceId.c_str());
        return nullptr;
    }
    auto modelUri = AlgorithmResourceHandler::findModelUri(modelNames[0]);
    auto resource = std::make_shared<DAVResource>(davinciResourceId);
    auto modelPath = AlgorithmResourceUtils::getModelPathFromModelUri(modelUri);
    resource->setResourceFile(modelPath);
    return resource;
}

bool davinci::algorithm::AlgorithmResourceHandler::canHandle(
        const std::shared_ptr<davinci::resource::DAVResource> &davinciResource) {
    return AlgorithmResourceProtocol::isAlgorithmResource(davinciResource->getResourceId());
}

davinci::algorithm::AlgorithmResourceHandler::Builder &
davinci::algorithm::AlgorithmResourceHandler::Builder::appID(const std::string &appID) {
    config.appID = appID;
    return *this;
}

davinci::algorithm::AlgorithmResourceHandler::Builder &
davinci::algorithm::AlgorithmResourceHandler::Builder::accessKey(const std::string &accessKey) {
    config.accessKey = accessKey;
    return *this;
}

davinci::algorithm::AlgorithmResourceHandler::Builder &
davinci::algorithm::AlgorithmResourceHandler::Builder::sdkVersion(const std::string &sdkVersion) {
    config.sdkVersion = sdkVersion;
    return *this;
}

davinci::algorithm::AlgorithmResourceHandler::Builder &
davinci::algorithm::AlgorithmResourceHandler::Builder::appVersion(const std::string &appVersion) {
    config.appVersion = appVersion;
    return *this;
}

davinci::algorithm::AlgorithmResourceHandler::Builder &
davinci::algorithm::AlgorithmResourceHandler::Builder::deviceType(const std::string &deviceType) {
    config.deviceType = deviceType;
    return *this;
}

davinci::algorithm::AlgorithmResourceHandler::Builder &
davinci::algorithm::AlgorithmResourceHandler::Builder::deviceId(const std::string &deviceId) {
    config.deviceId = deviceId;
    return *this;
}

davinci::algorithm::AlgorithmResourceHandler::Builder &
davinci::algorithm::AlgorithmResourceHandler::Builder::cacheDir(const std::string &cacheDir) {
    config.cacheDir = cacheDir;
    ModelsInfoCache::getInstance().addCachePath(cacheDir);
    return *this;
}

davinci::algorithm::AlgorithmResourceHandler::Builder &
davinci::algorithm::AlgorithmResourceHandler::Builder::platform(const std::string &platform) {
    config.platform = platform;
    return *this;
}

davinci::algorithm::AlgorithmResourceHandler::Builder &
davinci::algorithm::AlgorithmResourceHandler::Builder::host(const std::string &host) {
    config.host = host;
    return *this;
}

davinci::algorithm::AlgorithmResourceHandler::Builder &
davinci::algorithm::AlgorithmResourceHandler::Builder::busiId(
    const std::string &busiId) {
  config.busiId = busiId;
  return *this;
}

davinci::algorithm::AlgorithmResourceHandler::Builder &
davinci::algorithm::AlgorithmResourceHandler::Builder::status(
    const std::string &status) {
  config.status = status;
  return *this;
}

std::shared_ptr<AlgorithmResourceHandler>
davinci::algorithm::AlgorithmResourceHandler::Builder::build() {
    return std::make_shared<AlgorithmResourceHandler>(config);
}
