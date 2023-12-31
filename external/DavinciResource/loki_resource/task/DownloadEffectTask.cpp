//
// Created by wangchengyi.1 on 2021/4/28.
//

#include <utility>
#include <DAVFile.h>
#include "DownloadEffectTask.h"
#include "DavinciLogger.h"
#include "Bundle.h"
#include "../LokiConstanceDefine.h"

using davinci::loki::DownloadEffectTask;
using davinci::resource::DAVResource;
using davinci::resource::DRResult;

DownloadEffectTask::DownloadEffectTask(std::shared_ptr<davinci::resource::DAVResourceManager> resourceManager,
                                       std::shared_ptr<davinci::resource::DAVResource> davinciResource,
                                       std::function<void(
                                               std::shared_ptr<DAVResource> davinciResource)> onSuccess,
                                       std::function<void(int, long)> onProgress,
                                       std::function<void(const std::string &)> onFail)
        : resourceManager(std::move(resourceManager)),
          davinciResource(std::move(davinciResource)),
          onSuccess(std::move(onSuccess)),
          onProgress(std::move(onProgress)),
          onFail(std::move(onFail)) {

}

void davinci::loki::DownloadEffectTask::run() {
    auto effectInfo = std::dynamic_pointer_cast<Effect>(
            bundle->getModel(LokiConstanceDefine::PARAM_EFFECT_INFO));
    auto effectCacheDir = bundle->getString(LokiConstanceDefine::PARAM_EFFECT_CACHE_DIR);
    if (effectInfo == nullptr || effectCacheDir.empty()) {
        onFail("get effectInfo failed!");
        notifyBehindTasksFailed("get effectInfo failed!");
        return;
    }

    std::string filePath = effectCacheDir + "/" + effectInfo->md5;
    fetchUrlListWithIndex(effectInfo->file_url, 0, filePath, effectInfo->md5);
}

void
davinci::loki::DownloadEffectTask::fetchUrlListWithIndex(const std::vector<std::string> &file_url,
                                                         int index,
                                                         const std::string &filePath,
                                                         const std::string &md5) {
    if (index >= file_url.size() || index < 0) {
        if (onFail != nullptr) {
            onFail("failed");
        }
        notifyBehindTasksFailed("failed!");
        return;
    }
    auto urlResourceId = "dav://url_resource?http_url=" + file_url[index];
    auto urlResource = std::make_shared<davinci::resource::DAVResource>(urlResourceId);
    std::unordered_map<std::string, std::string> extraMap;
    extraMap["save_path"] = filePath;
    extraMap["md5"] = md5;
    extraMap["auto_unzip"] = "true";
    auto self = this->shared_from_this();
    auto davinciResource = this->davinciResource;
    resourceManager->fetchResource(urlResource, extraMap,
                                   std::make_shared<davinci::resource::StdFunctionDAVResourceFetchCallback>(
                                           [self, file_url, index, filePath, md5, davinciResource](
                                                   const std::shared_ptr<DAVResource> &fileResource) {
                                               LOGGER->i("success in fetch resource! %s",
                                                         fileResource->toString().c_str());
                                               davinciResource->setResourceFile(filePath);
                                               auto runningSelf = std::dynamic_pointer_cast<DownloadEffectTask>(
                                                       self);
                                               if (runningSelf->onSuccess != nullptr) {
                                                   runningSelf->onSuccess(davinciResource);
                                               }
                                               self->notifyBehindTasksSuccess();
                                           },
                                           [self](long progress) {
                                               auto runningSelf = std::dynamic_pointer_cast<DownloadEffectTask>(
                                                       self);
                                               if (runningSelf->onProgress != nullptr) {
                                                   runningSelf->onProgress(progress * 100, 1);
                                               }
                                           },
                                           [self, file_url, index, filePath, md5](DRResult error) {
                                               LOGGER->e("failed in fetch resource!");
                                               std::dynamic_pointer_cast<DownloadEffectTask>(
                                                       self)->fetchUrlListWithIndex(file_url, index + 1, filePath, md5);
                                           }));
}
