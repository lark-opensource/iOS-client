//
// Created by bytedance on 2021/4/19.
//
#include "ModelsInfoCache.h"

ModelsInfoCache &ModelsInfoCache::getInstance() {
    static ModelsInfoCache m_pInstance;
    return m_pInstance;
}

std::shared_ptr<davinci::algorithm::ModelInfo> ModelsInfoCache::getModelInfo(const std::string &modelName) {
    if (modelName.empty()) {
        return nullptr;
    }
    std::lock_guard<std::mutex> lock(mutex);
    auto modelInfo = modelInfoMap.find(modelName);
    if (modelInfo != modelInfoMap.end()) {
        return modelInfo->second;
    }
    return nullptr;
}

void ModelsInfoCache::saveModelInfo(const std::string &modelName,
                                    const std::shared_ptr<davinci::algorithm::ModelInfo> &modelInfo) {
    std::lock_guard<std::mutex> lock(mutex);
    modelInfoMap[modelName] = modelInfo;
}

void ModelsInfoCache::removeModelInfo(const std::string &modelName) {
    std::lock_guard<std::mutex> lock(mutex);
    modelInfoMap.erase(modelName);
}

void ModelsInfoCache::clear() {
    std::lock_guard<std::mutex> lock(mutex);
    modelInfoMap.clear();
}

std::unordered_set<std::string> ModelsInfoCache::getAllCachePaths() const {
    return *modelCachePaths;
}

void ModelsInfoCache::addCachePath(const std::string &path) {
    std::lock_guard<std::mutex> lock(mutex);
    modelCachePaths->insert(path);
}
