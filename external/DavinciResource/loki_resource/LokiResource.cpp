//
// Created by wangchengyi.1 on 2021/4/7.
//

#include "LokiResource.h"
#include "DAVResourceIdParser.h"

using namespace davinci::resource;
using namespace davinci::loki;

ENUM_STR_IMPLEMENT(davinci::loki::LokiResourceProtocol::PLATFORM_STRING, "effect_platform");
ENUM_STR_IMPLEMENT(davinci::loki::LokiResourceProtocol::PARAM_EFFECT_ID, "effect_id");
ENUM_STR_IMPLEMENT(davinci::loki::LokiResourceProtocol::PARAM_RESOURCE_ID, "resource_id");
ENUM_STR_IMPLEMENT(davinci::loki::LokiResourceProtocol::PARAM_PANEL, "panel");

LokiResourceProtocol::LokiResourceProtocol(std::string effectId) : effectId(std::move(effectId)) {

}

LokiResourceProtocol::LokiResourceProtocol(std::string resourceId, std::string panel)
        : resourceId(std::move(resourceId)),
          panel(std::move(panel)) {
}

bool davinci::loki::LokiResourceProtocol::isLokiResource(const davinci::resource::DavinciResourceId &resourceId) {
    auto parser = davinci::resource::DAVResourceIdParser(resourceId);
    if (parser.host == PLATFORM_STRING()) {
        return true;
    }
    return false;
}

std::string davinci::loki::LokiResourceProtocol::getSourceFrom() {
    return PLATFORM_STRING();
}

std::unordered_map<std::string, std::string> davinci::loki::LokiResourceProtocol::getParameters() {
    std::unordered_map<std::string, std::string> params;
    if (!effectId.empty()) {
        params.emplace(std::make_pair(PARAM_EFFECT_ID(), effectId));
    }
    if (!resourceId.empty() && !panel.empty()) {
        params.emplace(std::make_pair(PARAM_RESOURCE_ID(), resourceId));
        params.emplace(std::make_pair(PARAM_PANEL(), panel));
    }
    return params;
}




