// Copyright 2019 The Lynx Authors. All rights reserved.

#include "agent/domain_agent/inspector_runtime_agent.h"

#include "agent/devtool_agent_base.h"

namespace lynxdev {
namespace devtool {

InspectorRuntimeAgent::InspectorRuntimeAgent() {
  functions_map_["Runtime.enable"] = &InspectorRuntimeAgent::Enable;
}

InspectorRuntimeAgent::~InspectorRuntimeAgent() = default;

void InspectorRuntimeAgent::Enable(
    std::shared_ptr<DevToolAgentBase> devtool_agent,
    const Json::Value& message) {
  Json::Value response(Json::ValueType::objectValue);
  Json::Value content(Json::ValueType::objectValue);
  Json::Value msg(Json::ValueType::objectValue);
  Json::Value target_info(Json::ValueType::objectValue);
  msg["method"] = "Target.targetCreated";
  target_info["targetId"] = "18D8BD1EDE86A29BECB29184EA054C2B";
  target_info["type"] = "page";
  target_info["title"] = "Lynx.html";
  target_info["url"] = "file:///Lynx.html";
  target_info["attached"] = true;
  target_info["browserContextId"] = "010415DBEC81C69AD53A0B5AB6078482";
  msg["params"] = Json::ValueType::objectValue;
  msg["params"]["targetInfo"] = target_info;
  msg["is_callback"] = "true";
  devtool_agent->DispatchJsonMessage(msg);
  response["result"] = content;
  response["id"] = message["id"].asInt64();
  devtool_agent->SendResponseAsync(response);
}

void InspectorRuntimeAgent::CallMethod(
    std::shared_ptr<DevToolAgentBase> devtool_agent,
    const Json::Value& message) {
  Json::Value res;

#if OS_IOS && (defined(__i386__) || defined(__arm__))
  std::string method = message["method"].asString();
  Json::Value params = message["params"];

  auto iter = functions_map_.find(method);
  if (iter == functions_map_.end()) {
    Json::Value res;
    res["error"] = Json::ValueType::objectValue;
    res["error"]["code"] = -32601;
    res["error"]["message"] = "Not implemented: " + method;
    res["id"] = message["id"].asInt64();
    devtool_agent->SendResponse(res.toStyledString());
  } else {
    (this->*(iter->second))(devtool_agent, params);
  }
#else
  if (message.get("is_callback", "") != "") {
    res = message;
    devtool_agent->SendResponseAsync(res);
  } else if (devtool_agent != nullptr) {
    res["runtime"] = "true";
    res["id"] = message["id"].asInt64();
    devtool_agent->DispatchMessageToJSEngine(message.toStyledString());
  }
#endif
}
}  // namespace devtool
}  // namespace lynxdev
