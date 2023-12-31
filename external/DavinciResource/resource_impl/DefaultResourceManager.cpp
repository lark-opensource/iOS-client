//
// Created by wangchengyi.1 on 2021/4/13.
//

#include "DefaultResourceManager.h"
#include "DAVCreator.h"

using namespace davinci::resource;

DefaultResourceManager::DefaultResourceManager() {
    taskManager = DAVCreator::createDefaultTaskManager();
}

DAVResourceTaskHandle
davinci::resource::DefaultResourceManager::fetchResource(std::shared_ptr<DAVResource> &davinciResource,
                                                         const std::unordered_map<std::string, std::string> &extraParams,
                                                         const std::shared_ptr<DAVResourceFetchCallback> &callback) {
    for (const auto &handle: resourceHandlers) {
        if (handle->canHandle(davinciResource)) {
            return handle->fetchResource(davinciResource, extraParams, callback);
        }
    }
    return -1;
}

std::shared_ptr<DAVResource> DefaultResourceManager::fetchResourceFromCache(const DavinciResourceId &davinciResourceId,
                                                                            const std::unordered_map<std::string, std::string> &extraParams) {
    auto resource = std::make_shared<DAVResource>(davinciResourceId);
    for (const auto &handle: resourceHandlers) {
        if (handle->canHandle(resource)) {
            return handle->fetchResourceFromCache(davinciResourceId, extraParams);
        }
    }
    return nullptr;
}

DRResult DefaultResourceManager::registerResourceHandler(const std::shared_ptr<DAVResourceHandler> &resourceHandler) {
    resourceHandler->taskManager = getTaskManager();
    resourceHandler->resourceManager = shared_from_this();
    resourceHandlers.emplace_back(resourceHandler);
    return 0;
}

std::shared_ptr<DAVResourceTaskManager> DefaultResourceManager::getTaskManager() {
    return taskManager;
}

