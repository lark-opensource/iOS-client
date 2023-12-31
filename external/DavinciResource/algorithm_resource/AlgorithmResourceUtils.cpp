//
// Created by wangchengyi.1 on 2021/5/27.
//
#include "AlgorithmResourceUtils.h"
#include "AlgorithmResourceGlobalSettings.h"
#include "AlgorithmConstantsDefine.h"
#include "DavinciLogger.h"
#include <regex>
#include "DAVFile.h"

using davinci::algorithm::AlgorithmResourceUtils;

std::string davinci::algorithm::AlgorithmResourceUtils::getNormalizedNameOfModel(const std::string &modelName) {
    static std::regex REGEX_VERSION("([[:w:]]+)(_v[0-9])+.*");
    static std::regex REGEX_SUFFIX("([[:w:]]+)((\\.model)+|(_model)+|(\\.dat)+)");
    std::string normalizeName;
    try {
        auto index = modelName.find_last_of('/');
        if (index == modelName.size() - 1) {
            std::string error = "modelName is illegal, " + modelName;
            LOGGER->e(error.c_str());
            return "";
        }
        if (index == std::string::npos) {
            index = -1;
        }
        normalizeName = modelName.substr(index + 1, modelName.size());
        if (normalizeName.empty()) {
            std::string error = "normalizeName is empty, modelName is " + modelName;
            LOGGER->e(error.c_str());
            return "";
        }
        std::sregex_token_iterator pos{normalizeName.cbegin(), normalizeName.cend(), REGEX_VERSION, 1};
        std::sregex_token_iterator end;
        if (pos != end) {
            normalizeName = *pos;
        }
        pos = {normalizeName.cbegin(), normalizeName.cend(), REGEX_SUFFIX, 1};
        if (pos != end) {
            normalizeName = *pos;
        }
    } catch (std::exception &e) {
        LOGGER->e("getNormalizedNameOfModel error: %s", e.what() ? e.what() : "unknown error");
    }
    return normalizeName;
}

std::string davinci::algorithm::AlgorithmResourceUtils::getFullNameOfModel(
        const std::shared_ptr<davinci::algorithm::ModelInfo> &modelInfo) {
    return modelInfo->name
           + "_v" + modelInfo->version
           + "_size" + std::to_string(modelInfo->type)
           + "_md5" + modelInfo->file_url.uri
           + ".model";
}

bool
davinci::algorithm::AlgorithmResourceUtils::isModelDownloaded(const std::string &cacheDir,
                                                              const std::string &modelName,
                                                              const std::shared_ptr<davinci::algorithm::ModelInfo> &modelInfo) {
    if (AlgorithmResourceGlobalSettings::getBuildInModelFinder() != nullptr &&
        AlgorithmResourceGlobalSettings::getBuildInModelFinder()->isBuildInModel(modelName,
                                                                                 modelInfo->version,
                                                                                 modelInfo->type)) {
        return true;
    }
    return file::DAVFile::isFileExist(cacheDir + "/" + getFullNameOfModel(modelInfo));
}

void davinci::algorithm::AlgorithmResourceUtils::clearOldVersionOfModel(const std::string &cacheDir,
                                                                        const std::shared_ptr<davinci::algorithm::ModelInfo> &modelInfo) {
    std::string latestModelName = getFullNameOfModel(modelInfo);
    std::vector<std::string> fileList;
    file::DAVFile::getFileList(cacheDir, fileList);
    for (const auto &fileName:fileList) {
        if (latestModelName == fileName) {
            continue;
        }
        auto normalizedName = AlgorithmResourceUtils::getNormalizedNameOfModel(fileName);
        if (normalizedName == modelInfo->name) {
            file::DAVFile::removeFile(cacheDir + "/" + fileName);
        }
    }
}

std::string davinci::algorithm::AlgorithmResourceUtils::getModelPathFromModelUri(const std::string &modelUri) {
    if (modelUri.empty()) {
        return "";
    }
    if (modelUri == AlgorithmConstantsDefine::MODEL_NOT_FOUND()) {
        return "";
    }
    if (modelUri.size() <= AlgorithmConstantsDefine::MODEL_RESOURCE_URI_PREFIX().size()) {
        return "";
    }
    auto preFix = modelUri.substr(0, AlgorithmConstantsDefine::MODEL_RESOURCE_URI_PREFIX().size());
    if (preFix != AlgorithmConstantsDefine::MODEL_RESOURCE_URI_PREFIX()) {
        return "";
    }
    auto modelPath = modelUri.substr(AlgorithmConstantsDefine::MODEL_RESOURCE_URI_PREFIX().size());
    return modelPath;
}
