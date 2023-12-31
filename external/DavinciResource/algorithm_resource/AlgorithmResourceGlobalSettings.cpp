//
// Created by bytedance on 2021/4/21.
//
#include "AlgorithmResourceGlobalSettings.h"
#include "AlgorithmResourceFinder.h"

void davinci::algorithm::AlgorithmResourceGlobalSettings::setRequirementsPeeker(
        std::shared_ptr<IRequirementsPeeker> requirementsPeeker) {
    obtain()->requirementsPeeker = std::move(requirementsPeeker);
}

davinci::algorithm::AlgorithmResourceGlobalSettings *davinci::algorithm::AlgorithmResourceGlobalSettings::obtain() {
    static AlgorithmResourceGlobalSettings _instance;
    return &_instance;
}

void davinci::algorithm::AlgorithmResourceGlobalSettings::setBuildInModelFinder(
        std::shared_ptr<IBuildInModelFinder> buildInModelFinder) {
    obtain()->buildInModelFinder = std::move(buildInModelFinder);
}

davinci::algorithm::resource_finder davinci::algorithm::AlgorithmResourceGlobalSettings::getResourceFinder() {
    return AlgorithmResourceFinder::resourceFinder;
}

std::shared_ptr<davinci::algorithm::IRequirementsPeeker>
davinci::algorithm::AlgorithmResourceGlobalSettings::getRequirementsPeeker() {
    return obtain()->requirementsPeeker;
}

std::shared_ptr<davinci::algorithm::IBuildInModelFinder>
davinci::algorithm::AlgorithmResourceGlobalSettings::getBuildInModelFinder() {
    return obtain()->buildInModelFinder;
}
