//
// Created by wangchengyi.1 on 2021/4/29.
//
#include "DAVCreator.h"
#include "DefaultResourceManager.h"
#include "DefaultResourceTaskManager.h"

using davinci::resource::DAVCreator;

std::shared_ptr<davinci::resource::DAVResourceManager> DAVCreator::createDefaultResourceManager() {
    auto resourceManager = std::make_shared<DefaultResourceManager>();
    return resourceManager;
}

std::shared_ptr<davinci::resource::DAVResourceTaskManager> DAVCreator::createDefaultTaskManager() {
    auto taskManager = std::make_shared<DefaultResourceTaskManager>();
    return taskManager;
}