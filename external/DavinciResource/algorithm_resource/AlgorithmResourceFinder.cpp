//
// Created by bytedance on 2021/4/21.
//

#include "AlgorithmResourceFinder.h"
#include "AlgorithmResourceGlobalSettings.h"
#include "AlgorithmConstantsDefine.h"
#include "DAVFile.h"
#include "nlohmann/json.hpp"
#include "AlgorithmResourceUtils.h"
#include "ModelsInfoCache.h"

char *davinci::algorithm::AlgorithmResourceFinder::resourceFinder(void *handle, const char *dir,
                                                                  const char *name) {
    auto normalizedModelName = AlgorithmResourceUtils::getNormalizedNameOfModel(name);
    for (const auto &cacheDir: ModelsInfoCache::getInstance().getAllCachePaths()) {
        std::vector<std::string> fileList;
        file::DAVFile::getFileList(cacheDir, fileList);
        for (const auto &fileName:fileList) {
            auto normalizedFileName = AlgorithmResourceUtils::getNormalizedNameOfModel(fileName);
            if (normalizedFileName == normalizedModelName) {
                auto result = "file://" + cacheDir + "/" + fileName;
                return strcpy((char *) malloc(result.length() + 1), result.c_str());
            }
        }
    }
    auto result = AlgorithmConstantsDefine::MODEL_NOT_FOUND();
    if (AlgorithmResourceGlobalSettings::getBuildInModelFinder() != nullptr) {
        result = AlgorithmResourceGlobalSettings::getBuildInModelFinder()->findModelUri(name);
    }
    return strcpy((char *) malloc(result.length() + 1), result.c_str());
}
