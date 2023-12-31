// Copyright 2021 The Lynx Authors. All rights reserved.

#include "agent/domain_agent/inspector_layout_agent.h"

#include "agent/devtool_agent_base.h"
#include "base/lynx_env.h"

namespace lynxdev {
namespace devtool {

using lynx::base::LynxEnv;

InspectorLayoutAgent::InspectorLayoutAgent() {
  functions_map_["Layout.enable"] = &InspectorLayoutAgent::Enable;
  functions_map_["Layout.disable"] = &InspectorLayoutAgent::Disable;
  functions_map_["Layout.dataCollected"] = &InspectorLayoutAgent::DataCollected;
}

InspectorLayoutAgent::~InspectorLayoutAgent() = default;

void InspectorLayoutAgent::Enable(
    std::shared_ptr<DevToolAgentBase> devtool_agent,
    const Json::Value& message) {
  Json::Value response(Json::ValueType::objectValue);
  Json::Value content(Json::ValueType::objectValue);
  response["result"] = content;
  response["id"] = message["id"].asInt64();
  devtool_agent->SendResponseAsync(response);
  // lynx_env.cc add switch
  devtool_agent->SetLynxEnv(LynxEnv::kLynxLayoutPerformanceEnable, true);
}

void InspectorLayoutAgent::Disable(
    std::shared_ptr<DevToolAgentBase> devtool_agent,
    const Json::Value& message) {
  Json::Value response(Json::ValueType::objectValue);
  Json::Value content(Json::ValueType::objectValue);
  response["result"] = content;
  response["id"] = message["id"].asInt64();
  devtool_agent->SendResponseAsync(response);
  // lynx_env.cc remove switch
  devtool_agent->SetLynxEnv(LynxEnv::kLynxLayoutPerformanceEnable, false);
}

void InspectorLayoutAgent::DataCollected(
    std::shared_ptr<DevToolAgentBase> devtool_agent,
    const Json::Value& message) {
  Json::Value content(Json::ValueType::objectValue);
  content["method"] = "Layout.dataCollected";
  content["params"] = message["params"];
  devtool_agent->SendResponseAsync(content);
}

void InspectorLayoutAgent::CallMethod(
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
