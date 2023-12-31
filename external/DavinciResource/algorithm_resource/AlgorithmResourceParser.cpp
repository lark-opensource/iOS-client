//
// Created by wangchengyi.1 on 2021/5/27.
//

#include "AlgorithmResourceParser.h"
#include "AlgorithmResourceProtocol.h"
#include "DAVPublicUtil.h"
#include "nlohmann/json.hpp"
#include "AlgorithmResourceUtils.h"
#include <memory>

using davinci::algorithm::AlgorithmResourceParser;

davinci::algorithm::AlgorithmResourceParser::AlgorithmResourceParser(const std::shared_ptr<IRequirementsPeeker> &peeker,
                                                                     const davinci::resource::DavinciResourceId &resourceId)
        : davinci::resource::DAVResourceIdParser(resourceId) {

    std::unordered_set<std::string> requirements;
    if (queryParams.find(AlgorithmResourceProtocol::PARAM_REQUIREMENTS()) != queryParams.end()) {
        auto requirementsStr = queryParams.at(AlgorithmResourceProtocol::PARAM_REQUIREMENTS());
        auto requirementsStrSub = requirementsStr.substr(1, requirementsStr.size() - 2);
        auto list = resource::DAVPublicUtil::split(requirementsStrSub, ",");
        requirements = std::unordered_set<std::string>(list.begin(), list.end());
    }

    std::unordered_map<std::string, std::vector<std::string>> modelNamesMap;
    if (queryParams.find(AlgorithmResourceProtocol::PARAM_MODEL_NAME_MAP_STRING()) != queryParams.end()) {
        auto modelNamesMapString = queryParams.at(AlgorithmResourceProtocol::PARAM_MODEL_NAME_MAP_STRING());
        if (!modelNamesMapString.empty()) {
            nlohmann::json json = nlohmann::json::parse(modelNamesMapString);
            modelNamesMap = json.get<std::unordered_map<std::string, std::vector<std::string>>>();
        }
    }
    if (queryParams.find(AlgorithmResourceProtocol::PARAM_MODEL_NAME()) != queryParams.end()) {
        auto modelName = queryParams.at(AlgorithmResourceProtocol::PARAM_MODEL_NAME());
        modelNames.emplace(AlgorithmResourceUtils::getNormalizedNameOfModel(modelName));
    }

    for (auto &entry: modelNamesMap) {
        if (requirements.find(entry.first) != requirements.end()) {
            requirements.erase(entry.first);
        }
        for (const auto &item: entry.second) {
            modelNames.emplace(AlgorithmResourceUtils::getNormalizedNameOfModel(item));
        }
    }
    if (peeker != nullptr) {
        auto peekResult = peeker->peekRequirements(
                std::vector<std::string>(requirements.begin(), requirements.end()));
        for (const auto &item: peekResult) {
            modelNames.emplace(AlgorithmResourceUtils::getNormalizedNameOfModel(item));
        }
    }
}
