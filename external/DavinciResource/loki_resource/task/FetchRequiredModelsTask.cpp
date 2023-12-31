//
// Created by wangchengyi.1 on 2021/5/6.
//

#include "FetchRequiredModelsTask.h"
#include "DavinciLogger.h"
#include "DAVPublicUtil.h"
#include "../LokiConstanceDefine.h"
#include <utility>

using davinci::loki::FetchRequiredModelsTask;

davinci::loki::FetchRequiredModelsTask::FetchRequiredModelsTask(std::shared_ptr<davinci::resource::DAVResourceManager> resourceManager)
        : resourceManager(std::move(resourceManager)) {

}

void davinci::loki::FetchRequiredModelsTask::run() {
    auto effectInfo = std::dynamic_pointer_cast<Effect>(
            bundle->getModel(LokiConstanceDefine::PARAM_EFFECT_INFO));
    if (effectInfo == nullptr) {
        notifyBehindTasksFailed("get effectInfo failed!");
        return;
    }

    if (effectInfo->requirements.empty() && effectInfo->model_names.empty()) {
        notifyBehindTasksSuccess();
        return;
    }
    std::vector<std::string> requirements = effectInfo->requirements;
    std::string modelNames = effectInfo->model_names;
    auto algorithmResourceId = "dav://algorithm_resource?model_name_map=" + modelNames + "&requirements=" +
                               davinci::resource::DAVPublicUtil::vector_join_to_string(requirements, ",", "[", "]");
    auto algorithmResource = std::make_shared<davinci::resource::DAVResource>(algorithmResourceId);
    std::unordered_map<std::string, std::string> extraMap;
    LOGGER->i("FetchRequiredModelsTask, resource url: %s", algorithmResourceId.c_str());
    auto self = this->shared_from_this();
    resourceManager->fetchResource(algorithmResource, extraMap,
                                   std::make_shared<davinci::resource::StdFunctionDAVResourceFetchCallback>(
                                           [self](
                                                   const std::shared_ptr<davinci::resource::DAVResource> &davinciResource) {
                                               LOGGER->i("success in fetch resource! %s",
                                                         davinciResource->toString().c_str());

                                               self->notifyBehindTasksSuccess();
                                           },
                                           [self](long progress) {

                                           },
                                           [self](davinci::resource::DRResult error) {
                                               LOGGER->e("failed in fetch resource!");
                                               self->notifyBehindTasksFailed("failed in fetch algorithm resource!");
                                           }));
}
