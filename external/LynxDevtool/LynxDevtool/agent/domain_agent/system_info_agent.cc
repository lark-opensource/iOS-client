// Copyright 2021 The Lynx Authors. All rights reserved.

#include "agent/domain_agent/system_info_agent.h"

#include "agent/devtool_agent_base.h"

namespace lynxdev {
namespace devtool {

SystemInfoAgent::SystemInfoAgent() {
  functions_map_["SystemInfo.getInfo"] = &SystemInfoAgent::getInfo;
}

SystemInfoAgent::~SystemInfoAgent() = default;

void SystemInfoAgent::getInfo(std::shared_ptr<DevToolAgentBase> devtool_agent,
                              const Json::Value& message) {
  Json::Value response(Json::ValueType::objectValue);
  Json::Value content(Json::ValueType::objectValue);
  content["modelName"] = devtool_agent->GetSystemModelName();
#if defined(OS_ANDROID)
  content["platform"] = "Android";
#else
  content["platform"] = "iOS";
#endif
  response["result"] = content;
  response["id"] = message["id"].asInt64();
  devtool_agent->SendResponseAsync(response);
}

void SystemInfoAgent::CallMethod(
    std::shared_ptr<DevToolAgentBase> devtool_agent,
    const Json::Value& content) {
  std::string method = content["method"].asString();
  auto iter = functions_map_.find(method);
  if (iter != functions_map_.end()) {
    (this->*(iter->second))(devtool_agent, content);
  } else {
    Json::Value res;
    res["error"] = Json::ValueType::objectValue;
    res["error"]["code"] = kLynxInspectorErrorCode;
    res["error"]["message"] = "Not implemented: " + method;
    res["id"] = content["id"].asInt64();
    devtool_agent->SendResponseAsync(res);
  }
}

}  // namespace devtool
}  // namespace lynxdev
