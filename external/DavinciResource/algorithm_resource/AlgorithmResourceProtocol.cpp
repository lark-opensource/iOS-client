//
// Created by wangchengyi.1 on 2021/4/7.
//

#include "AlgorithmResourceProtocol.h"

#include <utility>
#include "DAVResourceIdParser.h"
#include "DAVPublicUtil.h"

using davinci::algorithm::AlgorithmResourceProtocol;


ENUM_STR_IMPLEMENT(davinci::algorithm::AlgorithmResourceProtocol::PLATFORM_STRING, "algorithm_resource");
ENUM_STR_IMPLEMENT(davinci::algorithm::AlgorithmResourceProtocol::PARAM_REQUIREMENTS, "requirements");
ENUM_STR_IMPLEMENT(davinci::algorithm::AlgorithmResourceProtocol::PARAM_MODEL_NAME_MAP_STRING, "model_name_map");
ENUM_STR_IMPLEMENT(davinci::algorithm::AlgorithmResourceProtocol::PARAM_MODEL_NAME, "model_name");
ENUM_STR_IMPLEMENT(davinci::algorithm::AlgorithmResourceProtocol::PARAM_BUSI_ID, "busi_id");

davinci::algorithm::AlgorithmResourceProtocol::AlgorithmResourceProtocol(std::vector<std::string> requirements,
                                                                         std::string modelNameMapString)
        : requirements(std::move(requirements)), modelNameMapString(std::move(modelNameMapString)) {

}

davinci::algorithm::AlgorithmResourceProtocol::AlgorithmResourceProtocol(std::string modelName) : modelName(
        std::move(modelName)) {

}

std::string davinci::algorithm::AlgorithmResourceProtocol::getSourceFrom() {
    return PLATFORM_STRING();
}

std::unordered_map<std::string, std::string> davinci::algorithm::AlgorithmResourceProtocol::getParameters() {
    std::unordered_map<std::string, std::string> params;
    if (!requirements.empty()) {
        auto requirementsStr = davinci::resource::DAVPublicUtil::vector_join_to_string(requirements, ",", "[", "]");
        params.emplace(std::make_pair(PARAM_REQUIREMENTS(), requirementsStr));
    }
    if (!modelNameMapString.empty()) {
        params.emplace(std::make_pair(PARAM_MODEL_NAME_MAP_STRING(), modelNameMapString));
    }
    if (!modelName.empty()) {
        params.emplace(std::make_pair(PARAM_MODEL_NAME(), modelName));
    }
    return params;
}

bool davinci::algorithm::AlgorithmResourceProtocol::isAlgorithmResource(
        const davinci::resource::DavinciResourceId &resourceId) {
    auto parser = davinci::resource::DAVResourceIdParser(resourceId);
    if (parser.host == PLATFORM_STRING()) {
        return true;
    }
    return false;
}



