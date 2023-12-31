//
// Created by wangchengyi.1 on 2021/5/8.
//

#include "DownloadModelTask.h"
#include "DavinciLogger.h"
#include "../ModelsInfoCache.h"
#include "../AlgorithmResourceUtils.h"

using davinci::algorithm::DownloadModelTask;
using davinci::algorithm::AlgorithmResourceConfig;

davinci::algorithm::DownloadModelTask::DownloadModelTask(davinci::algorithm::AlgorithmResourceConfig config,
                                                         std::string modelName,
                                                         std::shared_ptr<davinci::resource::DAVResourceManager> resourceManager)
        : config(std::move(config)), modelName(std::move(modelName)),
          resourceManager(std::move(resourceManager)) {

}

void davinci::algorithm::DownloadModelTask::run() {
    LOGGER->i("DownloadModelTask");
    auto modelInfo = ModelsInfoCache::getInstance().getModelInfo(
            AlgorithmResourceUtils::getNormalizedNameOfModel(this->modelName));

    if (modelInfo == nullptr) {
        notifyBehindTasksFailed("get modelInfo failed! model name:" + this->modelName);
        return;
    }
    if (AlgorithmResourceUtils::isModelDownloaded(config.cacheDir, this->modelName, modelInfo)) {
        notifyBehindTasksSuccess();
        return;
    }
    fetchUrlListWithIndex(modelInfo->file_url.url_list, 0, modelInfo->file_url.uri, modelInfo);
}

void davinci::algorithm::DownloadModelTask::fetchUrlListWithIndex(const std::vector<std::string> &file_url, int index,
                                                                  const std::string &uri,
                                                                  const std::shared_ptr<davinci::algorithm::ModelInfo> &modelInfo) {
    if (index >= file_url.size() || index < 0) {
        notifyBehindTasksFailed("failed!");
        return;
    }
    auto urlResourceId = "dav://url_resource?http_url=" + file_url[index];
    auto urlResource = std::make_shared<davinci::resource::DAVResource>(urlResourceId);
    std::unordered_map<std::string, std::string> extraMap;
    extraMap["save_path"] = config.cacheDir + "/" + AlgorithmResourceUtils::getFullNameOfModel(modelInfo);
    extraMap["md5"] = uri;
    auto self = this->shared_from_this();
    auto cacheDir = config.cacheDir;
    resourceManager->fetchResource(urlResource, extraMap,
                                   std::make_shared<davinci::resource::StdFunctionDAVResourceFetchCallback>(
                                           [self, modelInfo, cacheDir](
                                                   const std::shared_ptr<davinci::resource::DAVResource> &davinciResource) {
                                               LOGGER->i("success in fetch resource! %s",
                                                         davinciResource->toString().c_str());
                                               AlgorithmResourceUtils::clearOldVersionOfModel(cacheDir, modelInfo);
                                               self->notifyBehindTasksSuccess();
                                           },
                                           [self, modelInfo](long progress) {

                                           },
                                           [self, modelInfo, file_url, uri, index](
                                                   davinci::resource::DRResult error) {
                                               LOGGER->e("failed in fetch resource!");
                                               std::dynamic_pointer_cast<DownloadModelTask>(
                                                       self)->fetchUrlListWithIndex(file_url, index + 1, uri,
                                                                           modelInfo);
                                           }));
}
