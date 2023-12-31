//
// Created by bytedance on 2021/4/19.
//

#ifndef DAVINCIRESOURCE_MODELSINFOCACHE_H
#define DAVINCIRESOURCE_MODELSINFOCACHE_H

#include <unordered_map>
#include <unordered_set>
#include "AlgorithmDataModel.h"

class ModelsInfoCache {
private:
    ModelsInfoCache() = default;
    ~ModelsInfoCache() = default;
public:
    ModelsInfoCache(const ModelsInfoCache&)            = delete;
    ModelsInfoCache& operator=(const ModelsInfoCache&) = delete;
    std::mutex mutex;
    std::unordered_map<std::string, std::shared_ptr<davinci::algorithm::ModelInfo>> modelInfoMap;
    std::shared_ptr<std::unordered_set<std::string>> modelCachePaths = std::make_shared<std::unordered_set<std::string>>();
public:
    static ModelsInfoCache& getInstance();

    std::shared_ptr<davinci::algorithm::ModelInfo> getModelInfo(const std::string &modelName);

    void saveModelInfo(const std::string &modelName, const std::shared_ptr<davinci::algorithm::ModelInfo> &modelInfo);

    void removeModelInfo(const std::string &modelName);

    std::unordered_set<std::string> getAllCachePaths() const;

    void addCachePath(const std::string& path);

    void clear();
};

#endif //DAVINCIRESOURCE_MODELSINFOCACHE_H
