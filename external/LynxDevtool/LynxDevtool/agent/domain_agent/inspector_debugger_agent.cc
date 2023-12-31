// Copyright 2019 The Lynx Authors. All rights reserved.

#include "agent/domain_agent/inspector_debugger_agent.h"

#include "agent/devtool_agent_base.h"

namespace lynxdev {
namespace devtool {
constexpr char kMethodDebuggerSetLepusDebugActive[] =
    "Debugger.setLepusDebugActive";

InspectorDebuggerAgent::InspectorDebuggerAgent() = default;

InspectorDebuggerAgent::~InspectorDebuggerAgent() = default;

void InspectorDebuggerAgent::CallMethod(
    std::shared_ptr<DevToolAgentBase> devtool_agent,
    const Json::Value& message) {
  Json::Value res;
  if (message.get("is_callback", "") != "") {
    res = message;
  } else if (devtool_agent != nullptr) {
    devtool_agent->DispatchMessageToJSEngine(message.toStyledString());
    if (message.isMember("method") &&
        message["method"].asString() == kMethodDebuggerSetLepusDebugActive) {
      res["id"] = message["id"].asInt64();
      res["result"] = Json::Value(Json::ValueType::objectValue);
    }
  }
  devtool_agent->SendResponseAsync(res);
}
}  // namespace devtool
}  // namespace lynxdev
