// Copyright 2019 The Lynx Authors. All rights reserved.

#include "agent/domain_agent/inspector_agent.h"

#include "agent/devtool_agent_base.h"

namespace lynxdev {
namespace devtool {

InspectorAgent::InspectorAgent() {
  functions_map_["Inspector.enable"] = &InspectorAgent::Enable;
  functions_map_["Inspector.detached"] = &InspectorAgent::Enable;
}

InspectorAgent::~InspectorAgent() = default;

void InspectorAgent::Enable(std::shared_ptr<DevToolAgentBase> devtool_agent,
                            const Json::Value& message) {
  Json::Value response(Json::ValueType::objectValue);
  Json::Value content(Json::ValueType::objectValue);
  response["result"] = content;
  response["id"] = message["id"].asInt64();
  devtool_agent->SendResponseAsync(response);
}

void InspectorAgent::Detached(std::shared_ptr<DevToolAgentBase> devtool_agent,
                              const Json::Value& params) {
  Json::Value content;
  content["method"] = "Inspector.detached";
  content["params"] = Json::ValueType::objectValue;
  content["params"]["reason"] = "";
  devtool_agent->SendResponseAsync(content);
}

void InspectorAgent::CallMethod(std::shared_ptr<DevToolAgentBase> devtool_agent,
                                const Json::Value& message) {
  std::string method = message["method"].asString();
  auto iter = functions_map_.find(method);
  if (iter == functions_map_.end() || devtool_agent == nullptr) {
    Json::Value res;
    res["error"] = Json::ValueType::objectValue;
    res["error"]["code"] = kLynxInspectorErrorCode;
    res["error"]["message"] = "Not implemented: " + method;
    res["id"] = message["id"].asInt64();
    devtool_agent->SendResponseAsync(res);
  } else {
    (this->*(iter->second))(devtool_agent, message);
  }
}
}  // namespace devtool
}  // namespace lynxdev
