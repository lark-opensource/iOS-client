// Copyright 2022 The Lynx Authors. All rights reserved.

#include "agent/domain_agent/inspector_memory_agent.h"

#include "agent/devtool_agent_base.h"
#include "lepus/json_parser.h"

namespace lynxdev {
namespace devtool {
InspectorMemoryAgent::InspectorMemoryAgent() {
  functions_map_["Memory.GetAppMemoryInfo"] =
      &InspectorMemoryAgent::GetAppMemoryInfo;
  functions_map_["Memory.startTracing"] = &InspectorMemoryAgent::StartTracing;
  functions_map_["Memory.stopTracing"] = &InspectorMemoryAgent::StopTracing;
  functions_map_["Memory.startDump"] = &InspectorMemoryAgent::StartDump;
}

InspectorMemoryAgent::~InspectorMemoryAgent() = default;

void InspectorMemoryAgent::GetAppMemoryInfo(
    std::shared_ptr<DevToolAgentBase> devtool_agent,
    const Json::Value& message) {
  Json::Value response(Json::ValueType::objectValue);
  Json::Value result(Json::ValueType::objectValue);
  response["result"] = devtool_agent->GetAppMemoryInfo();
  response["id"] = message["id"].asInt64();
  devtool_agent->SendResponse(response.toStyledString());
}

void InspectorMemoryAgent::StartTracing(
    std::shared_ptr<DevToolAgentBase> devtoolagent,
    const Json::Value& message) {
  int id = static_cast<int>(message["id"].asInt64());
  devtoolagent->StartMemoryTracing();
  Json::Value response(Json::ValueType::objectValue);
  response["result"] = Json::Value(Json::ValueType::objectValue);
  response["id"] = id;
  devtoolagent->SendResponseAsync(response);
}

void InspectorMemoryAgent::StopTracing(
    std::shared_ptr<DevToolAgentBase> devtoolagent,
    const Json::Value& message) {
  int id = static_cast<int>(message["id"].asInt64());
  devtoolagent->StopMemoryTracing();
  Json::Value response(Json::ValueType::objectValue);
  response["result"] = Json::Value(Json::ValueType::objectValue);
  response["id"] = id;
  devtoolagent->SendResponseAsync(response);
}

void InspectorMemoryAgent::CallMethod(
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
    devtool_agent->SendResponse(res.toStyledString());
  }
}

void InspectorMemoryAgent::StartDump(
    std::shared_ptr<DevToolAgentBase> devtoolagent,
    const Json::Value& message) {
  int id = static_cast<int>(message["id"].asInt64());
  devtoolagent->StartMemoryDump();
  Json::Value response(Json::ValueType::objectValue);
  response["result"] = Json::Value(Json::ValueType::objectValue);
  response["id"] = id;
  devtoolagent->SendResponseAsync(response);
}

}  // namespace devtool
}  // namespace lynxdev
