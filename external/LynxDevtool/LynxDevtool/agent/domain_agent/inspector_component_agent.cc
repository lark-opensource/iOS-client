// Copyright 2021 The Lynx Authors. All rights reserved.

#include "agent/domain_agent/inspector_component_agent.h"

#include "agent/devtool_agent_base.h"
#include "base/lynx_env.h"

namespace lynxdev {
namespace devtool {

using lynx::base::LynxEnv;

InspectorComponentAgent::InspectorComponentAgent() {
  functions_map_["Component.uselessUpdate"] =
      &InspectorComponentAgent::UselessUpdate;
}

InspectorComponentAgent::~InspectorComponentAgent() = default;

void InspectorComponentAgent::UselessUpdate(
    std::shared_ptr<DevToolAgentBase> devtool_agent,
    const Json::Value& message) {
  Json::Value content(Json::ValueType::objectValue);
  content["method"] = "Component.uselessUpdate";
  content["params"] = message["params"];
  devtool_agent->SendResponseAsync(content);
}

void InspectorComponentAgent::CallMethod(
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
